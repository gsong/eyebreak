//
//  SoundManagerTests.swift
//  EyeBreakTests
//

import AppKit
import XCTest

final class SoundManagerTests: XCTestCase {

    // MARK: - A stuck audio daemon

    func testPlayReturnsWhileThePlayerIsStillBlocked() {
        // On 2026-10-26 a wedged coreaudiod held each NSSound.play for about 24
        // seconds. Called from the main thread, that froze the break countdown
        // and every way out of the overlay. Here the player blocks for up to two
        // seconds, so a playSound that waits on it takes at least that long.
        let release = DispatchSemaphore(value: 0)
        let played = expectation(description: "the player ran")
        let sounds = SoundManager { _ in
            _ = release.wait(timeout: .now() + 2)
            played.fulfill()
        }

        let started = Date()
        sounds.playSound(.breakStart)
        let elapsed = Date().timeIntervalSince(started)

        release.signal()
        wait(for: [played], timeout: 3)
        XCTAssertLessThan(elapsed, 0.5)
    }

    func testASoundRequestedWhileOneIsStuckIsDropped() {
        // Queued behind a stuck play, the second sound would go off whenever
        // audio recovered. ADR-0009: a late sound is worse than none.
        let release = DispatchSemaphore(value: 0)
        let played = expectation(description: "the first sound played")
        var names: [NSSound.Name] = []
        let sounds = SoundManager { name in
            names.append(name)
            _ = release.wait(timeout: .now() + 2)
            played.fulfill()
        }

        sounds.playSound(.breakStart)
        Thread.sleep(forTimeInterval: 0.1)
        sounds.playSound(.breakEnd)

        release.signal()
        wait(for: [played], timeout: 3)
        // Gives a wrongly queued second sound time to run before counting.
        Thread.sleep(forTimeInterval: 0.2)
        XCTAssertEqual(names, ["Glass"])
    }

    func testEachSoundTypePlaysItsOwnSound() {
        var names: [NSSound.Name] = []
        var played: XCTestExpectation?
        let sounds = SoundManager { name in
            names.append(name)
            played?.fulfill()
        }

        // One at a time, so none is dropped for overlapping the last. The pause
        // lets the sound finish being marked done after the player returns.
        for type in [SoundManager.SoundType.start, .breakStart, .breakEnd, .skip] {
            played = expectation(description: "\(type) played")
            sounds.playSound(type)
            wait(for: [played!], timeout: 1)
            Thread.sleep(forTimeInterval: 0.05)
        }

        XCTAssertEqual(names, ["Blow", "Glass", "Purr", "Tink"])
    }
}
