//
//  ScreenBlurManager.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import AppKit
import SwiftUI

/// Manages full-screen blur overlay during breaks
class ScreenBlurManager {

    static let shared = ScreenBlurManager()

    private var overlayWindows: [NSWindow] = []
    private var hostingViews: [NSHostingView<BreakOverlayView>] = []
    /// The app that was frontmost when the break started. The overlay activates
    /// EyeBreak to take keyboard focus, so it has to hand focus back on the way out.
    private var previousFrontmostApp: NSRunningApplication?
    /// The one clock behind every screen's overlay.
    private var countdown: BreakCountdown?
    /// The style and the skip closure of the break in progress. A rebuild needs
    /// both, and only `showBreakOverlay` is given them.
    private var overlayStyle: OverlayStyle = .blur
    private var skipHandler: (() -> Void)?
    /// The overlay on the screen that held the pointer when the windows were
    /// built. Only one window can be key, and only one should claim VoiceOver.
    private var keyOverlayWindow: NSWindow?
    /// The screen frames the current windows cover, in a fixed order. macOS
    /// posts a screen change for things that leave the layout alone, so this is
    /// what says whether a rebuild is worth the flicker.
    private var coveredFrames: [CGRect] = []
    private var screenChangeObserver: NSObjectProtocol?
    private var escapeMonitor: Any?
    private let windowQueue = DispatchQueue(label: "com.eyebreak.window", qos: .userInteractive)

    enum OverlayStyle {
        case blur
        case exercise
    }

    private init() {}

    // MARK: - Public Methods

