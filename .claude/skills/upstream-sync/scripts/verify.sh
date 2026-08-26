#!/usr/bin/env bash
# Compare each rebased branch against the snapshot plan.sh took beforehand.
# Exits non-zero if any branch lost or gained a commit.
set -uo pipefail

git_dir=$(git rev-parse --git-dir)
if [ -d "$git_dir/rebase-merge" ] || [ -d "$git_dir/rebase-apply" ] ||
  [ -f "$git_dir/MERGE_HEAD" ]; then
  echo "error: a rebase or merge is still in progress. Finish it before verifying." >&2
  exit 1
fi

plan="$git_dir/upstream-sync/plan.tsv"
[ -f "$plan" ] || {
  echo "error: no plan at $plan. Run plan.sh first." >&2
  exit 1
}

status=0
skipped=0

while IFS=$'\t' read -r branch kind old_head old_base new_base; do
  case "$kind" in
  fork | upstream | main) ;;
  *) continue ;;
  esac

  new_head=$(git rev-parse --verify "$branch")
  echo "=== $branch ($kind)"

  if [ "$new_head" = "$old_head" ]; then
    echo "    unchanged at ${old_head:0:9}"
    continue
  fi

  # A merge fallback leaves main with a merge commit, so a range-diff against the
  # old linear range is meaningless. Say so rather than raising a false alarm.
  if [ "$(git rev-list --count --merges "$old_base..$new_head")" -gt 0 ]; then
    echo "    ${old_head:0:9} -> ${new_head:0:9} (merge commit present)"
    echo "    range-diff skipped. Verify this branch with the test suite."
    skipped=$((skipped + 1))
    continue
  fi

  nb=$(git merge-base "$branch" "$new_base")
  before=$(git rev-list --count "$old_base..$old_head")
  after=$(git rev-list --count "$nb..$new_head")
  echo "    ${old_head:0:9} -> ${new_head:0:9}   commits $before -> $after"

  # Subjects decide pass or fail. Conflict resolution rewrites a patch but never
  # the message, so comparing subjects as sorted multisets survives resolutions
  # that a content comparison would call a different commit.
  subj_diff=$(diff \
    <(git log --format=%s "$old_base..$old_head" | sort) \
    <(git log --format=%s "$nb..$new_head" | sort))

  if [ "$before" -ne "$after" ] || [ -n "$subj_diff" ]; then
    echo "    LOSS: commits do not line up."
    printf '%s\n' "$subj_diff" | sed 's/^/      /'
    status=1
    continue
  fi

  # range-diff needs two non-empty ranges. Equal counts of zero means both
  # branches are fully merged into their base, which the check above accepted.
  [ "$before" -eq 0 ] && continue

  # --creation-factor=999 pairs commits generously. At the default of 60 a
  # conflict resolution can shift a patch far enough that range-diff reports the
  # commit as dropped-and-recreated, which reads as data loss when nothing was
  # lost. Loose pairing is safe because the subject check above already decided.
  rd=$(git range-diff --no-color --creation-factor=999 "$old_base..$old_head" "$nb..$new_head")
  changed=$(printf '%s\n' "$rd" | grep -cE '^ *[0-9]+: +[0-9a-f]+ ! +[0-9]+:')
  echo "    identical $((before - changed))  changed $changed"

  if [ "$changed" -gt 0 ]; then
    echo "    Changed commits are expected after conflict resolution. Read each one"
    echo "    and confirm the change is your resolution and nothing else:"
    printf '%s\n' "$rd" | grep -E '^ *[0-9]+: +[0-9a-f]+ ! ' | sed 's/^/      /'
    echo "      git range-diff --creation-factor=999 ${old_base:0:9}..${old_head:0:9} ${nb:0:9}..${new_head:0:9}"
  fi
done <"$plan"

if [ "$status" -eq 0 ]; then
  echo
  if [ "$skipped" -gt 0 ]; then
    echo "No commits lost on the branches this could check. $skipped branch(es) carry a"
    echo "merge commit and were skipped -- the test suite is the only check on those."
  else
    echo "No commits lost. Safe to push after the tests pass."
  fi
else
  echo
  echo "Commits went missing. Do NOT push. Run rollback.sh to restore the snapshot."
fi
exit "$status"
