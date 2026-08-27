# 👁️ EyeBreak

A macOS menu bar app that reduces digital eye strain by enforcing the 20-20-20 rule:
every 20 minutes, look 20 feet away for 20 seconds.

This repository is a personal project. It ships to nobody: no DMG, no Homebrew
cask, no release asset. A release is a tag, a `CHANGELOG.md` section, and a
locally installed build. See [CLAUDE.md](CLAUDE.md) for the reasoning.

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later
- Swift 5.9 or later
- [mise](https://mise.jdx.dev) — pins SwiftLint to the version CI uses

## Build and install

```bash
mise install          # once, to get SwiftLint
./scripts/dev-install.sh
```

`dev-install.sh` builds Release, stamps a version derived from the current git
tag, signs with a local certificate, and replaces `/Applications/EyeBreak.app`.

To work in Xcode instead:

```bash
open EyeBreak.xcodeproj   # ⌘R to run, ⌘U to test
```

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for the longer form.

## Test and lint

```bash
xcodebuild test -project EyeBreak.xcodeproj -scheme EyeBreak -destination 'platform=macOS'
swiftlint lint --strict
```

CI runs both on every push and pull request.

## macOS permissions

EyeBreak asks for three grants. Only the first is required for the default
break style.

### Screen Recording — required for Blur Screen and Eye Exercise

1. **System Settings** > **Privacy & Security** > **Screen Recording**
2. Enable **EyeBreak**
3. Restart the app

The permission draws a blur overlay. Nothing is recorded or saved. Without it
the app falls back to Notification Only mode.

### Accessibility — required to hold the keyboard during a break

Blur Screen and Eye Exercise cover every display and hold the keyboard for the
length of the break. macOS revokes this grant on every EyeBreak update, so if
breaks stop holding the keyboard after `dev-install.sh`, re-enable EyeBreak
under **Privacy & Security** > **Accessibility**. Breaks still cover every
display and still end on **⎋** either way.

### Notifications — recommended

Requested on first launch. Needed for pre-break warnings and for Notification
Only mode.

## Keyboard shortcuts

| Shortcut | Action                |
| -------- | --------------------- |
| ⌘⇧S      | Start timer           |
| ⌘⇧X      | Stop timer            |
| ⌘⇧B      | Take break now        |
| ⌘⇧R      | Show ambient reminder |
| ⌘⇧W      | Show water reminder   |

The last three override Smart Schedule.

During a break the keyboard is held, so shortcuts in other apps — and
EyeBreak's own — stay quiet. Three keys still get through:

| Shortcut | Action                                                         |
| -------- | -------------------------------------------------------------- |
| ⎋        | End the break early                                            |
| ⌃⌥⌘⎋     | Release the keyboard and end the break, if anything goes wrong |
| ⌘⌥⎋      | Force Quit — passed through, but opens behind the overlay      |

## Layout

```
EyeBreak/
├── EyeBreakApp.swift    # App entry point
├── Models/              # TimerState, Settings
├── Managers/            # Timer, idle detection, notifications, screen blur
├── Views/               # SwiftUI: menu bar, settings, break overlay, stats
└── Resources/           # Assets.xcassets
EyeBreakTests/           # Unit tests
scripts/                 # dev-install.sh, create-cert.sh, update_app_icon.sh
docs/                    # Architecture, development, testing
```

MVVM with SwiftUI and Combine. See
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Troubleshooting

**Blur not working** — grant Screen Recording, then restart the app.

**Breaks stop holding the keyboard** — re-grant Accessibility. macOS drops it
on every update.

**Notifications missing** — check **System Settings** > **Notifications** >
**EyeBreak**.

**Timer not pausing when idle** — enable Idle Detection in Settings and check
the threshold (default 5 minutes).

## License

MIT. See [LICENSE](LICENSE).

Forked from [cheat2001/eyebreak](https://github.com/cheat2001/eyebreak), which
wrote most of the Swift here. Inspired by [LookAway](https://lookaway.app).
Icons from [SF Symbols](https://developer.apple.com/sf-symbols/).
