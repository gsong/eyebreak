//
//  TimerStatusBanner.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

// The live timer strip above every settings tab.

struct TimerStatusBanner: View {
    @EnvironmentObject var timerManager: BreakTimerManager
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 24) {
                // Status indicator
                ZStack {
                    // Outer halo
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 40, height: 40)

                    // Middle ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [statusColor, statusColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    // Core indicator
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [statusColor, statusColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 12, height: 12)
                        .shadow(color: statusColor.opacity(0.5), radius: 4)
                }

                // Enhanced timer display
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(statusText)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(statusColor)

                        if case .working(let seconds) = timerManager.state {
                            Text("\(formatTime(seconds)) remaining")
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundColor(.secondary)
                                .contentTransition(.numericText())
                        } else if case .breaking(let seconds) = timerManager.state {
                            Text("\(seconds) seconds")
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundColor(.secondary)
                                .contentTransition(.numericText())
                        } else {
                            Text("Start your healthy eye habit")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Visual icon based on state
                    if timerManager.state.isActive {
                        Image(systemName: statusIcon)
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [statusColor, statusColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }

                Spacer()

                // Enhanced control buttons
                controlButtons
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)

            // Enhanced progress bar
            if case .working(let remaining) = timerManager.state {
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(height: 4)

                    GeometryReader { geometry in
                        let progress = 1.0 - (Double(remaining) / Double(settings.workIntervalSeconds))

                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 4)
                            .shadow(color: Color.blue.opacity(0.3), radius: 2)
                            .animation(.linear(duration: 1), value: progress)
                    }
                    .frame(height: 4)
                }
                .transition(.opacity)

            } else if case .breaking(let remaining) = timerManager.state {
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.green.opacity(0.1))
                        .frame(height: 4)

                    GeometryReader { geometry in
                        let progress = 1.0 - (Double(remaining) / Double(settings.breakDurationSeconds))

                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.green, Color.mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 4)
                            .shadow(color: Color.green.opacity(0.3), radius: 2)
                            .animation(.linear(duration: 1), value: progress)
                    }
                    .frame(height: 4)
                }
                .transition(.opacity)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }

    private var statusIcon: String {
        switch timerManager.state {
        case .working: return "desktopcomputer"
        case .breaking: return "eye.slash.fill"
        default: return "timer"
        }
    }

    private var statusColor: Color {
        switch timerManager.state {
        case .idle:
            return .gray
        case .working:
            return .blue
        case .breaking:
            return .green
        case .paused:
            return .yellow
        case .awaitingDismissal:
            return .green
        }
    }

    private var timerDisplay: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(statusText)
                .font(.headline)
                .foregroundColor(.primary)

            Text(timeText)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .monospacedDigit()
        }
    }

    private var statusText: String {
        switch timerManager.state {
        case .idle:
            return "Idle"
        case .working:
            return "Next break in:"
        case .breaking:
            return "Break time remaining:"
        case .paused:
            return "Paused"
        case .awaitingDismissal:
            return "Break complete:"
        }
    }

    private var timeText: String {
        switch timerManager.state {
        case .idle:
            return "--:--"
        case .working(let remainingSeconds), .breaking(let remainingSeconds):
            let minutes = remainingSeconds / 60
            let seconds = remainingSeconds % 60
            return String(format: "%02d:%02d", minutes, seconds)
        case .paused, .awaitingDismissal:
            return "--:--"
        }
    }

    private var controlButtons: some View {
        HStack(spacing: 12) {
            switch timerManager.state {
            case .idle:
                Button {
                    timerManager.start()
                } label: {
                    Label("Start", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)

            case .working:
                Button {
                    timerManager.takeBreakNow()
                } label: {
                    Label("Break Now", systemImage: "pause.fill")
                }
                .buttonStyle(.bordered)

                Button {
                    timerManager.stop()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(.bordered)

            case .breaking:
                Button {
                    timerManager.skipBreak()
                } label: {
                    Label("Skip Break", systemImage: "forward.fill")
                }
                .buttonStyle(.bordered)

            case .awaitingDismissal:
                Button {
                    timerManager.dismissBreak()
                } label: {
                    Label("Back to Work", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.borderedProminent)

            case .paused:
                Button {
                    timerManager.resume()
                } label: {
                    Label("Resume", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
