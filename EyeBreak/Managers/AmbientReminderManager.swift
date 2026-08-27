//
//  AmbientReminderManager.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI
import AppKit
import Combine

/// Manages ambient eye exercise reminders that appear while working
class AmbientReminderManager: ObservableObject {

    // MARK: - Singleton

    static let shared = AmbientReminderManager()

    // MARK: - Properties

    private var reminderTimer: Timer?
    private var activeReminders: [NSWindow] = []
    @Published var isEnabled: Bool = false
    @Published var isPausedDueToScreenLock: Bool = false
    @Published var secondsUntilNextReminder: Int = 0
    private var nextReminderDate: Date?
    private var cancellables = Set<AnyCancellable>()

    private let reminderTypes: [ReminderType] = [
        .blink,
        .lookLeft,
        .lookRight,
        .lookUp,
        .lookDown,
        .lookAround
    ]

    // MARK: - Initialization

    private init() {
        setupScreenLockNotifications()
        startCountdownTimer()
    }

    // MARK: - Public Methods

    func startAmbientReminders() {
        guard !isEnabled else { return }
        isEnabled = true

        scheduleNextReminder()
    }

    func stopAmbientReminders() {
        isEnabled = false
        reminderTimer?.invalidate()
        reminderTimer = nil
        hideAllReminders()
    }

    func showAmbientReminder() {
        let settings = AppSettings.shared

        // Check if Smart Schedule allows reminders now
        if settings.smartScheduleEnabled && !settings.shouldShowBreaksNow {
            showOutsideWorkHoursAlert()
            return
        }

        showRandomReminder()
    }

    /// Force show reminder bypassing Smart Schedule (private, called from alert)
    private func forceShowReminder() {
        _showRandomReminderInternal(bypassSchedule: true)
    }

    // MARK: - Private Methods

    private func scheduleNextReminder() {
        guard isEnabled else { return }

        let settings = AppSettings.shared
        let interval = TimeInterval(settings.ambientReminderIntervalMinutes * 60)

        // Store the next reminder date
        nextReminderDate = Date().addingTimeInterval(interval)
        secondsUntilNextReminder = Int(interval)

        reminderTimer?.invalidate()
        reminderTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.showRandomReminder()
            self?.scheduleNextReminder()
        }
    }

    private func startCountdownTimer() {
        // Update countdown every second
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateCountdown()
            }
            .store(in: &cancellables)
    }

    /// Updates the countdown display every second
    private func updateCountdown() {
        // When paused, keep the saved value frozen - don't recalculate
        guard !isPausedDueToScreenLock else { return }

        // Only update if reminders are active and a date is set.
        // @Published fires on every assignment, not only on change, so assigning
        // an unchanged value would wake every observing view once a second even
        // when this feature is switched off. Only publish real changes.
        guard isEnabled, let nextDate = nextReminderDate else {
            if secondsUntilNextReminder != 0 {
                secondsUntilNextReminder = 0
            }
            return
        }

        // Calculate remaining seconds until next reminder
        let remaining = max(0, Int(nextDate.timeIntervalSinceNow))
        if remaining != secondsUntilNextReminder {
            secondsUntilNextReminder = remaining
        }
    }

    private func showRandomReminder() {
        _showRandomReminderInternal(bypassSchedule: false)
    }

    private func _showRandomReminderInternal(bypassSchedule: Bool) {
        guard isEnabled else { return }

        let settings = AppSettings.shared

        // Check Smart Schedule (unless bypassed)
        if !bypassSchedule && settings.smartScheduleEnabled && !settings.shouldShowBreaksNow {
            return
        }

        // Generate a new random color theme for this reminder (if using random color theme)
        settings.regenerateAmbientReminderRandomTheme()

        // Check if using custom reminder
        let reminderType: ReminderType
        if settings.useCustomReminder && !settings.customReminderEmoji.isEmpty {
            reminderType = .custom
        } else {
            reminderType = reminderTypes.randomElement() ?? .blink
        }

        // Get the screen with mouse cursor (the active screen user is on)
        let mouseLocation = NSEvent.mouseLocation
        let activeScreen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) ?? NSScreen.main ?? NSScreen.screens[0]
        let screenFrame = activeScreen.visibleFrame

        // Center horizontally, position at top with larger size for full text
        let windowWidth: CGFloat = 420
        let windowHeight: CGFloat = 110
        let x = screenFrame.midX - (windowWidth / 2)
        let y = screenFrame.maxY - windowHeight - 60  // 60pt from top

        let windowRect = NSRect(x: x, y: y, width: windowWidth, height: windowHeight)

        // Create floating window
        let window = NSWindow(
            contentRect: windowRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))  // Highest possible level - above everything
        // CRITICAL: Use .canJoinAllSpaces to show on ALL desktops simultaneously
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .transient, .fullScreenAuxiliary]
        window.hasShadow = false
        window.isMovable = false

        // Create SwiftUI view
        let contentView = AmbientReminderView(
            reminderType: reminderType,
            onDismiss: { [weak self, weak window] in
                self?.dismissReminder(window: window)
            }
        )

        window.contentView = NSHostingView(rootView: contentView)

        // CRITICAL: Force window to the calculated position on the active screen
        window.setFrame(windowRect, display: true, animate: false)

        // CRITICAL: Show window WITHOUT activating the app
        // This prevents desktop switching but still shows the reminder
        window.orderFrontRegardless()

        activeReminders.append(window)

        // Auto-dismiss after duration
        let duration = TimeInterval(settings.ambientReminderDurationSeconds)

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self, weak window] in
            self?.dismissReminder(window: window)
        }
    }

    private func dismissReminder(window: NSWindow?) {
        guard let window = window else { return }

        window.orderOut(nil)
        activeReminders.removeAll { $0 == window }
    }

    private func hideAllReminders() {
        activeReminders.forEach { $0.orderOut(nil) }
        activeReminders.removeAll()
    }
}

// MARK: - Reminder Type

// MARK: - Smart Schedule Alert Extension

extension AmbientReminderManager {
    private func showOutsideWorkHoursAlert() {
        let settings = AppSettings.shared
        let alert = NSAlert()
        alert.messageText = "Outside Work Hours"
        alert.informativeText = """
            Your Smart Schedule is active and ambient reminders are currently paused.

            Work Hours: \(settings.timeString(from: settings.workHoursStart)) - \
            \(settings.timeString(from: settings.workHoursEnd))

            Would you like to show a reminder anyway?
            """
        alert.alertStyle = .informational
        alert.icon = NSImage(systemSymbolName: "eye.circle", accessibilityDescription: "Ambient Reminder")

        alert.addButton(withTitle: "Show Anyway")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            // Force show reminder bypassing schedule
            forceShowReminder()
        }
    }

    // MARK: - Screen Lock Handling

    /// Sets up system notifications to automatically pause/resume reminders when screen locks
    private func setupScreenLockNotifications() {
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

        // Hide any active reminders
        hideAllReminders()

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
                self?.showRandomReminder()
                self?.scheduleNextReminder()
            }
        } else {
            // Time expired during lock - schedule immediately
            scheduleNextReminder()
        }
    }
}
