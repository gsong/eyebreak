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
            ambientRemindersSection
            waterRemindersSection
            colorThemesSection
            goalsSection
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
                    range: 10...60
                ) { newValue in
                    settings.workIntervalMinutes = Int(newValue)
                }

                EnhancedSliderCard(
                    title: "Break Duration",
                    value: settings.breakDurationSeconds,
                    unit: "sec",
                    icon: "eye.slash",
                    color: .green,
                    range: 10...120
                ) { newValue in
                    settings.breakDurationSeconds = Int(newValue)
                }

                EnhancedSliderCard(
                    title: "Pre-Break Warning",
                    value: settings.preBreakWarningSeconds,
                    unit: "sec",
                    icon: "bell.fill",
                    color: .orange,
                    range: 10...60
                ) { newValue in
                    settings.preBreakWarningSeconds = Int(newValue)
                }
            }
        } header: {
            SectionHeaderView(title: "Timing", icon: "clock.fill", color: .blue)
        }
    }

    // MARK: - Preview Function

}
