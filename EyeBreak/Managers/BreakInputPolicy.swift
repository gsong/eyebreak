//
//  BreakInputPolicy.swift
//  EyeBreak
//
//  The rules the break's keyboard tap runs on, kept apart from the tap itself so
//  they can be tested without taking anyone's keyboard away. See BreakInputTap
//  for what installs them and why the escape hatches are shaped this way.
//

import CoreGraphics
import Foundation

/// What the break's keyboard tap does with one event.
enum BreakKeyDecision: Equatable {
    /// Hand the event on. It reaches whatever would have had it.
    case pass
    /// Drop the event. Nothing downstream ever sees it.
    case consume
    /// Bare Escape. Drop the event and end the break.
    case endBreak
    /// The panic chord. End the break, tear the tap down, and hand the event on.
    case panic
}

enum BreakInputPolicy {

    static let escapeKeyCode: Int64 = 53

    /// How long the watchdog outlives the break it was armed for.
    static let watchdogSlack: TimeInterval = 10

    /// How many times a disabled tap may be re-enabled before the tap gives up.
    /// See `TapReenableBudget`.
    static let maximumTapReenables = 3

    /// The events the tap asks for. Keyboard only.
    ///
    /// No mouse. The overlay covers every display at the maximum window level and
    /// takes mouse events, so a click cannot reach another app. A mouse mask would
    /// add a hot callback for no gain, and mouseMoved would add one at a very high
    /// rate.
    ///
    /// flagsChanged is here for the triggers a modifier fires on its own: fn
    /// twice for dictation, the Globe key for input sources, the double-tap-Cmd
    /// launchers. The cost is that an app tracking modifier state from these
    /// events can believe a modifier is still held until the user next presses
    /// one. That state is cosmetic and it corrects itself; the triggers are not.
    static let eventMask = CGEventMask(
        (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)
    )

    // MARK: - Public Methods

    /// Consume everything except the three ways out, and end the break on the
    /// first of them.
    ///
    /// The rule reads only the event in hand. It does not ask which app is
    /// frontmost or what the break is doing: that would be a race, and it would
    /// put work in a callback that runs on every keystroke.
    ///
    /// Presses, releases and modifier changes all come through here, and get the
    /// same answer for the same keys. That is what stops an app from seeing half
    /// a key.
    static func decision(keyCode: Int64, flags: CGEventFlags) -> BreakKeyDecision {
        guard keyCode == escapeKeyCode else { return .consume }

        switch flags.intersection(consideredModifiers) {
        case []:
            // Ends the break from here rather than from the overlay's monitor.
            // The monitor only sees keys macOS has routed to EyeBreak, and under
            // cooperative activation (macOS 14+) a self-activation from a timer
            // can be refused while another app is frontmost. The tap sees ESC
            // whichever app has focus.
            return .endBreak
        case [.maskCommand, .maskAlternate]:
            // Force Quit. It passes even though it also lets the user force-quit
            // an app mid-break.
            //
            // Passing it is not the same as it working. Tested during a break:
            // the panel does open, but it opens below an overlay that sits at
            // the maximum window level, and the arrow keys and Return that would
            // drive it are consumed here like everything else. So it is a way
            // out only once the overlay is gone. Treat the panic chord and the
            // watchdog as the outs that actually work, and keep this one because
            // consuming it could only make things worse.
            return .pass
        case [.maskControl, .maskAlternate, .maskCommand]:
            // The panic chord. Checked twice over before it was chosen: it is in
            // neither the system's symbolic hotkey table nor Apple's published
            // list of Mac keyboard shortcuts, where Cmd-Opt-Esc is the only
            // Escape chord. Neither check settles it alone, because macOS
            // hardcodes Force Quit rather than listing it in that table.
            return .panic
        default:
            return .consume
        }
    }

    /// Whether this is the bare Escape that ends a break.
    ///
    /// The overlay's own ESC monitor asks this rather than matching the key code
    /// alone. The monitor is the fallback for a break without a tap, and without
    /// this the two Escape chords the tap deliberately passes would both end the
    /// break as a side effect of reaching EyeBreak.
    static func isBreakEndingEscape(keyCode: Int64, modifiers: CGEventFlags) -> Bool {
        return keyCode == escapeKeyCode && modifiers.isDisjoint(with: consideredModifiers)
    }

    /// When the watchdog tears the tap down: the break, plus enough slack that a
    /// break ending normally has always got there first.
    static func watchdogDelay(forBreakOf seconds: TimeInterval) -> TimeInterval {
        return max(0, seconds) + watchdogSlack
    }

    // MARK: - Private

    /// The modifiers a decision turns on. Caps lock, fn and the numeric-pad bit
    /// ride along on ordinary events, and a user with caps lock on still has to
    /// be able to reach every escape hatch.
    private static let consideredModifiers: CGEventFlags = [
        .maskCommand, .maskAlternate, .maskControl, .maskShift
    ]
}

/// How many times a disabled tap may be re-enabled before the tap gives up.
///
/// macOS disables a tap whose callback ran too long, and again when the user
/// floods it with input. Re-enabling is right a few times over; past that the tap
/// is losing an argument with the system, and the thing being argued over is the
/// user's keyboard.
struct TapReenableBudget {

    private(set) var used = 0

    /// Takes one re-enable from the budget. False once it is spent.
    mutating func claim() -> Bool {
        guard used < BreakInputPolicy.maximumTapReenables else { return false }
        used += 1
        return true
    }
}
