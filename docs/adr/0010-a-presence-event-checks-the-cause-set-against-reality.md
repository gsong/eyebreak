# A presence event checks the cause set against reality

Status: accepted, not yet implemented. Decided in
[#30](https://github.com/gsong/eyebreak/issues/30), wired in
[#32](https://github.com/gsong/eyebreak/issues/32).

Return waits for the cause set to empty
([ADR-0002](0002-only-a-presence-event-ends-an-absence.md)). The set empties only
when a clear signal arrives, and a clear signal can fail to arrive. So **every
presence event is also a check**: the app reads real system state for all four
causes and clears each one it finds false.

| Cause | What clears it on a presence event |
| --- | --- |
| Display sleep | `CGDisplayIsAsleep` reads false |
| System sleep | the app's run loop is running, so the system is awake |
| Screen lock | nothing — only `com.apple.screenIsUnlocked` clears it |
| Screensaver | the presence event itself |

The check is unconditional and reads no app state. It runs on all four causes
whether or not the app thinks they are outstanding, because clearing a cause that
is not outstanding does nothing.

**The reading happens outside the machine.** A pure reducer cannot query the
system, so the host does the four reads and reports each false cause as an
ordinary cause-cleared event before it reports the presence event. The check
needs no event of its own and no payload. Order does not matter, because Return
is the later of two conditions and both event kinds test it: if the clears land
first, Return fires on the presence event; if the presence event lands first, it
banks and Return fires on the last clear. Decided in
[#32](https://github.com/gsong/eyebreak/issues/32).

## Why bookkeeping alone is not enough

A dropped clear signal leaves a cause outstanding for good. Return never fires,
the work interval never resumes, and the app stops raising breaks. That is the
outcome [ADR-0002](0002-only-a-presence-event-ends-an-absence.md) rules out in
its own accepted costs: a degraded break is tolerable, a broken timer is not.

The risk is real but small. [#87](https://github.com/gsong/eyebreak/issues/87)
found that distributed notification delivery is best-effort, and Apple DTS
confirms `screensDidSleepNotification` and `screensDidWakeNotification` arrive
inconsistently across MacBooks — one LaunchAgent author never received them at
all. Against that, [#96](https://github.com/gsong/eyebreak/issues/96) measured
the display pair firing every time across 9h15m unattended, plus four trials in
[#93](https://github.com/gsong/eyebreak/issues/93). This Mac behaves. The rule
exists so that a Mac that does not behave degrades into extra breaks rather than
into none.

## This is not the fallback signal ADR-0001 refused

[ADR-0001](0001-absence-is-time-since-the-last-input-event.md) ships no fallback
signal for **detecting** an absence: a display held awake records nothing, and
nothing polls to catch it. That still holds. This rule adds no way to start an
absence. It refuses to trust bookkeeping about an absence already running.

## Considered and rejected

**Accept the wedge.** No check; a stuck absence needs Stop then Start from the
menu. Cheapest, and it matches ADR-0001's taste for accepting inaccuracy. It was
rejected because the failure is not an inaccuracy — it is the timer not running,
which the user may not notice for hours.

**Implication clears as the general strategy.** An unlock clears lock,
screensaver, and display sleep; a wake clears system sleep. No new API at all.
Rejected because it infers rather than checks, and it covers nothing on a Mac
that never requires a password — where display sleep is the only cause and no
unlock follows it. Implication survives for the screensaver alone, where no
query exists.

**Presence clears the whole set.** The set becomes advisory and presence is the
truth. Rejected because it collapses ADR-0002's "later of" into "first presence
event", which drops the guard against something registering as input at a dark
screen — the effect [#93](https://github.com/gsong/eyebreak/issues/93) saw at
20:16 with nobody in the room.

**Reading the lock state directly.** `CGSessionCopyCurrentDictionary` is Apple
API, but its `CGSSessionScreenIsLocked` key is not, and #87 found no documented
substitute. The check stays documented-only.

## Accepted costs

- **A dropped unlock wedges the absence.** Lock has no documented query, so if
  `com.apple.screenIsUnlocked` never arrives, that cause stays outstanding. The
  check closes three holes of four.
- **Mouse movement at the lock screen is presence but not Return.** The check
  clears display sleep, lock stays, and the absence runs until the unlock. That
  is correct — the screen is locked, so it is not being consumed — but it means a
  banked presence event can sit for minutes.
- **Four system reads per presence event.** During an absence the input monitor
  can fire often, so the reads must stay cheap. All four are local state
  queries; none is a notification round trip.
