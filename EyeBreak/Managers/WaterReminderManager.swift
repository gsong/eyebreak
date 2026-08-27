//
//  WaterReminderManager.swift
//  EyeBreak
//
//  Created on October 18, 2025.
//

import SwiftUI
import AppKit
import Combine

/// Manages water drinking reminders to encourage hydration during work
class WaterReminderManager: ObservableObject {

    // MARK: - Singleton

    static let shared = WaterReminderManager()

    // MARK: - Properties

    // Internal rather than private: WaterReminderManager+Pausing.swift needs
    // these, and Swift's `private` does not reach across files.
    var reminderTimer: Timer?
    @Published var isEnabled: Bool = false
    @Published var isPausedDueToScreenLock: Bool = false
    @Published var secondsUntilNextReminder: Int = 0
    var nextReminderDate: Date?
    private var cancellables = Set<AnyCancellable>()

    // Preset water message templates (theme will be added at runtime)
    private struct MessageTemplate {
        let icon: String
        let title: String
        let message: String
    }

    private let waterMessages: [MessageTemplate] = [
        MessageTemplate(icon: "drop.fill", title: "Time for Water!", message: "Stay hydrated! Take a sip of water."),
        MessageTemplate(icon: "waterbottle.fill", title: "Hydration Check", message: "Don't forget to drink some water!"),
        MessageTemplate(icon: "drop.circle.fill", title: "Water Break", message: "Your body needs water. Take a quick sip!"),
        MessageTemplate(icon: "figure.water.fitness", title: "Stay Hydrated", message: "Grab a glass of water and refresh yourself."),
        MessageTemplate(icon: "drop.triangle.fill", title: "Quick Reminder", message: "Have you had water recently? Time to hydrate!"),
        MessageTemplate(icon: "cup.and.saucer.fill", title: "Drink Up!", message: "Keep your energy up with some water."),
        MessageTemplate(icon: "sparkles", title: "Hydration Time", message: "A sip of water helps you stay focused!"),
        MessageTemplate(icon: "leaf.fill", title: "Wellness Check", message: "Take a moment to drink some water.")
    ]

    // MARK: - Initialization

    private init() {
        setupScreenLockNotifications()
        startCountdownTimer()
    }

    // MARK: - Public Methods

    /// Start water reminders based on settings
    func startWaterReminders() {
        guard !isEnabled else { return }
        isEnabled = true

        scheduleNextReminder()
    }

    /// Stop water reminders
    func stopWaterReminders() {
        isEnabled = false
        reminderTimer?.invalidate()
        reminderTimer = nil
    }

    /// Show a water reminder immediately (manual trigger)
    func showWaterReminderNow() {
        let settings = AppSettings.shared

        // Check if Smart Schedule allows reminders now
        if settings.smartScheduleEnabled && !settings.shouldShowBreaksNow {
            showOutsideWorkHoursAlert()
            return
        }

        showWaterReminder()
    }

    /// Force show water reminder bypassing Smart Schedule (private, called from alert)
    func forceShowWaterReminder() {
        _showWaterReminderInternal(bypassSchedule: true)
    }

    // MARK: - Private Methods

    func scheduleNextReminder() {
        guard isEnabled else { return }

        let settings = AppSettings.shared
        let interval = settings.waterReminderInterval

        // Store the next reminder date
        nextReminderDate = Date().addingTimeInterval(interval)
        secondsUntilNextReminder = Int(interval)

        reminderTimer?.invalidate()
        reminderTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.showWaterReminder()
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

    func showWaterReminder() {
        _showWaterReminderInternal(bypassSchedule: false)
    }

    private func _showWaterReminderInternal(bypassSchedule: Bool) {
        guard isEnabled else { return }

        let settings = AppSettings.shared

        // Check Smart Schedule (unless bypassed)
        if !bypassSchedule && settings.smartScheduleEnabled && !settings.shouldShowBreaksNow {
            return
        }

        // Generate a new random color theme for this reminder (if using random color theme)
        settings.regenerateWaterReminderRandomTheme()
        let theme = settings.waterReminderTheme

        // Check if using custom reminder
        let message: WaterMessage
        if settings.useCustomWaterReminder && !settings.customWaterReminderMessage.isEmpty {
            message = WaterMessage(
                icon: settings.customWaterReminderIcon.isEmpty ? "drop.fill" : settings.customWaterReminderIcon,
                title: "Water Reminder",
                message: settings.customWaterReminderMessage,
                theme: theme
            )
        } else {
            // Use random preset message with theme
            let preset = waterMessages.randomElement() ?? waterMessages[0]
            message = WaterMessage(
                icon: preset.icon,
                title: preset.title,
                message: preset.message,
                theme: theme
            )
        }

        switch settings.waterReminderStyle {
        case .blurScreen:
            showBlurScreenReminder(message: message)
        case .ambient:
            showAmbientReminder(message: message)
        }
    }

    private func showBlurScreenReminder(message: WaterMessage) {
        // Play sound if enabled
        if AppSettings.shared.soundEnabled {
            NSSound(named: "Glass")?.play()
        }

        // Create blur screen overlay on active screen only - using same approach as break overlay
        if Thread.isMainThread {
            showWaterOverlayOnMainThread(message: message)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.showWaterOverlayOnMainThread(message: message)
            }
        }
    }

