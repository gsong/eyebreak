# 👁️ EyeBreak

A macOS menu bar app that runs a 25/5 work-and-break timer. Every 25 minutes it
covers every display with a break overlay and holds the break there until you
dismiss it.

This repository is a personal project. It ships to nobody: no DMG, no Homebrew
cask, no release asset, and no update check. A release is a tag, a
`CHANGELOG.md` section, and a locally installed build. See
[CLAUDE.md](CLAUDE.md) for the reasoning.

## What the app does

The timer starts on launch and runs one loop: work, break, wait for dismissal,
work. There is no other mode.

- **Work interval** — 15 to 45 minutes, in 5-minute stops. Default 25.
- **Break** — 1 to 10 minutes. Default 5. The overlay covers every display and
  holds the keyboard for the length of the break.
- **Wait for dismissal** — on by default. The countdown reaches zero, the
  overlay stays up, and the next work interval starts when you dismiss it.
- **Idle detection** — on by default. The timer pauses after 1 to 15 minutes
  with no input, and resumes on activity.

Six settings, one window. Nothing is tracked, stored, or sent anywhere.

## Requirements

- macOS 26.0 (Tahoe) or later
- Xcode 26 or later
- Swift 5.9 or later
- [mise](https://mise.jdx.dev) — pins SwiftLint and prettier to the versions CI
  uses

## Build and install

```bash
mise install          # once, to get SwiftLint
./scripts/create-cert.sh   # once, before the first install
./scripts/dev-install.sh
```

`dev-install.sh` builds Release, stamps a version derived from the current git
tag, signs with the local certificate, and replaces `/Applications/EyeBreak.app`.
See [scripts/README.md](scripts/README.md) for what each script does.

To work in Xcode instead:

```bash
open EyeBreak.xcodeproj   # ⌘R to run, ⌘U to test
```

## Test and lint

```bash
xcodebuild test \
  -project EyeBreak.xcodeproj \
  -scheme EyeBreak \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  DEVELOPMENT_TEAM=""

swiftlint lint --strict
```

The four signing flags are not optional here. The project pins
`DEVELOPMENT_TEAM = SM4A6Z8B5H`, and a machine with no matching identity fails a
bare `xcodebuild test` with `No signing certificate "Mac Development" found`.
These are the flags CI uses; see `.github/workflows/ci.yml`.

CI runs both on every push and pull request.

## macOS permissions

EyeBreak asks for one grant: **Accessibility**.

It buys two things — the ⌃⌥B shortcut, and the keyboard hold that makes a break
a break. Without it the app still runs and breaks still cover every display, but
shortcuts in other apps keep working during a break and ⌃⌥B does nothing.

**The grant survives updates, as long as you installed with the scripts.** macOS
binds it to the app's designated requirement, and `create-cert.sh` gives EyeBreak
a stable certificate that `dev-install.sh` re-signs with every time, so the
requirement does not change. Grant it once.

Two things still revoke it: recreating the certificate, and clearing the grant by
hand. A throwaway `xcodebuild` build can never hold it at all — that one is
signed ad-hoc, so its requirement is pinned to a hash that changes every build.
Whenever the grant is missing, the Settings window shows a warning row with a
button to **System Settings** > **Privacy & Security** > **Accessibility**.

## Keyboard shortcuts

One global shortcut:

| Shortcut | Action         |
| -------- | -------------- |
| ⌃⌥B      | Take break now |

Settings opens by clicking the menu bar icon. The status-item menu shows ⌃⌥B
next to Take Break Now, but a status-item menu's key equivalents never dispatch
— the working chord is an `NSEvent` monitor in `EyeBreakApp.swift`.

During a break the keyboard is held, so shortcuts in other apps — and EyeBreak's
own — stay quiet. Three keys still get through:

| Shortcut | Action                                                         |
| -------- | -------------------------------------------------------------- |
| ⎋        | End the break early, or dismiss a break that is waiting        |
| ⌃⌥⌘⎋     | Release the keyboard and end the break, if anything goes wrong |
| ⌘⌥⎋      | Force Quit — passed through, but opens behind the overlay      |

A watchdog releases the keyboard on its own after the break length, plus two
minutes if the break is waiting for dismissal, plus ten seconds. It reads no
break state, so it fires even when something else has gone wrong.

## Layout

```
EyeBreak/
├── EyeBreakApp.swift    # App entry, the ⌃⌥B monitors, the Settings window scene
├── Models/              # TimerState, AppSettings, BreakCountdown, TimeFormat
├── Managers/            # Timer, overlay, keyboard tap, idle, sound, status item
├── Views/               # Settings form, break overlay
└── Resources/           # Assets.xcassets
EyeBreakTests/           # Unit tests: timer state, countdown, input policy, settings
scripts/                 # create-cert, dev-install, prune-prefs, update_app_icon
docs/                    # Architecture, testing, agent conventions
```

MVVM with SwiftUI and Combine. See
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Troubleshooting

**⌃⌥B does nothing, or breaks stop holding the keyboard** — re-grant
Accessibility. This should be rare; check whether the signing certificate was
recreated.

**A break is on screen and something is wrong** — press ⌃⌥⌘⎋. It releases the
keyboard and ends the break, and it works inside the tap's own callback, so it
does not depend on the rest of the app being healthy.

**Timer not pausing when idle** — enable Idle Detection in Settings and check
the threshold (default 5 minutes).

**`defaults read com.eyebreak.app` shows keys the app does not use** — run
`./scripts/prune-prefs.sh`. 3.0.0 orphaned 38 keys.

## License

MIT. See [LICENSE](LICENSE).

Forked from [cheat2001/eyebreak](https://github.com/cheat2001/eyebreak), which
wrote most of the Swift here. Inspired by [LookAway](https://lookaway.app).
Icons from [SF Symbols](https://developer.apple.com/sf-symbols/).
