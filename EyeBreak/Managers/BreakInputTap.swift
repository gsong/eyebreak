//
//  BreakInputTap.swift
//  EyeBreak
//
//  Holds the keyboard for the length of a break.
//
//  A full-screen overlay on every display stops the mouse, and making the
//  overlay key gets clicks. macOS routes plenty of keyboard past all of that
//  anyway: Cmd-Tab, Cmd-Q, Cmd-H, and every global hotkey any app has
//  registered. A break the user can type straight through is not a break.
//
//  ESC ends the break from here too. The overlay's own ESC monitor needs
//  EyeBreak to be frontmost, and macOS does not promise that: cooperative
//  activation can refuse an app that activates itself from a timer. The tap
//  sees the key whichever app has focus.
//
//  This is the riskiest code in the app. A live process holding an active tap
//  that no longer consumes correctly leaves the machine with no keyboard: no
//  Cmd-Q, no menu bar, no Activity Monitor. Recovery is a power cycle. A crash
//  is safe, because the tap dies with the process. The failure paths that matter
//  are a teardown that never runs, a state bug that keeps the tap alive past the
//  break, and a callback that blocks.
//
//  Three independent ways out, each of which works without the other two:
//
//  1. Cmd-Opt-Esc (Force Quit) always passes. See BreakInputPolicy.
//  2. Ctrl-Opt-Cmd-Esc, the panic chord, tears the tap down inside the callback,
//     on the callback's own thread, before the break is told anything.
//  3. A watchdog on its own queue tears the tap down at break duration plus a
//     fixed slack, and plus a fixed allowance when the break is going to wait to
//     be dismissed. It is armed once and reads no break state, so no state bug
//     can extend it. It gives the keyboard back and nothing else: a break still
//     waiting for the user keeps waiting.
//
//  Known limitation: Secure Event Input. While a password field has focus, macOS
//  routes no keyboard event to any tap, so interception silently stops for as
//  long as that field holds focus. There is no supported way around it and we do
//  not try. The break is still covered by the overlay; only the tap goes quiet.
//

import CoreGraphics
import Foundation

/// Installs a keyboard-only event tap for the duration of a break.
final class BreakInputTap {

    static let shared = BreakInputTap()

    private init() {}

    // MARK: - Public Methods

    /// Starts holding the keyboard. Does nothing if a tap is already installed.
    ///
    /// Creating the tap needs the Accessibility grant, and `CGEvent.tapCreate`
    /// returns nil without it. That is not an edge case: EyeBreak is ad-hoc
    /// signed, so macOS drops the grant on every update, which makes the
    /// grant-less path the normal state after each release. Without a tap the
    /// break falls back to the overlay alone — covered, the first click working,
    /// and ESC working once EyeBreak is frontmost. Weaker than the tap, never
    /// worse than before it existed. `AccessibilityPermission` is what watches
    /// for the grant and surfaces a missing one in Settings.
    ///
    /// `onEndBreak` runs on the main thread for bare ESC and for the panic
    /// chord. The chord tears the tap down first; ESC leaves that to the break's
    /// own teardown. Once the break has been served, ending it means dismissing
    /// it; `BreakTimerManager` decides that from the state, so nothing here has
    /// to know which phase the break is in.
    ///
    /// `awaitsDismissal` only lengthens the watchdog. It is read once, here, and
    /// never again.
    func start(
        breakDuration: TimeInterval,
        awaitsDismissal: Bool = false,
        onEndBreak: @escaping () -> Void
    ) {
        lock.lock()
        guard tapPort == nil else {
            lock.unlock()
            return
        }

        guard let port = createTap() else {
            lock.unlock()
            return
        }

        tapPort = port
        budget = TapReenableBudget()
        endBreakHandler = onEndBreak
        startWatchdog(after: BreakInputPolicy.watchdogDelay(
            forBreakOf: breakDuration,
            awaitsDismissal: awaitsDismissal
        ))
        lock.unlock()

        startTapThread(port)
    }

    /// Gives the keyboard back. Safe to call from any thread, and safe to call
    /// when no tap is installed, which is what lets every exit path call it.
    func stop() {
        lock.lock()
        guard let port = tapPort else {
            lock.unlock()
            return
        }
        tapPort = nil
        endBreakHandler = nil
        watchdog?.cancel()
        watchdog = nil
        lock.unlock()

        // The tap thread notices the cleared port and unwinds on its own, which
        // is what invalidates the port. This call is what actually restores
        // input, so it does not wait for that. If the two ever crossed, the
        // loser is a no-op on a port that is being destroyed either way.
        CGEvent.tapEnable(tap: port, enable: false)
    }

    // MARK: - Event Handling

    /// The whole hot path. It runs for every key the user presses, so it decides
    /// and returns: no allocation, no logging, no waiting on another thread.
    fileprivate func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        switch type {
        case .keyDown, .keyUp, .flagsChanged:
            break
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            recoverFromDisable()
            return nil
        default:
            // Nothing else is in the mask, and passing is the safe answer for
            // anything that turns up anyway.
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        switch BreakInputPolicy.decision(keyCode: keyCode, flags: event.flags) {
        case .consume:
            return nil
        case .pass:
            return Unmanaged.passUnretained(event)
        case .endBreak:
            // The release and any auto-repeat are consumed too, but only the
            // first press ends the break. Once is enough, and the release lands
            // after the break has already started tearing this tap down.
            if type == .keyDown, event.getIntegerValueField(.keyboardEventAutorepeat) == 0 {
                handleEscape()
            }
            return nil
        case .panic:
            handlePanicChord()
            return Unmanaged.passUnretained(event)
        }
    }

