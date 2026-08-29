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
}
