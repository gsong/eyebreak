//
//  AccessibilityPermission.swift
//  EyeBreak
//
//  Watches the Accessibility (input monitoring) permission that the global
//  keyboard shortcuts depend on.
//
//  macOS binds the grant to the app's designated requirement. What that
//  requirement is depends on how the build was signed, and the two cases behave
//  oppositely:
//
//      ad-hoc      designated => cdhash H"e39f52e1…"
//      certificate designated => identifier "com.eyebreak.app"
//                                 and certificate leaf = H"1f6dc175…"
//
//  An ad-hoc signature pins the requirement to the build's cdhash, which changes
//  every build, so macOS treats each install as a different program and drops the
//  grant. A certificate pins it to the certificate, which does not change, so the
//  grant survives. `scripts/create-cert.sh` exists for exactly this, and
//  `dev-install.sh` re-signs with it — so an installed build keeps its grant
//  across updates, and a throwaway `xcodebuild` build (signed ad-hoc, or not at
//  all) can never hold one.
//
//  So this watcher is not for the ordinary update path any more. It covers the
//  cases that still revoke: the certificate being recreated, the user clearing
//  the grant, and a first install before the grant is given. Without it ⌃⌥B and
//  the break-time keyboard hold fail with no error and no prompt.
//

import Foundation
import AppKit
import ApplicationServices

@MainActor
final class AccessibilityPermission: ObservableObject {

    static let shared = AccessibilityPermission()

    /// Whether the process is currently trusted for accessibility/input monitoring.
    @Published private(set) var isTrusted: Bool = AXIsProcessTrusted()

    /// Set once the user has dismissed the prompt for this version, so we ask at
    /// most once per update rather than on every launch.
    private static let promptedVersionKey = "accessibilityPromptedForVersion"

    private var pollTimer: Timer?

    private var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    private init() {}

    // MARK: - Monitoring

    /// Begins watching the permission. There is no notification for TCC changes,
    /// so a low-frequency poll is the only reliable option; it stops as soon as
    /// the grant appears.
    func startMonitoring() {
        refresh()
        guard pollTimer == nil else { return }

        pollTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func stopMonitoring() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func refresh() {
        let trusted = AXIsProcessTrusted()
        if trusted != isTrusted {
            isTrusted = trusted
        }
        if trusted {
            // Nothing left to watch, and a granted permission cannot silently
            // revoke itself while the app keeps running.
            stopMonitoring()
        }
    }

    // MARK: - Prompting

    /// Called at launch. Stays quiet when the permission is present, or when the
    /// user has already been asked about this particular version.
    func promptIfNeededOnLaunch() {
        startMonitoring()
        guard !isTrusted else { return }

        let alreadyAsked = UserDefaults.standard.string(forKey: Self.promptedVersionKey)
        guard alreadyAsked != currentVersion else { return }

        UserDefaults.standard.set(currentVersion, forKey: Self.promptedVersionKey)

        // Give the menu bar time to settle before putting an alert on screen.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self, !self.isTrusted else { return }
            self.presentPrompt(afterUpdate: alreadyAsked != nil)
        }
    }

    /// Explicit request, e.g. from a button in Settings. Always shows something.
    func requestAccess() {
        refresh()
        if isTrusted {
            presentAlreadyGrantedAlert()
        } else {
            presentPrompt(afterUpdate: false)
        }
    }

    private func presentPrompt(afterUpdate: Bool) {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Keyboard shortcuts need permission"

        if afterUpdate {
            alert.informativeText = """
            EyeBreak no longer has Accessibility permission, so ⌃⌥B has stopped \
            working and a break can no longer hold the keyboard.

            Re-enabling EyeBreak under Accessibility restores both. Everything else — \
            the timer, the break overlay and the menu bar — works normally either way.
            """
        } else {
            alert.informativeText = """
            EyeBreak needs Accessibility permission for ⌃⌥B, its one keyboard \
            shortcut, and to hold the keyboard while a break waits to be dismissed.

            Everything else — the timer, the break overlay and the menu bar — works \
            normally without it.
            """
        }

        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Not Now")

        if alert.runModal() == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
    }

    private func presentAlreadyGrantedAlert() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Keyboard shortcuts are enabled"
        alert.informativeText = "EyeBreak already has Accessibility permission."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    /// Opens System Settings directly on Privacy & Security › Accessibility.
    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
