//
//  StatusBarController.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import AppKit
import SwiftUI
import Combine

class StatusBarController: NSObject, ObservableObject {
    private(set) var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()
    private var timerManager = BreakTimerManager.shared

    override init() {
        super.init()
        // Setup status bar synchronously on main thread
        if Thread.isMainThread {
            self.setupStatusBar()
        } else {
            DispatchQueue.main.sync {
                self.setupStatusBar()
            }
        }

        // Subscribe to timer state changes to update menu bar text
        setupTimerObserver()
    }

    // MARK: - Timer Observer

    private func setupTimerObserver() {
        timerManager.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateMenuBarText(for: state)
            }
            .store(in: &cancellables)
    }

    private func updateMenuBarText(for state: TimerState) {
        guard let button = statusItem?.button else { return }

        let icon = NSImage(systemSymbolName: Self.iconName(for: state),
                           accessibilityDescription: "EyeBreak")
        icon?.isTemplate = true
        // Menu bar sizing. Without it the symbol renders at its natural size.
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium, scale: .small)
        button.image = icon?.withSymbolConfiguration(config)

        let timeText = timeText(for: state)
        if timeText.isEmpty {
            button.imagePosition = .imageOnly
            button.title = ""
        } else {
            button.imagePosition = .imageLeading
            button.title = " \(timeText)"
            // Monospaced digits, so the countdown does not shift the menu bar
            // as it ticks.
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
                .foregroundColor: NSColor.labelColor
            ]
            button.attributedTitle = NSAttributedString(string: " \(timeText)", attributes: attributes)
        }

        button.toolTip = tooltipText(for: state)
    }

    private static func iconName(for state: TimerState) -> String {
        switch state {
        case .idle:
            return "eye"
        case .working, .preBreak:
            return "eye.fill"
        case .breaking:
            return "eye.slash.fill"
        case .paused:
            return "pause.circle"
        case .awaitingDismissal:
            // The break is already banked, so the icon says done rather than
            // resting. There is no eye symbol with a checkmark badge to use.
            return "checkmark.circle.fill"
        }
    }

    /// The countdown shown beside the icon. Empty when nothing is counting.
    private func timeText(for state: TimerState) -> String {
        switch state {
        case .idle, .awaitingDismissal:
            return ""
        case .working(let seconds), .preBreak(let seconds), .breaking(let seconds):
            return formatTimeCompact(seconds)
        case .paused(_, let seconds):
            return formatTimeCompact(seconds)
        }
    }

    private func formatTimeCompact(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60

        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", secs))"
        } else {
            return "0:\(String(format: "%02d", secs))"
        }
    }

    private func tooltipText(for state: TimerState) -> String {
        switch state {
        case .idle:
            return "EyeBreak - Click to start"
        case .working(let seconds):
            return "Working - Break in \(formatTimeCompact(seconds))"
        case .preBreak(let seconds):
            return "Break starting in \(seconds) seconds"
        case .breaking(let seconds):
            return "On break - \(seconds) seconds remaining"
        case .paused:
            return "Timer paused"
        case .awaitingDismissal:
            return "Break complete - dismiss to continue"
        }
    }

    private func setupStatusBar() {
        // Variable length, because the button grows a countdown beside the icon.
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let item = statusItem, let button = item.button else { return }

        configureStatusButton(button)
        item.isVisible = true
        item.behavior = []                        // Empty means the user cannot remove it.
        item.autosaveName = "EyeBreakStatusItem"  // Persist the position across launches.
        item.menu = makeMenu()
    }

    private func configureStatusButton(_ button: NSStatusBarButton) {
        if let icon = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: "EyeBreak") {
            icon.isTemplate = true
            // Menu bar sizing. Without it the symbol renders at its natural size.
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular, scale: .small)
            button.image = icon.withSymbolConfiguration(config)
            button.imagePosition = .imageOnly
        }

        button.toolTip = "EyeBreak - Eye Care Reminders"
        button.appearsDisabled = false
        button.isHidden = false
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = true

        menu.addItem(makeMenuItem(title: "Open Settings...", action: #selector(openSettings), key: ","))
        menu.addItem(.separator())

        menu.addItem(makeMenuItem(title: "Start Timer", action: #selector(startTimer), key: "s", chord: true))
        menu.addItem(makeMenuItem(title: "Take Break Now", action: #selector(takeBreak), key: "b", chord: true))
        menu.addItem(makeMenuItem(title: "Stop Timer", action: #selector(stopTimer), key: "x", chord: true))
        menu.addItem(.separator())

        menu.addItem(makeMenuItem(title: "Quit EyeBreak", action: #selector(quit), key: "q"))

        return menu
    }

    /// `chord: true` gives the item ⌘⇧ instead of the default ⌘, matching the
    /// global shortcuts in AppDelegate.
    private func makeMenuItem(title: String, action: Selector, key: String, chord: Bool = false) -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: key)
        if chord {
            menuItem.keyEquivalentModifierMask = [.command, .shift]
        }
        menuItem.target = self
        return menuItem
    }

    @objc func openSettings() {

        // Check if settings window already exists
        var settingsWindowExists = false
        for window in NSApp.windows where window.title == "EyeBreak Settings" {
            // Window exists, just bring it to front
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            settingsWindowExists = true
            break
        }

        // If no settings window exists, open a new one using the SwiftUI Window API
        if !settingsWindowExists {
            // Use NSWorkspace to open the window via the app's URL scheme or environment
            // This will trigger the SwiftUI Window("settings") to open
            NSApp.activate(ignoringOtherApps: true)

            // Create the settings window through SwiftUI Window scene
            let settingsView = SettingsView()
                .environmentObject(BreakTimerManager.shared)
                .environmentObject(AppSettings.shared)

            let hostingController = NSHostingController(rootView: settingsView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = "EyeBreak Settings"
            window.setContentSize(NSSize(width: 700, height: 600))
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.center()
            window.isReleasedWhenClosed = false

            window.makeKeyAndOrderFront(nil)
        }
    }

    @objc private func startTimer() {
        BreakTimerManager.shared.start()
    }

    @objc private func takeBreak() {
        BreakTimerManager.shared.takeBreakNow()
    }

    @objc private func stopTimer() {
        BreakTimerManager.shared.stop()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
