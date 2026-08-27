//
//  StatsView.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var settings: AppSettings
    @State var selectedTimeRange: TimeRange = .week

    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Today's Summary
                todaySummarySection

                Divider()
                    .padding(.vertical)

                // Historical Chart
                historicalChartSection

                Divider()
                    .padding(.vertical)

                // Insights
                insightsSection

                // Reset Button
                Button {
                    settings.resetStats()
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Reset Statistics")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.red.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top)
            }
            .padding(40)
        }
    }

    // MARK: - Today's Summary

    private var todaySummarySection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text("Today's Statistics")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()
            }

            let todayStats = settings.getTodayStats()

            HStack(spacing: 20) {
                EnhancedStatBox(
                    title: "Breaks Taken",
                    value: "\(todayStats.breaksCompleted)",
                    icon: "checkmark.seal.fill",
                    color: .green,
                    trend: .up
                )

                EnhancedStatBox(
                    title: "Breaks Skipped",
                    value: "\(todayStats.breaksSkipped)",
                    icon: "xmark.seal.fill",
                    color: .red,
                    trend: .down
                )

                EnhancedStatBox(
                    title: "Total Break Time",
                    value: formatDuration(todayStats.totalBreakTime),
                    icon: "clock.badge.fill",
                    color: .blue,
                    trend: .neutral
                )
            }

            // Enhanced progress bar with animation
            VStack(spacing: 8) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "target")
                            .foregroundStyle(.blue)
                        Text("Daily Goal Progress")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text("\(todayStats.breaksCompleted)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("/")
                            .foregroundColor(.secondary)
                        Text("\(settings.dailyBreakGoal)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                }

                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 12)

                    // Progress with gradient
                    GeometryReader { geometry in
                        let progress = min(Double(todayStats.breaksCompleted) / Double(settings.dailyBreakGoal), 1.0)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: todayStats.breaksCompleted >= settings.dailyBreakGoal ?
                                        [Color.green, Color.mint] : [Color.blue, Color.cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress)
                            .shadow(color: (todayStats.breaksCompleted >= settings.dailyBreakGoal ? Color.green : Color.blue).opacity(0.3), radius: 4)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
                    }
                    .frame(height: 12)

                    // Sparkle effect when goal reached
                    if todayStats.breaksCompleted >= settings.dailyBreakGoal {
                        HStack(spacing: 4) {
                            Spacer()
                            Image(systemName: "sparkles")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text("Goal Reached!")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                            Spacer()
                        }
                        .offset(y: -20)
                    }
                }
                .frame(height: 12)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondary.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [.blue.opacity(0.3), .cyan.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
    }

    // MARK: - Historical Chart

    // MARK: - Insights

    // MARK: - Helper Methods

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60

        if minutes > 0 {
            return "\(minutes)m \(secs)s"
        } else {
            return "\(secs)s"
        }
    }

}

// MARK: - Supporting Types

// MARK: - Supporting Views

// MARK: - Enhanced Stat Box
