# An absence is time since the last input event, confirmed by a system cause

Status: accepted, not yet implemented. Decided in
[#88](https://github.com/gsong/eyebreak/issues/88).

The timer tracks **time since the last input event**. An absence starts at the
last input event and ends at Return ([ADR-0002](0002-only-a-presence-event-ends-an-absence.md)).
An absence at least as long as the break fulfills the break, so a fresh work
interval starts on Return. A shorter absence rewinds the work interval to the
last input event and resumes it there — the quiet minutes before the cause are
absence, not work, and they cannot be both.

One rule covers every cause: system sleep, display sleep, screen lock, and
screensaver. Nothing special-cases an idle-driven cause against a deliberate
one, because measuring actual last input already handles both. A hot-corner
sleep or a manual lock backdates by roughly zero, because the keystroke that
triggered it _is_ input. An idle display sleep backdates by whatever the OS's
own delay was.

**Input is read only when a cause arrives.** Nothing polls. The read uses
`CGEventSourceSecondsSinceLastEventType`, once per absence — see
[ADR-0002](0002-only-a-presence-event-ends-an-absence.md) for why once.

## What this replaced

Input-idle is gone as a polled cause, and display sleep takes its place.
`IdleDetector`, the `idleDetectionEnabled` and `idleThresholdMinutes` settings,
and their Settings toggle and slider all go. Display sleep arrives in the same
change, because without it the app is blind whenever "Require password" is off:
[#87](https://github.com/gsong/eyebreak/issues/87) found the display then sleeps
with no lock notification.

**Note the collapse honestly.** Backdating a display sleep to the last input
event reconstructs roughly what `IdleDetector` measured. This is less the
deletion of input-idle than its re-derivation from a better trigger. What
actually changes: the threshold now comes from the OS's assertion-aware
display-sleep delay instead of a user slider, so a film playing behind a
`PreventUserIdleDisplaySleep` assertion correctly records no absence while it
plays. And two settings disappear.

## The principle changed, and the counter-argument lost

An earlier draft said the timer tracks _time since the eyes last rested_, and
argued that reading the screen without typing is not rest, so crediting it is
the unsafe direction. **That argument was considered and overruled.**

The cost is real and is accepted: read on AC for five minutes, let the display
sleep, wake it a second later, and you are granted a fresh work interval you did
not earn. The alternative fails a case that happens far more often. Without
backdating, a seven-minute trip away from the desk on AC registers as two
minutes of dark time — under the threshold, so no fresh interval. Real absence
would have to run about eight minutes on AC and six on battery to count at all.
That is the case the rule exists to serve, and it loses to a corner case.

## Considered and rejected

**Backdating by the configured `pmset` delay** instead of by actual last input.
On this Mac `displaysleep` is 5 minutes on AC and the break is 5 minutes, so
subtracting the delay makes _every_ completed display sleep clear the threshold.
Wake the screen one second after it darkens and you still get a fresh interval,
and the duration test becomes dead code on mains power. On battery, where the
delay is 1 minute, the test survives — the same code is two different products
depending on the charger. It also gifts five minutes to every deliberate
hot-corner sleep. The equality of those two numbers is a coincidence nothing
maintains.

**A Reading Mode or content-aware presence.** Workrave ships an explicit Reading
Mode that keeps timers running through input silence; LookAway inverts the signal
set and reads video and meetings as presence. Both are real fixes for the gap
above. EyeBreak takes Dejal's position instead — accept the inaccuracy, write it
down, add no mode.

## Accepted costs

- **A display held awake records no absence.** A `caffeinate` assertion or a
  video player keeps the screen lit, so breaks keep firing at an empty chair. No
  fallback signal and no override ship. Extra breaks are the safe failure, and
  [ADR-0003](0003-an-absence-during-a-break-counts-toward-it.md) serves that
  break anyway.
- **An absence too short to trip any cause is invisible.** A four-minute trip on
  AC never pauses the work interval. Today's `IdleDetector` at its five-minute
  default is equally blind, so nothing is lost against current behavior. This is
  where EyeBreak deviates from the category, which polls input idle
  continuously.
