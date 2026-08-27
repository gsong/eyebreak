//
//  SmartScheduleView.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

// The work-hours and active-days editor.

struct SmartScheduleView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var selectedPreset: SchedulePreset?

    enum SchedulePreset: String, CaseIterable {
        case standard = "Standard (9 AM - 5 PM)"
        case flexible = "Flexible (8 AM - 6 PM)"
        case earlyBird = "Early Bird (6 AM - 2 PM)"
        case nightOwl = "Night Owl (2 PM - 10 PM)"
        case fullTime = "24/7 (Always Active)"

        var hours: (start: Double, end: Double) {
            switch self {
            case .standard: return (9.0, 17.0)
            case .flexible: return (8.0, 18.0)
            case .earlyBird: return (6.0, 14.0)
            case .nightOwl: return (14.0, 22.0)
            case .fullTime: return (0.0, 24.0)
            }
        }

        var days: Set<Int> {
            switch self {
            case .fullTime:
                return Set(1...7) // All days
            default:
                return [2, 3, 4, 5, 6] // Monday to Friday
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Enable Smart Schedule", isOn: $settings.smartScheduleEnabled)
                .font(.headline)

            if settings.smartScheduleEnabled {
                Divider()
                    .padding(.vertical, 4)

                // Quick Presets
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Presets")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(SchedulePreset.allCases, id: \.self) { preset in
                            Button {
                                applyPreset(preset)
                            } label: {
                                HStack {
                                    Image(systemName: preset == selectedPreset ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(preset == selectedPreset ? .blue : .secondary)
                                    Text(preset.rawValue)
                                        .font(.caption)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(preset == selectedPreset ? Color.blue.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(preset == selectedPreset ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.bottom, 8)

                Divider()

                // Custom Work Hours
                VStack(alignment: .leading, spacing: 12) {
                    Text("Custom Work Hours")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Start Time")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Picker("Start", selection: $settings.workHoursStart) {
                                ForEach(0..<24) { hour in
                                    Text(settings.timeString(from: Double(hour)))
                                        .tag(Double(hour))
                                }
                            }
                            .labelsHidden()
                            .frame(width: 120)
                            .onChange(of: settings.workHoursStart) { _, _ in
                                selectedPreset = nil
                            }
                        }

                        Image(systemName: "arrow.right")
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("End Time")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Picker("End", selection: $settings.workHoursEnd) {
                                ForEach(0..<24) { hour in
                                    Text(settings.timeString(from: Double(hour)))
                                        .tag(Double(hour))
                                }
                            }
                            .labelsHidden()
                            .frame(width: 120)
                            .onChange(of: settings.workHoursEnd) { _, _ in
                                selectedPreset = nil
                            }
                        }
                    }

                    Text("Breaks will only show between \(settings.timeString(from: settings.workHoursStart)) and \(settings.timeString(from: settings.workHoursEnd))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(.bottom, 8)

                Divider()

                // Active Days
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Active Days")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button(settings.pauseOnWeekends ? "Weekdays Only" : "All 7 Days") {
                            settings.pauseOnWeekends.toggle()
                            if settings.pauseOnWeekends {
                                settings.activeDays = [2, 3, 4, 5, 6] // Mon-Fri
                            } else {
                                settings.activeDays = Set(1...7) // All days
                            }
                            selectedPreset = nil
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }

                    HStack(spacing: 8) {
                        ForEach(1...7, id: \.self) { weekday in
                            DayButton(
                                weekday: weekday,
                                isActive: settings.activeDays.contains(weekday),
                                dayName: settings.dayName(for: weekday)
                            ) {
                                toggleDay(weekday)
                            }
                        }
                    }

                    Text("Select which days breaks should be active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Status Indicator
                HStack {
                    Image(systemName: settings.shouldShowBreaksNow ? "checkmark.circle.fill" : "pause.circle.fill")
                        .foregroundColor(settings.shouldShowBreaksNow ? .green : .orange)

                    Text(settings.shouldShowBreaksNow ? "Breaks Active Now" : "Breaks Paused (Outside Work Hours)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(settings.shouldShowBreaksNow ? .green : .orange)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill((settings.shouldShowBreaksNow ? Color.green : Color.orange).opacity(0.1))
                )
            }
        }
    }

    private func applyPreset(_ preset: SchedulePreset) {
        selectedPreset = preset
        let hours = preset.hours
        settings.workHoursStart = hours.start
        settings.workHoursEnd = hours.end
        settings.activeDays = preset.days
        settings.pauseOnWeekends = !preset.days.contains(1) || !preset.days.contains(7)
    }

    private func toggleDay(_ weekday: Int) {
        if settings.activeDays.contains(weekday) {
            settings.activeDays.remove(weekday)
        } else {
            settings.activeDays.insert(weekday)
        }
        selectedPreset = nil

        // Update pause on weekends based on active days
        let hasWeekends = settings.activeDays.contains(1) || settings.activeDays.contains(7)
        settings.pauseOnWeekends = !hasWeekends
    }
}

struct DayButton: View {
    let weekday: Int
    let isActive: Bool
    let dayName: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(dayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isActive ? .white : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ?
                          LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing) :
                          LinearGradient(colors: [Color(NSColor.controlBackgroundColor)], startPoint: .top, endPoint: .bottom))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isActive ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .help(isActive ? "Click to deactivate" : "Click to activate")
    }
}
