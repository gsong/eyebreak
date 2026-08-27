//
//  BreakSettingsWaterSection.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

// The Water Reminders section of the Breaks tab.

extension BreakSettingsView {
    var waterRemindersSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                // Water reminder toggle card
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.2), Color.cyan.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)

                        Image(systemName: "drop.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable Water Reminders")
                            .font(.headline)
                        Text("Stay hydrated with gentle reminders")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { settings.waterReminderEnabled },
                        set: { newValue in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                settings.waterReminderEnabled = newValue
                            }
                            if newValue {
                                WaterReminderManager.shared.startWaterReminders()
                            } else {
                                WaterReminderManager.shared.stopWaterReminders()
                            }
                        }
                    ))
                    .toggleStyle(.switch)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(settings.waterReminderEnabled ? Color.blue.opacity(0.08) : Color.secondary.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    settings.waterReminderEnabled ?
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.3), Color.cyan.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom),
                                    lineWidth: 1
                                )
                        )
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: settings.waterReminderEnabled)
            }

            if settings.waterReminderEnabled {
                VStack(alignment: .leading, spacing: 16) {
                    // Reminder interval picker
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.blue)
                            Text("Reminder Interval")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        Picker("Interval", selection: $settings.waterReminderInterval) {
                            Text("30 minutes").tag(TimeInterval(1800))
                            Text("45 minutes").tag(TimeInterval(2700))
                            Text("1 hour").tag(TimeInterval(3600))
                            Text("1.5 hours").tag(TimeInterval(5400))
                            Text("2 hours").tag(TimeInterval(7200))
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: settings.waterReminderInterval) { _, _ in
                            // Restart reminders with new interval
                            if settings.waterReminderEnabled {
                                WaterReminderManager.shared.stopWaterReminders()
                                WaterReminderManager.shared.startWaterReminders()
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                            )
                    )

                    // Reminder style picker
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "bell.badge.fill")
                                .foregroundColor(.cyan)
                            Text("Reminder Style")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        Picker("Style", selection: $settings.waterReminderStyle) {
                            ForEach(WaterReminderStyle.allCases) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text(settings.waterReminderStyle.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.cyan.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                            )
                    )

                    // Test button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            WaterReminderManager.shared.showWaterReminderNow()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "drop.fill")
                            Text("Show Water Reminder Now")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.blue, .cyan],
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
                        Text("Press ⌘⇧W to test anytime")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 4)

                    Divider()

                    // Custom water reminder section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .foregroundColor(.blue)
                            Text("Customize Your Water Reminder")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }

                        Toggle("Use Custom Reminder", isOn: $settings.useCustomWaterReminder)
                            .toggleStyle(.switch)
                            .padding(.horizontal, 4)

                        if settings.useCustomWaterReminder {
                            VStack(alignment: .leading, spacing: 16) {
                                // SF Symbol picker for water reminder
                                VStack(alignment: .leading, spacing: 12) {
                                    Label("Choose Icon", systemImage: "star.circle")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)

                                    // Icon grid selector - water-related icons
                                    CustomWaterIconPickerView(selectedIcon: $settings.customWaterReminderIcon)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue.opacity(0.06))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                        )
                                )

                                // Custom message input
                                VStack(alignment: .leading, spacing: 12) {
                                    Label("Reminder Message", systemImage: "text.bubble")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)

                                    TextField("e.g., \"Time to hydrate\" or \"Drink water\"", text: $settings.customWaterReminderMessage)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(size: 14))

                                    // Preview
                                    if !settings.customWaterReminderMessage.isEmpty {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.blue.opacity(0.15))
                                                    .frame(width: 40, height: 40)

                                                Image(systemName: settings.customWaterReminderIcon.isEmpty ? "drop.fill" : settings.customWaterReminderIcon)
                                                    .font(.system(size: 18))
                                                    .foregroundColor(.blue)
                                                    .symbolRenderingMode(.hierarchical)
                                            }

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(settings.customWaterReminderMessage)
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundColor(.primary)
                                                Text("Preview")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }

                                            Spacer()
                                        }
                                        .padding(12)
                                        .background(Color.blue.opacity(0.08))
                                        .cornerRadius(10)
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue.opacity(0.06))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                }
            }
        } header: {
            SectionHeaderView(title: "Water Reminders", icon: "drop.fill", color: .blue)
        } footer: {
            Text("Stay hydrated for better focus and health. Reminders appear at your chosen interval.")
                .font(.caption)
        }
    }
}
