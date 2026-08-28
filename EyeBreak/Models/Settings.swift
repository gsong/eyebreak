//
//  Settings.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import Foundation
import SwiftUI

/// App settings stored in UserDefaults
class AppSettings: ObservableObject {

    // MARK: - Singleton

    static let shared = AppSettings()

    // MARK: - Slider Ranges

    /// The stops the Work Interval slider offers, in minutes.
    static let workIntervalRange = 15...45

    /// The span a break may run, in seconds. Seconds are canonical because the
    /// timer counts in them; the minutes range below derives from this one.
    static let breakDurationRange = 60...600

    /// The stops the Break Duration slider offers, in minutes.
    static var breakDurationMinutesRange: ClosedRange<Int> {
        (breakDurationRange.lowerBound / 60)...(breakDurationRange.upperBound / 60)
    }

    // MARK: - Published Properties

    // The two timing settings clamp on read, not on write. BreakTimerManager
    // reads them at seven sites, so a clamp in the view would let Settings show
    // 45 while the timer ran 50. Clamping the getter makes every reader agree.
    // The setter stays open on purpose: a hand-written out-of-range value keeps
    // its stored form and returns intact if a range ever widens back.

    @AppStorage("workIntervalMinutes") private var storedWorkInterval: Int = 25
    var workIntervalMinutes: Int {
        get { Self.clamp(storedWorkInterval, to: Self.workIntervalRange) }
        set { storedWorkInterval = newValue }
    }

    @AppStorage("breakDurationSeconds") private var storedBreakDuration: Int = 300
    var breakDurationSeconds: Int {
        get { Self.clamp(storedBreakDuration, to: Self.breakDurationRange) }
        set { storedBreakDuration = newValue }
    }

    @AppStorage("preBreakWarningSeconds") var preBreakWarningSeconds: Int = 30
    @AppStorage("breakStyle") private var breakStyleRaw: String = BreakStyle.blurScreen.rawValue
    // Whether a served break waits for the user to dismiss it before the work
    // timer restarts. On, because a break nobody was present for is not a break.
    @AppStorage("requireBreakDismissal") var requireBreakDismissal: Bool = true
    @AppStorage("soundEnabled") var soundEnabled: Bool = true
    @AppStorage("idleDetectionEnabled") var idleDetectionEnabled: Bool = true
    @AppStorage("idleThresholdMinutes") var idleThresholdMinutes: Int = 5
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false
    @AppStorage("autoStartTimer") var autoStartTimer: Bool = true // Auto-start timer when app launches
    @AppStorage("dailyBreakGoal") var dailyBreakGoal: Int = 24 // Roughly every 20 min for 8 hours
    @AppStorage("eyeExerciseDurationSeconds") var eyeExerciseDurationSeconds: Int = 300 // 5 minutes default
    @AppStorage("exerciseIntervalSeconds") var exerciseIntervalSeconds: Int = 3 // Change direction every 3 seconds

    // Ambient reminders
    @AppStorage("ambientRemindersEnabled") var ambientRemindersEnabled: Bool = false
    @AppStorage("ambientReminderIntervalMinutes") var ambientReminderIntervalMinutes: Int = 5 // Pop up every 5 minutes
    @AppStorage("ambientReminderDurationSeconds") var ambientReminderDurationSeconds: Int = 8 // Stay for 8 seconds
    @AppStorage("customReminderEmoji") var customReminderEmoji: String = "" // Custom emoji
    @AppStorage("customReminderMessage") var customReminderMessage: String = "" // Custom message
    @AppStorage("useCustomReminder") var useCustomReminder: Bool = false // Use custom instead of random

    // Water reminders
    @AppStorage("waterReminderEnabled") var waterReminderEnabled: Bool = false
    @AppStorage("waterReminderInterval") var waterReminderInterval: TimeInterval = 3600 // 1 hour default (in seconds)
    @AppStorage("waterReminderStyle") private var waterReminderStyleRaw: String = WaterReminderStyle.blurScreen.rawValue
    @AppStorage("customWaterReminderIcon") var customWaterReminderIcon: String = "" // Custom SF Symbol icon
    @AppStorage("customWaterReminderMessage") var customWaterReminderMessage: String = "" // Custom message
    @AppStorage("useCustomWaterReminder") var useCustomWaterReminder: Bool = false // Use custom instead of random

    // Smart Schedule
    @AppStorage("smartScheduleEnabled") var smartScheduleEnabled: Bool = false
    @AppStorage("workHoursStart") var workHoursStart: Double = 9.0 // 9:00 AM
    @AppStorage("workHoursEnd") var workHoursEnd: Double = 17.0 // 5:00 PM
    @AppStorage("pauseOnWeekends") var pauseOnWeekends: Bool = true
    @AppStorage("activeDays") private var activeDaysData: Data = {
        // Default: Monday to Friday (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
        let defaultDays: Set<Int> = [2, 3, 4, 5, 6]
        return (try? JSONEncoder().encode(defaultDays)) ?? Data()
    }()

