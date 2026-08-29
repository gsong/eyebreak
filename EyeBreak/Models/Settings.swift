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

    /// The stops the Idle Threshold slider offers, in minutes. One minute fires
    /// during ordinary reading, which George chose knowingly — see #53.
    static let idleThresholdRange = 1...15

    // MARK: - Published Properties

    // The three slider settings clamp on read, not on write. BreakTimerManager
    // reads them at eight sites, so a clamp in the view would let Settings show
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

    // Whether a served break waits for the user to dismiss it before the work
    // timer restarts. On, because a break nobody was present for is not a break.
    @AppStorage("requireBreakDismissal") var requireBreakDismissal: Bool = true
    @AppStorage("soundEnabled") var soundEnabled: Bool = true
    @AppStorage("idleDetectionEnabled") var idleDetectionEnabled: Bool = true
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false

    // A slider cannot refuse an out-of-range stored value the way the picker it
    // replaced could, so this clamps like the two above it.
    @AppStorage("idleThresholdMinutes") private var storedIdleThreshold: Int = 5
    var idleThresholdMinutes: Int {
        get { Self.clamp(storedIdleThreshold, to: Self.idleThresholdRange) }
        set { storedIdleThreshold = newValue }
    }

    // MARK: - Computed Properties

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

    // MARK: - Helper Methods

    /// Deliberately excludes `launchAtLogin`. Writing that key registers or
    /// unregisters a macOS login item — real system state, not a preference.
    func resetToDefaults() {
        workIntervalMinutes = 25
        breakDurationSeconds = 300
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
