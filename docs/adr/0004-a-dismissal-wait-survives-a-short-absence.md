# A dismissal wait survives a short absence, floored at the moment the wait began

Status: accepted, not yet implemented. Decided in
[#94](https://github.com/gsong/eyebreak/issues/94), floor restated by
[#32](https://github.com/gsong/eyebreak/issues/32).

An absence that begins while a served break waits to be dismissed is measured
from `max(last input event, the moment the wait began)` to Return. The wait
begins at the break's natural end.

This used to say "the moment the break was served", which reads two ways — the
break going up, or the break being given in full. Only the second is the floor.
See "Which instant the floor names" below.

- **Absence at least as long as the break clears the wait.** On Return the
  overlay does not come back, and a fresh work interval starts.
- **Shorter leaves the wait standing.** On Return the overlay is rebuilt, still
  asking for a dismissal, with a fresh keyboard allowance.

The overlay comes down when the absence begins, as it does for a running break
([ADR-0003](0003-an-absence-during-a-break-counts-toward-it.md)). **Each absence
is measured alone** — three two-minute locks do not add up, because each return
means the user saw the overlay and chose not to dismiss it. Nothing counts
during a wait, so a short absence rewinds nothing; the threshold decides only
whether the dismissal is still asked for.

There is **no separate timeout on the wait**. Absence is the bound. A second
timeout would be a second arithmetic rule doing the same job.

## The floor is now shared with ADR-0003

[ADR-0003](0003-an-absence-during-a-break-counts-toward-it.md) carries the same
floor, added in [#28](https://github.com/gsong/eyebreak/issues/28) for the same
reason. So a running break and a dismissal wait differ in **what the threshold
decides**, not in how the absence is measured. Both measure from **the moment the
current stretch began**.

## Which instant the floor names

This paragraph used to say both floors measure from "the moment the overlay took
the keyboard". For a running break that is the same instant. For a dismissal wait
it is a whole break length earlier, and it breaks the rule.

Take the overlay's keyboard grab as the floor. The wait starts at the break's
natural end, so every absence during a wait then measures at least a break
length, the threshold is met every time, and the wait is always cleared. That is
the failure this ADR exists to stop, in the ADR's own words below: "any cause
arriving then measures at least a break length, and the threshold is met every
time."

The floor is the start of the wait. That is what the reason below already says —
the break's own time is already spent and must not be counted twice. So the
phrase that covers both floors is **the moment the current stretch began**: for a
running break, when the overlay went up or was last rebuilt; for a dismissal
wait, the natural end.

In [#25](https://github.com/gsong/eyebreak/issues/25)'s reducer both read as one
field, `ctx.enteredAt`. Found while writing the transition table in
[#32](https://github.com/gsong/eyebreak/issues/32).

## Why the floor is not optional

Without it, [ADR-0001](0001-absence-is-time-since-the-last-input-event.md)'s
last-input rule reads back through the break itself. The overlay holds the
keyboard, so a user who sat still through a five-minute break already has a
last-input event five minutes stale the instant the wait begins. Any cause
arriving then measures at least a break length, and the threshold is met every
time. The floor is also correct on its own terms: that time was break time,
already spent and already credited. Counting it again as absence spends it
twice.

## Why duration, and not "any absence"

Letting any absence clear the wait was the recommendation, and it was
**overruled**. Its case was that the arithmetic here moves no clock, so it buys
nothing. The answer is that the threshold does a different job in this row than
it does in the absence rule. It is not asking _did they rest enough_ — the break
already ran. It is asking _is the acknowledgment still meaningful_, and a
30-second screensaver trip does not make it meaningless.

Break length was chosen over a shorter number for one-duration consistency
across the model, and over reusing the 120 s `dismissalWaitAllowance`, which is a
safety backstop rather than a behavior rule.

## What this does not change

The keyboard hold was already bounded. The watchdog is armed once at break start
for break length plus 120 s plus 10 s, so an undismissed wait gives the keyboard
back about 130 s after the break is served, leaving the overlay up. That backstop
is unchanged. The wait now has two exits that are not the user: a long absence,
and the watchdog releasing the keyboard.

Stop is not a substitute for this rule. Stop is a deliberate act at the menu bar,
and this is what happens when the user does _nothing_ — walks off from a finished
break. Since display sleep is a cause, an undismissed overlay with nobody typing
reaches a cause on its own, so this is the ordinary fate of an ignored break
rather than a corner case.
