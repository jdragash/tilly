# Working on Tilly

A personal iOS app for recurring-expense visibility, and a deliberate exercise in learning iOS
development. Read `docs/PROJECT.md` before making product judgements.

## Authority, highest first

1. Jake's direction in the current conversation
2. `PROJECT.md` tenets
3. `TASTE.md`
4. `DESIGN.md` and `DECISIONS.md`
5. `ROADMAP.md`, a forecast rather than a contract
6. Plans, which are deleted once shipped

When Jake's direction differs from a doc, the doc is out of date: update it in the same change,
and **don't narrate the difference** in docs or commits. Tenets included: they are a starting
point, so rewrite one rather than asking. Hard rules change only when Jake says so explicitly.

**When Jake overrides a proposal, remember it.** Note in auto memory what Claude proposed, what
Jake chose, and his reason if he gave one. Never write these to tracked files. `tilly-prune`
promotes patterns into `TASTE.md`. Agreement teaches nothing; corrections are the signal.

## Docs

**Before proposing a design or product direction, read `docs/TASTE.md` and name the principle
your proposal leans on.**

| File | Holds |
|---|---|
| `docs/PROJECT.md` | What the app is and why. The tenets. |
| `docs/TASTE.md` | How choices get made. Distilled principles, ≤ 40. |
| `docs/DESIGN.md` | Current visual and interaction rules, present tense. |
| `docs/DECISIONS.md` | Costly-to-reverse choices and the tempting options that lost. Replaced in place. |
| `docs/ROADMAP.md` | What's next, and short reasons for deferral. |
| `docs/INSPIRATION.md` | Dime and competitor analysis, the evidence base. |
| `docs/briefs/<slug>/brief.md` | Scope for a piece of work. |
| `docs/plans/<slug>.md` | Implementation step specs. Lessons extracted, then deleted once shipped. |
| `docs/prototypes/<slug>.html` | Kept and dated. The docs win where they disagree. |
| `.claude/rules/*.md` | Lessons invisible to tests, loaded by file path. |

State is rewritten in place; history lives in git. `scripts/doc-budget.sh` enforces size budgets.

## Model routing

| Work | Skill | Model |
|---|---|---|
| Scope a change | `tilly-brief` | Opus |
| Settle the design | `tilly-explore` | Opus |
| Specify the implementation | `tilly-plan` | Opus |
| Implement it | `tilly-build` | Sonnet, but see below |
| Verify, land it | `tilly-ship` | Sonnet |
| Distill the docs | `tilly-prune` | Opus |

**Implementation splits by how a step proves itself.** If a green suite would still be green with
the step broken (scroll geometry, pinning, anchoring), Opus builds it; otherwise Sonnet. On such
work Sonnet's diagnosis went wide toward more machinery, costing a full Opus pass anyway.

Everything on the deciding side produces a written artifact, so execution needs no decisions.
A spec that leaves a decision open relocates it to the model with the least context.

**Switching.** Start fresh for a distinct piece of work: the artifacts make a cold start cheap.
Switch model in place for a short hop, when the conversation *is* the context. Long sessions are the trap.

**Say when to switch, in one line, unprompted:**

- when a skill's model doesn't match the active one, before proceeding
- when deciding work is finished and written down: a fresh session on the execution model is now cheaper
- when implementation hits something the plan doesn't settle: name it as a decision that wants Opus
- when a long session is about to change activity: flag it before starting

**When a spec is wrong, stop.** Report it rather than improvising.

## Hard rules

**Never copy from Dime.** `rafsoh/dimeApp` is read for patterns and reasoning only. No code, no
assets, no strings.

**`Core/` is a separate Swift package (`TillyCore`) and must not import SwiftData.** If a change
seems to need it there, the change is in the wrong layer.

**Views reference `Tokens`, never raw values.** No literal hex, point sizes, bare `.largeTitle`
or layout numbers.

**Dates go through `Calendar` components, never `TimeInterval`.** Recurrence generates from the
rule's anchor, never from the previous occurrence.

**Tilly is GPL-3.0 with an App Store exception**, effective only when every copyright holder
grants it. Flag any outside contribution as needing it re-granted.

**The repo is public; the conversation isn't.** Record what a decision implies for the product,
stated generally. Leave out the personal circumstance behind it: income and its timing, specific
bills and amounts, living situation, employer, health, family. "Ask Jake" is fine. Facts about
his life aren't, and an example of a banned disclosure is itself a disclosure.

**Ask before every commit and push.** Say what will be committed and the message, then wait.

## Code

- Swift 6, SwiftUI, SwiftData. iOS 26, iPhone and portrait only. No third-party dependencies.
- **Swift Testing** (`@Test`, `#expect`), not XCTest.
- SwiftData models stay CloudKit-compatible. More in `.claude/rules/` (views and tokens, controls, engine).
- **Building a pinned or scroll-anchored list anywhere?** Read `.claude/rules/swiftui-scrolling.md`.
- Adding, moving or removing source files never touches `.pbxproj` (synchronized groups).
  Fixing or adding a build setting there is ordinary work.

## Verification

Report actual output, never "should pass".

```
cd Core && swift test
xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0' test
```

Both green before landing on `main`. For UI work, also screenshot in the Simulator, in dark mode
and at an accessibility text size.

## Commits

Present tense, lowercase, scoped: `engine:`, `app:`, `design:`, `docs:`, `meta:` (the workflow). `engine: clamp month-end without sticking`.

**Branch for work with a brief or plan behind it**, or exploration that may be thrown away. Commit
small certain things (a docs fix, a typo) straight to `main`. Land a branch with
`git merge --no-ff` and delete it. **No pull requests** until there's CI or an outside
contribution. **No staging branch** until the first TestFlight build.

**The body is plain English, and opens with what is now true about the project.** "Tilly is an app
you can launch now", not "creates the Xcode project". Describe a bug as the person using the app
hit it, before naming code. Keep specifics: test counts, real output, what was left out and why.
*Test:* read the first line alone. Can someone tell whether the project moved forward?

| Change | Body |
|---|---|
| Typo, formatting, rename, one-line fix | None |
| Small change with a non-obvious reason | A sentence or two on why |
| Changes what the app does, can be trusted to do, or how it's built | What is now true, the reasoning, what was left out |

**Trailers link the work to what drove it.** If a brief or plan exists, name it, in the same
block as `Co-Authored-By` with no blank line between (git only parses the last paragraph):

```
Plan: docs/plans/app-scaffolding.md
Brief: docs/briefs/timeline/brief.md
Co-Authored-By: ...
```

## Expect these conventions to change

When a convention stops fitting the work, say so and propose the revision. A rule that has to be
worked around needs rewriting.
