---
name: release
description: Cut an EyeBreak release — tag, CHANGELOG section, GitHub Release with no assets, and a locally installed build. Use when George wants to release, cut a version, ship a build, tag a version, or publish a release.
---

# Release

A release is four things: a git tag, a `CHANGELOG.md` section, a GitHub Release
with **no assets**, and `/Applications/EyeBreak.app` rebuilt from that tag.

There is no DMG, no appcast, and no Homebrew cask. See
[CLAUDE.md](../../../CLAUDE.md).

## The gate

Steps 1–6 are local, and you can undo every one of them. Step 7 is the gate: it pushes and publishes.
Nothing crosses the gate until `dev-install.sh` has produced a working app.

The tag is created **before** the build, because `dev-install.sh` stamps the
version from `git describe --tags`. Tag second and the app reports the previous
version.

Run the steps in order. Stop and report on any failure.

## Step 1: Run the tests

```bash
xcodebuild test -project EyeBreak.xcodeproj -scheme EyeBreak \
  -configuration Release -destination 'platform=macOS'
swiftlint lint --strict
```

Both must pass. A failure ends the release here.

Also confirm the working tree is clean and you are on `main`, up to date with
`origin/main`.

## Step 2: Compute the version

```bash
LAST="$(git describe --tags --abbrev=0)"
git log "$LAST"..HEAD --format="%s%n%b"
```

Bump from the conventional-commit types in that range:

| Found                                                | Bump  |
| ---------------------------------------------------- | ----- |
| `BREAKING CHANGE` in a body, or `!` before the colon | major |
| any `feat:`                                          | minor |
| anything else                                        | patch |

Now cross-check: read `[Unreleased]` in `CHANGELOG.md` and decide what bump
**its entries** imply. Report both numbers.

**When they disagree, say so before going further.** A mismatch means the
changelog has drifted from the commits. That drift is exactly how v2.4.0 and
v2.4.1 shipped with no entries at all. Ask George which is right.

## Step 3: Close the changelog gap

List every commit in the range that changed something a user would notice and
has no matching `[Unreleased]` entry. Name each one.

For each, draft an entry and get George's approval before writing it. House
style is a `####` grouping of a feature, then bolded lead-ins:

```markdown
#### Breaks Wait for You

- **A break no longer ends itself** - The countdown reaches zero, the break is counted, and the screen stays up
```

Entries written at commit time are richer than anything reconstructed
afterwards, so most of `[Unreleased]` should already be there. This step fills
gaps; it does not rewrite what exists.

## Step 4: Promote the section

In `CHANGELOG.md`:

- Rename `## [Unreleased]` to `## [<version>] - <YYYY-MM-DD>`, using today's
  date.
- Add a fresh, empty `## [Unreleased]` above it.
- Update the `[Unreleased]` compare link to `v<version>...HEAD`.
- Add a `[<version>]` compare link against the previous tag.

Run `mise exec -- prettier --check .` — `CHANGELOG.md` is in `.prettierignore`,
so this only catches damage elsewhere.

## Step 5: Commit and tag locally

```bash
git add CHANGELOG.md
git commit -m "chore: release <version>"
git tag "v<version>"
```

Do not push either one yet.

## Step 6: Build and install

```bash
./scripts/dev-install.sh
```

This is the proof. Confirm all four:

1. The script exits 0.
2. It prints `Installed <version>` — the plain version, with no suffix.
3. The app relaunches and the menu bar icon returns.
4. Settings > About reads `Version <version>`.

**If any of these fail, stop.** Nothing has been pushed. Undo with:

```bash
git tag -d "v<version>"
git reset --hard HEAD~1
```

Then fix the cause and start again at step 1.

## Step 7: Publish

Only after step 6 succeeded.

```bash
git push origin main
git push origin "v<version>"
gh release create "v<version>" --title "v<version>" --notes-file <body>
```

`<body>` is the new `CHANGELOG.md` section, without its `## [<version>]`
heading. Pass **no** files — this release has no assets.

Report the release URL.

## Verify

```bash
git ls-remote --tags origin "refs/tags/v<version>"   # the tag is on origin
gh release view "v<version>" --json assets           # assets is []
/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" \
  /Applications/EyeBreak.app/Contents/Info.plist     # reads <version>
```