    // Color Theme Settings
    @AppStorage("ambientReminderThemeType") var ambientReminderThemeTypeRaw: String = ColorThemeType.defaultTheme.rawValue
    @AppStorage("ambientReminderCustomTheme") var ambientReminderCustomThemeData: Data?
    @AppStorage("breakOverlayThemeType") var breakOverlayThemeTypeRaw: String = ColorThemeType.defaultTheme.rawValue
    @AppStorage("breakOverlayCustomTheme") var breakOverlayCustomThemeData: Data?
    @AppStorage("waterReminderThemeType") var waterReminderThemeTypeRaw: String = ColorThemeType.defaultTheme.rawValue
    @AppStorage("waterReminderCustomTheme") var waterReminderCustomThemeData: Data?

    // Cached random themes (regenerated each time a new overlay/reminder appears)
    var cachedAmbientReminderRandomTheme: ColorTheme?
    var cachedBreakOverlayRandomTheme: ColorTheme?
    var cachedWaterReminderRandomTheme: ColorTheme?

    // MARK: - Computed Properties

    var breakStyle: BreakStyle {
        get { BreakStyle(rawValue: breakStyleRaw) ?? .blurScreen }
        set { breakStyleRaw = newValue.rawValue }
    }

    var waterReminderStyle: WaterReminderStyle {
        get { WaterReminderStyle(rawValue: waterReminderStyleRaw) ?? .blurScreen }
        set { waterReminderStyleRaw = newValue.rawValue }
    }

    var workIntervalSeconds: Int {
        workIntervalMinutes * 60
    }

    /// The Break Duration slider's unit. Seconds stay canonical on disk, so a
    /// stored 90 reads as 1 here and still runs the full 90 seconds.
    var breakDurationMinutes: Int {
        get { breakDurationSeconds / 60 }
        set { breakDurationSeconds = newValue * 60 }
    }

    var idleThresholdSeconds: Int {
        idleThresholdMinutes * 60
    }

    // MARK: - Smart Schedule Computed Properties

    /// Get the set of active days (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
    var activeDays: Set<Int> {
        get {
            guard let decoded = try? JSONDecoder().decode(Set<Int>.self, from: activeDaysData) else {
                // Default: Monday to Friday
                return [2, 3, 4, 5, 6]
            }
            return decoded
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                activeDaysData = encoded
            }
        }
    }

    /// Check if breaks should be active right now based on smart schedule
    var shouldShowBreaksNow: Bool {
        guard smartScheduleEnabled else { return true }

        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentTime = Double(hour) + Double(minute) / 60.0

        // Check if today is an active day
        guard activeDays.contains(weekday) else {
            return false
        }

        // Check if current time is within work hours
        if workHoursStart <= workHoursEnd {
            // Normal case: e.g., 9:00 AM to 5:00 PM
            return currentTime >= workHoursStart && currentTime < workHoursEnd
        } else {
            // Overnight case: e.g., 10:00 PM to 6:00 AM
            return currentTime >= workHoursStart || currentTime < workHoursEnd
        }
    }

    /// Convert hour double to time string (e.g., 9.5 -> "9:30 AM")
    func timeString(from hour: Double) -> String {
        let hours = Int(hour)
        let minutes = Int((hour - Double(hours)) * 60)
        let isPM = hours >= 12
        let displayHour = hours > 12 ? hours - 12 : (hours == 0 ? 12 : hours)
        let period = isPM ? "PM" : "AM"
        return String(format: "%d:%02d %@", displayHour, minutes, period)
    }

    /// Get day name from weekday number (1 = Sun, 2 = Mon, etc.)
    func dayName(for weekday: Int) -> String {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        guard weekday >= 1 && weekday <= 7 else { return "" }
        return days[weekday - 1]
    }

    // MARK: - Color Theme Computed Properties

    // MARK: - Water Reminder Theme Properties

    // MARK: - Statistics Management

    let statsKey = "breakStatistics"

    // MARK: - Helper Methods

    /// Deliberately excludes `launchAtLogin`. Writing that key registers or
    /// unregisters a macOS login item — real system state, not a preference.
    func resetToDefaults() {
        workIntervalMinutes = 25
        breakDurationSeconds = 300
        preBreakWarningSeconds = 30
        breakStyle = .blurScreen
        requireBreakDismissal = true
        soundEnabled = true
        idleDetectionEnabled = true
        idleThresholdMinutes = 5
        dailyBreakGoal = 24
    }

    // MARK: - Private

    private static func clamp(_ value: Int, to range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
