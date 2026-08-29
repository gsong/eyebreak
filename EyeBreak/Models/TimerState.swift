//
//  TimerState.swift
//  EyeBreak
//
//  Created on October 5, 2025.
//

import Foundation

/// Represents the current state of the break timer
enum TimerState: Equatable {
    case idle              // Timer not started
    case working(remainingSeconds: Int)  // Working period
    case breaking(remainingSeconds: Int) // Break period
    case paused(wasWorking: Bool, remainingSeconds: Int) // Paused due to idle
    case awaitingDismissal // Break served, waiting for the user to dismiss it

    var isActive: Bool {
        switch self {
        case .idle, .paused, .awaitingDismissal:
            // Nothing counts while a served break waits to be dismissed, and
            // `pause()` guards on this, which is what makes sleep, screen lock
            // and idle detection leave the waiting overlay where it is.
            return false
        case .working, .breaking:
            return true
        }
    }

    /// Whether a break is on screen right now, running or served and waiting.
    /// Starting a break on top of either would announce two for one rest.
    var hasBreakOnScreen: Bool {
        switch self {
        case .breaking, .awaitingDismissal:
            return true
        case .idle, .working, .paused:
            return false
        }
    }

    var displayText: String {
        switch self {
        case .idle:
            return "Ready to start"
        case .working(let seconds):
            return "Next break in \(formatTime(seconds))"
        case .breaking(let seconds):
            return "Break time! \(seconds)s remaining"
        case .paused(_, let seconds):
            return "Paused - \(formatTime(seconds)) remaining"
        case .awaitingDismissal:
            return "Break complete — dismiss to continue"
        }
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
