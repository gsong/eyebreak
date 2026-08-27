//
//  BreakSettingsAppearanceSection.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

// The Color Themes and Goals sections of the Breaks tab.

extension BreakSettingsView {
    var colorThemesSection: some View {
        Section {
            VStack(spacing: 20) {
                // Ambient Reminder Theme
                ThemeSettingsCard(
                    title: "Ambient Reminder Theme",
                    icon: "sparkles",
                    selectedThemeType: Binding(
                        get: { settings.ambientReminderThemeType },
                        set: { settings.ambientReminderThemeType = $0 }
                    ),
                    customTheme: Binding(
                        get: { settings.ambientReminderTheme },
                        set: { settings.ambientReminderTheme = $0 }
                    ),
                    onThemeChange: {
                        settings.objectWillChange.send()
                    }
                )

                Divider()

                // Break Overlay Theme
                ThemeSettingsCard(
                    title: "Break Overlay Theme",
                    icon: "moon.stars.fill",
                    selectedThemeType: Binding(
                        get: { settings.breakOverlayThemeType },
                        set: { settings.breakOverlayThemeType = $0 }
                    ),
                    customTheme: Binding(
                        get: { settings.breakOverlayTheme },
                        set: { settings.breakOverlayTheme = $0 }
                    ),
                    onThemeChange: {
                        settings.objectWillChange.send()
                    }
                )

                Divider()

                // Water Reminder Theme - always show now since all styles support themes
                ThemeSettingsCard(
                    title: "Water Reminder Theme",
                    icon: "drop.fill",
                    selectedThemeType: Binding(
                        get: { settings.waterReminderThemeType },
                        set: { settings.waterReminderThemeType = $0 }
                    ),
                    customTheme: Binding(
                        get: { settings.waterReminderTheme },
                        set: { settings.waterReminderTheme = $0 }
                    ),
                    onThemeChange: {
                        settings.objectWillChange.send()
                    }
                )

                // Quick presets for custom themes
                if settings.ambientReminderThemeType == .custom ||
                   settings.breakOverlayThemeType == .custom ||
                   settings.waterReminderThemeType == .custom {
                    QuickPresetsView(
                        customTheme: Binding(
                            get: {
                                // Use whichever is custom, prioritize in order
                                if settings.ambientReminderThemeType == .custom {
                                    return settings.ambientReminderTheme
                                } else if settings.breakOverlayThemeType == .custom {
                                    return settings.breakOverlayTheme
                                } else {
                                    return settings.waterReminderTheme
                                }
                            },
                            set: { newTheme in
                                // Apply to whichever is custom
                                if settings.ambientReminderThemeType == .custom {
                                    settings.ambientReminderTheme = newTheme
                                }
                                if settings.breakOverlayThemeType == .custom {
                                    settings.breakOverlayTheme = newTheme
                                }
                                if settings.waterReminderThemeType == .custom {
                                    settings.waterReminderTheme = newTheme
                                }
                            }
                        ),
                        onThemeChange: {
                            settings.objectWillChange.send()
                        }
                    )
                }
            }
        } header: {
            SectionHeaderView(title: "Color Themes", icon: "paintpalette.fill", color: .pink)
        } footer: {
            Text("Customize the appearance of ambient reminders, break overlays, and water reminders. Choose from preset themes or create your own custom color scheme.")
                .font(.caption)
        }
    }

    var goalsSection: some View {
        Section {
            Stepper(
                "Daily Break Goal: \(settings.dailyBreakGoal)",
                value: $settings.dailyBreakGoal,
                in: 1...100
            )

            Text("Set a target for breaks to take each day")
                .font(.caption)
                .foregroundColor(.secondary)
        } header: {
            SectionHeaderView(title: "Goals", icon: "target", color: .green)
        }
    }
}