    private func showWaterOverlayOnMainThread(message: WaterMessage) {
        // Get the screen with mouse cursor (the active screen user is on)
        let mouseLocation = NSEvent.mouseLocation
        let activeScreen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) ?? NSScreen.main ?? NSScreen.screens[0]

        // Create overlay window using custom class (like BreakOverlayWindow)
        let window = WaterReminderWindow(
            contentRect: activeScreen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: activeScreen
        )

        // Configure window properties (matching break overlay)
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .transient]
        window.acceptsMouseMovedEvents = true
        window.isReleasedWhenClosed = false
        window.animationBehavior = .none
        window.alphaValue = 1.0
        window.hidesOnDeactivate = false
        window.canHide = false

        // CRITICAL: Force window frame to the active screen
        window.setFrame(activeScreen.frame, display: true, animate: false)

        // Create the content view with water reminder
        let contentView = WaterBlurOverlayView(
            message: message,
            onDismiss: { [weak window] in
                window?.orderOut(nil)
            }
        )

        let hostingController = NSHostingController(rootView: contentView)
        hostingController.view.frame = activeScreen.frame
        window.contentView = hostingController.view

        // CRITICAL: Use orderFrontRegardless() instead of makeKeyAndOrderFront()
        // This prevents desktop switching but still shows the overlay
        window.orderFrontRegardless()

        // No auto-dismiss - user must click the button to acknowledge
    }

    private func showAmbientReminder(message: WaterMessage) {
        // Play sound if enabled
        if AppSettings.shared.soundEnabled {
            NSSound(named: "Glass")?.play()
        }

        // Get the screen with mouse cursor (the active screen user is on)
        let mouseLocation = NSEvent.mouseLocation
        let activeScreen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) ?? NSScreen.main ?? NSScreen.screens[0]
        let screenFrame = activeScreen.visibleFrame

        // Center horizontally, position at top
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
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .transient, .fullScreenAuxiliary]
        window.hasShadow = false
        window.isMovable = false

        // Create SwiftUI view
        let contentView = WaterReminderView(
            message: message,
            onDismiss: { [weak window] in
                window?.orderOut(nil)
            }
        )

        window.contentView = NSHostingView(rootView: contentView)
        window.setFrame(windowRect, display: true, animate: false)
        window.orderFrontRegardless()

        // Auto-dismiss after 8 seconds (same as ambient reminders)
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak window] in
            window?.orderOut(nil)
        }
    }
}

// MARK: - Water Message Model

// MARK: - Water Reminder View

// MARK: - Water Blur Overlay View

// MARK: - Custom Window Class

// MARK: - Visual Effect Blur Helper

// MARK: - Preview

#Preview {
    WaterReminderView(
        message: WaterMessage(
            icon: "drop.fill",
            title: "Time for Water!",
            message: "Stay hydrated! Take a sip of water.",
            theme: ColorTheme(
                themeType: .defaultTheme,
                backgroundColorHex: "#4D99CC",  // Ocean blue
                backgroundOpacity: 0.75,
                textColorHex: "#FFFFFF",
                textOpacity: 0.95,
                secondaryTextColorHex: "#FFFFFF",
                secondaryTextOpacity: 0.75,
                accentColorHex: "#66CCFF",  // Light cyan
                accentOpacity: 0.85,
                glassBlurRadius: 1.0,
                glassHighlightOpacity: 0.25
            )
        ),
        onDismiss: {}
    )
    .frame(width: 500, height: 200)
    .background(Color.black.opacity(0.1))
}

// MARK: - Smart Schedule Alert Extension
