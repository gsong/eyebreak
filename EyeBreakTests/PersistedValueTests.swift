//
//  PersistedValueTests.swift
//  EyeBreakTests
//
//  AppSettings stores these enums by rawValue and BreakStats as JSON, both in
//  UserDefaults. So a rawValue is not a display string that can be reworded
//  freely: change one and every existing user silently falls back to the
//  default, because the stored string no longer decodes. These tests pin the
//  exact stored spellings so that break is loud instead of silent.
//

import XCTest

final class PersistedValueTests: XCTestCase {

    // MARK: - BreakStyle

    func testBreakStyleRawValues() {
        XCTAssertEqual(BreakStyle.blurScreen.rawValue, "Blur Screen")
        XCTAssertEqual(BreakStyle.eyeExercise.rawValue, "Eye Exercise")

        // Deliberate mismatch: the case is notificationOnly but the stored
        // string is "Floating Window". Renaming the string to match the case
        // would reset the setting for everyone who picked it.
        XCTAssertEqual(BreakStyle.notificationOnly.rawValue, "Floating Window")
    }

    func testBreakStyleDecodesFromStoredString() {
        XCTAssertEqual(BreakStyle(rawValue: "Blur Screen"), .blurScreen)
        XCTAssertEqual(BreakStyle(rawValue: "Floating Window"), .notificationOnly)
        XCTAssertNil(BreakStyle(rawValue: "Notification Only"))
    }

    func testBreakStyleIdentityMatchesRawValue() {
        for style in BreakStyle.allCases {
            XCTAssertEqual(style.id, style.rawValue)
        }
    }

    // MARK: - BreakStats

    func testBreakStatsDefaultsToAnEmptyDay() {
        let stats = BreakStats()
        XCTAssertEqual(stats.breaksCompleted, 0)
        XCTAssertEqual(stats.breaksSkipped, 0)
        XCTAssertEqual(stats.totalBreakTime, 0)
    }

    func testBreakStatsSurvivesAJSONRoundTrip() throws {
        // getAllStats decodes an array of these out of UserDefaults. A property
        // rename would drop a user's whole 30-day history on the next launch.
        let original = BreakStats(date: Date(timeIntervalSince1970: 1_700_000_000),
                                  breaksCompleted: 12,
                                  breaksSkipped: 3,
                                  totalBreakTime: 240)

        let data = try JSONEncoder().encode([original])
        let decoded = try JSONDecoder().decode([BreakStats].self, from: data)

        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0].breaksCompleted, 12)
        XCTAssertEqual(decoded[0].breaksSkipped, 3)
        XCTAssertEqual(decoded[0].totalBreakTime, 240)
        XCTAssertEqual(decoded[0].date.timeIntervalSince1970, 1_700_000_000, accuracy: 0.001)
    }

    func testBreakStatsDecodesTheKeysAlreadyOnDisk() throws {
        // Written the way an installed copy would have written it.
        let json = """
        [{"date":751200000,"breaksCompleted":5,"breaksSkipped":1,"totalBreakTime":100}]
        """
        let decoded = try JSONDecoder().decode([BreakStats].self,
                                               from: Data(json.utf8))
        XCTAssertEqual(decoded[0].breaksCompleted, 5)
        XCTAssertEqual(decoded[0].breaksSkipped, 1)
        XCTAssertEqual(decoded[0].totalBreakTime, 100)
    }
}
