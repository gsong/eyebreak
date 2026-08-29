//
//  TimeFormat.swift
//  EyeBreak
//

import Foundation

/// How a countdown reads, everywhere the app shows one.
///
/// One definition on purpose. The status button and the break overlay both count
/// the same seconds down, and a second formatter would let them disagree about
/// what time looks like.
enum TimeFormat {

    /// `M:SS` — minutes, a colon, two digits of seconds. The colon carries the
    /// unit, so no caller needs a "seconds" caption.
    ///
    /// The widest value the app can pass is a ten-minute break, so the minutes
    /// field is one digit for every value below `10:00`.
    static func compact(_ seconds: Int) -> String {
        "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }
}
