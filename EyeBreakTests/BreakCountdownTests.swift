//
//  BreakCountdownTests.swift
//  EyeBreakTests
//

import XCTest

final class BreakCountdownTests: XCTestCase {

    // MARK: - Counting

    func testStartsAtTheFullDuration() {
        let countdown = BreakCountdown(totalSeconds: 20, onFinish: {})
        XCTAssertEqual(countdown.remainingSeconds, 20)
    }

    func testEachTickRemovesOneSecond() {
        let countdown = BreakCountdown(totalSeconds: 20, onFinish: {})
        countdown.tick()
        countdown.tick()
        XCTAssertEqual(countdown.remainingSeconds, 18)
    }

    func testCountingStopsAtZero() {
        // Zero is displayed for a second before the break ends, so the tick that
        // finishes the break is the one after the count reaches zero.
        let countdown = BreakCountdown(totalSeconds: 2, onFinish: {})
        for _ in 0..<5 {
            countdown.tick()
        }
        XCTAssertEqual(countdown.remainingSeconds, 0)
    }

    // MARK: - Finishing

    func testFinishFiresOnTheTickAfterZero() {
        var finishes = 0
        let countdown = BreakCountdown(totalSeconds: 1, onFinish: { finishes += 1 })

        countdown.tick()
        XCTAssertEqual(countdown.remainingSeconds, 0)
        XCTAssertEqual(finishes, 0)

        countdown.tick()
        XCTAssertEqual(finishes, 1)
    }

    func testFinishFiresOnlyOnce() {
        // The overlay rebuilds when displays change, and a stale timer could
        // outlive the break. Ending the break twice would skip the next one.
        var finishes = 0
        let countdown = BreakCountdown(totalSeconds: 0, onFinish: { finishes += 1 })

        for _ in 0..<5 {
            countdown.tick()
        }

        XCTAssertEqual(finishes, 1)
    }

    func testStopEndsTheCountForGood() {
        var finishes = 0
        let countdown = BreakCountdown(totalSeconds: 3, onFinish: { finishes += 1 })

        countdown.tick()
        countdown.stop()
        countdown.tick()
        countdown.tick()

        XCTAssertEqual(countdown.remainingSeconds, 2)
        XCTAssertEqual(finishes, 0)
    }

    // MARK: - Progress

    func testProgressRunsFromOneToZero() {
        let countdown = BreakCountdown(totalSeconds: 4, onFinish: {})
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
        let countdown = BreakCountdown(totalSeconds: 0, onFinish: {})
        XCTAssertEqual(countdown.progress, 0.0, accuracy: 0.0001)
    }
}
