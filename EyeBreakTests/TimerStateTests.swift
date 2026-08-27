//
//  TimerStateTests.swift
//  EyeBreakTests
//

import XCTest

final class TimerStateTests: XCTestCase {

    // MARK: - isActive

    func testIdleAndPausedAreNotActive() {
        XCTAssertFalse(TimerState.idle.isActive)
        XCTAssertFalse(TimerState.paused(wasWorking: true, remainingSeconds: 300).isActive)
        XCTAssertFalse(TimerState.paused(wasWorking: false, remainingSeconds: 0).isActive)
    }

    func testAwaitingDismissalIsNotActive() {
        // Nothing counts during the wait, and `pause()` guards on isActive, so
        // the false is also what makes sleep, lock and idle leave the waiting
        // overlay alone.
        XCTAssertFalse(TimerState.awaitingDismissal.isActive)
    }

    func testRunningStatesAreActive() {
        XCTAssertTrue(TimerState.working(remainingSeconds: 1200).isActive)
        XCTAssertTrue(TimerState.preBreak(remainingSeconds: 30).isActive)
        XCTAssertTrue(TimerState.breaking(remainingSeconds: 20).isActive)
    }

    // MARK: - A break on screen

    func testOnlyABreakCountsAsOnScreen() {
        // Both guard the same thing: starting a break on top of one already on
        // screen would credit two for one rest.
        XCTAssertTrue(TimerState.breaking(remainingSeconds: 20).hasBreakOnScreen)
        XCTAssertTrue(TimerState.awaitingDismissal.hasBreakOnScreen)
        XCTAssertFalse(TimerState.idle.hasBreakOnScreen)
        XCTAssertFalse(TimerState.working(remainingSeconds: 1200).hasBreakOnScreen)
        XCTAssertFalse(TimerState.preBreak(remainingSeconds: 30).hasBreakOnScreen)
        XCTAssertFalse(TimerState.paused(wasWorking: false, remainingSeconds: 10).hasBreakOnScreen)
    }

    // MARK: - Time formatting
    //
    // displayText is what the menu bar shows every second, so the exact shape of
    // the string matters more than most strings in the app.

    func testWorkingPadsSecondsToTwoDigits() {
        XCTAssertEqual(TimerState.working(remainingSeconds: 90).displayText,
                       "Next break in 1:30")
        XCTAssertEqual(TimerState.working(remainingSeconds: 65).displayText,
                       "Next break in 1:05")
    }

    func testWorkingUnderOneMinuteShowsZeroMinutes() {
        XCTAssertEqual(TimerState.working(remainingSeconds: 59).displayText,
                       "Next break in 0:59")
        XCTAssertEqual(TimerState.working(remainingSeconds: 0).displayText,
                       "Next break in 0:00")
    }

    func testWorkingBeyondAnHourKeepsCountingMinutes() {
        // The format has no hours field, so 90 minutes reads as 90:00 rather
        // than rolling over to 1:30:00.
        XCTAssertEqual(TimerState.working(remainingSeconds: 5400).displayText,
                       "Next break in 90:00")
    }

    func testPreBreakAndBreakingUseBareSeconds() {
        XCTAssertEqual(TimerState.preBreak(remainingSeconds: 30).displayText,
                       "Break starting in 30s")
        XCTAssertEqual(TimerState.breaking(remainingSeconds: 20).displayText,
                       "Break time! 20s remaining")
    }

    func testPausedFormatsLikeWorkingAndHidesWasWorking() {
        // wasWorking drives resume behavior, not the label, so both spellings
        // produce the same text.
        XCTAssertEqual(TimerState.paused(wasWorking: true, remainingSeconds: 300).displayText,
                       "Paused - 5:00 remaining")
        XCTAssertEqual(TimerState.paused(wasWorking: false, remainingSeconds: 300).displayText,
                       "Paused - 5:00 remaining")
    }

    func testAwaitingDismissalTellsTheUserWhatToDo() {
        // The break is already credited by the time this shows, so the text has
        // to name the one thing still outstanding.
        XCTAssertEqual(TimerState.awaitingDismissal.displayText,
                       "Break complete — dismiss to continue")
    }

    func testIdleText() {
        XCTAssertEqual(TimerState.idle.displayText, "Ready to start")
    }

    // MARK: - Equatable

    func testStatesDifferByAssociatedValue() {
        XCTAssertEqual(TimerState.working(remainingSeconds: 10),
                       TimerState.working(remainingSeconds: 10))
        XCTAssertNotEqual(TimerState.working(remainingSeconds: 10),
                          TimerState.working(remainingSeconds: 11))
        XCTAssertNotEqual(TimerState.working(remainingSeconds: 10),
                          TimerState.breaking(remainingSeconds: 10))
        XCTAssertNotEqual(TimerState.paused(wasWorking: true, remainingSeconds: 10),
                          TimerState.paused(wasWorking: false, remainingSeconds: 10))
        XCTAssertEqual(TimerState.awaitingDismissal, TimerState.awaitingDismissal)
        XCTAssertNotEqual(TimerState.awaitingDismissal, TimerState.breaking(remainingSeconds: 0))
    }
}
