//
//  StatsChartSection.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import SwiftUI
import Charts

// The 7- and 30-day history chart and the points it plots.

extension StatsView {
    var historicalChartSection: some View {
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
}
