//
//  UnifiedCountdownCard.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

// The Active Timers card and the rows it lists.

struct UnifiedCountdownCard: View {
    @EnvironmentObject var timerManager: BreakTimerManager

    var body: some View {
        VStack(spacing: 20) {
            // Header with icon
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.3), Color.cyan.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Active Timers")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("All your health reminders at a glance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.bottom, 8)

            VStack(spacing: 12) {
                // Eye Break Timer
                CountdownRow(
                    icon: "eye.fill",
                    title: "Next Eye Break",
                    color: .blue,
                    countdown: eyeBreakCountdown,
                    isActive: eyeBreakIsActive,
                    status: eyeBreakStatus
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.2), Color.cyan.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - Eye Break Computed Properties

    private var eyeBreakIsActive: Bool {
        timerManager.state != .idle
    }

    private var eyeBreakStatus: String {
        switch timerManager.state {
        case .idle:
            return "Not started"
        case .working:
            return "Working"
        case .preBreak:
            return "Break soon"
        case .breaking:
            return "On break"
        case .paused:
            return "Paused"
        case .awaitingDismissal:
            return "Break complete"
        }
    }

    private var eyeBreakCountdown: String {
        switch timerManager.state {
        case .idle:
            return "--:--"
        case .working(let seconds), .preBreak(let seconds), .breaking(let seconds):
            return formatTime(seconds)
        case .paused(_, let seconds):
            return formatTime(seconds)
        case .awaitingDismissal:
            return "--:--"
        }
    }

    // MARK: - Helper Methods

    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct CountdownRow: View {
    let icon: String
    let title: String
    let color: Color
    let countdown: String
    let isActive: Bool
    let status: String

    var body: some View {
        HStack(spacing: 16) {
            // Icon with status indicator
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(color)
                        .symbolRenderingMode(.hierarchical)
                }

                // Status dot
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color(NSColor.controlBackgroundColor), lineWidth: 2)
                    )
                    .offset(x: 2, y: 2)
            }

            // Title and status
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)

                    Text(status)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Countdown display
            VStack(alignment: .trailing, spacing: 2) {
                Text(countdown)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: isActive ? [color, color.opacity(0.7)] : [Color.secondary.opacity(0.5), Color.secondary.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .monospacedDigit()
                    .contentTransition(.numericText())

                if isActive {
                    Text("remaining")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("interval")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? color.opacity(0.05) : Color.clear)
        )
    }

    private var statusColor: Color {
        if !isActive {
            return .gray
        } else if status.contains("Paused") {
            return .orange
        } else {
            return .green
        }
    }
}
