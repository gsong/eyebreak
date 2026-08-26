#!/usr/bin/env bash
# Snapshot every local branch and classify what it should be rebased onto.
# Writes a tab-separated plan to $GIT_DIR/upstream-sync/plan.tsv and prints it.
# Mutates nothing except the remote-tracking refs that `git fetch` updates.
set -euo pipefail

git rev-parse --git-dir >/dev/null

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "error: working tree is dirty. Commit or stash before syncing." >&2
  exit 1
fi

git_dir=$(git rev-parse --git-dir)
if [ -d "$git_dir/rebase-merge" ] || [ -d "$git_dir/rebase-apply" ] ||
  [ -f "$git_dir/MERGE_HEAD" ] || [ -f "$git_dir/CHERRY_PICK_HEAD" ]; then
  echo "error: a rebase, merge, or cherry-pick is already in progress." >&2
  exit 1
fi

git fetch --prune upstream
git fetch --prune origin

old_main=$(git rev-parse --verify main)
new_upstream=$(git rev-parse --verify upstream/main)

# upstream-main is our local mirror of upstream/main. If it is missing, the fork
# point of main is the next best record of where upstream stood.
if old_upstream=$(git rev-parse --verify --quiet upstream-main); then :; else
  old_upstream=$(git merge-base main upstream/main)
fi

# Branches checked out in another worktree cannot be rebased from here.
top=$(git rev-parse --show-toplevel)
locked=$(git worktree list --porcelain | awk -v self="$top" '
  /^worktree /{path=substr($0,10)}
  /^branch /{b=substr($0,8); sub("refs/heads/","",b); if (path != self) print b}
')

state_dir="$git_dir/upstream-sync"
mkdir -p "$state_dir"
plan="$state_dir/plan.tsv"
: >"$plan"

{
  printf 'old_main\t%s\n' "$old_main"
  printf 'old_upstream\t%s\n' "$old_upstream"
  printf 'new_upstream\t%s\n' "$new_upstream"
} >"$state_dir/refs.tsv"

classify() {
  local branch=$1 head base kind new_base
  head=$(git rev-parse --verify "$branch")

  if [ "$branch" = upstream-main ]; then
    printf '%s\tmirror\t%s\t%s\tupstream/main\n' "$branch" "$head" "$old_upstream"
    return
  fi

  if [ "$branch" = main ]; then
    printf '%s\tmain\t%s\t%s\tupstream-main\n' "$branch" "$head" "$old_upstream"
    return
  fi

  if printf '%s\n' "$locked" | grep -qx "$branch"; then
    printf '%s\tlocked\t%s\t-\t-\n' "$branch" "$head"
    return
  fi

  # try/* branches merge main into an upstream branch purely to run our tests.
  # The upstream-pr skill treats them as disposable, so rebasing one is wasted work.
  case "$branch" in
  try/*)
    printf '%s\tthrowaway\t%s\t-\t-\n' "$branch" "$head"
    return
    ;;
  esac

  # A branch built on main carries main's fork-only tooling commits, so its merge
  # base with main sits above where upstream stood. A branch cut from upstream/main
  # for an upstream PR carries none of them, so its merge base is at or below it.
  base=$(git merge-base "$branch" "$old_main")
  if git merge-base --is-ancestor "$base" "$old_upstream"; then
    kind=upstream
    new_base=upstream-main
  else
    kind=fork
    new_base=main
  fi

  if [ "$(git rev-list --count "$base..$head")" -eq 0 ]; then
    kind=merged
    new_base=-
  fi

  printf '%s\t%s\t%s\t%s\t%s\n' "$branch" "$kind" "$head" "$base" "$new_base"
}

while read -r branch; do
  classify "$branch"
done < <(git for-each-ref --format='%(refname:short)' refs/heads) >>"$plan"

if [ "$old_upstream" = "$new_upstream" ]; then
  echo "upstream/main has not moved ($new_upstream). Nothing to sync."
else
  echo "upstream/main moved $old_upstream -> $new_upstream"
  echo "$(git rev-list --count "$old_upstream..$new_upstream") new upstream commit(s)"
fi
echo
printf '%-40s %-10s %-10s %s\n' BRANCH KIND OLD_HEAD REBASE_ONTO
while IFS=$'\t' read -r branch kind head base new_base; do
  printf '%-40s %-10s %-10s %s\n' "$branch" "$kind" "${head:0:9}" "$new_base"
done <"$plan"
echo
echo "plan: $plan"
