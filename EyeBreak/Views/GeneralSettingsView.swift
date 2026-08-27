//
//  GeneralSettingsView.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

// The General tab.

struct GeneralSettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            // Unified Countdown Display at the top
            Section {
                UnifiedCountdownCard()
            } header: {
                Text("")
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            Section {
                Toggle("Launch at Login", isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { newValue in
                        settings.launchAtLogin = newValue
                        LaunchAtLoginManager.shared.setEnabled(newValue)
                    }
                ))
                .help("Automatically start EyeBreak when you log in to your Mac")

                Toggle("Auto-Start Timer", isOn: $settings.autoStartTimer)
                    .help("Automatically start the break timer when the app launches")

                Toggle("Enable Sound Effects", isOn: $settings.soundEnabled)

                Toggle("Idle Detection", isOn: $settings.idleDetectionEnabled)

                if settings.idleDetectionEnabled {
                    Picker("Idle Threshold", selection: $settings.idleThresholdMinutes) {
                        Text("3 minutes").tag(3)
                        Text("5 minutes").tag(5)
                        Text("10 minutes").tag(10)
                        Text("15 minutes").tag(15)
                    }
                }
            } header: {
                SectionHeaderView(title: "General", icon: "gearshape.fill", color: .gray)
            }

            Section {
                Picker("Session Type", selection: $settings.sessionType) {
                    ForEach(SessionType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .onChange(of: settings.sessionType) { _, _ in
                    // Session type change will automatically update intervals
                }
            } header: {
                SectionHeaderView(title: "Session Type", icon: "clock.badge.checkmark", color: .blue)
            } footer: {
                Text(sessionTypeDescription)
            }

            Section {
                SmartScheduleView()
            } header: {
                SectionHeaderView(title: "Smart Schedule", icon: "calendar.badge.clock", color: .purple)
            } footer: {
                Text("Automatically pause breaks outside your work hours")
            }

            Section {
                Button {
                    settings.resetToDefaults()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset to Defaults")
                    }
                    .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            } header: {
                SectionHeaderView(title: "Reset", icon: "arrow.triangle.2.circlepath", color: .red)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var sessionTypeDescription: String {
        switch settings.sessionType {
        case .standard:
            return "20-20-20 rule: Every 20 minutes, look 20 feet away for 20 seconds"
        case .pomodoro:
            return "Pomodoro technique: 25 minutes of work, 5 minutes break"
        case .custom:
            return "Customize your own work and break intervals"
        }
    }
}
