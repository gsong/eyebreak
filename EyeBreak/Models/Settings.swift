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
    @AppStorage("eyeExerciseDurationSeconds") var eyeExerciseDurationSeconds: Int = 300 // 5 minutes default
    @AppStorage("exerciseIntervalSeconds") var exerciseIntervalSeconds: Int = 3 // Change direction every 3 seconds

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

    // MARK: - Color Theme Computed Properties

    // MARK: - Water Reminder Theme Properties

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
    }

    // MARK: - Private

    private static func clamp(_ value: Int, to range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
