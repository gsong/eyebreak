# The break cycle runs on one ContinuousClock reading per event

Status: accepted, not yet implemented. Decided in
[#31](https://github.com/gsong/eyebreak/issues/31), which
[ADR-0006](0006-a-relaunch-is-stop-then-start.md) handed the question of how many
clocks the app needs.

**Nothing counts down.** The state records the instant it was entered, and every
duration is worked out on the fly from a `ContinuousClock` reading. There is no
`remainingSeconds` anywhere, in the machine or on screen.

**One reading per event.** The manager reads the clock once, then passes that
single instant to both pure functions — `reduce`, which decides, and `project`,
which draws. Two readings inside one event could straddle a deadline and let the
two functions disagree about what moment it is.

## Why a counter cannot work

Every rule the app has settled compares a duration against the break length
across a possible sleep: an absence rewinding the work interval
([ADR-0001](0001-absence-is-time-since-the-last-input-event.md)), an absence
counting toward a running break ([ADR-0003](0003-an-absence-during-a-break-counts-toward-it.md)),
an absence discharging a deferral ([ADR-0008](0008-any-absence-discharges-a-deferral.md)).
None of them is evaluable from a counter.

`BreakTimerManager.tick()` does `remainingSeconds -= 1` on a one-second `Timer`,
and an overdue repeating `Timer` fires **once** after `didWake`
([#87](https://github.com/gsong/eyebreak/issues/87)). So a three-hour sleep costs
today's counter one second.

## Why `ContinuousClock` and not the others

Measured on this Mac on 2026-08-30, seconds since boot:

| | |
| --- | --- |
| Wall clock (`kern.boottime` to now) | 979,418 |
| `ContinuousClock` | 979,422 |
| `SuspendingClock` / `ProcessInfo.systemUptime` | 652,959 |

That is 91 hours of sleep in 11 days of uptime that the suspending clock never
counted. `SuspendingClock`, `CACurrentMediaTime` and `DispatchTime` are all the
same clock — `systemUptime` matches `SuspendingClock` exactly above — so
recording an instant on any of them reproduces the counter bug in timestamp form.

`Date` is barred outright. [ADR-0006](0006-a-relaunch-is-stop-then-start.md)
persists nothing, so no instant crosses a process exit and nothing needs a
wall-clock date.

## The consequences worth naming

**The break cycle has two clocks.** The manager's one-second tick, and the
keyboard watchdog in `BreakInputTap`, which is a safety backstop and stays
independent of the machine. `BreakCountdown` is deleted, and `IdleDetector`
becomes a one-shot reader with no timer of its own.

**A reading is not a clock.** Two more `ContinuousClock` readings live outside
the count above, and neither one drives the cycle. The presence monitor keeps the
instant of its last report, so that it reports at most one presence event a
second. The `showOverlay` effect carries a `remaining: Duration`, read once when
the overlay goes up, so that the overlay and the keyboard watchdog are armed from
one number — the overlay's own seconds still come from `project`. Neither reading
reaches `reduce` or `project`, so neither can disagree with the manager's one
reading per event, and neither counts down. Decided in
[#104](https://github.com/gsong/eyebreak/issues/104).

**The tick only has to be roughly punctual.** Derived durations mean a coalesced
or delayed tick loses no time; it only delays a redraw. The single exception is
[ADR-0009](0009-one-sound-at-a-breaks-natural-end.md)'s freshness window, which
is why the app holds an App Nap activity assertion for the length of a break.

**Deterministic tests come free.** `now` is a plain `ContinuousClock.Instant`
parameter, so a test takes one reading and advances it. There is no `Clock`
protocol and nothing to fake.

## Considered and rejected

**Keeping a counter for the display alone.** `BreakCountdown` ran a second
one-second `Timer` and decremented its own number, which is how the app ended up
with a comment explaining that the manager's clock and the overlay's "do not
share a second boundary". Deriving the displayed number from the same reading
that drove `reduce` removes the boundary rather than documenting it.

**A `Clock` protocol injected into the manager.** It would make the manager's own
scheduling testable, not just the reducer's decisions. That is a question about
how effects are performed, which is
[#104](https://github.com/gsong/eyebreak/issues/104)'s, and a pure reducer taking
an instant already gives the machine everything it needs.
