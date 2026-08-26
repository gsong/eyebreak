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

    override func setUp() {
        super.setUp()
        savedSmartSchedule = settings.smartScheduleEnabled
        savedActiveDays = settings.activeDays
    }

    override func tearDown() {
        settings.smartScheduleEnabled = savedSmartSchedule
        settings.activeDays = savedActiveDays
        super.tearDown()
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
