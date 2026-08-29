# Testing EyeBreak

Four unit-test files cover the logic that runs without a screen. Everything else
is checked by hand against a running app. This is that walkthrough.

Run it before a release, and run the sections a change touches before merging
that change.

## Unit tests

```bash
xcodebuild test \
  -project EyeBreak.xcodeproj \
  -scheme EyeBreak \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  DEVELOPMENT_TEAM=""
```

The four signing flags are required. Without them this machine fails with
`No signing certificate "Mac Development" found`, because the project pins
`DEVELOPMENT_TEAM = SM4A6Z8B5H` and no matching identity exists here.

## Before you start

**A scratchpad build shares preferences with `/Applications`.** Both read
`com.eyebreak.app`. Changing a setting to reach a state changes it for the
installed app too, so note what you changed and put it back.

**A scratchpad build can never hold the Accessibility grant.** macOS pins the
grant to the code-signing hash, and a throwaway build has a new one. So a test
build gets no keyboard hold and no working ⌃⌥B. To see the granted-permission UI,
build a throwaway with `AXIsProcessTrusted()` forced true. To test the real
behaviour, install with `./scripts/dev-install.sh` and re-grant Accessibility.

**Quit the installed app first** if you are running a second copy. Two status
items and two timers is not a useful test.

## What a script can and cannot drive

Worth reading before you spend a session rediscovering it.

**Works:**

- `screencapture -R` for a region, and full-screen captures.
- `osascript` against System Events to read window titles, click buttons, and
  drive the Settings form.
- `defaults write com.eyebreak.app <key> <value>` to reach a state faster —
  within the clamps, see below.
- Opening the status-item menu and clicking its items.

**Does not work:**

- **Giving the app keyboard focus.** Five routes were tried — `activate`,
  `set frontmost`, `NSApp.activate` from a menu item, and synthetic clicks on
  both the title bar and the window body. All of them leave the app not
  frontmost while the window still reads as focused. macOS 14+ cooperative
  activation refuses an accessory app's request, and a synthetic click carries
  no activation.
- **Therefore neither ⌃⌥B monitor is script-reachable.** The local monitor needs
  focus; the global one needs a grant a scratchpad signature cannot hold. **Press
  the chords by hand.**
- **Getting under the setting clamps.** Work interval clamps on read to a floor
  of 15 minutes, so no `defaults write` can make a work interval shorter than
  that. Use **Take Break Now** to reach `.breaking` immediately — it covers every
  break-phase check. Only `tick()`'s work arm needs a real 15-minute wait.

**A locked screen looks exactly like a bug.** With the screen locked,
`screencapture -R` fails and System Events reports zero windows — which reads as
`openSettings()` being broken. Check the screen is awake before believing a
window is gone.

## 1. The status-item menu

- [ ] The eye icon is in the menu bar at launch, and the timer is already
      running — the countdown appears next to it
- [ ] Clicking it opens four commands split by two separators: Open Settings…,
      Stop Timer, Take Break Now ⌃⌥B, Quit EyeBreak
- [ ] Stop Timer stops it. Reopening the menu now reads **Start Timer**
- [ ] Start Timer starts it. Reopening reads Stop Timer again
- [ ] The countdown in the menu bar reads `M:SS` and does not shift width as it
      ticks
- [ ] Hovering the icon shows a tooltip in the same `M:SS` format — not raw
      seconds
- [ ] The icon changes during a break
- [ ] Open Settings… brings the window forward, whether it was closed or just
      behind something

## 2. The Settings window

One scrolling form. No sidebar, no tabs.

- [ ] A one-row timer strip sits above the form: a dot, the state, and buttons
- [ ] The strip reads Start when idle, and Stop plus Break Now when running
- [ ] The strip's countdown reads `M:SS`
- [ ] The **Timer** section holds Work Interval, Break Duration, "Wait for me to
      dismiss the break", Launch at Login, Enable Sound Effects, and Idle
      Detection
- [ ] Each slider is one row: icon, title, track, value
- [ ] Work Interval runs 15 to 45 in steps of 5 — it cannot reach 10 or 50
- [ ] Break Duration runs 1 to 10 **minutes** in whole-minute steps
- [ ] Turning Idle Detection off hides the Idle Threshold slider; turning it on
      brings it back
