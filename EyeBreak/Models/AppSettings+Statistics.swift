//
//  AppSettings+Statistics.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import Foundation

// Break statistics: reading today's, recording a change, and resetting.

extension AppSettings {
    func getTodayStats() -> BreakStats {
        let allStats = getAllStats()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let todayStats = allStats.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            return todayStats
        } else {
            return BreakStats(date: today)
        }
    }

    func updateStats(breaksCompleted: Int = 0, breaksSkipped: Int = 0, breakTime: Int = 0) {
        var allStats = getAllStats()
        var todayStats = getTodayStats()

        todayStats.breaksCompleted += breaksCompleted
        todayStats.breaksSkipped += breaksSkipped
        todayStats.totalBreakTime += breakTime

        // Remove old entry for today if exists
        let calendar = Calendar.current
        allStats.removeAll { calendar.isDate($0.date, inSameDayAs: todayStats.date) }

        // Add updated stats
        allStats.append(todayStats)

        // Keep only last 30 days
        allStats.sort { $0.date > $1.date }
        if allStats.count > 30 {
            allStats = Array(allStats.prefix(30))
        }

        saveStats(allStats)
        objectWillChange.send()
    }

    func getAllStats() -> [BreakStats] {
        guard let data = UserDefaults.standard.data(forKey: statsKey),
              let stats = try? JSONDecoder().decode([BreakStats].self, from: data) else {
            return []
        }
        return stats
    }

    private func saveStats(_ stats: [BreakStats]) {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: statsKey)
        }
    }

    func resetStats() {
        UserDefaults.standard.removeObject(forKey: statsKey)
        objectWillChange.send()
    }
}
