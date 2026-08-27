//
//  BreakTimerManager.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import Foundation
import Combine
import AppKit

/// Manages the core timer logic for work/break cycles
class BreakTimerManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = BreakTimerManager()
    
    // MARK: - Published Properties
    
    @Published var state: TimerState = .idle
    @Published var settings = AppSettings.shared
    
    // MARK: - Private Properties
    
    private var timer: Timer?
    private var remainingSeconds: Int = 0
    private var idleDetector: IdleDetector?
    private var cancellables = Set<AnyCancellable>()
    private var wasWorkingBeforePause = false
    private var isForcedBreak = false // Flag to bypass Smart Schedule during forced breaks
    
    // MARK: - Initialization
    
    private init() {
        setupIdleDetection()
        setupWorkspaceNotifications()
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Public Methods
    
    /// Start the timer from idle state
    func start() {
        guard state == .idle else { return }
        
        remainingSeconds = settings.workIntervalSeconds
        state = .working(remainingSeconds: remainingSeconds)
        startTimer()
        
        if settings.soundEnabled {
            SoundManager.shared.playSound(.start)
        }
    }
    
    /// Stop the timer and return to idle
    func stop() {
        timer?.invalidate()
        timer = nil
        state = .idle
        idleDetector?.stop()
        
        NotificationManager.shared.cancelAllNotifications()
    }
    
    /// Trigger an immediate break
    func takeBreakNow() {
        // Don't start a new break if a break is already on screen. A served one
        // waiting to be dismissed counts: it is still the last break, and
        // starting another on top of it would credit two for one rest.
        if case .breaking = state {
            return
        }
        if case .awaitingDismissal = state {
            return
        }
        
        // Check if Smart Schedule allows breaks now
        if settings.smartScheduleEnabled && !settings.shouldShowBreaksNow {
            showOutsideWorkHoursAlert()
            return
        }
        
        stop()
        remainingSeconds = settings.breakDurationSeconds
        state = .breaking(remainingSeconds: remainingSeconds)
        startTimer()
        showBreakOverlay(duration: remainingSeconds)
        
        if settings.soundEnabled {
            SoundManager.shared.playSound(.breakStart)
        }
    }
    
    /// Force a break even if outside work hours (from alert "Take Break Anyway")
    func forceBreakNow() {
        // Don't start a new break if a break is already on screen — see takeBreakNow.
        if case .breaking = state {
            return
        }
        if case .awaitingDismissal = state {
            return
        }
        
        // Set flag to bypass Smart Schedule checks during this break
        isForcedBreak = true
        
        stop()
        remainingSeconds = settings.breakDurationSeconds
        state = .breaking(remainingSeconds: remainingSeconds)
        startTimer()
        showBreakOverlay(duration: remainingSeconds)
        
        if settings.soundEnabled {
            SoundManager.shared.playSound(.breakStart)
        }
    }
    
    /// Skip the current break (discouraged!)
    func skipBreak() {
        // Once the break has been served there is nothing left to skip. Every
        // way out of the overlay arrives here — bare ESC from the keyboard tap,
        // ESC from the overlay's own monitor, the panic chord, and the button —
        // so the waiting state answers all four with a dismissal.
        if case .awaitingDismissal = state {
            dismissBreak()
            return
        }
        
        guard case .breaking = state else {
            // Stop or Pause during a break leaves the breaking state behind but
            // not the overlay. The overlay holds keyboard focus now, so leaving
            // it up would trap the user behind a screen that ignores ESC and
            // Skip. Tear it down instead.
            ScreenBlurManager.shared.hideOverlay()
            return
        }
        
        settings.updateStats(breaksSkipped: 1)
        endBreak()
        
        if settings.soundEnabled {
            SoundManager.shared.playSound(.skip)
        }
    }
    
    /// End the wait after a served break and go back to work.
    ///
    /// The next work interval is a full one. The break was credited when it was
    /// served, so the minutes spent waiting were the user's, not the timer's, and
    /// stats are not touched again here.
    func dismissBreak() {
        // Whichever style put the break on screen, this takes it back down —
        // before the state is checked, and even if Stop has already moved the
        // timer on. The Floating Window panel does not close itself on the way
        // here, and a panel whose only button had stopped working would have no
        // way to close at all.
        ScreenBlurManager.shared.hideOverlay()
        FloatingBreakWindow.shared?.hide()
        
        guard case .awaitingDismissal = state else { return }
        
        startNextWorkInterval()
    }
    
    /// Pause the timer
    func pause() {
        guard state.isActive else { return }
        
        let wasWorking: Bool
        switch state {
        case .working, .preBreak:
            wasWorking = true
        case .breaking:
            wasWorking = false
        default:
            wasWorking = true
        }
        
        timer?.invalidate()
        timer = nil
        state = .paused(wasWorking: wasWorking, remainingSeconds: remainingSeconds)
        wasWorkingBeforePause = wasWorking
        
        // A paused break has to lose its overlay. Nothing behind it is counting
        // any more, and an overlay left up holds the keyboard until its watchdog
        // gives it back. `resume()` puts the overlay back for what is left of
        // the break.
        if !wasWorking && usesScreenOverlay {
            ScreenBlurManager.shared.hideOverlay()
        }
    }
    
    /// Resume from paused state
    func resume() {
        guard case .paused(let wasWorking, let seconds) = state else { return }
        
        remainingSeconds = seconds
        if wasWorking {
            state = .working(remainingSeconds: remainingSeconds)
        } else {
            state = .breaking(remainingSeconds: remainingSeconds)
            
            // Put the break back on screen for what is left of it.
            if usesScreenOverlay {
                showBreakOverlay(duration: remainingSeconds)
            }
        }
        startTimer()
    }
    
    // MARK: - Private Methods
    
    private func startTimer() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        
        // Optimize: Use default run loop mode instead of common to reduce CPU usage
        // This prevents timer from firing during UI interactions
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .default)
        }
        
        // Start idle detection if enabled
        if settings.idleDetectionEnabled {
            idleDetector?.start()
        }
    }
    
    private func tick() {
        remainingSeconds -= 1
        
        // Check smart schedule - pause if outside work hours (UNLESS it's a forced break)
        if !isForcedBreak && !settings.shouldShowBreaksNow {
            if state.isActive && state != .paused(wasWorking: wasWorkingBeforePause, remainingSeconds: remainingSeconds) {
                pause()
                return
            }
        }
        
        switch state {
        case .working(let seconds):
            if remainingSeconds <= settings.preBreakWarningSeconds && seconds > settings.preBreakWarningSeconds {
                // Transition to pre-break warning
                state = .preBreak(remainingSeconds: remainingSeconds)
                NotificationManager.shared.sendPreBreakNotification(seconds: remainingSeconds)
            } else if remainingSeconds <= 0 {
                // Start break
                startBreak()
            } else {
                state = .working(remainingSeconds: remainingSeconds)
            }
            
        case .preBreak:
            if remainingSeconds <= 0 {
                startBreak()
            } else {
                state = .preBreak(remainingSeconds: remainingSeconds)
            }
            
        case .breaking:
            if remainingSeconds <= 0 {
                serveBreak()
            } else {
                state = .breaking(remainingSeconds: remainingSeconds)
            }
            
        default:
            break
        }
    }
    
    private func startBreak() {
        // Check if Smart Schedule allows breaks now
        if settings.smartScheduleEnabled && !settings.shouldShowBreaksNow {
            // Skip to next work session instead of showing break
            remainingSeconds = settings.workIntervalSeconds
            state = .working(remainingSeconds: remainingSeconds)
            return
        }
        
        remainingSeconds = settings.breakDurationSeconds
        state = .breaking(remainingSeconds: remainingSeconds)
        
        showBreakOverlay(duration: remainingSeconds)
        
        if settings.soundEnabled {
            SoundManager.shared.playSound(.breakStart)
        }
        
        NotificationManager.shared.sendBreakStartNotification()
    }
    
    /// The break ran its length. Credit it, then either go straight back to work
    /// or hold the overlay until the user says they are back.
    ///
    /// The guard is what keeps a break to one credit. The Floating Window style
    /// runs a clock of its own alongside this one and both reach zero, so this is
    /// called twice; the second call finds the state already moved on.
    private func serveBreak() {
        guard case .breaking = state else { return }
        
        guard settings.requireBreakDismissal else {
            endBreak()
            return
        }
        
        // Reset forced break flag
        isForcedBreak = false
        
        creditBreak()
        awaitDismissal()
    }
    
    /// The break is over and work starts again now. Either it ran out with the
    /// wait turned off, or the user skipped it — a skip is already a deliberate
    /// act, so it does not ask for a second one.
    private func endBreak() {
        // Reset forced break flag
        isForcedBreak = false
        
        creditBreak()
        
        ScreenBlurManager.shared.hideOverlay()
        
        startNextWorkInterval()
    }
    
    /// Records the break as taken. This is the moment the rest was served, which
    /// is not the moment the user comes back to the machine.
    private func creditBreak() {
        settings.updateStats(breaksCompleted: 1, breakTime: settings.breakDurationSeconds)
        
        if settings.soundEnabled {
            SoundManager.shared.playSound(.breakEnd)
        }
        
        NotificationManager.shared.sendBreakCompleteNotification()
    }
    
    /// Holds the overlay on screen with nothing counting behind it. No timer runs
    /// during the wait, which is also what keeps sleep, screen lock and idle
    /// detection from touching it: they all go through `pause()`, and `pause()`
    /// guards on `state.isActive`.
    private func awaitDismissal() {
        timer?.invalidate()
        timer = nil
        state = .awaitingDismissal
        
        ScreenBlurManager.shared.awaitBreakDismissal()
    }
    
    private func startNextWorkInterval() {
        remainingSeconds = settings.workIntervalSeconds
        state = .working(remainingSeconds: remainingSeconds)
        
        // The break's own timer is still running on the path straight back to
        // work, and `awaitDismissal` invalidated it on the other. Starting it
        // here covers both; `startTimer` invalidates whatever it replaces.
        startTimer()
    }
    
    /// Whether the break style puts a full-screen overlay up. The Floating
    /// Window style does not, and it runs its own timer, so pausing must leave
    /// it alone.
    private var usesScreenOverlay: Bool {
        switch settings.breakStyle {
        case .blurScreen, .eyeExercise:
            return true
        case .notificationOnly:
            return false
        }
    }
    
    private func showBreakOverlay(duration: Int) {
        switch settings.breakStyle {
        case .blurScreen:
            ScreenBlurManager.shared.showBreakOverlay(
                duration: duration,
                style: .blur
            ) { [weak self] in
                self?.skipBreak()
            }
        case .eyeExercise:
            ScreenBlurManager.shared.showBreakOverlay(
                duration: duration,
                style: .exercise
            ) { [weak self] in
                self?.skipBreak()
            }
        case .notificationOnly:
            // Show floating window instead of notification only
            let window = FloatingBreakWindow()
            window.show(
                duration: duration,
                onSkip: { [weak self] in
                    self?.skipBreak()
                },
                onComplete: { [weak self] in
                    self?.serveBreak()
                }
            )
        }
    }
    
    // MARK: - Idle Detection Setup
    
    private func setupIdleDetection() {
        idleDetector = IdleDetector(threshold: TimeInterval(settings.idleThresholdSeconds))
        
        idleDetector?.onIdleStateChanged = { [weak self] isIdle in
            guard let self = self else { return }
            
            if isIdle && self.state.isActive {
                // User went idle, pause timer
                self.pause()
                NotificationManager.shared.sendIdlePausedNotification()
            } else if !isIdle, case .paused = self.state {
                // User returned, resume timer
                self.resume()
            }
        }
    }
    
    // MARK: - Screen Lock and Sleep Handling
    
    /// Sets up system notifications to automatically pause/resume timer during sleep and screen lock
    private func setupWorkspaceNotifications() {
        // Mac sleep events
        NotificationCenter.default.publisher(for: NSWorkspace.willSleepNotification)
            .sink { [weak self] _ in
                self?.pause()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in
                if case .paused = self?.state {
                    self?.resume()
                }
            }
            .store(in: &cancellables)
        
        // Screen lock events
        let notificationCenter = DistributedNotificationCenter.default()
        
        notificationCenter.addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pause()
        }
        
        notificationCenter.addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            if case .paused = self?.state {
                self?.resume()
            }
        }
        
        // Screen saver events (treated same as screen lock)
        notificationCenter.addObserver(
            forName: NSNotification.Name("com.apple.screensaver.didstart"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pause()
        }
        
        notificationCenter.addObserver(
            forName: NSNotification.Name("com.apple.screensaver.didstop"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            if case .paused = self?.state {
                self?.resume()
            }
        }
    }
    
    // MARK: - Smart Schedule Alert
    
    private func showOutsideWorkHoursAlert() {
        let alert = NSAlert()
        alert.messageText = "Outside Work Hours"
        alert.informativeText = """
            Your Smart Schedule is active and breaks are currently paused.

            Work Hours: \(settings.timeString(from: settings.workHoursStart)) - \
            \(settings.timeString(from: settings.workHoursEnd))

            Would you like to take a break anyway or adjust your schedule?
            """
        alert.alertStyle = .informational
        alert.icon = NSImage(systemSymbolName: "clock.badge.exclamationmark", accessibilityDescription: "Schedule")
        
        alert.addButton(withTitle: "Take Break Anyway")
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn:
            // Take break anyway - use forceBreakNow method
            forceBreakNow()
        case .alertSecondButtonReturn:
            // Open settings
            NotificationCenter.default.post(name: NSNotification.Name("OpenSettings"), object: nil)
        default:
            break
        }
    }
}
