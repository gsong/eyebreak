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
    @State private var selectedTimeRange: TimeRange = .week

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

    private var historicalChartSection: some View {
        VStack(spacing: 16) {
            // Header row
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text("Break History")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Picker("", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 140)
            }

            // Chart container with card styling
            if #available(macOS 13.0, *) {
                VStack(spacing: 12) {
                    // Legend
                    HStack(spacing: 16) {
                        LegendItem(color: .green, secondaryColor: .mint, label: "Goal Met")
                        LegendItem(color: .blue, secondaryColor: .cyan, label: "Below Goal")
                        Spacer()
                    }
                    .padding(.horizontal, 4)

                    chartView
                        .frame(height: 220)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: .black.opacity(0.05), radius: 10)
                )
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
            } else {
                Text("Charts require macOS 13.0 or later")
                    .foregroundColor(.secondary)
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
            }
        }
    }

    @available(macOS 13.0, *)
    private var chartView: some View {
        let data = getChartData()

        return Chart(data) { item in
            BarMark(
                x: .value("Date", item.date, unit: .day),
                y: .value("Breaks", item.breaks)
            )
            .foregroundStyle(
                item.breaks >= settings.dailyBreakGoal ?
                    LinearGradient(colors: [.green, .mint], startPoint: .bottom, endPoint: .top) :
                    LinearGradient(colors: [.blue, .cyan], startPoint: .bottom, endPoint: .top)
            )
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: selectedTimeRange == .week ? .day : .day)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .foregroundStyle(Color.secondary.opacity(0.3))
                AxisValueLabel(format: selectedTimeRange == .week ? .dateTime.day().month(.abbreviated) : .dateTime.day())
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .foregroundStyle(Color.secondary.opacity(0.3))
                AxisValueLabel()
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
            }
        }
        .chartPlotStyle { plotArea in
            plotArea
                .background(Color.clear)
        }
    }

    // MARK: - Insights

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.2), Color.orange.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text("Insights")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()
            }

            let stats = settings.getAllStats()
            let insights = generateInsights(from: stats)

            ForEach(insights, id: \.title) { insight in
                InsightCard(
                    icon: insight.icon,
                    title: insight.title,
                    description: insight.description,
                    color: insight.color
                )
            }
        }
    }

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

    private func getChartData() -> [ChartDataPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let allStats = settings.getAllStats()

        var data: [ChartDataPoint] = []

        for i in 0..<selectedTimeRange.days {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let stats = allStats.first { calendar.isDate($0.date, inSameDayAs: date) }

            data.append(ChartDataPoint(
                date: date,
                breaks: stats?.breaksCompleted ?? 0
            ))
        }

        return data.reversed()
    }

    private func generateInsights(from stats: [BreakStats]) -> [Insight] {
        var insights: [Insight] = []

        // Calculate weekly average
        let recentStats = stats.prefix(7)
        let weeklyAverage = recentStats.map { $0.breaksCompleted }.reduce(0, +) / max(recentStats.count, 1)

        if weeklyAverage >= settings.dailyBreakGoal {
            insights.append(Insight(
                icon: "star.fill",
                title: "Excellent Progress!",
                description: "You're consistently meeting your daily break goal. Keep it up!",
                color: .green
            ))
        } else {
            insights.append(Insight(
                icon: "chart.line.uptrend.xyaxis",
                title: "Room for Improvement",
                description: "Try to increase your break frequency to meet your daily goal.",
                color: .orange
            ))
        }

        // Check skip rate
        let totalBreaks = recentStats.map { $0.breaksCompleted }.reduce(0, +)
        let totalSkips = recentStats.map { $0.breaksSkipped }.reduce(0, +)

        if totalSkips > totalBreaks / 4 {
            insights.append(Insight(
                icon: "exclamationmark.triangle.fill",
                title: "High Skip Rate",
                description: "You're skipping \(Int(Double(totalSkips) / Double(totalBreaks + totalSkips) * 100))% of breaks. Your eyes need rest!",
                color: .red
            ))
        }

        // Streak
        let currentStreak = calculateStreak(from: stats)
        if currentStreak >= 3 {
            insights.append(Insight(
                icon: "flame.fill",
                title: "\(currentStreak) Day Streak!",
                description: "You've taken breaks every day for \(currentStreak) days. Amazing!",
                color: .orange
            ))
        }

        return insights
    }

    private func calculateStreak(from stats: [BreakStats]) -> Int {
        let calendar = Calendar.current
        let sortedStats = stats.sorted { $0.date > $1.date }

        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        for stat in sortedStats {
            if calendar.isDate(stat.date, inSameDayAs: currentDate) && stat.breaksCompleted > 0 {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }

        return streak
    }
}

// MARK: - Supporting Types

// MARK: - Supporting Views

// MARK: - Enhanced Stat Box
