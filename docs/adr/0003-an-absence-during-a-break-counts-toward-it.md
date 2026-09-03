# An absence during a break counts toward the break

Status: accepted, not yet implemented. Settled while charting
[#85](https://github.com/gsong/eyebreak/issues/85), floored by
[#28](https://github.com/gsong/eyebreak/issues/28), floor restated by
[#32](https://github.com/gsong/eyebreak/issues/32).

Walking away mid-break is resting. The absence counts toward the break, and it is
measured from `max(last input event, the moment the break went up)`:

- **Absence at least as long as the break's remainder** — the break is
  satisfied, and a fresh work interval starts on Return.
- **Shorter** — the overlay returns on Return for what is left.

**A break satisfied by an absence asks for no dismissal.** Require Dismissal
exists to keep hands off the keyboard for the length of the break. The user was
already away, so there is nothing left to enforce and nothing to acknowledge.

The overlay comes down when the absence begins and is rebuilt on Return if the
break survives. An overlay is only up while something behind it is live, so no
overlay rides through system sleep holding the keyboard with nothing counting.

Alongside this, an absence that begins during a **dismissal wait** is a
different question with a different answer — see
[ADR-0004](0004-a-dismissal-wait-survives-a-short-absence.md).

## The floor, and why it was missing

The floor is the same one
[ADR-0004](0004-a-dismissal-wait-survives-a-short-absence.md) puts on a dismissal
wait, for the same reason. The overlay holds the keyboard from the instant a
break goes up, so a user who sits still through it has a last-input event that
goes stale at exactly the rate the break runs. Without the floor,
[ADR-0001](0001-absence-is-time-since-the-last-input-event.md)'s last-input rule
reads back through the break itself.

Stated so that one phrase covers both floors, it is **the moment the current
stretch began** — here, when the overlay went up or was last rebuilt. It is
**not** "the moment the overlay took the keyboard", which names the right instant
for a running break and one a break length early for a dismissal wait. See "Which
instant the floor names" in ADR-0004. Restated in
[#32](https://github.com/gsong/eyebreak/issues/32).

The failure is concrete. A display sleep at minute one of a five-minute break
backdates to whenever the user last typed, which the keyboard hold guarantees is
at least a minute earlier and is usually far more. The absence then measures
longer than the four-minute remainder, "the break is satisfied" fires, and the
user gets a fresh work interval after one minute of rest. That is **less** rest
than the setting asked for, and this app errs the other way.

ADR-0004 shipped with its floor and this ADR did not. Nobody noticed, because the
two rules were written as answers to different questions — what an absence does
to a running break, and what it does to a finished one — and only the second was
read against the keyboard hold. Found while resolving
[#28](https://github.com/gsong/eyebreak/issues/28).

## What the floor makes true

Break time and absence time become one currency, so an absence is **transparent**
to a running break. The break simply keeps counting:

- The remainder shrinks by the wall time that passed, whether the overlay was up
  or the user was away.
- The break is satisfied when the remainder reaches zero, and the duration test
  needs no separate arithmetic.
- The backdated absence start is **never read while a break runs**.

That last point is worth stating on its own. `breakRunning` is the one state
where the read-back problem cannot bite, rather than the state where it bites
hardest.

## Nothing shipping today is affected

Today's `pause()` stores `remainingSeconds` and `resume()` restores it, so a
break simply freezes and the absence is credited with nothing at all. That is
neither this ADR nor its floor — the whole rule is unimplemented. The floor
changes no current behavior. It changes what
[#25](https://github.com/gsong/eyebreak/issues/25)'s reducer would have done had
it implemented this ADR as originally written.

## Why this is worth recording

It is the payoff for the accepted cost in
[ADR-0001](0001-absence-is-time-since-the-last-input-event.md). A display held
awake by an assertion records no absence, so breaks keep firing at an empty
chair. This rule is what makes that harmless: the break the user was not there
for is served by the absence itself.
