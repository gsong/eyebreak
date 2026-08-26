#!/usr/bin/env bash
# Restore every branch to the SHA plan.sh recorded before the rebase.
# Only useful before pushing. After a push, reset and force-push again instead.
set -euo pipefail

plan="$(git rev-parse --git-dir)/upstream-sync/plan.tsv"
[ -f "$plan" ] || {
  echo "error: no plan at $plan." >&2
  exit 1
}

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "error: working tree is dirty. Commit or stash first." >&2
  exit 1
fi

current=$(git rev-parse --abbrev-ref HEAD)

while IFS=$'\t' read -r branch kind old_head _rest; do
  [ "$kind" = locked ] && continue
  now=$(git rev-parse --verify --quiet "$branch") || continue
  [ "$now" = "$old_head" ] && continue
  echo "restoring $branch: ${now:0:9} -> ${old_head:0:9}"
  if [ "$branch" = "$current" ]; then
    git reset --hard "$old_head"
  else
    git branch -f "$branch" "$old_head"
  fi
done <"$plan"

echo "Done. Branches match the pre-sync snapshot."
