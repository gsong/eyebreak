//
//  BreakTimerManager+Break.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import Foundation
import Combine
import AppKit

// The break itself: starting it, crediting it, waiting for dismissal, and the overlay it shows.

extension BreakTimerManager {
    func startBreak() {
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
    /// Called twice in the Floating Window style, which runs a clock of its own
    /// alongside this one. `breakEndAction` is what keeps that to one credit.
    func serveBreak() {
        switch state.breakEndAction(awaitsDismissal: breakAwaitsDismissal) {
        case .ignore:
            return
        case .endNow:
            endBreak()
        case .awaitDismissal:
            // Reset forced break flag
            isForcedBreak = false

            creditBreak()
            awaitDismissal()
        }
    }

    /// The break is over and work starts again now. Either it ran out with the
    /// wait turned off, or the user skipped it — a skip is already a deliberate
    /// act, so it does not ask for a second one.
    func endBreak() {
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

    func startNextWorkInterval() {
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
    var usesScreenOverlay: Bool {
        switch settings.breakStyle {
        case .blurScreen, .eyeExercise:
            return true
        case .notificationOnly:
            return false
        }
    }

    func showBreakOverlay(duration: Int) {
        // One read of the setting for this break, shared by the overlay, the
        // keyboard watchdog and the end of the countdown. Toggling it mid-break
        // applies to the next break rather than to this one.
        breakAwaitsDismissal = settings.requireBreakDismissal

        switch settings.breakStyle {
        case .blurScreen:
            ScreenBlurManager.shared.showBreakOverlay(
                duration: duration,
                style: .blur,
                awaitsDismissal: breakAwaitsDismissal
            ) { [weak self] in
                self?.skipBreak()
            }
        case .eyeExercise:
            ScreenBlurManager.shared.showBreakOverlay(
                duration: duration,
                style: .exercise,
                awaitsDismissal: breakAwaitsDismissal
            ) { [weak self] in
                self?.skipBreak()
            }
        case .notificationOnly:
            // Show floating window instead of notification only
            let window = FloatingBreakWindow()
            window.show(
                duration: duration,
                awaitsDismissal: breakAwaitsDismissal,
                onSkip: { [weak self] in
                    self?.skipBreak()
                },
                onComplete: { [weak self] in
                    self?.serveBreak()
                },
                onDismiss: { [weak self] in
                    self?.dismissBreak()
                }
            )
        }
    }
}
