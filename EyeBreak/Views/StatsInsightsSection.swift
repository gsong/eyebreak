//
//  StatsInsightsSection.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI

// The insights panel and the analysis behind it.

extension StatsView {
    var insightsSection: some View {
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
