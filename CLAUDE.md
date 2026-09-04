# Working on Tilly

A personal iOS app for recurring-expense visibility, and a deliberate exercise in learning
iOS development. Read `docs/PROJECT.md` before making product judgements.

## Docs contract

| File | Holds | Changes |
|---|---|---|
| `docs/PROJECT.md` | What the app is and why. Tenets. | Rarely |
| `docs/ROADMAP.md` | What's next, in order, with reasons for deferral | Often |
| `docs/DESIGN.md` | Visual language, state grammar, copy and interaction rules | As decisions land |
| `docs/DECISIONS.md` | Dated log: chosen, rejected, and *why each rejection lost* | Append only |
| `docs/INSPIRATION.md` | Annotated Dime / competitor analysis — the evidence base | As things are learned |
| `docs/briefs/<slug>/brief.md` | Per-feature or per-change briefs | Per piece of work |
| `docs/plans/<slug>.md` | Implementation plans — ordered step specs | Per piece of work |

Never delete from `DECISIONS.md`. Superseding an entry means adding a new one that says
what changed and why, not editing history.

## Model routing

| Work | Skill | Model |
|---|---|---|
| Scope a change | `tilly-brief` | Opus |
| Settle the design | `tilly-explore` | Opus |
| Specify the implementation | `tilly-plan` | Opus |
| Implement it | `tilly-build` | Sonnet |
| Verify, PR, merge | `tilly-ship` | Sonnet |

The boundary sits between deciding and executing, and **everything on the deciding side
produces a written artifact**. That is the point: by the time work reaches `tilly-build`,
the decisions are made, reviewed, and on disk — so execution needs none.

A step spec that leaves a decision open doesn't remove that decision; it relocates it to
the model with the least context and no way to ask first.

If a skill's model doesn't match the active one, say so before proceeding rather than
silently running on whatever is loaded.

**When a spec is wrong, stop.** Plans are written before the code exists, so some steps will
be mistaken. Report it rather than improvising — that escape hatch is what keeps detailed
specs safe.

## Hard rules

**Never copy from Dime.** `rafsoh/dimeApp` is read for patterns and reasoning only. No
code, no assets, no strings. Every line in this repo is original work — that is the point
of the project, independent of licensing.

**`Core/` is a separate Swift package (`TillyCore`) and must not import SwiftData.** The
recurrence engine is pure logic over `Calendar`. The package boundary makes that a compile
error rather than a convention, and lets the engine be tested against a pinned calendar and
timezone in about a second. If a change seems to need SwiftData in `Core/`, the change is in
the wrong layer.

**Views reference `Tokens`, never raw values.** No literal hex, no literal point sizes, no
bare `.largeTitle`. See `docs/DESIGN.md` for why.

**Dates go through `Calendar` components, never `TimeInterval`.** Adding 86,400 seconds is
wrong twice a year. Recurrence generates from the rule's anchor, never from the previous
occurrence — that's Dime's live drift bug and `docs/DECISIONS.md` explains it.

**Tilly is MIT; Dime is GPL-3.0.** These are incompatible in one direction — GPL code
cannot enter an MIT project without relicensing everything. This makes the no-copying rule
above load-bearing, not just a preference.

## Code

- Swift 6, SwiftUI, SwiftData. iOS 26 deployment target. No third-party dependencies.
- **Swift Testing** (`@Test`, `#expect`), not XCTest.
- SwiftData models stay CloudKit-compatible: properties optional or defaulted, no unique
  constraints, relationships optional. Sync is off in v1; the schema is ready for it.
- Keep files focused. Dime's `InsightsView.swift` is 98KB in one file — the standing
  cautionary example. A file growing past a few hundred lines usually means it's doing too
  much.
- New `.swift` files appear in the app project automatically (file-system synchronized
  groups). Don't hand-edit `.pbxproj`. Files in `Core/Sources/` are picked up by SPM with
  no registration at all.

## Verification

Report actual output, never "should pass".

Engine work — fast, no simulator:

```
cd Core && swift test
```

App work:

```
xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Both green before any PR. For UI work, also build and launch in the Simulator, screenshot,
and check dark mode and Dynamic Type at accessibility sizes before calling it done.

## Commits

Present tense, lowercase, scoped: `engine: clamp month-end without sticking`. Branch per
piece of work; PR into `main`.
