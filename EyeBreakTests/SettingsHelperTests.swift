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

    private var savedWorkInterval: Int = 0
    private var savedBreakDuration: Int = 0
    private var savedIdleThreshold: Int = 0

    override func setUp() {
        super.setUp()
        savedWorkInterval = settings.workIntervalMinutes
        savedBreakDuration = settings.breakDurationSeconds
        savedIdleThreshold = settings.idleThresholdMinutes
    }

    override func tearDown() {
        settings.workIntervalMinutes = savedWorkInterval
        settings.breakDurationSeconds = savedBreakDuration
        settings.idleThresholdMinutes = savedIdleThreshold
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

    func testIdleThresholdClampsAboveTheRange() {
        settings.idleThresholdMinutes = 30
        XCTAssertEqual(settings.idleThresholdMinutes, 15)
    }

    func testIdleThresholdClampsBelowTheRange() {
        settings.idleThresholdMinutes = 0
        XCTAssertEqual(settings.idleThresholdMinutes, 1)
    }

    func testIdleThresholdSecondsUsesTheClampedMinutes() {
        // setupIdleDetection reads this, so it must not see the raw 30.
        settings.idleThresholdMinutes = 30
        XCTAssertEqual(settings.idleThresholdSeconds, 15 * 60)
    }
}
