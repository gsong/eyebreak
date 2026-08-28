//
//  SettingsHelperTests.swift
//  EyeBreakTests
//
//  These touch AppSettings.shared, which reads and writes UserDefaults. The test
//  bundle has no host application, so that is the xctest process's own domain,
//  not com.eyebreak.app. Running the suite therefore cannot disturb the settings
//  of an installed copy. Keep it that way: do not give this target a TEST_HOST.
//

import XCTest

final class SettingsHelperTests: XCTestCase {

    private var settings: AppSettings { AppSettings.shared }

    private var savedSmartSchedule: Bool = false
    private var savedActiveDays: Set<Int> = []
    private var savedWorkInterval: Int = 0
    private var savedBreakDuration: Int = 0

    override func setUp() {
        super.setUp()
        savedSmartSchedule = settings.smartScheduleEnabled
        savedActiveDays = settings.activeDays
        savedWorkInterval = settings.workIntervalMinutes
        savedBreakDuration = settings.breakDurationSeconds
    }

    override func tearDown() {
        settings.smartScheduleEnabled = savedSmartSchedule
        settings.activeDays = savedActiveDays
        settings.workIntervalMinutes = savedWorkInterval
        settings.breakDurationSeconds = savedBreakDuration
        super.tearDown()
    }

    // MARK: - breakDurationMinutes

    // The Break Duration slider reads and writes minutes; the timer and disk
    // stay in seconds.

    func testBreakDurationMinutesRoundTripsThroughSeconds() {
        settings.breakDurationMinutes = 5
        XCTAssertEqual(settings.breakDurationSeconds, 300)
        XCTAssertEqual(settings.breakDurationMinutes, 5)
    }

    func testBreakDurationMinutesFloorsAPartialMinute() {
        // 90 seconds is reachable by hand-editing the key. The slider shows the
        // whole minute, and the break still runs the stored 90 seconds.
        settings.breakDurationSeconds = 90
        XCTAssertEqual(settings.breakDurationMinutes, 1)
        XCTAssertEqual(settings.breakDurationSeconds, 90)
    }

    // MARK: - Range clamping

    // Bounds are hard-coded on purpose. Restating AppSettings.workIntervalRange
    // here would pass no matter what that static held.

    func testWorkIntervalClampsAboveTheRange() {
        settings.workIntervalMinutes = 50
        XCTAssertEqual(settings.workIntervalMinutes, 45)
    }

    func testWorkIntervalClampsBelowTheRange() {
        settings.workIntervalMinutes = 10
        XCTAssertEqual(settings.workIntervalMinutes, 15)
    }

    func testBreakDurationClampsAboveTheRange() {
        settings.breakDurationSeconds = 900
        XCTAssertEqual(settings.breakDurationSeconds, 600)
    }

    func testBreakDurationClampsBelowTheRange() {
        // The old slider's floor. It is what a stale stored value looks like.
        settings.breakDurationSeconds = 10
        XCTAssertEqual(settings.breakDurationSeconds, 60)
    }

    func testWorkIntervalSecondsUsesTheClampedMinutes() {
        // BreakTimerManager reads this, so it must not see the raw 50.
        settings.workIntervalMinutes = 50
        XCTAssertEqual(settings.workIntervalSeconds, 45 * 60)
    }

    // MARK: - timeString

    func testWholeHoursCoverTheWholeDay() {
        // These are the only values the Start and End pickers produce.
        XCTAssertEqual(settings.timeString(from: 0), "12:00 AM")
        XCTAssertEqual(settings.timeString(from: 1), "1:00 AM")
        XCTAssertEqual(settings.timeString(from: 11), "11:00 AM")
        XCTAssertEqual(settings.timeString(from: 12), "12:00 PM")
        XCTAssertEqual(settings.timeString(from: 13), "1:00 PM")
        XCTAssertEqual(settings.timeString(from: 17), "5:00 PM")
        XCTAssertEqual(settings.timeString(from: 23), "11:00 PM")
    }

    func testNoonAndMidnightDoNotBecomeZero() {
        // The two values a 12-hour clock gets wrong most often.
        XCTAssertEqual(settings.timeString(from: 12), "12:00 PM")
        XCTAssertEqual(settings.timeString(from: 0), "12:00 AM")
    }

    func testFractionalHoursBecomeMinutes() {
        // The doc comment promises this shape, and a preset could supply it even
        // though the picker currently cannot.
        XCTAssertEqual(settings.timeString(from: 9.5), "9:30 AM")
        XCTAssertEqual(settings.timeString(from: 13.25), "1:15 PM")
        XCTAssertEqual(settings.timeString(from: 23.75), "11:45 PM")
    }

    // MARK: - dayName

    func testDayNamesUseCalendarWeekdayNumbering() {
        // 1 = Sunday, matching Calendar.component(.weekday:).
        XCTAssertEqual(settings.dayName(for: 1), "Sun")
        XCTAssertEqual(settings.dayName(for: 2), "Mon")
        XCTAssertEqual(settings.dayName(for: 7), "Sat")
    }

    func testDayNameRejectsOutOfRangeWeekdays() {
        XCTAssertEqual(settings.dayName(for: 0), "")
        XCTAssertEqual(settings.dayName(for: 8), "")
        XCTAssertEqual(settings.dayName(for: -1), "")
    }

    // MARK: - activeDays

    func testActiveDaysSurvivesAWriteAndRead() {
        settings.activeDays = [1, 7]
        XCTAssertEqual(settings.activeDays, [1, 7])
    }

    func testActiveDaysAcceptsAnEmptySet() {
        // Clearing every day is reachable from the UI, and must not silently
        // fall back to the Monday-to-Friday default.
        settings.activeDays = []
        XCTAssertEqual(settings.activeDays, [])
    }

    // MARK: - shouldShowBreaksNow

    func testBreaksAlwaysShowWhenSmartScheduleIsOff() {
        settings.smartScheduleEnabled = false
        XCTAssertTrue(settings.shouldShowBreaksNow)
    }

    func testAnInactiveDayStopsBreaks() {
        // Whatever today is, an empty active-day set excludes it.
        settings.smartScheduleEnabled = true
        settings.activeDays = []
        XCTAssertFalse(settings.shouldShowBreaksNow)
    }

    // The work-hours branches of shouldShowBreaksNow, including the overnight
    // case where start is later than end, read Date() and Calendar.current
    // directly. They cannot be tested until that clock is injectable.
}
