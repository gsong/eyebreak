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
            breakStyleSection
            eyeExerciseSection
            colorThemesSection
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
            }
        } header: {
            SectionHeaderView(title: "Timing", icon: "clock.fill", color: .blue)
        }
    }

    // MARK: - Preview Function

}
