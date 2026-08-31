# No user-facing pause

Status: accepted. Decided in
[#86](https://github.com/gsong/eyebreak/issues/86).

The app has no Pause. The status-item menu stays at four items: Open Settings…,
Start/Stop, Take Break Now, Quit. `.paused` stays in `TimerState` but stays
system-only — no user action reaches it. It is an implementation name for the
away state, and the state machine work in
[#25](https://github.com/gsong/eyebreak/issues/25) may rename it.

## Why

**Pause and Stop collapse into each other.** Under
[ADR-0001](0001-absence-is-time-since-the-last-input-event.md), an absence at
least as long as the break starts a fresh work interval on Return. So pausing
for anything long enough to be worth pausing for, then resuming, produces exactly
what Stop-then-Start produces. Pause would be a second name for Stop with a
different amount of typing.

**Absence is detected, not declared.** Every cause in this model is the machine
reporting a fact about the screen: it slept, it locked, the system slept. A
user-declared absence is a second source of truth sitting beside those signals,
and the two can disagree — you declare yourself away while the screen stays lit
and the OS says otherwise. One source of truth is worth more than the
convenience.

**Stop already carries the habit.** Asked what he does today when an overlay
would be unwelcome, George answered: Stop, then Start after. It works. The cost
is an occasionally forgotten Start, and the fix for that is the menu bar saying
"stopped" unmistakably — not a fifth menu item.

## The one case Pause might have served

A meeting or call at the desk, screen awake, is the situation no detected cause
covers. It is **deliberately deferred**, not solved here. George drives it
manually with Stop. A manual meeting hold is a later effort of its own; do not
reopen it as a missing pause.
