//
//  MenuBarStatusSection.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

// The countdown card: state, progress ring, and the time it shows.

extension MenuBarView {
    var statusSection: some View {
        VStack(spacing: 12) {
            Text(timerManager.state.displayText)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.secondary)
                .animation(.easeInOut, value: timerManager.state)

            if case .working(let seconds) = timerManager.state {
                VStack(spacing: 12) {
                    // Progress ring with gradient
                    ZStack {
                        Circle()
                            .stroke(Color.blue.opacity(0.2), lineWidth: 6)
                            .frame(width: 100, height: 100)

                        Circle()
                            .trim(from: 0, to: progressValue)
                            .stroke(
                                AngularGradient(
                                    colors: [.blue, .cyan, .blue],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                            .shadow(color: .blue.opacity(0.4), radius: 8)
                            .animation(.linear(duration: 1), value: progressValue)

                        // Time display
                        VStack(spacing: 4) {
                            Text(formatTime(seconds))
                                .font(.system(.title2, design: .monospaced))
                                .fontWeight(.bold)
                                .contentTransition(.numericText())

                            Text("remaining")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Mini progress bar
                    ProgressView(value: progressValue, total: 1.0)
                        .tint(.blue)
                        .scaleEffect(y: 0.5)
                }
                .transition(.scale.combined(with: .opacity))

            } else if case .breaking(let seconds) = timerManager.state {
                VStack(spacing: 12) {
                    // Animated break indicator
                    ZStack {
                        Circle()
                            .stroke(Color.green.opacity(0.2), lineWidth: 6)
                            .frame(width: 100, height: 100)

                        Circle()
                            .trim(from: 0, to: progressValue)
                            .stroke(
                                AngularGradient(
                                    colors: [.green, .mint, .green],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                            .shadow(color: .green.opacity(0.4), radius: 8)
                            .animation(.linear(duration: 1), value: progressValue)

                        VStack(spacing: 4) {
                            Text("\(seconds)")
                                .font(.system(.title, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .contentTransition(.numericText())

                            Text("seconds")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    Text("👁️ Rest your eyes")
                        .font(.caption)
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))
                }
                .transition(.scale.combined(with: .opacity))

            } else if case .preBreak(let seconds) = timerManager.state {
                VStack(spacing: 8) {
                    // Warning icon with pulse
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.bounce.byLayer, value: seconds)

                    Text("\(seconds)s until break")
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .contentTransition(.numericText())

                    Text("Prepare to rest")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: timerManager.state)
    }

    private var progressValue: Double {
        switch timerManager.state {
        case .working(let remaining):
            let total = Double(settings.workIntervalSeconds)
            return 1.0 - (Double(remaining) / total)
        case .breaking(let remaining):
            let total = Double(settings.breakDurationSeconds)
            return 1.0 - (Double(remaining) / total)
        default:
            return 0
        }
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
