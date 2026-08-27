//
//  WaterReminderManager+Pausing.swift
//  EyeBreak
//
//  Created on October 18, 2025.
//

import SwiftUI
import AppKit
import UserNotifications
import Combine

// Everything that stops a reminder firing: the Smart Schedule override
// and the screen-lock pause.

extension WaterReminderManager {
    func showOutsideWorkHoursAlert() {
        let settings = AppSettings.shared
        let alert = NSAlert()
        alert.messageText = "Outside Work Hours"
        alert.informativeText = """
            Your Smart Schedule is active and water reminders are currently paused.

            Work Hours: \(settings.timeString(from: settings.workHoursStart)) - \
            \(settings.timeString(from: settings.workHoursEnd))

            Would you like to show a reminder anyway?
            """
        alert.alertStyle = .informational
        alert.icon = NSImage(systemSymbolName: "drop.circle", accessibilityDescription: "Water Reminder")

        alert.addButton(withTitle: "Show Anyway")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            // Force show reminder bypassing schedule
            forceShowWaterReminder()
        }
    }

    // MARK: - Screen Lock Handling

    /// Sets up system notifications to automatically pause/resume reminders when screen locks
    func setupScreenLockNotifications() {
        let notificationCenter = DistributedNotificationCenter.default()

        // Screen lock events
        notificationCenter.addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pauseForScreenLock()
        }

        notificationCenter.addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resumeFromScreenLock()
        }

        // Screen saver events (treated same as screen lock)
        notificationCenter.addObserver(
            forName: NSNotification.Name("com.apple.screensaver.didstart"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pauseForScreenLock()
        }

        notificationCenter.addObserver(
            forName: NSNotification.Name("com.apple.screensaver.didstop"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resumeFromScreenLock()
        }
    }

    /// Pauses the reminder timer when screen locks, preserving the remaining time
    private func pauseForScreenLock() {
        guard isEnabled else { return }

        // Mark as paused
        isPausedDueToScreenLock = true

        // Stop the timer
        reminderTimer?.invalidate()
        reminderTimer = nil

        // Save the remaining seconds before clearing the date
        // This preserves the countdown value for display and resume
        if let nextDate = nextReminderDate {
            secondsUntilNextReminder = max(0, Int(nextDate.timeIntervalSinceNow))
        }

        // Clear the date to prevent updateCountdown() from recalculating
        nextReminderDate = nil
    }

    /// Resumes the reminder timer when screen unlocks, continuing from saved time
    private func resumeFromScreenLock() {
        guard isEnabled && isPausedDueToScreenLock else { return }

        // Clear paused flag
        isPausedDueToScreenLock = false

        // Resume with saved remaining time
        if secondsUntilNextReminder > 0 {
            let remaining = TimeInterval(secondsUntilNextReminder)
            nextReminderDate = Date().addingTimeInterval(remaining)

            // Schedule timer to fire after the remaining time
            reminderTimer = Timer.scheduledTimer(withTimeInterval: remaining, repeats: false) { [weak self] _ in
                self?.showWaterReminder()
                self?.scheduleNextReminder()
            }
        } else {
            // Time expired during lock - schedule immediately
            scheduleNextReminder()
        }
    }
}