    /// - Parameter awaitsDismissal: Whether this break will wait to be dismissed
    ///   once it has been served. All it does here is lengthen the keyboard
    ///   watchdog, and the caller decides it: a break reads the setting, and the
    ///   Settings preview never waits.
    func showBreakOverlay(
        duration: Int,
        style: OverlayStyle,
        awaitsDismissal: Bool,
        onSkip: @escaping () -> Void
    ) {

        // Optimize: Execute on main thread directly if already on main thread
        if Thread.isMainThread {
            self.showOverlayOnMainThread(
                duration: duration,
                style: style,
                awaitsDismissal: awaitsDismissal,
                onSkip: onSkip
            )
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.showOverlayOnMainThread(
                    duration: duration,
                    style: style,
                    awaitsDismissal: awaitsDismissal,
                    onSkip: onSkip
                )
            }
        }
    }

    /// Swaps the overlay to its completion state and leaves it up.
    ///
    /// The keyboard tap stays installed, so the ways out of a break are still the
    /// ways out of this. A break style with no overlay has nothing to swap, which
    /// is what the guard inside the countdown covers.
    func awaitBreakDismissal() {
        if Thread.isMainThread {
            self.countdown?.awaitDismissal()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.countdown?.awaitDismissal()
            }
        }
    }

    func hideOverlay() {

        // Optimize: Execute on main thread directly if already on main thread
        if Thread.isMainThread {
            self.hideOverlayOnMainThread()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.hideOverlayOnMainThread()
            }
        }
    }

    // MARK: - Private Methods

    private func showOverlayOnMainThread(
        duration: Int,
        style: OverlayStyle,
        awaitsDismissal: Bool,
        onSkip: @escaping () -> Void
    ) {
        // Generate a new random color theme for this break overlay (if using random color theme)
        AppSettings.shared.regenerateBreakOverlayRandomTheme()

        // Clear anything a previous break left behind, the keyboard tap included.
        // Starting a break inside a break must not leave the last one's watchdog
        // holding the only teardown.
        self.closeOverlayWindows()
        self.countdown?.stop()
        BreakInputTap.shared.stop()

        self.overlayStyle = style
        self.skipHandler = {
            // Ensure onSkip is called on main thread safely
            if Thread.isMainThread {
                onSkip()
            } else {
                DispatchQueue.main.async {
                    onSkip()
                }
            }
        }

        // One countdown for the whole break, not one per screen. N timers would
        // drift apart, and a rebuild would restart the count. It only draws:
        // reaching zero here ends nothing, because `BreakTimerManager` owns that
        // transition and two clocks racing for it was safe only by accident.
        let countdown = BreakCountdown(totalSeconds: duration)
        self.countdown = countdown

        // Remember who had focus so the break can hand it back. Ignore EyeBreak
        // itself, or a preview started from Settings would make us the app we
        // return to.
        let frontmost = NSWorkspace.shared.frontmostApplication
        if frontmost?.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            self.previousFrontmostApp = frontmost
        }

        self.buildOverlayWindows()

        // The overlay has to be modal, so the app activates and a window takes
        // key status. This is a request, not a guarantee: under cooperative
        // activation (macOS 14+) the system can refuse an app that activates
        // itself from a timer while another app is frontmost. The windows join
        // all Spaces, so EyeBreak always has one on the current Space, which is
        // what keeps a granted activation from switching Spaces.
        NSApp.activate()
        self.keyOverlayWindow?.makeKey()

        // Covering every screen and holding focus still leaves macOS routing
        // Cmd-Tab, Cmd-Q and every registered global hotkey past the overlay.
        // The tap is what closes that. It is also what makes ESC end the break
        // whether or not the activation above was granted: the tap sees the key
        // whichever app has focus, where the local monitor below sees it only
        // once EyeBreak is frontmost.
        BreakInputTap.shared.start(
            breakDuration: TimeInterval(duration),
            awaitsDismissal: awaitsDismissal
        ) { [weak self] in
            self?.skipHandler?()
        }

        countdown.start()
        self.startObservingScreenChanges()
        self.startMonitoringEscape()
    }

    private func hideOverlayOnMainThread() {

        // First, ahead of the window teardown. Every exit path from a break ends
        // up here, and the keyboard should come back on the earliest of them.
        BreakInputTap.shared.stop()

        self.stopObservingScreenChanges()
        self.stopMonitoringEscape()

        self.countdown?.stop()
        self.countdown = nil
        self.skipHandler = nil

        self.closeOverlayWindows()

        // Give focus back to whatever the break interrupted. Every way out of a
        // break — timer expiry, ESC, the Skip button, and Stop or Pause from the
        // menu — ends up here.
        //
        // `from: .current` tells macOS that EyeBreak is yielding, which is what
        // lets the other app take focus under cooperative activation.
        if let previous = self.previousFrontmostApp {
            self.previousFrontmostApp = nil
            _ = previous.activate(from: .current)
        }
    }

    // MARK: - Overlay Windows

    /// Covers every attached screen. A break that covers one of three displays
    /// is not modal: the other two stay visible and stay clickable.
    private func buildOverlayWindows() {
        guard let countdown = self.countdown, let onSkip = self.skipHandler else { return }

        let screens = NSScreen.screens

        // The screen holding the pointer is the one the user was working on. It
        // takes key status, and its overlay is the one VoiceOver should land on.
        // Both are single-window jobs, so the other screens must not claim them.
        let mouseLocation = NSEvent.mouseLocation
        let pointerScreen = screens.first { NSMouseInRect(mouseLocation, $0.frame, false) } ?? screens.first

        for screen in screens {
            let window = self.createOverlayWindow(for: screen)

            // CRITICAL: Force window frame to this screen
            window.setFrame(screen.frame, display: true, animate: false)

            // Every screen shows the full break. The user may be looking at any
            // of them, and "the active screen" stops meaning anything once the
            // overlay holds focus.
            let overlayView = BreakOverlayView(
                countdown: countdown,
                style: self.overlayStyle,
                onSkip: onSkip,
                claimsAccessibilityFocus: screen == pointerScreen
            )

            let hostingView = FirstMouseHostingView(rootView: overlayView)
            hostingView.frame = CGRect(origin: .zero, size: screen.frame.size)

            window.contentView = hostingView
            window.orderFrontRegardless()

            self.overlayWindows.append(window)
            self.hostingViews.append(hostingView)

            if screen == pointerScreen {
                self.keyOverlayWindow = window
            }
        }

        self.coveredFrames = Self.sortedFrames(of: screens)
    }

    private func closeOverlayWindows() {
        self.close(self.overlayWindows)

        // Clear arrays
        self.overlayWindows.removeAll()
        self.hostingViews.removeAll()
        self.coveredFrames.removeAll()
        self.keyOverlayWindow = nil
    }

    private func close(_ windows: [NSWindow]) {
        // First, remove content views to break retain cycles
        for window in windows {
            window.contentView = nil
            window.orderOut(nil)
        }

        // Then close windows
        for window in windows {
            window.close()
        }
    }

    private func createOverlayWindow(for screen: NSScreen) -> NSWindow {
        let window = BreakOverlayWindow(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: screen
        )

        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))  // Highest possible level - above everything
        window.backgroundColor = .clear  // Clear background for blur effect
        window.isOpaque = false  // Allow transparency
        window.hasShadow = false
        window.ignoresMouseEvents = false
        // CRITICAL: Use .canJoinAllSpaces to show on ALL desktops simultaneously
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .transient]
        window.acceptsMouseMovedEvents = true
        window.isReleasedWhenClosed = false
        window.animationBehavior = .none
        window.alphaValue = 1.0  // Full opacity
        window.hidesOnDeactivate = false
        window.canHide = false

        return window
    }

    // MARK: - Display Changes

    private func startObservingScreenChanges() {
        guard self.screenChangeObserver == nil else { return }

        self.screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.rebuildOverlayWindowsIfScreensChanged()
        }
    }

    private func stopObservingScreenChanges() {
        guard let observer = self.screenChangeObserver else { return }
        NotificationCenter.default.removeObserver(observer)
        self.screenChangeObserver = nil
    }

    /// Rebuilds the overlay for the screens attached right now. A display added
    /// mid-break must not stay an uncovered hole, and removing one must not end
    /// the break. The countdown is left alone, so the remaining time carries over.
    private func rebuildOverlayWindowsIfScreensChanged() {
        guard self.countdown != nil else { return }
        guard Self.sortedFrames(of: NSScreen.screens) != self.coveredFrames else { return }

        // Build the replacements before dropping the old windows. An overlay
        // that goes to zero windows, even for an instant, hands focus back to
        // whatever is underneath and stops being modal.
        let stale = self.overlayWindows
        self.overlayWindows.removeAll()
        self.hostingViews.removeAll()
        self.keyOverlayWindow = nil

        self.buildOverlayWindows()
        self.keyOverlayWindow?.makeKey()

        self.close(stale)
    }

    /// Screen frames in a fixed order. `NSScreen.screens` puts the main screen
    /// first, so choosing a different main display reorders it without moving a
    /// single pixel. Sorting keeps that out of the rebuild test.
    private static func sortedFrames(of screens: [NSScreen]) -> [CGRect] {
        screens.map(\.frame).sorted { lhs, rhs in
            (lhs.origin.x, lhs.origin.y, lhs.width, lhs.height)
                < (rhs.origin.x, rhs.origin.y, rhs.width, rhs.height)
        }
    }

    // MARK: - Escape Key

    /// One ESC monitor for the whole overlay set. It used to live in the SwiftUI
    /// view, which with a view per screen would install one monitor per display.
    ///
    /// With the keyboard tap installed this never fires: the tap consumes bare
    /// ESC and ends the break itself. It is the fallback for a break without the
    /// Accessibility grant, and there it works only once EyeBreak is frontmost,
    /// which may take a click on the overlay.
    private func startMonitoringEscape() {
        guard self.escapeMonitor == nil else { return }

        self.escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Bare ESC only. The keyboard tap passes two Escape chords on
            // purpose — Force Quit and the panic chord — and matching the key
            // code alone would quietly turn both of them into a skip.
            guard BreakInputPolicy.isBreakEndingEscape(
                keyCode: Int64(event.keyCode),
                modifiers: Self.eventFlags(of: event.modifierFlags)
            ) else { return event }

            // Deferred, like the Skip button. Skipping removes this monitor and
            // closes the key window, and doing either inside AppKit's dispatch
            // of the event pulls them out from under it.
            let skip = self?.skipHandler
            DispatchQueue.main.async {
                skip?()
            }
            return nil  // Consume the event
        }
    }

    /// The modifiers of an AppKit event, in the terms the tap's rules are written
    /// in. One definition of "bare ESC" serves the monitor and the tap; only the
    /// event types differ.
    private static func eventFlags(of modifiers: NSEvent.ModifierFlags) -> CGEventFlags {
        var flags: CGEventFlags = []
        if modifiers.contains(.command) { flags.insert(.maskCommand) }
        if modifiers.contains(.option) { flags.insert(.maskAlternate) }
        if modifiers.contains(.control) { flags.insert(.maskControl) }
        if modifiers.contains(.shift) { flags.insert(.maskShift) }
        return flags
    }

    private func stopMonitoringEscape() {
        guard let monitor = self.escapeMonitor else { return }
        NSEvent.removeMonitor(monitor)
        self.escapeMonitor = nil
    }
}

// MARK: - Custom Content View

/// Hosting view that takes the click which activates EyeBreak instead of
/// swallowing it. Without this the first click on the overlay only brings the
/// app forward, and a skip needs two clicks.
private final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}

// MARK: - Custom Window Class

/// Custom NSWindow that can become key window even when borderless
class BreakOverlayWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }
}

// MARK: - Sound Manager

class SoundManager {

    static let shared = SoundManager()

    enum SoundType {
        case start
        case breakStart
        case breakEnd
        case skip
    }

    private init() {}

    func playSound(_ type: SoundType) {
        let soundName: NSSound.Name

        switch type {
        case .start:
            soundName = .init("Blow")
        case .breakStart:
            soundName = .init("Glass")
        case .breakEnd:
            soundName = .init("Purr")
        case .skip:
            soundName = .init("Tink")
        }

        NSSound(named: soundName)?.play()
    }
}
