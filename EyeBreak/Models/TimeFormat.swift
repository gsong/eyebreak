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
    /// The minutes field is as wide as it needs to be: a break reads `5:00`, a
    /// 45-minute work interval reads `45:00`. There is no hours field, so a value
    /// past an hour keeps counting minutes rather than rolling over.
    static func compact(_ seconds: Int) -> String {
        "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }
}
