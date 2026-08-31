# Only a presence event ends an absence, and an absence is one span

Status: accepted, not yet implemented. Decided in
[#95](https://github.com/gsong/eyebreak/issues/95), verified by
[#96](https://github.com/gsong/eyebreak/issues/96).

**A wake is a power event. Only a presence event ends an absence.** Return is
the **later** of two moments: when the last outstanding cause clears, and the
first presence event after the absence began. A presence event is an unlock
(`com.apple.screenIsUnlocked`), a screensaver stop
(`com.apple.screensaver.didstop`), or a real user input event the app observes.

**An absence is one span.** `Away` is one state. The set of outstanding causes
lives inside it as bookkeeping, not as its definition, so the set may empty and
refill without ending the absence. A dark wake followed by a re-sleep is one
absence, not two. The idle counter is read **once**, at the first cause arrival
of the absence; later arrivals within the same absence read nothing.

## Why a wake cannot be trusted

[#93](https://github.com/gsong/eyebreak/issues/93) traced a Mac waking at
19:59:40 with nobody in the room, and George returning at 20:23:00. Both posted
`screensDidWake` and `didWake`; only the second posted `screenIsUnlocked`. An
empty room produces power events.

The class is worse than "maintenance dark wake", so do not call it that.
[#96](https://github.com/gsong/eyebreak/issues/96) recorded `pmset -g log`
reporting `DarkWake to FullWake ... due to HID Activity` at 02:59:40 — macOS woke
fully and claimed human input, while the global monitor stayed silent and
`hidSystemState` held a true 53m28s silence. A Return keyed to a wake, **or to
the OS's own stated wake reason**, resumes at 3 AM.

## Why "later of", and not "after"

A presence event strictly _after_ every cause has cleared strands a real return.
George presses a key to wake the Mac, the key lands before `screensDidWake`, and
the app then waits for a second event that may not come for minutes.

If any presence event counts, the keystroke that triggered a manual lock is
banked before the absence starts, and the next dark wake ends the absence — the
original bug, restored.

"Later of" closes that hole by construction. An absence starts at the last input
event ([ADR-0001](0001-absence-is-time-since-the-last-input-event.md)), so no
input exists between the start and Return. A wake keystroke lands after the
start and is banked; the cause clears milliseconds later; Return fires there.

## Why the idle counter is read once

`CGEventSourceSecondsSinceLastEventType` **does not survive a wake.** #96
measured 17 counter resets across 9h15m with nobody at the machine, and every
one landed 4–76 s after a system wake — none anywhere else. The counter reads
small after a wake whether or not anyone touched anything. Reading it at a later
cause arrival, or at Return, would import a post-wake value every time. #93's
unexplained resets have the same cause: one read at 19:43 gave 0.342 s in an
empty room, and a re-read would have moved that absence's start forward by
twenty minutes.

**No event source rescues the counter.** Do not write "read `.hidSystemState`
instead of `.combinedSessionState` to avoid synthetic events." It does not avoid
them. A `privateState` post from a separate process reset both counters to the
same value, `.hidSystemState` reset in 16 of the 17 unattended resets, and in one
cross-process trial the two read 15.409 and 22.082 _before_ the post — so
neither is a subset of the other and neither is the narrower. The narrowing comes
from the `NSEvent` global monitor or from nowhere. #96 measured that monitor
firing **zero** times in 9h15m unattended, with its own positive control proving
it was observing, so it is a sound presence signal and the counter is not.

## Considered and rejected

**`screenIsUnlocked` as the only return signal.** It separates the cases cleanly
only where lock is immediate. A Mac set never to require a password has display
sleeps with no unlock to follow, and display sleep is a cause in its own right.
Those absences would never end.

**Input only** — absence runs from the last input event to the next one. It
over-credits: lock the screen, leave for two minutes, unlock, then sit reading
for twenty without touching anything, and it measures a 22-minute absence. The
unlock _was_ presence, and this throws it away.

**Filtering dark wakes** — keep "last cause clears" and detect the dark wake
specifically. The most fragile of the four. It needs the app to classify a wake
reason Apple does not document, and #96 then showed the OS labelling the very
event in question as `HID Activity`. Every new wake reason would be a new bug.

**Splitting `Away` into two states** — causes outstanding, then causes clear but
nobody back. The second phase is real and ran 23 minutes in #93's trace. But no
resume path reads the cause set; they key on the interrupted state and the
duration. A second state would carry no distinct behavior and would double the
absence rows in the scenario table.

**Polling the idle counter through the absent window** and reading a drop as
input. That is exactly the signal measured resetting in an empty room.

## Accepted costs

- **`Away` stops meaning "a cause is outstanding".** The cause set can empty
  while the user is still gone. Anyone reading the model who assumes otherwise
  will write the wrong rule.
- **Without the Accessibility grant the app sees mouse input only.** A global
  `NSEvent` monitor gets mouse movement, clicks, and scrolls with no permission;
  key events need the grant. So the gap needs a Mac that never requires a
  password, **plus** a missing grant, **plus** a user who returns by keyboard and
  never touches the mouse. On a Mac that locks, the unlock covers it. Making
  Accessibility load-bearing for the absence rule was rejected: today a missing
  grant means a degraded break, and that must not become a broken timer.
