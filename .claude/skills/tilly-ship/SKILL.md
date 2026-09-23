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

1. Confirm the direction was actually approved — check the brief and the conversation. If
   neither shows Jake agreed to it, stop and ask rather than assuming.
2. Branch from `main` if the work isn't already on one. Name it for the work: `timeline`,
   `occurrence-overrides`.

## Verification — run these, report actual output

```
xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0' test
```

Report what it printed. Never "should pass", never "tests look fine". If anything fails, fix
and re-run before merging. Nothing lands on `main` red.

For UI work, also: build, launch, screenshot each changed screen, and show Jake those
screenshots before merging.

## Self-review — technical

**Run the checks in `CLAUDE.md`** — Hard rules, Code, Verification. They are not restated
here, deliberately; see the note in `tilly-build`. Report what you actually found, per check,
not "all clear".

Only these three are not in `CLAUDE.md` and belong to shipping:

- [ ] VoiceOver labels on any new interactive element, and a hint where the action is not
      obvious from the label.
- [ ] Tests cover the awkward cases, not just the happy path.
- [ ] If the diff conflicts with a doc, ask Jake which is right, then update the doc in this
      change. Don't narrate the difference.

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
- What changed and why, and which brief it implements
- Screenshots for any UI work — before and after where there's a before
- Anything deliberately left out, and why

Ask before merging and before pushing. Both, every time.

## After merging

1. **Promote durable learnings**, each to its one right home. Rewrite in place; don't append.
   - A standing visual or interaction rule → `docs/DESIGN.md`, present tense, no backstory
   - A choice that is costly to reverse, or will be reopened with a tempting loser →
     `docs/DECISIONS.md`, replacing any entry it changes
   - A tuning value → a comment beside the token or constant, not a doc
   - The plan's `## Lessons` → `.claude/rules/<topic>.md`, path-scoped; then delete the plan
   - Something learned about what works on this kind of surface → `docs/INSPIRATION.md`
   - Scope that shifted → `docs/ROADMAP.md`, silently
   - A workflow change → the skill or `CLAUDE.md` line itself, with the why in a `meta:` commit
   - Anything else → nowhere. It's in git.
2. Delete the merged branch, local and remote.
3. Run `scripts/doc-budget.sh`. If a feature landed rather than a fix, or the budget fails,
   suggest `tilly-prune` in one line.

Only promote things likely to recur. `docs/TASTE.md` is never edited here — that's
`tilly-prune`'s job, with Jake's approval.

## Hard constraints

- **Never merge on failing tests or a failing build.**
- **Never claim verification you didn't run.** Paste the output.
- **Never skip the tenet half of the review** because the technical half passed. A change
  can be perfectly correct Swift and still be wrong for this app.
- **Never merge without promoting learnings.** That step is why there's no separate
  close-out skill — it would just get forgotten.
