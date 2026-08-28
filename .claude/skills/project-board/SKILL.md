---
name: project-board
description: Read and update the EyeBreak GitHub Project board — move issues and PRs between Todo, Up Next, In Progress, and Done, see what is on the board, and add items to it. Use this whenever work status changes or the board comes up: "move #51 to in progress", "what am I working on", "what's next", "mark that done", "is this on the board", "add the new issue to the project", or when you have just opened, merged, or closed something and its column is now stale. Reach for it before writing any `gh project` command by hand — the board's field and option IDs live here, and guessing them wastes a lookup.
---

# EyeBreak project board

The board is [GitHub Project 7](https://github.com/users/gsong/projects/7), owned
by the user `gsong`, tracking issues and pull requests from `gsong/eyebreak`.

`gh project item-edit` takes three opaque IDs and the issue number is none of
them. That is the whole friction this skill removes. Use `board.sh` rather than
assembling the call yourself.

## The helper

```bash
.claude/skills/project-board/board.sh list                  # whole board, In Progress first
.claude/skills/project-board/board.sh list in-progress      # one column
.claude/skills/project-board/board.sh set in-progress 49 51  # move one or many
.claude/skills/project-board/board.sh add 58                # put a new item on the board
```

Statuses are `todo`, `up-next`, `in-progress`, and `done`. `set` takes any number
of issue or PR numbers and does one board read for the whole batch.

`set` fails loudly when a number is not on the board, because a silent no-op
there would read as success and leave the column wrong.

## Reading one item's column

`list` fetches the whole board. When the question is about a single issue or PR,
ask the item itself instead — one call, no board scan, and it cannot be truncated:

```bash
gh issue view 53 --json projectItems --jq '.projectItems[].status.name'
gh pr view 57 --json projectItems --jq '.projectItems[].status.name'
```

Reach for `list` when you need the shape of the board — what is in flight, what
is next, whether a column has drifted. Reach for `view` when you already know
which item you care about.

## What the columns mean here

This board tracks a personal project, so the columns carry the user's own
meaning rather than a team process:

| Column          | Meaning                                                             |
| --------------- | ------------------------------------------------------------------- |
| **Todo**        | Filed, not scheduled. Includes tickets parked behind another effort |
| **Up Next**     | Part of the effort now in flight, but not started                   |
| **In Progress** | Being worked, or an open PR waiting on a merge                      |
| **Done**        | Closed, or merged                                                   |

A map issue stays **In Progress** for as long as any of its tickets is live — it
does not go to Done until the effort it charts is finished.

Keep the board honest as work moves. An open green PR sitting in Todo, or a map
in Up Next after one of its tickets has landed, is the kind of drift worth
correcting when you notice it.

## The raw IDs

Only needed if `board.sh` cannot express what you want — a field other than
Status, or a bulk operation over the GraphQL API. Everything here came from
`gh project field-list 7 --owner gsong`.

| Thing                | ID                               |
| -------------------- | -------------------------------- |
| Project (number)     | `7`                              |
| Project (node)       | `PVT_kwHOAAlEvM4BhmqW`           |
| Status field         | `PVTSSF_lAHOAAlEvM4BhmqWzhghziU` |
| Status → Todo        | `a0d09249`                       |
| Status → Up Next     | `97d00ba1`                       |
| Status → In Progress | `9b9ecfa0`                       |
| Status → Done        | `c5197983`                       |

A status change by hand is a lookup and then a call:

```bash
# The item ID is per board row, not per issue. It has to be looked up.
gh project item-list 7 --owner gsong --limit 200 --format json \
  | jq -r '.items[] | select(.content.number == 51) | .id'

gh project item-edit --id <item-id> \
  --project-id PVT_kwHOAAlEvM4BhmqW \
  --field-id PVTSSF_lAHOAAlEvM4BhmqWzhghziU \
  --single-select-option-id 9b9ecfa0
```

The other fields — Assignees, Labels, Milestone, Parent issue, and the rest —
are GitHub's built-ins and mirror the issue itself. Change them on the issue with
`gh issue edit`, not on the board.

## Two things that will bite you

**`item-list` defaults to 30 rows and truncates in silence.** The board is past
that already, so a read without `--limit` quietly drops the oldest rows and any
lookup over them fails for the wrong reason. `board.sh` passes `--limit 200`.

**New issues and PRs appear on the board by themselves, in Todo.** The project
has an auto-add workflow, so a freshly opened item is almost always on the board
already — in the wrong column. Check before reaching for `add`. Adding a row that
exists is not harmful, but it means the real problem was the status, not the
absence.

## Rebuilding these IDs

If the board is ever recreated, every ID above changes. Regenerate them and
update both this file and the constants at the top of `board.sh`:

```bash
gh project list --owner gsong                       # project number and node ID
gh project field-list 7 --owner gsong --format json # field and option IDs
```
