---
name: upstream-sync
description: Fast-forward upstream-main to cheat2001/eyebreak, rebase main on top of it, and rebase every other local branch onto its correct new base — fork work onto main, upstream PR branches onto upstream-main. Verifies no commit was lost before pushing. Use whenever George wants to sync with upstream, update or refresh upstream-main, pull in upstream changes, rebase the fork on upstream, catch the fork up, or says the fork has fallen behind.
---

# Upstream Sync

Bring the fork level with `upstream/main` and move every branch onto its correct new base.

Our `main` is a linear stack of fork-only tooling commits sitting directly on `upstream/main`:
mise, prettier, the `.claude/` skills, `scripts/dev-install.sh`, the `EyeBreakTests` target. No
Swift source differs. That shape is what makes a rebase clean, and keeping it that way is the
point of this skill — a merge commit on `main` would make every future sync harder.

Two bases exist, and branches split between them:

- **Fork work** (anything cut from `main`) rebases onto the new `main`.
- **Upstream PR branches** (`fix/*` cut from `upstream/main`, per the `upstream-pr` skill)
  rebase onto `upstream-main`. Never put them on `main` — that buries the tooling commits in
  the PR and the branch has to be rebuilt.

Never push to `upstream`. `origin` is `gsong/eyebreak`.

## 1. Plan

```bash
.claude/skills/upstream-sync/scripts/plan.sh
```

This fetches both remotes, snapshots every local branch's SHA, and classifies each one. It
mutates no branches. Read the table before doing anything else.

| Kind        | Meaning                         | Action                              |
| ----------- | ------------------------------- | ----------------------------------- |
| `mirror`    | `upstream-main`                 | fast-forward to `upstream/main`     |
| `main`      | `main`                          | rebase onto `upstream-main`         |
| `fork`      | built on `main`                 | rebase onto the new `main`          |
| `upstream`  | cut from `upstream/main`        | rebase onto the new `upstream-main` |
| `merged`    | nothing left to replay          | skip                                |
| `throwaway` | `try/*` test branch             | delete, recreate later if needed    |
| `locked`    | checked out in another worktree | stop and tell George                |

The snapshot lands in `$GIT_DIR/upstream-sync/plan.tsv`. Steps 4 and 5 read it, so do not
rerun `plan.sh` mid-sync — that would overwrite the "before" state you need to verify against.

If the script reports upstream has not moved, stop. There is nothing to do.

**Before rebasing a `fork` branch, check whether it belongs to a gh-stack.** Rebasing stack
layers one at a time detaches them from each other. Use the `gh-stack` skill instead:

```bash
GH_REPO=gsong/eyebreak gh stack view --json
```

If the branch is in a stack, rebase `main` here and then hand the stack to `gh stack sync`.

## 2. Fast-forward upstream-main

```bash
git checkout upstream-main && git merge --ff-only upstream/main
```

If this is not a fast-forward, upstream rewrote its history. Stop and tell George — every
classification in the plan assumed the old `upstream-main` was still an ancestor.

## 3. Rebase main

`rerere.enabled` should be `true` so a resolution you make here replays automatically the next
time the same conflict appears. Confirm it, since it is set on George's machine and not in the
repo:

```bash
git config rerere.enabled
git rebase upstream-main main
```

**Conflict budget: two commits.** Resolve conflicts as they come. If a third separate commit
conflicts, the histories have diverged enough that a rebase is no longer the cheap option —
abort and merge instead:

```bash
git rebase --abort
git checkout main && git merge --no-ff upstream-main
```

Say plainly that you fell back to a merge and why. A merge leaves `main` non-linear, which
makes the next sync harder and complicates `upstream-pr`, so it is worth George knowing.

The rest of the skill works either way: `fork` branches still rebase onto `main`, `upstream`
branches still rebase onto `upstream-main`.

## 4. Rebase the other branches

Use `--onto` with the branch's recorded old base, so only that branch's own commits replay.
Take the old base from the plan's fourth column, not from a fresh `git merge-base` — `main`
has moved and a fresh one would be wrong.

```bash
git rebase --onto main <old_base> <fork-branch>
git rebase --onto upstream-main <old_base> <upstream-branch>
```

After resolving a conflict, continue with `GIT_EDITOR=true`. Plain
`git rebase --continue` opens an editor for the commit message and stalls.

```bash
git add <resolved-files>
GIT_EDITOR=true git rebase --continue
```

Never `git rebase --skip`. It drops the commit, which is exactly the loss step 5 hunts for.

Do the `upstream` branches first. They are what feed open PRs, and a mistake there is visible
outside the fork.

Delete `throwaway` branches rather than rebasing them — the `upstream-pr` skill rebuilds them
from scratch anyway:

```bash
git branch -D try/some-bug
```

**Expect `EyeBreak.xcodeproj/project.pbxproj` conflicts** on branches that touch the Xcode
project. Our test target lives in that file and upstream's does not.

## 5. Verify nothing was lost

Two checks, both required before any push.

```bash
.claude/skills/upstream-sync/scripts/verify.sh
```

For each rebased branch it compares the commit count and the set of commit subjects against
the snapshot. Subjects are the check that decides: conflict resolution rewrites a patch but
never the message, so a subject that vanished means a commit really was dropped. Anything
missing or added exits non-zero.

It then range-diffs the branch and lists commits whose content changed. That is normal after a
conflict resolution. Read each one and confirm the change is the resolution you made, not
something git dropped along the way.

A branch carrying a merge commit — `main` after the step 3 fallback — cannot be range-diffed
against its old linear range. The script says so and leaves that branch to the test suite.

It refuses to run while a rebase is still in progress, so finish or abort first.

If it reports loss, do not push. `rollback.sh` restores every branch to its snapshot SHA,
so you can retry from a known state:

```bash
.claude/skills/upstream-sync/scripts/rollback.sh
```

Then run the tests on `main`, which is the only branch carrying the test target:

```bash
git checkout main
xcodebuild test -project EyeBreak.xcodeproj -scheme EyeBreak \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO DEVELOPMENT_TEAM=""
```

A range-diff proves the commits survived. The tests prove upstream's changes and ours still
work together. Neither substitutes for the other, so report both results.

## 6. Push

Show George what will move before pushing anything — every rebased branch needs a force-push,
and `main` among them:

```bash
git for-each-ref --format='%(refname:short) %(objectname:short) -> %(upstream:short) %(upstream:trackshort)' refs/heads
```

Then push the rewritten branches:

```bash
git push --force-with-lease origin main
git push --force-with-lease origin <each-rebased-branch>
```

`--force-with-lease`, never `--force`. Do not push `upstream-main`; it tracks `upstream/main`
and has no place on `origin`.

If a `--force-with-lease` is rejected, someone else moved the remote branch. Fetch and look at
what landed before doing anything else. Do not reach for `--force` to get past it.

## Watch for

- **`origin/main` gets rewritten.** That is inherent to rebasing a fork's `main`, and fine
  while George is the only one working in `gsong/eyebreak`. If anyone else has a clone, say so
  before pushing.
- **Open PRs on rebased branches.** A force-push updates the PR, but review comments on old
  commits go stale. Mention which PRs the push touches.
- **A `fix/*` branch that has already been merged upstream.** It classifies as `merged` and is
  skipped. Delete it rather than carrying it forward.
- **Do not run prettier on an `upstream`-kind branch.** Upstream markdown and YAML are
  unformatted, so the `PostToolUse` hook in `.claude/settings.json` rewrites whole files and
  buries the real change. Revert any such reformat before committing.