- [ ] Idle Threshold runs 1 to 15 minutes
- [ ] The section footer names ⎋ and ⌃⌥⌘⎋ when Accessibility is granted, and
      names the missing permission when it is not
- [ ] The tail section shows the permission row, Reset to Defaults in red, and
      `Version <n>` with a GitHub link
- [ ] Reset to Defaults writes 25 minutes, 5 minutes, dismissal on, sound on,
      idle on, 5-minute threshold — and **leaves Launch at Login alone**
- [ ] Every setting survives quitting and relaunching the app
- [ ] With the grant missing, the permission row shows a warning and an **Open
      Accessibility Settings** button that opens the right pane
- [ ] With the grant held, the row reads "Keyboard Shortcuts — Enabled"

## 3. The break overlay

Reach it with **Take Break Now**.

- [ ] Every display is covered, at once
- [ ] Each shows the same countdown, counting the same number
- [ ] The overlay is a flat veil over the desktop — system colours, an eye-slash
      icon, "Time for a Break", one instruction line, a ring, and one
      "Skip Break" button
- [ ] The ring's countdown reads `M:SS` — a five-minute break opens on `5:00`,
      not `287` or `300`
- [ ] It reads correctly in both light and dark appearance
- [ ] A click on the overlay away from the button does **not** end the break
- [ ] The button ends the break, in one click
- [ ] ⎋ ends the break early
- [ ] Attaching or detaching a display mid-break covers or uncovers it without
      restarting the countdown
- [ ] When the break ends, focus goes back to the app you were using

### The keyboard hold

Needs a real install with the Accessibility grant. Press these by hand.

- [ ] During a break, ⌘Tab, ⌘Q and ⌘H do nothing
- [ ] ⌃⌥B does nothing during a break
- [ ] ⎋ ends the break even when another app was frontmost
- [ ] ⌃⌥⌘⎋ releases the keyboard and ends the break
- [ ] ⌘⌥⎋ opens Force Quit, behind the overlay
- [ ] Left alone, the keyboard comes back on its own after the break length,
      plus two minutes if it is waiting for dismissal, plus ten seconds

### Waiting for dismissal

With **Wait for me to dismiss the break** on, which is the default.

- [ ] The overlay stays up when the countdown reaches zero, on every display
- [ ] It shows a checkmark, "Break Complete", and one "Back to Work" button
- [ ] The countdown is gone — nothing is counting
- [ ] ⎋, the button, and ⌃⌥⌘⎋ each dismiss it
- [ ] The next work interval is a full one, however long the wait was
- [ ] The menu bar drops the countdown
- [ ] Sleeping the Mac and waking it leaves the overlay waiting
- [ ] Locking the screen and unlocking it leaves the overlay waiting
- [ ] Going idle past the threshold leaves the overlay waiting
- [ ] Attaching or detaching a display during the wait keeps the completion state
- [ ] Turning the setting off makes breaks end themselves again

## 4. Idle detection

- [ ] With Idle Detection on, leaving the Mac past the threshold pauses the
      timer
- [ ] The status item reflects the pause
- [ ] Activity resumes it, with the remaining time intact
- [ ] Turning the toggle off stops it pausing at all

## 5. Edge cases

- [ ] Launching the app starts the timer with no click
- [ ] The app does not appear in the Dock or the ⌘Tab switcher
- [ ] Sleeping and waking the Mac leaves a running timer running
- [ ] Rapid Start / Stop from the menu does not leave the state stuck
- [ ] Idle CPU stays near zero with the Settings window closed
- [ ] The overlay costs a few percent of CPU during a break, not tens
- [ ] `defaults read com.eyebreak.app` shows only keys the app still reads
      (run `./scripts/prune-prefs.sh --dry-run` to check)

## Known limitations

1. **Accessibility resets on every install.** The signature changes, so macOS
   treats each build as a new program. Re-grant after `dev-install.sh`.
2. **Force Quit opens behind the overlay.** ⌘⌥⎋ is passed through, but the keys
   that would drive the panel are consumed, so it is usable only once the break
   has ended. ⌃⌥⌘⎋ and the watchdog are the outs that work.
3. **Multiple Spaces.** The overlay may not cover every Space at once.
4. **Full-screen apps.** The overlay may not cover a full-screen app on every
   configuration — a macOS window-level limitation.
