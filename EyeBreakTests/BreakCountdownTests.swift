//
//  BreakCountdownTests.swift
//  EyeBreakTests
//

import XCTest

final class BreakCountdownTests: XCTestCase {

    // MARK: - Counting

    func testStartsAtTheFullDuration() {
        let countdown = BreakCountdown(totalSeconds: 20)
        XCTAssertEqual(countdown.remainingSeconds, 20)
    }

    func testEachTickRemovesOneSecond() {
        let countdown = BreakCountdown(totalSeconds: 20)
        countdown.tick()
        countdown.tick()
        XCTAssertEqual(countdown.remainingSeconds, 18)
    }

    func testCountingStopsAtZero() {
        let countdown = BreakCountdown(totalSeconds: 2)
        for _ in 0..<5 {
            countdown.tick()
        }
        XCTAssertEqual(countdown.remainingSeconds, 0)
    }

    // MARK: - Display Only
    //
    // The countdown used to end the break when it reached zero, and so did
    // `BreakTimerManager.tick()`. Two clocks racing for one transition was only
    // safe by accident. The manager owns the transition now; this one draws.

    func testZeroEndsNothing() {
        let countdown = BreakCountdown(totalSeconds: 1)

        countdown.tick()
        countdown.tick()
        countdown.tick()

        XCTAssertEqual(countdown.remainingSeconds, 0)
        XCTAssertFalse(countdown.isAwaitingDismissal)
    }

    func testStopEndsTheCountForGood() {
        let countdown = BreakCountdown(totalSeconds: 3)

        countdown.tick()
        countdown.stop()
        countdown.tick()
        countdown.tick()

        XCTAssertEqual(countdown.remainingSeconds, 2)
    }

    // MARK: - Awaiting Dismissal

    func testARunningBreakIsNotAwaitingDismissal() {
        let countdown = BreakCountdown(totalSeconds: 20)
        XCTAssertFalse(countdown.isAwaitingDismissal)
    }

    func testAwaitDismissalParksTheCount() {
        // The manager's clock and this one do not share a second boundary, so a
        // break can be served with a second or two still on display. Parking the
        // count is what stops it running on behind the completion state.
        let countdown = BreakCountdown(totalSeconds: 20)
        countdown.tick()
        countdown.awaitDismissal()
        countdown.tick()
        countdown.tick()

        XCTAssertTrue(countdown.isAwaitingDismissal)
        XCTAssertEqual(countdown.remainingSeconds, 19)
    }

    // MARK: - Progress

    func testProgressRunsFromOneToZero() {
        let countdown = BreakCountdown(totalSeconds: 4)
        XCTAssertEqual(countdown.progress, 1.0, accuracy: 0.0001)

        countdown.tick()
        XCTAssertEqual(countdown.progress, 0.75, accuracy: 0.0001)

        countdown.tick()
        countdown.tick()
        countdown.tick()
        XCTAssertEqual(countdown.progress, 0.0, accuracy: 0.0001)
    }

    func testProgressIsZeroForAZeroLengthBreak() {
        // Guards the divide the progress ring would otherwise do by zero.
        let countdown = BreakCountdown(totalSeconds: 0)
        XCTAssertEqual(countdown.progress, 0.0, accuracy: 0.0001)
    }
}
