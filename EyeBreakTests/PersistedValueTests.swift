//
//  PersistedValueTests.swift
//  EyeBreakTests
//
//  AppSettings stores these enums by rawValue in UserDefaults. So a rawValue is
//  not a display string that can be reworded freely: change one and every
//  existing user silently falls back to the default, because the stored string
//  no longer decodes. These tests pin the exact stored spellings so that break
//  is loud instead of silent.
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
}