    /// Asks the main thread to end the break. The tap stays up until the break's
    /// teardown stops it, so the keys pressed between here and there are still
    /// held. If the main thread is wedged this does nothing, and that is what the
    /// panic chord is for.
    private func handleEscape() {
        lock.lock()
        let handler = endBreakHandler
        lock.unlock()

        DispatchQueue.main.async {
            handler?()
        }
    }

    /// Tears the tap down here, on the tap's own thread, and only then asks the
    /// main thread to end the break.
    ///
    /// The order matters. The chord exists for the case where the main thread is
    /// wedged, so nothing the keyboard depends on may be deferred to it: a
    /// deferred teardown would leave `tapPort` set, and the next break would find
    /// a tap already installed and quietly run without one.
    private func handlePanicChord() {
        lock.lock()
        let handler = endBreakHandler
        lock.unlock()

        stop()

        DispatchQueue.main.async {
            handler?()
        }
    }

    // MARK: - Watchdog

    /// The out that cannot be reasoned away. It is armed once with the tap and
    /// reads nothing after that: not the break state, not the countdown, not a
    /// setting. A bug anywhere else still ends with the keyboard back.
    ///
    /// It gives the keyboard back and stops there. A break waiting to be
    /// dismissed keeps waiting, because the overlay is not what has gone wrong,
    /// and a break the user has not acknowledged should not acknowledge itself.
    private func startWatchdog(after delay: TimeInterval) {
        let timer = DispatchSource.makeTimerSource(queue: watchdogQueue)
        timer.schedule(deadline: .now() + delay)
        timer.setEventHandler { [weak self] in
            self?.stop()
        }
        timer.resume()
        watchdog = timer
    }

    // MARK: - Tap Lifetime

    private func createTap() -> CFMachPort? {
        return CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: BreakInputPolicy.eventMask,
            callback: breakInputTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
    }

    /// The tap gets a thread of its own rather than the main run loop. The
    /// callback runs on whichever thread services the source, and a main thread
    /// busy with SwiftUI — or stuck behind a modal alert — would hold every
    /// keystroke on the machine for as long as it was busy.
    private func startTapThread(_ port: CFMachPort) {
        let thread = Thread { [weak self] in
            guard let self else { return }

            let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
            let runLoop = CFRunLoopGetCurrent()
            CFRunLoopAddSource(runLoop, source, .defaultMode)

            // `stop` can run before this thread has executed a single line, so
            // the tap only starts if it is still the one `stop` would tear down.
            if self.enableIfCurrent(port) {
                // A timed loop rather than CFRunLoopRun, so shutdown is a flag
                // the thread reads rather than a signal that has to arrive after
                // the loop is already running.
                while self.isCurrent(port) {
                    CFRunLoopRunInMode(.defaultMode, 0.5, false)
                }
            }

            CFRunLoopRemoveSource(runLoop, source, .defaultMode)
            CFMachPortInvalidate(port)
        }

        thread.name = "com.eyebreak.break-input-tap"
        thread.qualityOfService = .userInteractive
        thread.start()
    }

    private func isCurrent(_ port: CFMachPort) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return tapPort === port
    }

    /// Turns the tap on, but only under the lock `stop` clears the port behind.
    /// Whichever of the two gets the lock first wins outright, so a stop that
    /// lands mid-startup cannot be followed by a tap switching itself on.
    private func enableIfCurrent(_ port: CFMachPort) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard tapPort === port else { return false }
        CGEvent.tapEnable(tap: port, enable: true)
        return true
    }

    /// macOS disables a tap it is unhappy with. Re-enable it while the budget
    /// allows, then stop rather than fight — see `TapReenableBudget`. Giving up
    /// ends the keyboard hold, not the break.
    private func recoverFromDisable() {
        lock.lock()
        let port = tapPort
        let allowed = budget.claim()
        lock.unlock()

        guard let port else { return }

        if allowed {
            CGEvent.tapEnable(tap: port, enable: true)
        } else {
            stop()
        }
    }

    // MARK: - State

    /// Guards everything below. The tap thread, the watchdog queue and the main
    /// thread all reach this state.
    private let lock = NSLock()
    private let watchdogQueue = DispatchQueue(label: "com.eyebreak.break-input-watchdog")

    private var tapPort: CFMachPort?
    private var watchdog: DispatchSourceTimer?
    private var endBreakHandler: (() -> Void)?
    private var budget = TapReenableBudget()
}

// MARK: - C Callback

/// A tap callback is a C function pointer, so the tap carries `self` in its
/// refcon rather than a capture. The singleton outlives every tap it installs,
/// which is what makes the unretained reference safe.
private func breakInputTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon else { return Unmanaged.passUnretained(event) }
    let tap = Unmanaged<BreakInputTap>.fromOpaque(refcon).takeUnretainedValue()
    return tap.handle(type: type, event: event)
}
