#!/usr/bin/env bash
#
# EyeBreak project board helper.
#
# `gh project item-edit` wants three opaque IDs and none of them is the issue
# number, so every status change is a lookup followed by a call. This wraps both.
# The IDs are recorded in SKILL.md next door; change them there too if the board
# is ever rebuilt.
set -euo pipefail

readonly OWNER=gsong
readonly PROJECT_NUMBER=7
readonly PROJECT_ID=PVT_kwHOAAlEvM4BhmqW
readonly STATUS_FIELD=PVTSSF_lAHOAAlEvM4BhmqWzhghziU
readonly REPO=gsong/eyebreak

# item-list defaults to 30 rows and silently truncates. The board is past that,
# so every read asks for more than it can hold.
readonly LIMIT=200

usage() {
    cat >&2 <<'USAGE'
Usage:
  board.sh list [status]        Show the board, optionally one column
  board.sh set <status> <n>...  Move issues/PRs to a status
  board.sh add <n>...           Put issues/PRs on the board

Statuses: todo | up-next | in-progress | done
USAGE
    exit 1
}

# Accepts the board's own labels and the kebab-case forms that survive a shell.
status_option() {
    case "$(echo "$1" | tr '[:upper:] ' '[:lower:]-')" in
        todo) echo a0d09249 ;;
        up-next) echo 97d00ba1 ;;
        in-progress) echo 9b9ecfa0 ;;
        done) echo c5197983 ;;
        *) echo "Unknown status: $1 (todo|up-next|in-progress|done)" >&2; exit 1 ;;
    esac
}

rows() {
    gh project item-list "$PROJECT_NUMBER" --owner "$OWNER" --limit "$LIMIT" --format json
}

cmd_list() {
    local want="${1:-}"
    rows | python3 -c '
import json, sys
want = sys.argv[1] if len(sys.argv) > 1 else ""
order = {"In Progress": 0, "Up Next": 1, "Todo": 2, "Done": 3}
items = []
for i in json.load(sys.stdin)["items"]:
    c = i.get("content", {})
    n = c.get("number")
    if n is None:
        continue
    s = i.get("status", "(none)")
    if want and s.lower().replace(" ", "-") != want.lower().replace(" ", "-"):
        continue
    items.append((order.get(s, 9), -n, s, n, c.get("title", "")))
for _, _, s, n, t in sorted(items):
    print(f"{s:<12} #{n:<4} {t}")
' "$want"
}

# One read serves the whole batch; item IDs are what item-edit actually takes.
cmd_set() {
    local status="$1"; shift
    [ $# -gt 0 ] || usage
    local option; option=$(status_option "$status")

    local ids; ids=$(rows | python3 -c '
import json, sys
wanted = set(sys.argv[1:])
found = {}
for i in json.load(sys.stdin)["items"]:
    n = i.get("content", {}).get("number")
    if n is not None and str(n) in wanted:
        found[str(n)] = i["id"]
for n in sys.argv[1:]:
    if n not in found:
        sys.exit(f"#{n} is not on the board. Add it first: board.sh add {n}")
    print(n, found[n])
' "$@")

    while read -r number item_id; do
        gh project item-edit --id "$item_id" --project-id "$PROJECT_ID" \
            --field-id "$STATUS_FIELD" --single-select-option-id "$option" >/dev/null
        echo "#$number -> $status"
    done <<<"$ids"
}

# The issues API answers for pull requests too, and its html_url comes back
# under /pull/ for them. Building the URL by hand would hand item-add an
# /issues/ path for a PR.
cmd_add() {
    [ $# -gt 0 ] || usage
    for n in "$@"; do
        local url; url=$(gh api "repos/$REPO/issues/$n" --jq .html_url)
        gh project item-add "$PROJECT_NUMBER" --owner "$OWNER" --url "$url" >/dev/null
        echo "#$n added ($url)"
    done
}

case "${1:-}" in
    list) shift; cmd_list "$@" ;;
    set) shift; [ $# -ge 2 ] || usage; cmd_set "$@" ;;
    add) shift; cmd_add "$@" ;;
    *) usage ;;
esac
