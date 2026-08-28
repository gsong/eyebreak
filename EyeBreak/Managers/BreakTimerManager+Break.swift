//
//  BreakTimerManager+Break.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import Foundation

// The break itself: starting it, announcing it, waiting for dismissal, and the overlay it shows.

extension BreakTimerManager {
    func startBreak() {
        remainingSeconds = settings.breakDurationSeconds
        state = .breaking(remainingSeconds: remainingSeconds)

        showBreakOverlay(duration: remainingSeconds)

        if settings.soundEnabled {
            SoundManager.shared.playSound(.breakStart)
        }

        NotificationManager.shared.sendBreakStartNotification()
    }

    /// The break ran its length. Announce it, then either go straight back to work
    /// or hold the overlay until the user says they are back.
    ///
    /// Reads what the break was started under, not what the setting says now. The
    /// keyboard watchdog was armed from the same value, so the two cannot disagree.
    func serveBreak() {
        if breakAwaitsDismissal {
            announceBreakServed()
            awaitDismissal()
        } else {
            endBreak()
        }
    }

    /// The break is over and work starts again now. Either it ran out with the
    /// wait turned off, or the user skipped it — a skip is already a deliberate
    /// act, so it does not ask for a second one.
    func endBreak() {
        announceBreakServed()

        ScreenBlurManager.shared.hideOverlay()

        startNextWorkInterval()
    }

    /// Says the rest was served, with a sound and a notification. This is the
    /// moment the break ran out, which is not the moment the user comes back to
    /// the machine.
    private func announceBreakServed() {
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

    func showBreakOverlay(duration: Int) {
        // One read of the setting for this break, shared by the overlay, the
        // keyboard watchdog and the end of the countdown. Toggling it mid-break
        // applies to the next break rather than to this one.
        breakAwaitsDismissal = settings.requireBreakDismissal

        ScreenBlurManager.shared.showBreakOverlay(
            duration: duration,
            awaitsDismissal: breakAwaitsDismissal
        ) { [weak self] in
            self?.skipBreak()
        }
    }
}
