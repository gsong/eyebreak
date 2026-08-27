# scripts/

Three scripts. Nothing here builds a DMG, publishes a release, or talks to
Homebrew — see [CLAUDE.md](../CLAUDE.md) for why.

Run every one of them from the project root.

## create-cert.sh

Creates the self-signed `EyeBreak Local Signing` certificate in your login
keychain. Run it **once**, before the first `dev-install.sh`.

```bash
./scripts/create-cert.sh
```

macOS ties Accessibility and Screen Recording grants to the code signature. An
ad-hoc signature changes on every build, so every rebuild would ask again. A
stable certificate keeps the grants.

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

## update_app_icon.sh

Regenerates every size in `AppIcon.appiconset` from one source image. Needs
`sips`, which ships with macOS.

```bash
./scripts/update_app_icon.sh path/to/icon.png
```

Use a square image, 1024×1024 or larger.
