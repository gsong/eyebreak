//
//  BreakSettingsAmbientSection.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

// The Ambient Reminders section of the Breaks tab.

extension BreakSettingsView {
    var ambientRemindersSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                // Enhanced toggle with icon
                HStack {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange.opacity(0.3), Color.yellow.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)

                        Image(systemName: "sparkles")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable Ambient Reminders")
                            .font(.headline)
                        Text("Cute periodic reminders while you work")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { settings.ambientRemindersEnabled },
                        set: { newValue in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                settings.ambientRemindersEnabled = newValue
                            }
                            if newValue {
                                AmbientReminderManager.shared.startAmbientReminders()
                            } else {
                                AmbientReminderManager.shared.stopAmbientReminders()
                            }
                        }
                    ))
                    .toggleStyle(.switch)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(settings.ambientRemindersEnabled ? Color.orange.opacity(0.08) : Color.secondary.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    settings.ambientRemindersEnabled ?
                                        LinearGradient(
                                            colors: [Color.orange.opacity(0.3), Color.yellow.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom),
                                    lineWidth: 1
                                )
                        )
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: settings.ambientRemindersEnabled)
            }

            if settings.ambientRemindersEnabled {
                VStack(alignment: .leading, spacing: 16) {
                    // Enhanced interval slider
                    EnhancedSliderCard(
                        title: "Reminder Interval",
                        value: settings.ambientReminderIntervalMinutes,
                        unit: "min",
                        icon: "clock.fill",
                        color: .blue,
                        range: 1...15
                    ) { newValue in
                        settings.ambientReminderIntervalMinutes = Int(newValue)
                    }

                    // Enhanced duration slider
                    EnhancedSliderCard(
                        title: "Display Duration",
                        value: settings.ambientReminderDurationSeconds,
                        unit: "sec",
                        icon: "timer",
                        color: .green,
                        range: 3...15
                    ) { newValue in
                        settings.ambientReminderDurationSeconds = Int(newValue)
                    }

                    // Enhanced test button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            AmbientReminderManager.shared.showAmbientReminder()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Show Reminder Now")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)

                    HStack {
                        Image(systemName: "keyboard")
                            .foregroundColor(.secondary)
                        Text("Press ⌘⇧R to test anytime")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 4)

                    Divider()

                    // Professional custom reminder section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .foregroundColor(.purple)
                            Text("Customize Your Reminder")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }

                        Toggle("Use Custom Reminder", isOn: $settings.useCustomReminder)
                            .toggleStyle(.switch)
                            .padding(.horizontal, 4)

                        if settings.useCustomReminder {
                            VStack(alignment: .leading, spacing: 16) {
                                // Professional SF Symbol picker
                                VStack(alignment: .leading, spacing: 12) {
                                    Label("Choose Icon", systemImage: "star.circle")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)

                                    // Icon grid selector
                                    CustomIconPickerView(selectedIcon: $settings.customReminderEmoji)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.purple.opacity(0.06))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                                        )
                                )

                                // Custom message input - refined
                                VStack(alignment: .leading, spacing: 12) {
                                    Label("Reminder Message", systemImage: "text.bubble")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)

                                    TextField("e.g., \"Take a deep breath\" or \"Look away\"", text: $settings.customReminderMessage)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(size: 14))

                                    // Preview
                                    if !settings.customReminderMessage.isEmpty {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.purple.opacity(0.15))
                                                    .frame(width: 40, height: 40)

                                                Image(systemName: settings.customReminderEmoji.isEmpty ? "eye" : settings.customReminderEmoji)
                                                    .font(.system(size: 20))
                                                    .foregroundColor(.purple)
                                            }

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(settings.customReminderMessage)
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundColor(.primary)
                                                Text("Preview")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }

                                            Spacer()
                                        }
                                        .padding(12)
                                        .background(Color.purple.opacity(0.08))
                                        .cornerRadius(10)
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.purple.opacity(0.06))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                                        )
                                )

                            }
                        }
                    }
                }
            }
        } header: {
            SectionHeaderView(title: "Ambient Reminders", icon: "sparkles", color: .orange)
        } footer: {
            Text("Gentle reminders appear while you work to encourage blinking and looking away. They don't interrupt your workflow.")
                .font(.caption)
        }
    }
}
