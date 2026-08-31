# A deferral is not rest, and any absence discharges it

Status: accepted, not yet implemented. Decided in
[#89](https://github.com/gsong/eyebreak/issues/89).

A snooze is a remembered deferral. It is not rest and it is not a fresh work
interval, so the status text reads "Break in N:NN".

**Any absence discharges the deferral.** On Return:

- **Absence at least as long as the break** — the break is satisfied, a fresh
  work interval starts, and no dismissal is asked for.
- **Shorter** — the deferral is over and the break runs on Return.

The deferred break runs its **full** length when it arrives. A snooze defers a
break; it does not shorten one.

**Take Break Now** during a deferral serves the deferred break at once — the same
break pulled forward, with Skip only on its overlay. That makes Take Break Now
the decisive way out of a deferral rather than a re-entry into it. **Stop**
forgets the deferral with everything else, and **Skip** starts a full fresh work
interval. The budget resets whenever the break ends, however it ends.

## Why this carves out of the absence rule

[ADR-0001](0001-absence-is-time-since-the-last-input-event.md) says a short
absence rewinds the work interval to the last input event. **A deferral does not
rewind. It discharges.** That is deliberate.

The reason to defer — finishing something on screen — ended when the user left,
so there is nothing left to defer to. Rewinding would also be absurd on its own
terms: the Snooze press is itself input, so a rewind would restart the full
snooze length after any interruption.
