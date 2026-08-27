//
//  BreakTimerManager.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import Foundation
import Combine

/// Manages the core timer logic for work/break cycles
class BreakTimerManager: ObservableObject {

    // MARK: - Singleton

    static let shared = BreakTimerManager()

    // MARK: - Published Properties

    @Published var state: TimerState = .idle
    @Published var settings = AppSettings.shared

    // MARK: - Private Properties

    var timer: Timer?
    var remainingSeconds: Int = 0
    var idleDetector: IdleDetector?
    var cancellables = Set<AnyCancellable>()
    private var wasWorkingBeforePause = false
    var isForcedBreak = false // Flag to bypass Smart Schedule during forced breaks
    /// Whether the break now on screen will wait to be dismissed. Read once,
    /// when the break goes up, because the keyboard watchdog is armed from the
    /// same value: a setting toggled mid-break would otherwise leave the
    /// watchdog allowing for one behavior and the timer doing the other.
    var breakAwaitsDismissal = false

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
        // A served break waiting to be dismissed is still a break on screen.
        guard !state.hasBreakOnScreen else { return }

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
        guard !state.hasBreakOnScreen else { return }

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

    func startTimer() {
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

    // MARK: - Idle Detection Setup

    // MARK: - Screen Lock and Sleep Handling

    // MARK: - Smart Schedule Alert

}
