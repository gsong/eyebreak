//
//  BreakSettingsView.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

// The Breaks tab.

struct BreakSettingsView: View {
    @EnvironmentObject var settings: AppSettings
    /// Whether a break can hold the keyboard at all. macOS drops this grant on
    /// every update, so the answer changes under the user without warning.
    @StateObject var accessibility = AccessibilityPermission.shared

    var body: some View {
        Form {
            timingSection
        }
        .formStyle(.grouped)
        .padding()
    }

    private var timingSection: some View {
        Section {
            VStack(spacing: 12) {
                EnhancedSliderCard(
                    title: "Work Interval",
                    value: settings.workIntervalMinutes,
                    unit: "min",
                    icon: "desktopcomputer",
                    color: .blue,
                    range: AppSettings.workIntervalRange,
                    step: 5
                ) { newValue in
                    settings.workIntervalMinutes = newValue
                }

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
                ) { newValue in
                    settings.breakDurationMinutes = newValue
                }

                EnhancedSliderCard(
                    title: "Pre-Break Warning",
                    value: settings.preBreakWarningSeconds,
                    unit: "sec",
                    icon: "bell.fill",
                    color: .orange,
                    range: 10...60,
                    step: 1
                ) { newValue in
                    settings.preBreakWarningSeconds = newValue
                }

                VStack(alignment: .leading, spacing: 6) {
                    Toggle("Wait for me to dismiss the break", isOn: $settings.requireBreakDismissal)
                        .toggleStyle(.switch)

                    Text("The break is counted when it ends, but the screen stays up and your next work interval does not start until you dismiss it.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } header: {
            SectionHeaderView(title: "Timing", icon: "clock.fill", color: .blue)
        } footer: {
            // The panic chord has to be written down somewhere a user can
            // find it, because the moment they need it is the moment the
            // keyboard is doing something they did not expect. The claim is
            // gated on the grant, which is missing after every update.
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
                keyboard as well needs Accessibility permission, which macOS resets on \
                every update — see Keyboard Shortcuts under About. Until then, shortcuts \
                in other apps still work during a break.
                """)
                    .font(.caption)
            }
        }
    }
}
