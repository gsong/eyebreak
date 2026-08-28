# EyeBreak

## This fork is its own project

EyeBreak began as a fork of [cheat2001/eyebreak](https://github.com/cheat2001/eyebreak).
It is now an independent personal project. Upstream is **not a consideration**.

- Never open a pull request against upstream. Every pull request targets `origin`
  (`gsong/eyebreak`).
- Never add an `upstream` remote or read from one. There is nothing to sync.
- Restructure, reformat, and split any file under `EyeBreak/` freely. Nothing is
  waiting on a rebase.

This is deliberate, not neglect. Settled 2026-08-27 in
[#39](https://github.com/gsong/eyebreak/issues/39).

**Why.** `main` used to be a stack of fork-only commits rebased onto
`upstream/main`. That tax shaped the repo: `.swiftlint.yml` disabled seven rules
to keep the rebase cheap, prettier was barred from Swift sources, and
`SettingsView.swift` grew to 2,608 lines because we could not restructure code we
did not own. Separately, `Info.plist` pointed Sparkle at upstream's appcast signed
with upstream's key, so a manual update check would have overwritten the local
build with upstream's DMG.

The GitHub fork badge stays, so the provenance of upstream's Swift stays visible.
The 2.x version line stays, because `CHANGELOG.md` is a continuous record and the
app's preferences are keyed to `com.eyebreak.app`.

## Audience

Personal. This app ships to nobody. There is no DMG, no Homebrew cask, no
appcast, and no Sparkle — the app never checks for an update, because there is
nothing signed for it to find. Do not write end-user prose — no installation
guides, no FAQ, no contributor docs. `README.md` is for us and our agents.

## Releasing

A release is a tag, a `CHANGELOG.md` section, a GitHub Release with **no
assets**, and a freshly installed local app. Use the `release` skill rather than
running the steps by hand — it tags before it builds, and it gates every push on
a working build.

Keep `[Unreleased]` current as you go. Writing entries at commit time is what
keeps the release honest; v2.4.0 and v2.4.1 shipped with none because nobody
did.

## Pull requests

Multi-part work lands one concern per layer, one pull request per layer, merged
when CI is green before the next layer starts. Use a `gh-stack` when layers are
genuinely in flight together; a chain of tickets worked one session at a time does
not need one, and `main` stays installable at every step.

**Build-affecting means project-level**: deployment target, scheme, dependencies.
Isolate those in their own layer so a red CI run is unambiguous. Adding or removing
source files does not count — `project.pbxproj` carries a reference per file, so
nearly every layer touches it and the rule would separate nothing.

Settled 2026-08-28 in [#56](https://github.com/gsong/eyebreak/issues/56).

## Agent skills

### Issue tracker

Issues live in `gsong/eyebreak` GitHub Issues, driven by the `gh` CLI. See
`docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage roles, each label string equal to its name. See
`docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `CONTEXT.md` and `docs/adr/` at the repo root. See
`docs/agents/domain.md`.
