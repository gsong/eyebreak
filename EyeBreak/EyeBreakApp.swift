//
//  EyeBreakApp.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

@main
struct EyeBreakApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Settings window - shown on first launch
        Window("EyeBreak Settings", id: "settings") {
            SettingsWindowHost()
        }
        .defaultSize(width: 700, height: 600)
        .defaultPosition(.center)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About EyeBreak") {
                    NSApplication.shared.orderFrontStandardAboutPanel()
                }
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBar: StatusBarController?
    var eventMonitors: [Any] = []

    func applicationDidFinishLaunching(_ notification: Notification) {

        // Prevent automatic termination
        NSApp.disableRelaunchOnLogin()

        // CRITICAL: Create status bar FIRST, while still in default mode
        statusBar = StatusBarController()

        // Force a small delay to ensure status bar is fully registered
        // THEN change to accessory mode
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.setActivationPolicy(.accessory)
        }

        // Setup the global keyboard shortcut
        setupGlobalKeyboardShortcuts()

        // Sync launch at login status with settings
        LaunchAtLoginManager.shared.syncWithSettings(AppSettings.shared)

        // The global shortcut below needs Accessibility permission. macOS drops
        // that grant whenever the app's code signature changes, which happens on
        // every dev-install.sh run, so check and offer to restore it instead of
        // letting the shortcut fail silently.
        AccessibilityPermission.shared.promptIfNeededOnLaunch()

        // The timer always runs. There is no launch where the app is open and
        // the clock is not counting.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            BreakTimerManager.shared.start()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Before anything else. A break in progress holds a keyboard tap, and a
        // quit that skipped this would be the one way the tap outlives the app's
        // own teardown path.
        BreakInputTap.shared.stop()

        // Clean up event monitors
        for monitor in eventMonitors {
            NSEvent.removeMonitor(monitor)
        }
    }

    // Prevent app from quitting when last window closes
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    /// The one chord EyeBreak claims, keyed by the character the key produces
    /// with the modifiers ignored. ⌃⌥B rather than ⌘⇧B, because ⌘⇧ chords
    /// collide with what other apps use.
    private static let shortcutActions: [String: () -> Void] = [
        "b": { BreakTimerManager.shared.takeBreakNow() }
    ]

    /// The action this event triggers, or nil when the event is not one of ours.
    private static func shortcutAction(for event: NSEvent) -> (() -> Void)? {
        guard event.modifierFlags.contains([.control, .option]),
              let key = event.charactersIgnoringModifiers else { return nil }
        return shortcutActions[key]
    }

    private func setupGlobalKeyboardShortcuts() {
        // Two monitors, because neither covers both cases. The global one sees
        // the chord whichever app has focus but cannot consume the event. The
        // local one runs only when EyeBreak has focus and returns nil, which
        // stops the chord reaching the rest of the app.
        let global = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            guard let action = Self.shortcutAction(for: event) else { return }
            DispatchQueue.main.async { action() }
        }

        let local = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard let action = Self.shortcutAction(for: event) else { return event }
            DispatchQueue.main.async { action() }
            return nil
        }

        eventMonitors.append(contentsOf: [global, local].compactMap { $0 })
    }
}
