# EyeBreak Architecture

How the app is put together, as of 3.0.0. About 2,950 lines of Swift across 25
files, plus 500 lines of tests across 4.

- [Overview](#overview)
- [The loop](#the-loop)
- [Models](#models)
- [Managers](#managers)
- [Views](#views)
- [Settings and persistence](#settings-and-persistence)
- [Permissions](#permissions)
- [Tests](#tests)

## Overview

- **Language**: Swift 5.9
- **UI**: SwiftUI, with AppKit where SwiftUI cannot reach — the status item, the
  overlay windows, the keyboard tap
- **Reactive**: Combine
- **Minimum target**: macOS 26.0 (Tahoe)

The app has no Dock icon (`LSUIElement`). Two things are on screen: the status
item in the menu bar, and the Settings window. A third appears during a break —
one overlay window per display.

`EyeBreakApp.swift` owns the entry point. It declares a single SwiftUI `Window`
scene for Settings, installs two `NSEvent` monitors for ⌃⌥B, and starts the
timer unconditionally at launch.

Most managers are singletons reached through `.shared`. That is inherited, not
chosen; there is no dependency-injection container.

## The loop

There is one loop and one clock.

```
launch
  │
  ▼
BreakTimerManager.start()          state: .idle → .working
  │
  ▼
tick() every second                remainingSeconds counts down
  │
  ├──▶ idle past threshold ──▶ .paused(wasWorking:) ──▶ activity ──▶ .working
  │
  ▼
remainingSeconds == 0
  │
  ▼
startBreak()                       state: .working → .breaking
  │                                ScreenBlurManager puts one overlay on
  │                                every display, all driven by one
  │                                BreakCountdown
  │                                BreakInputTap takes the keyboard
  ▼
serveBreak()                       the break is over
  │
  ├── requireBreakDismissal off ──▶ endBreak() ──▶ .working
  │
  ▼
awaitDismissal()                   state: .awaitingDismissal
  │                                overlay stays up, nothing counts
  ▼
⎋, the button, or the panic chord
  │
  ▼
startNextWorkInterval()            state: .working, a full interval
```

`BreakTimerManager.tick()` is the only thing that ends a break. `BreakCountdown`
draws and nothing more — reaching zero there ends nothing. That split is what
lets the overlay set be rebuilt when a display is attached or detached without
restarting the break.

The manager is split across three files: `BreakTimerManager.swift` (state and
the tick), `+Break.swift` (the break phase), `+SystemEvents.swift` (sleep, wake,
screen lock, idle).

## Models

### TimerState

```swift
enum TimerState: Equatable {
    case idle
    case working(remainingSeconds: Int)
    case breaking(remainingSeconds: Int)
    case paused(wasWorking: Bool, remainingSeconds: Int)
    case awaitingDismissal
}
```

`awaitingDismissal` reports `isActive == false`, because nothing is counting
during the wait — and because `pause()` guards on `isActive`, which is what
makes sleep, screen lock and idle detection leave the waiting overlay where it
is.

`hasBreakOnScreen` covers `.breaking` and `.awaitingDismissal` together, so a
second break cannot start on top of either.

### AppSettings

Six settings, all `@AppStorage`. Three of them — work interval, break duration,
idle threshold — **clamp on read, not on write**. `BreakTimerManager` reads the
stored values at eight sites, so a clamp in the view would let Settings show 45
while the timer ran 50. The setter stays open on purpose, so a hand-written
out-of-range value keeps its stored form if a range ever widens back.

Break duration is stored in seconds and shown in minutes. A 60–600 second slider
gives under a point per second, so the thumb could not land on a round number.

`resetToDefaults()` deliberately skips `launchAtLogin`: writing that key
registers or unregisters a macOS login item, which is system state rather than a
preference.

### BreakCountdown

One instance per break, shared by the overlay on every screen. It carries the
seconds left and whether the break has been served. Two views counting
separately would drift.

### TimeFormat

One function, `compact(_:)`, producing `M:SS`. Every countdown in the app goes
through it — the status button, the overlay ring, the timer strip, the menu-bar
tooltip. Before 3.0.0 there were three formats and one of them printed raw
seconds.

## Managers

| File                        | Does                                                                |
| --------------------------- | ------------------------------------------------------------------- |
| `BreakTimerManager`         | The loop above. Owns `TimerState` and the one-second tick           |
| `ScreenBlurManager`         | Builds and tears down one overlay window per display                |
| `ScreenBlurManager+Windows` | Window level, screen-change rebuilds, focus hand-back               |
| `BreakOverlayWindow`        | The borderless `NSWindow` and a hosting view that takes first mouse |
| `BreakInputTap`             | The `CGEvent` tap that holds the keyboard during a break            |
| `BreakInputPolicy`          | The rules the tap runs on, kept separate so they are testable       |
| `AccessibilityPermission`   | Watches the grant the tap and ⌃⌥B both need                         |
| `IdleDetector`              | IOKit idle time, polled; pauses and resumes the timer               |
| `StatusBarController`       | The status item and its `NSMenu`                                    |
| `SoundManager`              | Four system sounds                                                  |
| `LaunchAtLoginManager`      | `SMAppService` registration                                         |

### BreakInputTap and BreakInputPolicy

The riskiest code in the app, and the reason the policy is a separate file with
its own tests.

A full-screen overlay stops the mouse. It does not stop ⌘Tab, ⌘Q, ⌘H, or any
global hotkey another app has registered. The tap consumes all of that. A live
process holding an active tap that no longer consumes correctly leaves the
machine with no keyboard, and recovery is a power cycle.

`BreakInputPolicy.decision(keyCode:flags:)` reads only the event in hand. It
never asks which app is frontmost or what the break is doing — that would be a
race, in a callback that runs on every keystroke.

Three independent ways out, each working without the other two:

1. **⌘⌥⎋** (Force Quit) always passes. It opens behind the overlay, so it is a
   way out only once the overlay is gone.
2. **⌃⌥⌘⎋**, the panic chord, tears the tap down inside the callback, on the
   callback's own thread, before the break is told anything.
3. A **watchdog** on its own queue tears the tap down at break duration, plus a
   dismissal allowance if the break will wait, plus slack. It is armed once when
   the break starts, reads no break state, and must never be re-armable.

Bare **⎋** ends the break from the tap rather than from the overlay's own
monitor. The monitor only sees keys macOS has routed to EyeBreak, and under
cooperative activation (macOS 14+) a self-activation from a timer can be
refused. The tap sees ⎋ whichever app has focus.

### StatusBarController

The menu bar has always been an AppKit `NSMenu`. There is no `MenuBarExtra` and
no `NSPopover`; the SwiftUI popover that used to be in the tree was never
reachable and was deleted in 3.0.0.

Four commands and two separators: Open Settings…, then one Start-or-Stop item
retitled by `menuNeedsUpdate`, Take Break Now, and Quit. One item covers both timer
directions because `start()` guards on `.idle` and `stop()` always returns
there, so the state names the only move available.

**A status-item menu's key equivalents never dispatch.** They are labels. The
chord that works is the `NSEvent` monitor pair in `EyeBreakApp.swift` — a global
monitor for other apps, a local one to stop the chord reaching the rest of
EyeBreak.

## Views

`SettingsWindowHost` wraps `SettingsView` and builds it only while the window is
on screen. SwiftUI instantiates the `Window` scene at launch and keeps it alive
after it is closed; `SettingsView` observes a manager that publishes once a
second, so the whole tree was being laid out and rendered every second into a
window nobody could see. That was about 24 percentage points of idle CPU.

`SettingsView` is a one-row timer strip (`TimerStatusBanner`) over a single
scrolling `Form(.grouped)`. Two sections: `Timer` — three sliders and four
toggles — and an untitled tail with the permission row, Reset to Defaults, and
the version. There is no sidebar and there are no tabs.

`BreakOverlayView` draws the ground and the frame; `BreakOverlayContent` holds
the two content arms — the running break and the completion state.
`BreakOverlayTimerDisplay` is the ring.

The overlay uses **system colours and no hex constant anywhere**. The ground is
`Color(nsColor: .windowBackgroundColor)` at 85% over a clear window — a flat
veil, not a blur. `NSVisualEffectView` renders flat under Reduce Transparency,
which is on on the machine this app runs on, so the blur it used to draw had
never blurred anything. `.secondary` is not used: over a veiled desktop it is
the first thing to fail.

## Settings and persistence

`@AppStorage` throughout, in `com.eyebreak.app`. Note that `@AppStorage` writes
a key when the setting is **set**, not when it is read, so a default that was
never changed leaves nothing on disk.

Nothing else is persisted. 3.0.0 stopped writing the `breakStatistics` history,
and the app records nothing about how many breaks you take or skip.

`scripts/prune-prefs.sh` clears the 38 keys 3.0.0 orphaned.

## Permissions

**Accessibility** is the only grant. `BreakInputTap` needs it to create the
`CGEvent` tap, and the ⌃⌥B global monitor needs it too.

EyeBreak is signed with a local certificate, so its designated requirement is
pinned to the build's `cdhash`. Every build produces a different hash, so macOS
treats each install as a different program and drops the grant.
`AccessibilityPermission` watches for that and the Settings window shows a
warning row with a button to the right pane.

The app requests **no other permission**. It does not link `UserNotifications`
and never asks for Screen Recording — the overlay is a plain window, and drawing
one needs no capture grant.

## Tests

Four test files, all unit tests on logic that can run without a screen:

| File                    | Covers                                        |
| ----------------------- | --------------------------------------------- |
| `BreakInputPolicyTests` | Every branch of the tap's decision table      |
| `TimerStateTests`       | `isActive`, `hasBreakOnScreen`, `displayText` |
| `BreakCountdownTests`   | Ticking, the served phase, boundaries         |
| `SettingsHelperTests`   | Clamping and the derived minutes properties   |

The test target compiles its own subset of app sources. Adding a file to the app
target is half the job — check both `Sources` phases in `project.pbxproj`.

Everything else is tested by hand. See [TESTING.md](TESTING.md), which also
records what a script can and cannot drive on this machine.
