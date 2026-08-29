//
//  SettingsView.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

// The whole settings window: a live timer strip over one scrolling form.

struct SettingsView: View {
    @EnvironmentObject var timerManager: BreakTimerManager
    @EnvironmentObject var settings: AppSettings

    /// Whether a break can hold the keyboard at all. The grant can go away
    /// without warning, so the view asks rather than assuming.
    @StateObject private var accessibility = AccessibilityPermission.shared

    /// Read from the bundle so this never drifts from the shipped version.
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    var body: some View {
        VStack(spacing: 0) {
            TimerStatusBanner()
                .environmentObject(timerManager)

            Divider()

            Form {
                timerSection
                tailSection
            }
            .formStyle(.grouped)
        }
    }

    // MARK: - Timer

    /// Timing and behaviour share one section because they answer one question:
    /// how does the timer behave. A grouped form charges roughly 80pt at every
    /// section seam, which is more than any of these headers is worth.
    private var timerSection: some View {
        Section {
            EnhancedSliderCard(
                title: "Work Interval",
                value: settings.workIntervalMinutes,
                unit: "min",
                icon: "desktopcomputer",
                color: .blue,
                range: AppSettings.workIntervalRange,
                step: 5
            ) { settings.workIntervalMinutes = $0 }

            // Minutes, not seconds. A 60...600 second slider gives under a
            // point per second, so the thumb cannot land on a round number.
            EnhancedSliderCard(
                title: "Break Duration",
                value: settings.breakDurationMinutes,
                unit: "min",
                icon: "eye.slash",
                color: .green,
                range: AppSettings.breakDurationMinutesRange,
                step: 1
            ) { settings.breakDurationMinutes = $0 }

            Toggle("Wait for me to dismiss the break", isOn: $settings.requireBreakDismissal)

            Toggle("Launch at Login", isOn: Binding(
                get: { settings.launchAtLogin },
                set: { newValue in
                    settings.launchAtLogin = newValue
                    LaunchAtLoginManager.shared.setEnabled(newValue)
                }
            ))
            .help("Automatically start EyeBreak when you log in to your Mac")

            Toggle("Enable Sound Effects", isOn: $settings.soundEnabled)

            Toggle("Idle Detection", isOn: $settings.idleDetectionEnabled)

            if settings.idleDetectionEnabled {
                EnhancedSliderCard(
                    title: "Idle Threshold",
                    value: settings.idleThresholdMinutes,
                    unit: "min",
                    icon: "moon.zzz",
                    color: .indigo,
                    range: AppSettings.idleThresholdRange,
                    step: 1
                ) { settings.idleThresholdMinutes = $0 }
            }
        } header: {
            SectionHeaderView(title: "Timer", icon: "clock.fill", color: .blue)
        } footer: {
            // The panic chord has to be written down somewhere a user can
            // find it, because the moment they need it is the moment the
            // keyboard is doing something they did not expect. The claim is
            // gated on the grant, because without it the hold does not happen.
            if accessibility.isTrusted {
                Text("""
                A break covers every display and holds the keyboard for its length, so \
                shortcuts in other apps stay quiet. Press \u{238B} to end a break early. \
                \u{2303}\u{2325}\u{2318}\u{238B} releases the keyboard and ends the break if \
                anything goes wrong. \u{2318}\u{2325}\u{238B} still reaches Force Quit, but it \
                opens behind the overlay.
                """)
                    .font(.caption)
            } else {
                Text("""
                A break covers every display, and \u{238B} ends it early. Holding the \
                keyboard as well needs Accessibility permission, which the row below \
                restores. Until then, shortcuts in other apps still work during a break.
                """)
                    .font(.caption)
            }
        }
    }

    // MARK: - Tail

    /// No header. A word above a button that repeats it says the same thing twice.
    private var tailSection: some View {
        Section {
            permissionRow

            Button {
                settings.resetToDefaults()
            } label: {
                Text("Reset to Defaults")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)

            HStack {
                Text("Version \(appVersion)")
                Spacer()
                Link("GitHub", destination: URL(string: "https://github.com/gsong/eyebreak")!)
            }
        }
    }

    /// One quiet row while the grant holds; the full warning when it does not.
    /// A silent row would let ⌃⌥B and break-time keyboard holding fail with no
    /// visible cause.
    @ViewBuilder
    private var permissionRow: some View {
        if accessibility.isTrusted {
            LabeledContent("Keyboard Shortcuts") {
                Text("Enabled")
                    .foregroundStyle(.secondary)
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Keyboard Shortcuts")
                    Spacer()
                    Text("Needs permission")
                        .foregroundStyle(.orange)
                }

                Text("""
                Without it \u{2303}\u{2325}B does nothing and breaks cannot hold the \
                keyboard. Granting it once is enough; the signing certificate keeps it.
                """)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Open Accessibility Settings") {
                    accessibility.openAccessibilitySettings()
                }
            }
            .padding(.vertical, 4)
        }
    }
}
