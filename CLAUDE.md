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
| Verify, land it | `tilly-ship` | Sonnet |

The boundary sits between deciding and executing, and **everything on the deciding side
produces a written artifact**. That is the point: by the time work reaches `tilly-build`,
the decisions are made, reviewed, and on disk — so execution needs none.

A step spec that leaves a decision open doesn't remove that decision; it relocates it to
the model with the least context and no way to ask first.

### Switching between them

Two ways to move, and the choice matters for cost.

**Start a fresh session** when beginning a distinct piece of work — executing a plan,
opening a new feature. The written artifacts are what make a cold start cheap: a plan holds
everything `tilly-build` needs, so carrying an earlier conversation adds cost without adding
context. Pick the model at the start and point the session at the plan.

**Switch model in place** for short hops inside a working session. Mid-implementation, a
question surfaces that the plan doesn't settle — switch to Opus, decide it, record it,
switch back. Here the conversation *is* the context, and starting fresh would lose it.

The rule of thumb: if the next stretch of work would need the last hour of conversation
explained to it, stay in the session and switch models. If a document already explains it
better than the conversation would, start fresh.

Long sessions are the trap. A session that has done briefing, exploring and planning is
carrying context that implementation doesn't need, and every turn pays for it. When the
deciding is done and written down, that is the moment to start fresh rather than switch.

### Say when to switch — don't wait to be asked

Jake should not have to judge this himself. Call it at the transition points, in one line,
without being prompted:

- **A skill's model doesn't match the active one** — say so before proceeding, rather than
  silently running on whatever is loaded.
- **Deciding work is finished and written down** — say the artifact is ready and that a
  fresh session on the execution model is now cheaper than continuing here.
- **Implementation hits something the plan doesn't settle** — name it as a decision rather
  than a detail, and say it wants Opus.
- **A long session is about to change activity** — flag it before starting, not after.

One line is enough. "Plan's written — cheaper to start fresh in Sonnet from here" beats a
paragraph of reasoning, and beats saying nothing.

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

**Tilly is GPL-3.0 with an App Store exception.** The exception is only effective when
granted by every copyright holder, and Tilly currently has one. If outside contributions are
ever accepted, flag that the exception needs re-granting rather than merging quietly.

**The repo is public; the conversation isn't.** Personal context drives decisions but does
not get written into tracked files. Record what a decision *implies for the product*, stated
generally, and leave out the personal circumstance that prompted it. A sentence beginning
"plenty of people…" is usually right; the same sentence naming Jake and his situation is
usually not.

This covers income and its timing, specific bills and amounts, living situation, employer,
health, and family. Referring to Jake as the person who decides things — "ask Jake", "wait
for Jake's choice" — is fine; disclosing facts about his life is not.

Note that an example of a banned disclosure is itself a disclosure. Don't illustrate this
rule with the real detail.

**Ask before every commit and push.** Publishing to a public repo is not reversible. Say
what will be committed and what the message will be, then wait. This applies to every push,
not just the first one in a session.

## Code

- Swift 6, SwiftUI, SwiftData. iOS 26 deployment target. No third-party dependencies.
- **Swift Testing** (`@Test`, `#expect`), not XCTest.
- SwiftData models stay CloudKit-compatible: properties optional or defaulted, no unique
  constraints, relationships optional. Sync is off in v1; the schema is ready for it.
- Keep files focused. Dime's `InsightsView.swift` is 98KB in one file — the standing
  cautionary example. A file growing past a few hundred lines usually means it's doing too
  much.
- New `.swift` files appear in the app project automatically (file-system synchronized
  groups) — adding, moving, or removing source files must never touch `.pbxproj`. Build
  settings in the project file are ordinary work: fix one that's wrong, or add one that's
  missing, without treating the file as frozen. Files in `Core/Sources/` are picked up by
  SPM with no registration at all.

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

Both green before anything lands on `main`. For UI work, also build and launch in the
Simulator, screenshot, and check dark mode and Dynamic Type at accessibility sizes before
calling it done.

## Commits

Present tense, lowercase, always scoped: `engine: clamp month-end without sticking`.

