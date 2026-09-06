---
name: tilly-ship
description: Use when Tilly work is complete and ready to land on main — "ship this", "let's land this", "this is done". Runs verification, a technical and product-tenet self-review, then merges and promotes what was learned back into the docs.
---

# tilly-ship

## Model

**Sonnet.** Verification and the checklist are execution against a fixed list. The one
judgement call is the final step — deciding what's genuinely durable enough to promote into
`DESIGN.md`. If that's ambiguous, ask Jake rather than guessing.

## Before starting

1. Confirm the direction was actually approved — check `docs/DECISIONS.md` for this work.
   If there's no recorded decision, stop and ask rather than assuming.
2. Branch from `main` if the work isn't already on one. Name it for the work: `timeline`,
   `occurrence-overrides`.

## Verification — run these, report actual output

```
xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Report what it printed. Never "should pass", never "tests look fine". If anything fails, fix
and re-run before merging. Nothing lands on `main` red.

For UI work, also: build, launch, screenshot each changed screen, and show Jake those
screenshots before merging.

## Self-review — technical

- [ ] No hardcoded hex or point values. Views reference `Tokens` only.
- [ ] `Core/` imports no SwiftData.
- [ ] Date arithmetic through `Calendar` components, never `TimeInterval`.
- [ ] Recurrence generates from the anchor, never from the previous occurrence.
- [ ] SwiftData models still CloudKit-compatible — properties optional or defaulted, no
      unique constraints, relationships optional.
- [ ] VoiceOver labels on new interactive elements.
- [ ] Dynamic Type checked at an accessibility size.
- [ ] Dark mode checked.
- [ ] No file has grown past a few hundred lines. (Dime's 98KB `InsightsView.swift` is the
      standing example — see `docs/INSPIRATION.md`.)
- [ ] Tests cover the awkward cases, not just the happy path.

## Self-review — product tenets

This half is what makes the skill Tilly's rather than generic. Check the diff against
`docs/PROJECT.md`:

- [ ] **Tenet 1** — does anything new ask the user to confirm, tick off, or maintain
      something the app could know itself?
- [ ] **Tenet 2** — on each changed screen, can you name the most important element, and
      does the design make it unmistakable? Have boxes accumulated above the actual content?
- [ ] **Tenet 3** — does any label restate its own control? Delete it and check whether
      anything is genuinely unclear.
- [ ] **Tenet 4** — does anything require input the feature doesn't actually need? Does
      anything prescribe a category, a name, or a structure that should be the user's?
- [ ] **Tenet 5** — is anything gated, limited, counted, or upsold?

A failure here is not a nitpick. These are the reasons the app exists.

## Landing it

This is a solo project with no CI, so there is no pull request. The review that matters
already happened in conversation, before each commit. Ask Jake before merging, then:

```
git checkout main && git merge --no-ff <branch>
```

The merge commit is where the summary lives — it is the only place a reader sees the whole
piece of work at once, so write it like the commit bodies: what is now true about the
project, what was deliberately left out, and the `Brief:` / `Plan:` trailers.

Before asking, have ready:
- What changed and why, and which `docs/DECISIONS.md` entry it implements
- Screenshots for any UI work — before and after where there's a before
- Anything deliberately left out, and why

Ask before merging and before pushing. Both, every time.

## After merging

1. **Promote durable learnings.** This is the step that keeps the library alive:
   - A new standing visual or interaction rule → `docs/DESIGN.md`
   - A decision made during implementation, with what lost → `docs/DECISIONS.md`
   - Something learned about what works on this kind of surface → `docs/INSPIRATION.md`
   - Scope that shifted → `docs/ROADMAP.md`
2. Delete the merged branch, local and remote.

Only promote things likely to recur. One-off choices are noise in a standing document; if
unsure, ask Jake before elevating something to a rule.

## Hard constraints

- **Never merge on failing tests or a failing build.**
- **Never claim verification you didn't run.** Paste the output.
- **Never skip the tenet half of the review** because the technical half passed. A change
  can be perfectly correct Swift and still be wrong for this app.
- **Never merge without promoting learnings.** That step is why there's no separate
  close-out skill — it would just get forgotten.
