//
//  BreakInputPolicyTests.swift
//  EyeBreakTests
//

import CoreGraphics
import XCTest

/// The rules the break's keyboard tap runs on. A mistake here takes the
/// keyboard away from the whole machine, so every rule is pinned by a test.
final class BreakInputPolicyTests: XCTestCase {

    // MARK: - Consuming

    func testAnOrdinaryKeyIsConsumed() {
        // "A" with no modifiers. Typing through a break is the thing the tap exists to stop.
        XCTAssertEqual(BreakInputPolicy.decision(keyCode: 0, flags: []), .consume)
    }

    func testCommandTabIsConsumed() {
        // The worst case: it hands the keyboard to another app for the rest of the break.
        XCTAssertEqual(BreakInputPolicy.decision(keyCode: 48, flags: [.maskCommand]), .consume)
    }

    func testCommandQIsConsumed() {
        // Quitting the app underneath, or EyeBreak itself, mid-break.
        XCTAssertEqual(BreakInputPolicy.decision(keyCode: 12, flags: [.maskCommand]), .consume)
    }

    func testAModifierOnItsOwnIsConsumed() {
        // The flagsChanged events behind fn-twice dictation, the Globe key and
        // the double-tap-Cmd launchers. The key code on one of these is the
        // modifier's own.
        XCTAssertEqual(BreakInputPolicy.decision(keyCode: 55, flags: [.maskCommand]), .consume)
        XCTAssertEqual(BreakInputPolicy.decision(keyCode: 63, flags: [.maskSecondaryFn]), .consume)
    }

    func testEyeBreakOwnShortcutsAreConsumed() {
        // Cmd-Shift-B takes a break. Starting a second break during one is meaningless,
        // and the tap does not get to ask which app an event was heading for.
        XCTAssertEqual(BreakInputPolicy.decision(keyCode: 11, flags: [.maskCommand, .maskShift]), .consume)
    }

    // MARK: - Escape

    func testEscapeAloneEndsTheBreak() {
        // From the tap, not the overlay's monitor. The monitor needs EyeBreak to
        // be frontmost, and macOS can refuse the activation that would make it so.
        XCTAssertEqual(BreakInputPolicy.decision(keyCode: 53, flags: []), .endBreak)
    }

    func testForceQuitIsPassed() {
        // Cmd-Opt-Esc is the user's last resort before a power cycle. Consuming it
        // removes that resort. Letting them force-quit their editor mid-break is
        // the accepted cost.
        XCTAssertEqual(BreakInputPolicy.decision(keyCode: 53, flags: [.maskCommand, .maskAlternate]), .pass)
    }

    func testThePanicChordIsRecognized() {
        XCTAssertEqual(
            BreakInputPolicy.decision(keyCode: 53, flags: [.maskControl, .maskAlternate, .maskCommand]),
            .panic
        )
    }

    func testLockKeysDoNotChangeAnEscapeDecision() {
        // Caps lock, fn and the numeric-pad bit ride along on unrelated events. A
        // user with caps lock on must still be able to reach every escape hatch.
        let noise: CGEventFlags = [.maskAlphaShift, .maskNumericPad, .maskSecondaryFn]

        XCTAssertEqual(BreakInputPolicy.decision(keyCode: 53, flags: noise), .endBreak)
        XCTAssertEqual(
            BreakInputPolicy.decision(keyCode: 53, flags: noise.union([.maskCommand, .maskAlternate])),
            .pass
        )
        XCTAssertEqual(
            BreakInputPolicy.decision(keyCode: 53, flags: noise.union([.maskControl, .maskAlternate, .maskCommand])),
            .panic
        )
    }

    func testANearMissOnTheChordIsConsumed() {
        // Only the exact combinations get through. A chord one modifier short is
        // an ordinary key press, and the break stays modal.
        XCTAssertEqual(BreakInputPolicy.decision(keyCode: 53, flags: [.maskShift]), .consume)
        XCTAssertEqual(BreakInputPolicy.decision(keyCode: 53, flags: [.maskCommand]), .consume)
        XCTAssertEqual(BreakInputPolicy.decision(keyCode: 53, flags: [.maskControl, .maskCommand]), .consume)
        XCTAssertEqual(
            BreakInputPolicy.decision(
                keyCode: 53,
                flags: [.maskControl, .maskAlternate, .maskCommand, .maskShift]
            ),
            .consume
        )
    }

