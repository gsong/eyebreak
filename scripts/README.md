# scripts/

Four scripts. Nothing here builds a DMG, publishes a release, or talks to
Homebrew — see [CLAUDE.md](../CLAUDE.md) for why.

Run every one of them from the project root.

## create-cert.sh

Creates the self-signed `EyeBreak Local Signing` certificate in your login
keychain. Run it **once**, before the first `dev-install.sh`.

```bash
./scripts/create-cert.sh
```

macOS ties the Accessibility grant to the code signature. An ad-hoc signature
changes on every build, so every rebuild would ask again. A stable certificate
keeps the grant.

## dev-install.sh

Builds EyeBreak and installs it to `/Applications` as your daily app. This is
the only way EyeBreak gets installed.

```bash
./scripts/dev-install.sh            # Release
./scripts/dev-install.sh Debug      # Debug
```

It quits the running instance, stamps the version from the nearest git tag,
re-signs with the local certificate, replaces `/Applications/EyeBreak.app`, and
reopens it. A reachable tag is required, so `git fetch origin --tags` first if
`git describe` finds nothing.

## prune-prefs.sh

Deletes the 38 preference keys 3.0.0 orphaned. Run it **once**, by hand, after
the first `dev-install.sh` of 3.0.0.

```bash
./scripts/prune-prefs.sh --dry-run   # list what it would delete
./scripts/prune-prefs.sh             # delete it
```

The feature cut left 32 settings with no code that reads them, and the Sparkle
removal before it left four more; the last two are the Settings window's saved
frame and its sidebar divider. Most were never written to disk, because
`@AppStorage` writes a key when the setting is set, not when it is read - the
script names all 38 anyway, so it records what 3.0.0 removed rather than what
one Mac happens to hold.

It quits EyeBreak and leaves it quit. AppKit writes the window frame back on
quit, so a running app would restore one of the keys.

## update_app_icon.sh

Regenerates every size in `AppIcon.appiconset` from one source image. Needs
`sips`, which ships with macOS.

```bash
./scripts/update_app_icon.sh path/to/icon.png
```

Use a square image, 1024×1024 or larger.
