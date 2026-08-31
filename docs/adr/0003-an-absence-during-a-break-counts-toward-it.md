# An absence during a break counts toward the break

Status: accepted, not yet implemented. Settled while charting
[#85](https://github.com/gsong/eyebreak/issues/85).

Walking away mid-break is resting. The absence counts toward the break:

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

## Why this is worth recording

It is the payoff for the accepted cost in
[ADR-0001](0001-absence-is-time-since-the-last-input-event.md). A display held
awake by an assertion records no absence, so breaks keep firing at an empty
chair. This rule is what makes that harmless: the break the user was not there
for is served by the absence itself.
