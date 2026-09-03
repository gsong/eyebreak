# Snooze exists, and it is capped by a time budget

Status: accepted, not yet implemented. Settled while charting
[#85](https://github.com/gsong/eyebreak/issues/85), extended by
[#89](https://github.com/gsong/eyebreak/issues/89), amended by
[#108](https://github.com/gsong/eyebreak/issues/108).

Snooze is distinct from Skip: the break returns after the snooze length instead
of being forfeited. It is offered twice — on the break warning before the break
goes up, and on the overlay once it has, where taking it brings the overlay down.

- **Length** is its own setting: default 3 minutes, range 1–5.
- **Budget** is half the work interval. The number of snoozes is therefore
  `floor((work / 2) / snoozeLength)` — 4 at the 25/3 default.
- **No count ceiling.** Half the interval is the protection. Four deferrals of
  3 minutes is the same screen time as two of 6. That count holds when every
  deferral runs to its end; a deferral an absence cuts short spends only what
  elapsed, so more of them fit — see
  [ADR-0008](0008-any-absence-discharges-a-deferral.md).
- **No partial snooze.** Once the next full snooze would exceed the budget,
  Snooze is shown **disabled** and the leftover budget is forfeited. Shown rather
  than hidden, so the cap is legible.
- **Frozen when the break is first offered.** Budget and length are read once,
  when the break warning goes up, and hold for that break's whole deferral. A
  work interval dropped from 45 to 15 mid-deferral cannot retroactively put the
  user over a budget they were under a moment ago. This used to say "frozen at
  break time... read once, when the break goes up", which
  [ADR-0012](0012-a-break-announces-itself-before-it-takes-the-keyboard.md) left
  without a referent: a break deferred from its warning never puts an overlay up,
  so that moment may never arrive. The break warning is the earliest moment
  Snooze is offered, so it is where the budget freezes.
- **Only on a timer-raised break.** A break started by Take Break Now offers
  Skip only, and gets no break warning at all. You asked for it; deferring it a
  moment later is incoherent.

**Two surfaces offer Snooze, both at the fixed length.** On the overlay it is one
key plus a button, and keys are ignored until the overlay has been up about one
second, because the overlay arrives mid-typing. On the break warning it is the
`⌃⌥S` chord plus a button, and **no guard applies** — a chord cannot be typed by
accident, and a click needs a pointer already on the button. This used to name
the overlay alone; see
[ADR-0012](0012-a-break-announces-itself-before-it-takes-the-keyboard.md). The
break warning offers **no Skip**, because Skip is capped by nothing.

## One invariant, stated and not built

A single snooze can never exceed the budget. The 1–5 minute range guarantees it:
5 minutes is under the 7.5 minute budget of even the shortest 15 minute work
interval, so at least one snooze always fits at every setting. **Write no dynamic
clamp** — nothing can violate this. This paragraph is here for whoever later
widens one of those ranges.

## Considered and rejected

**Digits 1–9 choosing a snooze length on the overlay.** Stray keystrokes, a
collision with the cap, and it undoes the limit the budget exists to impose.
