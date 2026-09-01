# One sound, at a break's natural end, absence included

Status: accepted, not yet implemented. Decided in
[#28](https://github.com/gsong/eyebreak/issues/28).

The app makes **one** sound: a break reaching its natural end. `.start`,
`.breakStart` and `.skip` go, and Snooze never gets one.

The natural end is the moment a break that **actually went up** runs out of its
length. It arrives whether the user is at the screen or away, so the sound plays
through display sleep, screen lock and the screensaver — the cases where it is
worth the most, because nobody is looking at the overlay that is no longer there.

Silent, then:

- **Skip, Snooze and Stop.** None is a natural end.
- **An absence that fulfils a break which never went up** — from a work interval
  ([ADR-0001](0001-absence-is-time-since-the-last-input-event.md)) or from a
  deferral ([ADR-0008](0008-any-absence-discharges-a-deferral.md)). There is no
  break whose end to announce, and a chime five minutes into a walk away from the
  desk explains nothing.
- **A dismissal wait, however it ends.** The break already chimed when it was
  served.

`soundEnabled` still gates it, and the check belongs to whatever performs the
sound rather than to the rule. Sound is presentation, and putting the setting in
the rule doubles every row of the transition table that makes a noise.

## The sound must not arrive late

No code runs while the Mac itself is asleep. A break whose natural end falls
inside a system sleep produces no sound, and it must not produce one on wake
either: the moment has passed and a chime minutes later is worse than silence.

**The guard is on time alone.** The sound fires only if the moment it is noticed
is within a few tick periods of the natural end. Past that window the sound is
marked spent and nothing plays.

Keying on the `systemSleep` cause instead was rejected twice over. It would be the
first rule in the model that asks _which_ cause fired, which is the thing
[ADR-0001](0001-absence-is-time-since-the-last-input-event.md) exists to prevent.
And [ADR-0002](0002-only-a-presence-event-ends-an-absence.md) makes the cause set
explicitly transient — it may empty and refill inside one absence — so the set
cannot be trusted to still name the sleep by the time anything reads it.

A window on time also covers every other reason the clock stopped, not just
system sleep. A menu-bar app under App Nap can have its timer coalesced, and a
stalled main thread does the same thing. The window has to be wide enough to
survive that coalescing and far narrower than any system sleep.

## The scenario table's headline finding needs a footnote

[#92](https://github.com/gsong/eyebreak/issues/92)'s table states that **no
deadline ever fires while the user is away**, and a reader will treat that as a
guarantee that nothing at all happens during an absence.

The guarantee holds where it was meant to: no state moves. But one effect now
leaves during an absence, and anyone reasoning from the stronger reading will get
this rule wrong.

## Considered and rejected

**Keeping the four sounds.** The start and break-start chimes announce something
already on screen — a status item that just changed, or an overlay covering every
display. The skip chime confirms an act the user just took deliberately. None
carries information the eyes do not already have.

**A snooze sound.** Skip had one, so symmetry argues for it. But the overlay
vanishing is the confirmation, and a chime on the action a user takes precisely to
be left alone is the wrong instinct.

## Accepted cost

**A break served during a system sleep is silent, and stays silent.** Closing the
lid mid-break means the sound is lost, not deferred. The alternative is a chime
that fires on wake with no relationship to the moment it names.
