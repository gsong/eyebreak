---
name: repo-refresh
description: Run all repo maintenance tasks in sequence — upgrade mise tools, resolve Swift package dependencies, upgrade GitHub Actions, audit workflows with zizmor — with per-step commits and a PR. Use when the user asks to refresh, upgrade, or maintain the repo.
---

# Repo Refresh

Run all repo maintenance tasks in sequence with per-step commits and a final PR.

## Scope

This skill covers the macOS app and its CI only. **Do not touch `website/`.** Its npm
dependencies are out of scope and are not part of a refresh.

## Pre-flight: Branch Setup

1. Use AskUserQuestion to ask: use the current branch, or provide a branch name to create off `main`?
   - Options: "Use current branch", "Create new branch"
   - If the user chooses a new branch, ask for the branch name
2. If creating a new branch:
   ```bash
   git fetch origin
   git checkout -b <branch-name> origin/main
   ```
3. If using the current branch, proceed as-is

`origin` is `gsong/eyebreak`. `upstream` is `cheat2001/eyebreak`, the repo this one forks.
Never branch from, push to, or open a PR against `upstream`.

## Steps

Run each step in order. After each step:

1. Run that step's verification command (listed with the step)
2. Check `git status` — if there are changes, stage and commit with the specified message
3. If no files changed, skip the commit and move to the next step

If any step fails: stop and attempt to diagnose/fix the issue. If fixed, re-run the verification,
commit, and continue. If not fixable, halt and report to the user.

A formatting-only change belongs in its own commit, never folded into a step's commit. Mixing the
two hides the real change inside reindented lines.

### Step 1: Upgrade mise tools

Invoke the `gs:repo-maintenance:mise` skill. It handles `minimum_release_age` resolution, dry-run
preview, and user confirmation. It does NOT perform git operations.

`mise.toml` declares only the tools this repo's own workflow needs: `zizmor` and `prettier`. Xcode
is not among them — it comes from the App Store, and CI takes whatever `macos-latest` ships.

**Verify:** `mise install`, then confirm each tool runs.

Commit:

```
chore: upgrade mise tools
```

### Step 2: Resolve Swift package dependencies

The app depends on Sparkle through Swift Package Manager, declared in `EyeBreak.xcodeproj`. The
version range lives in `project.pbxproj`; the resolved commit lives in
`EyeBreak.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.

Check for a newer release first:

```bash
gh api repos/sparkle-project/Sparkle/releases/latest --jq .tag_name
grep -n "minimumVersion" EyeBreak.xcodeproj/project.pbxproj
```

If the latest release sits outside the declared range, report it to the user and use
AskUserQuestion before widening the range. Sparkle handles app updates, so a major bump changes how
users receive releases. Read the release notes before recommending it.

Then resolve:

```bash
xcodebuild -resolvePackageDependencies -project EyeBreak.xcodeproj -scheme EyeBreak
```

**Verify:** if `Package.resolved` changed, build the app.

```bash
xcodebuild clean build -project EyeBreak.xcodeproj -scheme EyeBreak \
  -configuration Release -destination 'platform=macOS' \
  CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

Commit:

```
chore: update Swift package dependencies
```

### Step 3: Upgrade GitHub Actions

Invoke the `gs:repo-maintenance:gha` skill. It handles minimumReleaseAge resolution, dry-run
preview, and user confirmation. It does NOT perform git operations.

The repo has no `renovate.json`, so the skill falls back to its 7-day default cool-down. That
matches `minimum_release_age` in `mise.toml`. Keep the two in step if you change either.

This repo pins actions to commit SHAs with a trailing version comment, which is what `actions-up`
writes by default. Do not convert them back to floating tags, and do not hand-edit a SHA — re-run
the skill instead.

**Verify:** re-run zizmor and confirm no `unpinned-uses` finding remains.

```bash
GH_TOKEN=$(gh auth token) zizmor .
```

Commit:

```
chore: upgrade GitHub Actions dependencies
```

### Step 4: Audit workflows with zizmor

Invoke the `gs:repo-maintenance:zizmor` skill. It runs the audit, researches each finding type, and
asks before applying fixes. It does NOT perform git operations.

Two findings recur in this repo and need judgment, not a reflex fix:

- **`excessive-permissions`** — no workflow sets a `permissions:` block, so every job gets the
  default write token. `release.yml` genuinely needs `contents: write` to publish a release. Every
  other workflow needs `contents: read`.
- **`template-injection`** — check whether the interpolated value is attacker-controlled before
  rewriting a `run:` step. A tag name the maintainer pushes is not the same risk as a PR title.

**Verify:** re-run the audit and confirm the finding count dropped.

Commit:

```
chore: address zizmor workflow findings
```

### Step 5: Check formatting is clean

The `PostToolUse` hook in `.claude/settings.json` formats every Markdown, YAML, or JSON file
Claude edits directly. It never sees the files the maintenance tools rewrite on their own —
`actions-up` on the workflow YAML, the mise skill on `mise.toml`. This sweep catches those.

```bash
mise exec -- prettier --check .
```

`.prettierignore` keeps prettier away from `website/`, build output, `*.xcassets/`, `CHANGELOG.md`,
and `docs/releases/`. Prettier does not read Swift — that is what SwiftLint in `ci.yml` is for.

If it reports anything, run `--write`, then commit:

```
style: format with prettier
```

## Post-flight: Push and PR

After all steps complete:

1. Push the branch:

   ```bash
   git push -u origin <branch-name>
   ```

2. Create a PR **targeting `gsong/eyebreak`**, never `upstream`:

   ```bash
   gh pr create --repo gsong/eyebreak --base main --title "chore: repo refresh" --body "$(cat <<'EOF'
   ## Summary
   - [bullet points of what changed]

   ## Notable upgrades
   - [major version bumps, breaking changes, new features]
   EOF
   )"
   ```

   Include in the body:
   - Major version bumps and the breaking changes they carry
   - Sparkle version changes, called out separately — they affect the update mechanism
   - zizmor findings fixed, and any deliberately left open with the reason

3. Report the PR URL to the user.

## Constraints

- Do NOT run or launch the app
- Do NOT touch `website/`
- Each step gets its own commit
- Steps run sequentially (each can affect the next)
- Use `git push --force-with-lease` if the branch already exists on origin

## Prerequisites

- `mise install` — provides `zizmor` and `prettier`, both declared in `mise.toml`
- `gh`, authenticated — the maintenance skills use it for the GitHub API
- Xcode and its command line tools, for `xcodebuild`
