# A break announces itself before it takes the keyboard

Status: accepted, not yet implemented. Decided in
[#108](https://github.com/gsong/eyebreak/issues/108), which
[#32](https://github.com/gsong/eyebreak/issues/32) raised and then handed off
because it changes the state machine's rows.

**A timer-raised break does not wait for the user to stop typing.** It gives
warning instead. The last **15 seconds** of a work interval, and of a deferral,
are a **break warning**: a banner near the menu bar showing the time left and
offering Snooze.

**The 15 seconds come out of that stretch, not on top of it.** At 25 minutes the
warning appears at 24:45 and the break still goes up at 25:00. No screen time is
added, so the rule costs the eyes nothing and needs no delay budget.

## Why not wait for a lull

The proposal this replaces was to hold the break until the user had not typed for
about five seconds. It was aimed at the wrong injury.

**The injury is the broken thought, not the eaten keystroke.** `BreakInputTap`
consumes the rest of the word when the overlay lands, which is cosmetic; the
sentence you lose is not. A lull rule fixes only the first.

**A lull cannot fix the second, and plausibly worsens it.** A five-second gap in
typing is very often composition in progress — the pause where the next clause is
being formed. Interrupting there is worse than interrupting after a finished
word. The rule would aim at the exact moment it should avoid.

**A lull has no length.** A held key, a game, or an autoclicker starves the break
indefinitely, so the rule needs a cap, and the cap needs a number nothing
justifies. A warning is fixed-length by construction and starves nothing.

**A lull needs an input signal the app deliberately does not have.**
[ADR-0002](0002-only-a-presence-event-ends-an-absence.md) confined the `NSEvent`
global monitor to the length of an absence, and
[#30](https://github.com/gsong/eyebreak/issues/30) settled that on the grounds
that a global input monitor is scarce and permission-visible. The alternative
signal, `CGEventSourceSecondsSinceLastEventType`, is the counter
[#96](https://github.com/gsong/eyebreak/issues/96) measured resetting 17 times in
9h15m in an empty room. Reopening either was out of proportion to a minor
irritant. **This decision reads no input during a work interval**, so #30 stands
untouched.

## Why a banner and not something cheaper

**A free warning is no warning.** `StatusBarController` already prints the
countdown for the whole work interval, and it does not reach a user who is
typing. Tinting that countdown for the last 15 seconds costs nothing and would
change nothing, for the same reason.

**A fading veil is the wrong medium.** Bringing the overlay up gradually is
unmissable, but the user is trying to *read* the sentence they are finishing, and
a dimming screen makes that harder. The warning must be visible without covering
the work.

**Snooze needs a surface.** Fifteen seconds is rarely enough to finish a thought;
three minutes usually is. Putting Snooze on the warning means the overlay never
goes up and the keyboard is never taken — a better answer to the complaint than
any amount of waiting. A menu item would work, but it needs the user to notice a
tint and then open a menu, which does not fit a 15-second window.

**The chord is the point.** Snooze fires from the banner's button or from
`⌃⌥S`, a new global chord beside the existing `⌃⌥B` for Take Break Now. Reaching
for a mouse is itself the interruption the rule exists to avoid.

## What the model gains, and what it does not

**No sixth state value.** `Working | snooze` goes straight to `deferral`, which
already exists and already builds a `PendingBreak`. The warning is a stretch
inside `working` and `deferral`, derived from the entry instant, not a state of
its own.

**Two effects**, `showWarning` and `hideWarning`, taking
[#104](https://github.com/gsong/eyebreak/issues/104)'s list from five to seven.
The banner's *contents* come from `Display`, its *existence* from effects —
the same split #104 made for the overlay. Both `tick` rows that emit
`showWarning` fire on all fifteen ticks and rely on #104's rule that every
collaborator absorbs a repeat.

**`ctx.pendingBreak` is built at the first warning**, not when the overlay goes
up, so `pendingBreak != nil` means "a break has been offered and not yet
finished". This is what freezes the snooze budget at a moment that always
arrives — see the amendment in
[ADR-0007](0007-snooze-is-capped-by-a-time-budget.md).

**No new input guard.**
[ADR-0007](0007-snooze-is-capped-by-a-time-budget.md)'s one-second guard is
untouched: it defends the overlay, which still lands under the user's hands with
the keyboard taken instantly. The banner needs no equivalent, because a chord
cannot be typed by accident and a click needs a pointer already on the button.

## Two precedents that do not bind

**Smart schedule was cut for disuse.**
[#49](https://github.com/gsong/eyebreak/issues/49) records its reason as "Never
enabled". That is not a judgment that delaying a break is wrong.

**The pre-break warning was never seen.**
[#67](https://github.com/gsong/eyebreak/issues/67) cut it alongside
`NotificationManager`, and [#50](https://github.com/gsong/eyebreak/issues/50)
had already proved that manager inert: onboarding held the app's only
`requestAuthorization()` call, on an unreachable path. The `.preBreak` state
posted a banner that could never deliver. So this is not a reversal — it is the
first time the app has warned anyone.

## Considered and rejected

**Skip on the warning.** Skip forfeits a break with no budget and no cap, so a
pre-break Skip would let breaks be declined indefinitely. Snooze is capped by
half the work interval; Skip is capped by nothing. The warning offers Snooze
only, shown disabled when the budget is spent, exactly as the overlay does.

**A warning before a break the user raised.** Take Break Now means the user just
reached the menu item or pressed `⌃⌥B`. Warning them is noise.

**A warning on an overlay rebuilt on Return.** Return is itself the input, so the
user is not mid-sentence.

**Ten seconds.** It was the first number proposed, before Snooze rode on the
banner. Snooze adds a reaction budget on top of the time to finish a sentence.

**Twenty seconds.** Long enough that the banner becomes furniture — which is how
the menu bar countdown already fails.

## Accepted costs

- **A user who ignores the banner is exactly as badly off as before.** The
  overlay still lands mid-word and still eats the rest of it. That was accepted
  when the injury was named as the broken thought rather than the lost text.
- **A one-minute snooze gets a warning covering a quarter of it.** Snooze length
  ranges 1–5 minutes, so at the floor the fixed 15-second lead is 25% of the
  deferral; at the 3-minute default it is 8%. **Write no dynamic lead.** This
  paragraph is here for whoever narrows that range.
- **The banner has no automated test**, inheriting #104's accepted cost: the
  `perform` switch and the collaborators it calls are hand-run checklist items
  for [#33](https://github.com/gsong/eyebreak/issues/33).