    // MARK: - Ending a break with ESC

    func testOnlyBareEscapeEndsTheBreak() {
        // The overlay's own monitor asks this. It is the fallback for a break
        // without a tap, and the two chords the tap passes on purpose reach
        // EyeBreak while it is frontmost. Neither is a skip.
        XCTAssertTrue(BreakInputPolicy.isBreakEndingEscape(keyCode: 53, modifiers: []))
        XCTAssertTrue(BreakInputPolicy.isBreakEndingEscape(keyCode: 53, modifiers: [.maskAlphaShift]))

        XCTAssertFalse(
            BreakInputPolicy.isBreakEndingEscape(keyCode: 53, modifiers: [.maskCommand, .maskAlternate])
        )
        XCTAssertFalse(
            BreakInputPolicy.isBreakEndingEscape(
                keyCode: 53,
                modifiers: [.maskControl, .maskAlternate, .maskCommand]
            )
        )
        XCTAssertFalse(BreakInputPolicy.isBreakEndingEscape(keyCode: 48, modifiers: []))
    }

    // MARK: - Event mask

    func testTheTapAsksForKeyboardEventsOnly() {
        // No mouse. The overlay covers every display and takes mouse events, so
        // a mask entry for them would add a hot callback for no gain — and
        // mouseMoved would add one at a very high rate.
        let mask = BreakInputPolicy.eventMask

        XCTAssertNotEqual(mask & (1 << CGEventType.keyDown.rawValue), 0)
        XCTAssertNotEqual(mask & (1 << CGEventType.keyUp.rawValue), 0)
        XCTAssertNotEqual(mask & (1 << CGEventType.flagsChanged.rawValue), 0)
        XCTAssertEqual(mask & (1 << CGEventType.leftMouseDown.rawValue), 0)
        XCTAssertEqual(mask & (1 << CGEventType.mouseMoved.rawValue), 0)
    }

    // MARK: - Watchdog

    func testTheWatchdogOutlastsTheBreakByTheSlack() {
        XCTAssertEqual(BreakInputPolicy.watchdogDelay(forBreakOf: 20), 30, accuracy: 0.0001)
    }

    func testTheWatchdogNeverFiresBeforeTheSlackIsUp() {
        // A nonsense duration must not produce a watchdog that fires immediately,
        // which would tear the tap down under a break that is still running.
        XCTAssertEqual(BreakInputPolicy.watchdogDelay(forBreakOf: 0), 10, accuracy: 0.0001)
        XCTAssertEqual(BreakInputPolicy.watchdogDelay(forBreakOf: -60), 10, accuracy: 0.0001)
    }

    func testAWaitingBreakGetsTwoExtraMinutes() {
        // A break that waits to be dismissed has no end the watchdog can be
        // armed for, so it is armed for the longest wait we are willing to hold
        // the keyboard through, and no longer.
        XCTAssertEqual(BreakInputPolicy.watchdogDelay(forBreakOf: 20, awaitsDismissal: true),
                       150, accuracy: 0.0001)
    }

    func testTheWaitingCapIsOffByDefault() {
        // The default matters: it is what a break with the feature turned off
        // gets, and it must be the delay the tap has always used.
        XCTAssertEqual(BreakInputPolicy.watchdogDelay(forBreakOf: 300),
                       BreakInputPolicy.watchdogDelay(forBreakOf: 300, awaitsDismissal: false),
                       accuracy: 0.0001)
    }

    func testAWaitingBreakOfNonsenseLengthStillGetsTheFullWait() {
        XCTAssertEqual(BreakInputPolicy.watchdogDelay(forBreakOf: -60, awaitsDismissal: true),
                       130, accuracy: 0.0001)
    }

    // MARK: - Re-enable budget

    func testTheTapCanBeReenabledUpToTheLimit() {
        var budget = TapReenableBudget()

        for _ in 0..<BreakInputPolicy.maximumTapReenables {
            XCTAssertTrue(budget.claim())
        }
    }

    func testTheBudgetRunsOut() {
        // macOS disables a tap that misbehaves. Re-enabling it forever would fight
        // the system with the user's keyboard as the stake, so the tap gives up.
        var budget = TapReenableBudget()

        for _ in 0..<BreakInputPolicy.maximumTapReenables {
            _ = budget.claim()
        }

        XCTAssertFalse(budget.claim())
        XCTAssertFalse(budget.claim())
    }
}
