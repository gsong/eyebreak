---
name: upstream-pr
description: Prepare a bug fix or feature as a clean PR against the upstream repo (cheat2001/eyebreak), and test it locally with our fork-only tooling. Use when George wants to contribute a change upstream, send a fix back to the original project, upstream a patch, or mentions an upstream PR or an upstream branch.
---

# Upstream PR

Our `main` runs ahead of `upstream/main` by a handful of fork-only tooling commits: mise,
prettier, the `.claude/` skills, `scripts/dev-install.sh`, and the `EyeBreakTests` target. No
Swift source differs. Branching a fix off `main` would carry every one of those into the
upstream PR, so branch off `upstream/main` instead and merge `main` into a throwaway branch
when you need our tooling to test.

Check the real gap before starting — it grows each time we add tooling:

```bash
git fetch upstream
git log --oneline upstream/main..main
```

## Create the branch

```bash
git checkout -b fix/some-bug upstream/main
```

Write the fix and commit it here. This branch is what goes to upstream, so read upstream's
`CONTRIBUTING.md` on it — ours is reformatted and may have drifted from theirs.

## Test it with our tooling

Merge `main` into a throwaway branch. Recreate that branch from scratch after every new commit
so it never drifts:

```bash
git checkout -B try/some-bug fix/some-bug
git merge --no-ff main -m "temp: tooling for local testing"
xcodebuild test -project EyeBreak.xcodeproj -scheme EyeBreak \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO DEVELOPMENT_TEAM=""
./scripts/dev-install.sh
```

The test target exists only on `main`, which is why the tests run here and not on `fix/*`.
Delete the branch with `git branch -D try/some-bug` when you are done.

**The merge is one-way.** Never merge `try/*` back into `fix/*`, and never push `try/*` to
`origin`. Either mistake puts the tooling commits in the PR, and the branch has to be rebuilt.

## Open the PR

Confirm the branch carries only the fix, then push it to `origin` — upstream cannot see a
branch that exists only on your disk, and `--head gsong:...` resolves against our fork:

```bash
git log --oneline upstream/main..fix/some-bug
git diff --stat upstream/main..fix/some-bug
git push -u origin fix/some-bug
```

Then open it against upstream. This is the one case where `--repo cheat2001/eyebreak` is
correct; every other PR in this repo targets `origin`. Pass `--title` and `--body` explicitly,
since `gh` otherwise opens an editor and stalls:

```bash
gh pr create --repo cheat2001/eyebreak --base main --head gsong:fix/some-bug \
  --title "fix: short description" --body "..."
```

Upstream's `.github/PULL_REQUEST_TEMPLATE.md` governs the body. Read it from the branch and
follow its sections rather than inventing a format.

## Iterate after review

Commit review fixes on `fix/*` and push — the PR updates itself. Then recreate `try/*` from
scratch to retest. If `upstream/main` moves under you, rebase rather than merge, so the branch
keeps carrying only your commits:

```bash
git fetch upstream
git rebase upstream/main fix/some-bug
git push --force-with-lease origin fix/some-bug
```

## Watch for

- **`EyeBreak.xcodeproj/project.pbxproj` conflicts on the `try/*` merge.** Our test target
  lives in that file and upstream's does not. `git config rerere.enabled` should be `true`, so
  you resolve it once and later merges replay it. It is set globally on George's machine, not
  in the repo, so confirm it on a fresh clone or a different machine.
- **Adding a new source file.** Add it on the `fix/*` branch so Xcode writes the entry against
  upstream's project file, not ours.
- **Tests have nowhere to live upstream.** `EyeBreakTests/` and its target are ours alone. Keep
  the test on our side, or propose the test target to upstream as its own PR first.
- **Do not run prettier on a `fix/*` branch.** Upstream markdown and YAML are unformatted, so
  prettier rewrites whole files and buries the real change. The `PostToolUse` hook in
  `.claude/settings.json` formats `.md`, `.json`, and `.yml` on every edit — revert those
  reformats before committing, or avoid editing those file types on the branch.
- **Avoid touching `.github/workflows/`.** We reformatted every workflow, so any edit there
  conflicts noisily.
