# Survey: Swift state machine and statechart libraries

Research for [#26](https://github.com/gsong/eyebreak/issues/26), part of #25.
Surveyed 2026-08-26. All facts come from each project's GitHub repository:
the `Package.swift` manifest, the README, and the GitHub API (releases, tags,
commit history). "Commits, last 12 mo" counts commits on the default branch
since 2025-08-26. This document reports facts only. The decision is a later
ticket (#27).

## Constraints from EyeBreak

- macOS 14+, Swift 5.9 era toolchain, `SWIFT_VERSION = 5.0` language mode
  (`EyeBreak.xcodeproj/project.pbxproj`).
- SwiftUI + Combine. Only SPM dependency today is Sparkle.
- Under ten states (`EyeBreak/Models/TimerState.swift` has five cases).
- Needs a set of concurrent suspension causes: sleep, lock, screensaver,
  idle, smart schedule.
- Transitions must return effects as data, so the core is testable
  without AppKit.

## Candidates named in the ticket that do not exist

- **`narek-sv/StateMachine`** — GitHub user `narek-sv` has no StateMachine
  repository ([repo list](https://github.com/narek-sv?tab=repositories)
  shows KeyValueStorage, MetaCodable, and others). The closest match by
  name is [marcy731/StateMachine](https://github.com/marcy731/StateMachine)
  (6 stars, last push 2023-08-31) — tiny and dormant; not surveyed further.
- **`swift-statecharts`** — a GitHub repository search returns no Swift
  package of this name.
- **`Transitions`** — no notable Swift FSM repo of this name exists. The
  nearest library is [DenTelezhkin/Transporter](https://github.com/DenTelezhkin/Transporter),
  surveyed below.

## Summary table

| Library                                                                               | Last release                  | Commits, last 12 mo     | Swift / macOS floor                        | Parallel regions                                   | Effects as data                                     | Runtime deps                          |
| ------------------------------------------------------------------------------------- | ----------------------------- | ----------------------- | ------------------------------------------ | -------------------------------------------------- | --------------------------------------------------- | ------------------------------------- |
| [Tinder/StateMachine](https://github.com/Tinder/StateMachine)                         | 0.3.0, 2021-11                | 0 (last commit 2024-03) | tools 5.4 (5.9 manifest for macro) / 10.13 | No                                                 | Yes (`SideEffect` value per transition)             | 0 (macro pulls swift-syntax)          |
| [ReactKit/SwiftState](https://github.com/ReactKit/SwiftState)                         | 6.0.0, 2019-06                | 0 (last commit 2020-12) | tools 5.3 / any                            | No                                                 | No (closure handlers)                               | 0                                     |
| [albertodebortoli/Stateful](https://github.com/albertodebortoli/Stateful)             | 3.0.0, 2026-01                | 25                      | tools 6.2 / 10.15                          | No                                                 | No (pre/post closures)                              | 0                                     |
| [DenTelezhkin/Transporter](https://github.com/DenTelezhkin/Transporter)               | 3.2.0, 2019-05                | 2                       | legacy manifest; SPM cannot resolve it     | No                                                 | No (closures)                                       | 0                                     |
| [gistya/SwiftXState](https://github.com/gistya/SwiftXState)                           | 1.1.0, 2026-06 (2.0 in alpha) | 41                      | tools 6.1 / 14                             | Yes                                                | Yes (pure `transition()`; actions are machine data) | docc plugin only                      |
| [serhiybutz/HSM](https://github.com/serhiybutz/HSM)                                   | none (tag 0.12.0)             | 0 (last commit 2022-11) | tools 5.1 / 10.12                          | Yes (orthogonal regions)                           | No (entry/exit/transition handlers)                 | 0                                     |
| [sideeffect-io/AsyncStateMachine](https://github.com/sideeffect-io/AsyncStateMachine) | 0.1.0, 2022-08                | 0 (last commit 2022-08) | tools 5.6 / 10.15                          | No                                                 | Yes (declared `output` values mapped to effects)    | xctest-dynamic-overlay                |
| [couchdeveloper/Oak](https://github.com/couchdeveloper/Oak)                           | none                          | active (pushed 2026-04) | tools 6.2 / 12                             | Not claimed                                        | Yes (transducer returns state + `Effect`)           | async-algorithms, swift-mutex         |
| [square/workflow-swift](https://github.com/square/workflow-swift)                     | v6.0.1, 2026-08-25            | 13                      | tools 5.9 / 12                             | Via child-workflow composition                     | Partly (actions mutate state; effects via Workers)  | core: IssueReporting only             |
| [drseg/swift-fsm](https://github.com/drseg/swift-fsm)                                 | 0.9.6, 2025-02                | active (pushed 2026-04) | tools 6.0 / **15**                         | No                                                 | No (callbacks)                                      | swift-algorithms                      |
| [TCA (one reducer)](https://github.com/pointfreeco/swift-composable-architecture)     | 1.26.1, 2026-07               | 100+                    | tools 6.1 / 13                             | State is a struct; a `Set` of causes is plain data | Yes (`Effect<Action>` values)                       | 12 direct packages incl. swift-syntax |
| GKStateMachine (Apple, built in)                                                      | ships with macOS              | n/a                     | macOS 10.11+                               | No                                                 | No (`didEnter`/`willExit` callbacks)                | 0                                     |

## Per-candidate detail

### Tinder/StateMachine

- 2,078 stars. Last GitHub release 0.3.0 (2021-11-19). Last commit
  2024-03-25; zero commits in the last 12 months.
- Kotlin and Swift in one repo. The Swift library is one source file
  (`Swift/Sources/StateMachine/StateMachine.swift`) plus an optional
  `@StateMachineHashable` macro. The base manifest is tools 5.4 with zero
  dependencies; `Package@swift-5.9.swift` adds swift-syntax for the macro
  (Nimble is test-only). macOS 10.13+ (10.15+ under the 5.9 manifest).
- Effects as data: yes. A transition declares
  `transitionTo(state, sideEffect)`; the machine reports
  `Transition.success` carrying the `SideEffect` value, and the caller
  executes it (README, Swift section).
- Parallel regions: no. Flat FSM with a single current state. Concurrent
  suspension causes would live in associated values, as in a hand-rolled
  machine.
- Testing: pure Swift; the repo tests with XCTest + Nimble, no AppKit.

### ReactKit/SwiftState

- 909 stars. Last release 6.0.0 (2019-06-16, tag 6.0.1). Last commit
  2020-12-09. Dormant for about six years.
- Tools 5.3, zero dependencies, no platform floor declared.
- Route-based DSL. Handlers are closures (`addRoute(...) { context in }`,
  `addHandler`). Effects fire as callbacks; transitions do not return
  effect values. No parallel regions.

### albertodebortoli/Stateful

- 113 stars. Release 3.0.0 (2026-01-21); 25 commits in the last 12
  months, so actively maintained.
- Tools 6.2; the README states "Swift 6.2+". It will not build with a
  Swift 5.9 toolchain. macOS 10.15+, zero dependencies.
- `StateMachine` is an actor; every call is `await`ed. Transitions carry
  `preBlock`/`postBlock` closures — callbacks, not effects as data. No
  parallel regions.

### DenTelezhkin/Transporter

- 278 stars. Last release 3.2.0 (2019-05-27); 2 commits in the last 12
  months.
- Its `Package.swift` is a legacy pre-tools-version manifest with no
  targets (`let package = Package(name: "Transporter")` and nothing else),
  so current SPM cannot resolve it. Distribution was CocoaPods/Carthage.
- Closure-based callbacks on states and events (README feature list). No
  effects as data. No parallel regions.

### gistya/SwiftXState

- The real XState port (the ticket's "XState-Swift ports";
  [vijaysharm/SwiftXState](https://github.com/vijaysharm/SwiftXState) is a
  1-star experiment from 2023). 15 stars, one maintainer, 41 commits in
  the last 12 months. Release 1.1.0 (2026-06-22); the 2.x line is alpha
  (latest tag `2.0.0-alpha.15`).
- Tools 6.1, so it needs a Swift 6.1+ toolchain (Xcode 16.3+). Platforms:
  macOS 14+, which matches EyeBreak. Runtime dependency footprint: only
  the swift-docc-plugin (documentation build).
- Parallel regions: yes. The README parity table lists "State types
  (atomic, compound, parallel, final, history)" and "Parallel regions +
  multi-target transitions" at parity with XState.js.
- Effects as data: yes. A pure `transition()` path computes the next
  configuration without running side effects; actions are part of the
  machine definition and the interpreter runs them.
- Testing without AppKit: model-based path testing (`TestModel`,
  `getShortestPaths`, `validate` for dead-end/unreachable states) and a
  `SimulatedClock` for deterministic delays (README).
- Risk facts: alpha 2.x, small user base, single maintainer.

### serhiybutz/HSM

- 12 stars. No GitHub releases; latest tag 0.12.0. Last commit
  2022-11-02. The README calls it "under development and subject to
  change" and lists open TODOs about run-to-completion under concurrency.
- Tools 5.1, macOS 10.12+, zero dependencies.
- UML statecharts with hierarchy and orthogonal regions (README feature
  list) — the only dormant candidate with true parallel regions.
- Actions are entry/exit/transition handlers (closures), not returned
  effect values.

### sideeffect-io/AsyncStateMachine

- 60 stars. Single release 0.1.0 (2022-08-22); no commits since.
- Tools 5.6, macOS 10.15+. One dependency: xctest-dynamic-overlay.
- Effects as data: yes, by design. The DSL keeps transitions pure; they
  produce declared `output` values, and a separate `Runtime` maps outputs
  to `async` side-effect functions. README: "State machines are built in
  complete isolation: tests dont require mocks."
- Flat states per machine; no parallel regions.
- Built entirely on Swift concurrency (`await send(_:)`, `Task`-based
  effects). EyeBreak drives its pipeline with Combine today.

### couchdeveloper/Oak

- 8 stars, one maintainer, but active (pushed 2026-04-04). No GitHub
  releases. README: "actively developed and evolving … stable core API."
- Tools 6.2 (needs a Swift 6.2 toolchain), macOS 12+. Dependencies:
  swift-async-algorithms, swift-mutex, swift-docc-plugin.
- A finite state transducer: the pure update returns the new state plus
  an `Effect` value; effect implementations get dependencies via an
  environment (`EffectTransducer` example in the README). Closest external
  match to `reduce(state, event) -> (state, [Effect])`.
- The README claims no parallel-region concept; concurrent causes would
  be extended state, as in a hand-rolled machine.

### square/workflow-swift

- 369 stars, maintained by Square. Release v6.0.1 (2026-08-25); 13
  commits in the last 12 months.
- Tools 5.9 and macOS 12+ — the most compatible actively-released option
  with EyeBreak's stated toolchain.
- The core `Workflow` target depends only on IssueReporting (from
  xctest-dynamic-overlay). The ReactiveSwift, RxSwift, swift-syntax,
  case-paths, and identified-collections dependencies in the manifest
  belong to the UI and testing targets.
- Model: a `WorkflowAction.apply` mutates state and returns an optional
  output; ongoing side effects are `Worker`s declared during `render` —
  declared as data, executed by the runtime. Concurrency comes from
  composing child workflows rather than parallel regions.
- Testing: a dedicated `WorkflowTesting` product; core needs no AppKit.
- It is a full UI architecture (render trees, workers, hosts), not a
  standalone FSM; the concept count is much larger than one machine needs.

### The Composable Architecture (one reducer only)

- 14,886 stars. Release 1.26.1 (2026-07-21); 100+ commits in the last 12
  months. The most active project surveyed.
- Current manifest: tools 6.1, macOS 13+. Building the latest release
  needs a Swift 6.1 toolchain (Xcode 16.3+); the app itself can stay in
  Swift 5 language mode. Older 1.x releases built with 5.9.
- Effects as data: yes — `reduce(into: &state, action) -> Effect<Action>`;
  the store executes `Effect` values. This is the pattern the ticket's
  hand-rolled sketch copies.
- Parallel regions: none as a first-class concept; state is a struct, so
  a `Set` of suspension causes is plain data — identical to hand-rolling.
- Testing without AppKit: `TestStore` with exhaustive assertions and
  swift-clocks for deterministic time.
- Cost for one machine: 12 direct package dependencies (swift-collections,
  combine-schedulers, case-paths, clocks, concurrency-extras, custom-dump,
  dependencies, identified-collections, navigation, perception, sharing,
  xctest-dynamic-overlay) plus swift-syntax for macros, which dominates
  first-build time. Sparkle would stop being the only dependency by a
  wide margin, and the API surface (Store, `@Reducer` macro, dependency
  injection system) far exceeds one small machine.

### Apple GameplayKit `GKStateMachine` (built in, for reference)

- Ships with macOS since 10.11 as part of GameplayKit
  ([Apple docs](https://developer.apple.com/documentation/gameplaykit/gkstatemachine)).
  Zero package dependencies.
- States are `GKState` subclasses. Transitions happen by calling
  `enter(_:)` with a state class, gated by `isValidNextState`. Behavior
  lives in `didEnter`/`willExit` callbacks. No event type, no effects as
  data, no parallel regions.
- Unit-testable without AppKit (GameplayKit imports without UI).

### Dormant Elm-style libraries (noted, not surveyed in depth)

[inamiy/Harvest](https://github.com/inamiy/Harvest) (Combine + state
machine, effects as data, **archived**, last commit 2021-12) and its
siblings RxAutomaton and ReactiveAutomaton (last commits 2021) follow the
reducer-with-effects pattern but have been unmaintained for five years.

### drseg/swift-fsm (found in search, disqualified by platform floor)

27 stars, release 0.9.6 (2025-02-09), pushed 2026-04-20. Requires
**macOS 15+** and Swift 6 (README), above EyeBreak's macOS 14 floor.
Actions are callback functions, not effect values.

## Cost of the hand-rolled reducer

For comparison, the sketch in #26 — `reduce(state, event) -> (state,
[Effect])` — costs roughly:

- **Code**: a `Phase` enum (about 5 cases, close to today's
  `TimerState`), a state struct adding `suspensions: Set<SuspensionCause>`,
  an `Event` enum, an `Effect` enum, and one pure function. An estimated
  150–300 lines of pure Swift, plus about 100 lines of manager glue to
  execute effects. `BreakTimerManager.swift` already spends 440 lines
  doing this ad hoc with interleaved AppKit calls.
- **Parallel regions**: free. A `Set` of suspension causes is plain data
  in the state struct; every library above without true parallel regions
  (all but SwiftXState and HSM) would model it the same way.
- **Effects as data**: holds by construction; nothing to adapt.
- **Toolchain and dependencies**: zero new dependencies, no toolchain
  floor, no version risk, no learning curve beyond the pattern itself.
- **What is given up**: DSL-level guarantees the statechart tools provide
  — declarative transition tables, unreachable-state and dead-end checks,
  model-based path testing, and visualization (SwiftXState offers all
  four). Transition coverage becomes the team's own test discipline, in
  the style of the existing `EyeBreakTests/TimerStateTests.swift`.

## Sources

Every claim above cites the linked repository's `Package.swift`, README,
or GitHub API release/commit data, retrieved 2026-08-26. Search coverage:
GitHub repository search for `state machine`, `statechart`, `xstate`, and
`hierarchical state machine` (language:Swift) plus the
[state-machine Swift topic](https://github.com/topics/state-machine?l=swift),
sorted by stars. The Swift Package Index search was unreachable
(Cloudflare 403 / API requires auth), so GitHub search stands in for it.
