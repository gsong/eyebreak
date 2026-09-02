# EyeBreak

A macOS menu bar app that runs a work-and-break timer for the eyes. This
glossary fixes the words for the timer's behavior: what the clocks count, what
takes the user away from the screen, and what the user can do about a break.

**"Pause" is not in this vocabulary.** The app has no user-facing pause, and
`.paused` in `TimerState` is an implementation name for the away state, not a
domain term. Use **absence** for the machine's report and **stop** for the
user's act. See [ADR-0005](docs/adr/0005-no-user-facing-pause.md).

## Language

### The cycle

**Work interval**:
The stretch of screen time between one break and the next.
_Avoid_: work period, session, pomodoro, cycle

**Break**:
The stretch where the overlay covers every display and the eyes rest.
_Avoid_: rest, break time, pause

**Dismissal wait**:
The stretch after a break's countdown reaches zero, while the overlay stays up
waiting for the user to acknowledge it.
_Avoid_: overtime, hold, grace period

**Natural end**:
The moment a break that went up runs out of its length. It arrives whether the
user is at the screen or away, and it is the only moment the app makes a sound.
A break the user skips or snoozes has no natural end, and neither has a break an
absence fulfils before it ever went up. See
[ADR-0009](docs/adr/0009-one-sound-at-a-breaks-natural-end.md).
_Avoid_: break end, expiry, completion, timeout

### Being away

**Absence**:
A stretch where the machine reports the user is away from the screen. An
absence is **detected**, never declared by the user.
_Avoid_: idle, idle time, away time, pause

**Cause**:
A system signal that says the screen is no longer being consumed: system sleep,
display sleep, screen lock, or screensaver start. A cause confirms an absence.
_Avoid_: trigger, event, reason

**Presence event**:
A signal that says a person is at the machine: an unlock, a screensaver stop, or
a real user input event the app observes. A wake is a power event, not a
presence event.
_Avoid_: activity, wake, resume signal

**Return**:
The end of an absence — the later of the moment the last outstanding cause
clears and the first presence event after the last cause arrival.
_Avoid_: wake, resume, come back

**Absence rule**:
The rule that decides what an absence does to the clocks: an absence at least as
long as the break fulfills the break, and a shorter one rewinds the work
interval. See [ADR-0001](docs/adr/0001-absence-is-time-since-the-last-input-event.md).
_Avoid_: rest rule, idle rule

### What the user can do

**Stop**:
The user ends the session. Declared, and it forgets everything — a later Start
begins a fresh work interval. Stop is a within-session hold; it does not survive
a relaunch.
_Avoid_: pause, disable, turn off, suspend

**Take Break Now**:
The user raises a break immediately, ahead of the timer.
_Avoid_: break now, manual break, force break

**Skip**:
The user ends a break early and forfeits it. A fresh work interval starts.
_Avoid_: cancel, dismiss, close

**Snooze**:
The user defers _this_ break by a fixed length. Declared, and it remembers —
the same break arrives later at its full length.
_Avoid_: postpone, delay, remind me later

**Deferral**:
The state a break is in between a snooze and its arrival. A deferral is not
rest, and any absence discharges it.
_Avoid_: snoozed time, pending break, countdown

**Snooze budget**:
The total deferral one break may collect — half the work interval, fixed when
the break goes up.
_Avoid_: snooze cap, snooze limit, quota