**Branch for a piece of work; commit small certain things straight to `main`.** A branch buys
optionality — the ability to abandon work rather than unpick it — so it earns its place
whenever there's a brief or plan behind the work, and especially for exploration that may be
thrown away. A decision entry, a docs fix or a typo doesn't need one.

Land a branch with `git merge --no-ff` and delete it. The merge commit marks that a piece of
work landed, which is the same narrative the commit messages are for.

**No pull requests.** The review that matters happens in conversation before each commit, and
`docs/` explains the work better than a PR description would. A PR here would be a formality
approved without being read.

*Revisit when either of two things is true:* there's CI to run against a PR, or an outside
contribution arrives — which is already the moment the GPL App Store exception needs
re-granting. Same trigger, two reasons.

*A staging branch is not needed yet either.* It would integrate parallel work or soak changes
before a release, and neither exists — work is sequential and `main` isn't released anywhere.
The trigger there is the first TestFlight build, when "what people have" and "what's coming"
stop being the same thing.

**The scope comes from a fixed set** — `engine:`, `app:`, `design:`, `docs:`, `meta:`. Having
a closed list matters more than which five words; it is what stops the log reading as a pile
of unrelated changes. `meta:` covers the workflow itself — skills, this file, tooling.

**Write the body in plain English.** The subject line can carry a type name if that's
genuinely the clearest way to say it, but everything below it is prose for someone who wasn't
in the session and doesn't want to read the diff to find out what happened.

The test: describe the bug as the person using the app would have hit it, before naming
anything in the code. "Move a bill to a later date and it disappears from the month it
actually happened in" — then, if it helps, which function was at fault. A description that
opens with a function signature has buried the point.

This is not dumbing down. A change nobody can restate in a sentence is usually a change
that hasn't been understood yet, including by whoever wrote it. Specifics stay: exact test
counts, real output, what was deliberately left out and why.

Jargon that earns its place is fine — `anchorDate` is the clearest name for the thing it
names. Jargon standing in for an explanation is not.

### Link the work to what drove it

When a commit belongs to a brief or a plan, name it in a trailer, alongside `Co-Authored-By`:

```
Plan: docs/plans/app-scaffolding.md
Brief: docs/briefs/timeline/brief.md
Co-Authored-By: ...
```

Keep them in the **same block** as `Co-Authored-By`, with no blank line between. Git only
parses the last contiguous paragraph as trailers, so a blank line above them turns them back
into ordinary body text — searchable, but invisible to anything that reads trailers properly.

This is not decoration. It makes the history queryable — `git log --grep="briefs/timeline"`
returns every commit belonging to the timeline, months later, without anyone having
remembered to keep a list. Whether to include it is a fact about the work rather than a
judgement call: if a brief or plan exists, link it.

### Open the body with what is now true

The first line of the body says what changed *about the project*, not what changed in the
files. "Tilly is an app you can launch now" rather than "creates the Xcode project and app
target". The diff already says what changed; only a person can say what it meant.

*Test:* read that line alone. Could someone tell whether the project moved forward, without
knowing what a target or a model is?

This is the part that carries the value and the part that rots first. The guard is
specificity — "Tilly is an app you can launch now" passes; "improves the project's
foundations" is the same sentence with the content removed.

### Match the ceremony to the change

Not every commit deserves the full apparatus, and forcing one produces padding that makes the
history *harder* to read, not easier. The scope is always required — it costs one word. The
trailers follow from whether a brief or plan exists. The body is what scales:

| Change | Body |
|---|---|
| Typo, formatting, a rename, a one-line correction | None. The subject already says it. |
| Small change whose reason isn't obvious from the diff | A sentence or two on why. |
| Anything that changes what the app does, what it can be trusted to do, or how it is built | The full treatment — what is now true, the reasoning, what was deliberately left out. |

*Test for whether a body is needed at all:* someone reading the log in six months, trying to
understand how Tilly got here — are they worse off without it? If not, leave it out.

### Expect these conventions to change

Workflow, style and approach on this project are deliberately not fixed. When a convention
here stops fitting the work, say so and propose the revision rather than following it past
its usefulness. A rule that has to be worked around is a rule that needs rewriting.
