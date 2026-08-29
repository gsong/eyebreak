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
    /// Held because `menuNeedsUpdate` retitles it; every other item is static.
    private var startStopItem: NSMenuItem?

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
        case .working:
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
        case .working(let seconds), .breaking(let seconds):
            return TimeFormat.compact(seconds)
        case .paused(_, let seconds):
            return TimeFormat.compact(seconds)
        }
    }

    private func tooltipText(for state: TimerState) -> String {
        switch state {
        case .idle:
            return "EyeBreak - Click to start"
        case .working(let seconds):
            return "Working - Break in \(TimeFormat.compact(seconds))"
        case .breaking(let seconds):
            return "On break - \(TimeFormat.compact(seconds)) remaining"
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

        let menu = makeMenu()
        menu.delegate = self
        item.menu = menu
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

        menu.addItem(makeMenuItem(title: "Open Settings\u{2026}", action: #selector(openSettings)))
        menu.addItem(.separator())

        let startStop = makeMenuItem(title: startStopTitle, action: #selector(toggleTimer))
        startStopItem = startStop
        menu.addItem(startStop)

        menu.addItem(makeMenuItem(title: "Take Break Now",
                                  action: #selector(takeBreak),
                                  key: "b",
                                  modifiers: [.control, .option]))
        menu.addItem(.separator())

        menu.addItem(makeMenuItem(title: "Quit EyeBreak", action: #selector(quit), key: "q"))

        return menu
    }

    /// A status-item menu's key equivalents never dispatch — they are labels.
    /// The chords that work are AppDelegate's two `NSEvent` monitors and the
    /// standard app menu's own Quit, so only items those two cover carry a key.
    private func makeMenuItem(title: String,
                              action: Selector,
                              key: String = "",
                              modifiers: NSEvent.ModifierFlags = [.command]) -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: key)
        menuItem.keyEquivalentModifierMask = modifiers
        menuItem.target = self
        return menuItem
    }

    /// One item covers both directions: `start()` guards on `.idle` and `stop()`
    /// always returns there, so the state names the only move available.
    private var startStopTitle: String {
        timerManager.state == .idle ? "Start Timer" : "Stop Timer"
    }

    @objc private func openSettings() {
        // The SwiftUI `Window` scene is in `NSApp.windows` from launch, so this
        // scan always finds the window — closing it orders it out rather than
        // releasing it.
        guard let window = NSApp.windows.first(where: { $0.title == "EyeBreak Settings" }) else { return }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func toggleTimer() {
        if timerManager.state == .idle {
            timerManager.start()
        } else {
            timerManager.stop()
        }
    }

    @objc private func takeBreak() {
        BreakTimerManager.shared.takeBreakNow()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

extension StatusBarController: NSMenuDelegate {
    /// AppKit calls this just before the menu opens, which is the only moment
    /// the start/stop title has to be right.
    func menuNeedsUpdate(_ menu: NSMenu) {
        startStopItem?.title = startStopTitle
    }
}
