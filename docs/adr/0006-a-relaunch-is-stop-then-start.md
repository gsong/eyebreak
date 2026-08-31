# Stop is a within-session hold, and a relaunch is Stop-then-Start

Status: accepted. Decided in
[#90](https://github.com/gsong/eyebreak/issues/90). This changes no code — it
fixes today's behavior as deliberate rather than incidental.

**Stop forgets everything.** Start begins a fresh work interval. Stop during a
break tears the overlay down and counts nothing.

**Time the app was not running is not an absence — and not work either.** The
app persists nothing, arms on every launch, and begins a fresh work interval. A
break, a dismissal wait, and a snooze deferral are all lost. One rule covers
every relaunch — deliberate Quit, reboot, crash, and `scripts/dev-install.sh`
alike — because the app cannot reliably tell them apart, and gap duration is the
only signal it could key on.

**A prior Stop does not survive a relaunch.** Stop leaves the app disarmed; a
relaunch leaves it armed. The difference is deliberate, and any description of
the behavior must show both, or the relaunch row reads as a contradiction.

## Why the gap is not an absence

The app observes nothing while it is not running, and it cannot reconstruct the
gap afterward. The one signal that could —
`CGEventSourceSecondsSinceLastEventType` — is destroyed by the login that
follows a reboot, and reads as "input just now" after any manual relaunch.
[ADR-0005](0005-no-user-facing-pause.md) settled that absence is detected, not
declared. An unobserved gap declared as an absence repeats exactly that error, so
the absence-rule treatment was rejected on principle, not on cost.

## Why not resume where the clock stopped

Recommended and **overruled**. The argument for resuming was that the two errors
are not symmetric: a fresh interval _under_-rests, resuming _over_-rests, and
over-rest is the safe error for an eye-strain app.

George took the fresh interval anyway, on scope. Persistence buys accuracy only
in the sub-five-minute relaunch, which is a developer's situation, not a user's.
Paying for it with a persisted record on every quit is the wrong trade for a
personal app.

## Why a persisted Stop was rejected

Stop is now the only deliberate hold the app has, so a relaunch that re-arms does
override the user's only off switch. But `launchAtLogin` is on, so a persisted
Stop would leave the app silently disarmed the next morning — the forgot-to-Start
failure again, in its worst form.

## Consequences

**No `Date` is needed anywhere.** Persisting nothing means no instant crosses a
process exit, so every clock in the app can be a `ContinuousClock`. That matters
because a suspending clock does not count sleep: measured on this Mac on
2026-08-30, 979,418 s of wall time since boot against 652,959 s on the suspending
clock — 91 hours of sleep uncounted in 11 days of uptime. Every rule that
compares a duration against the break length is unevaluable on a clock like that.
How many clocks the app needs is [#31](https://github.com/gsong/eyebreak/issues/31)'s
question; this only settles that none of them needs a wall-clock date.

**Accepted cost.** A relaunch late in a work interval resets it, so a
`dev-install.sh` run at minute 24 gives 49 minutes of screen time with no break.
During a development session that repeats on every install. **No mitigation
ships** — the same position [ADR-0001](0001-absence-is-time-since-the-last-input-event.md)
takes on the reading gap: accept the inaccuracy and write it down.
