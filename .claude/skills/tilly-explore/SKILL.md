---
name: tilly-explore
description: Use when a Tilly brief exists and layout or interaction directions need exploring — "let's explore options for X", "show me some directions", or moving from a brief into visual iteration. Not for small tweaks to already-built UI; that's direct editing via tilly-build.
---

# tilly-explore

## Model

**Opus, throughout.** Both rungs of this skill are design decisions — the wireframes settle
structure, the design canvas settles type, spacing, colour and hierarchy. Neither is
mechanical assembly. The switch to Sonnet happens when this skill *ends* and `tilly-build`
begins, so the model boundary sits on a skill boundary rather than inside one.

If Sonnet is active when this triggers, say so before proceeding.

## Overview

Turns a brief into concrete directions, cheapest artifact first. The expensive mistake this
prevents: building real screens to settle questions a wireframe answers for a fraction of
the cost.

**Prerequisite:** a brief must exist at `docs/briefs/<slug>/brief.md`. If it doesn't, stop
and run `tilly-brief` — don't improvise one inline.

## Read first

- The brief in full
- `docs/PROJECT.md` — the tenets are the evaluation criteria
- `docs/INSPIRATION.md` — the specific evidence about what works on this kind of surface
- `docs/DESIGN.md` — existing tokens, state grammar, copy rules

## The gate (mandatory)

### Rung 1 — wireframes

Emit **three** ASCII/box-drawing wireframes, roughly 15-25 lines each, plus one short
trade-off paragraph. **Under 500 output tokens for all three combined.** This budget is the
whole point; don't let it balloon into an essay per variant.

Then **stop and show Jake.** Wait for a choice, or an instruction to merge two directions.
Do not proceed until this happens.

Wireframes are weak at colour, type scale and spacing polish — don't try to represent
those. They settle layout, hierarchy, ordering, density and how things collapse, which is
most of what a design argument is actually about.

For each variant, name which tenet it serves best and which it strains. A variant that
serves none is not a real option.

### Rung 2 — design canvas

**Only the chosen direction** (plus at most one contender if Jake explicitly wants a
side-by-side). Never all three — that's the exact cost this gate exists to cut.

Use `/design` to build artboards: real type scale, real spacing, real colour, real content.
Not lorem — actual expense names and amounts, including the awkward cases (a long name, an
estimated amount, a skipped occurrence, an empty state).

Show the states, not just the happy path. For anything on the timeline that means: upcoming
and charged, estimated and known, and the empty state.

## Recording the decision

After Jake picks (or rejects everything), append to `docs/DECISIONS.md`:

```markdown
## <what was decided>

**Decided:** YYYY-MM-DD · **From:** <brief slug>

**Chosen:** <direction, one line>

**Rejected — <name>:** <why it lost>
**Rejected — <name>:** <why it lost>
```

Rejected alternatives with reasons matter as much as the winner. That's what stops the same
debate recurring.

If the exploration settled anything about the visual language — state grammar, a copy rule,
a spacing decision — also update `docs/DESIGN.md`. `DECISIONS.md` records *that* it was
decided; `DESIGN.md` records the rule itself.

## Hard constraints

- **No code.** This skill ends at an approved design. `tilly-build` implements it.
- **Never skip rung 1** because the render is already imaginable. The gate exists for
  Jake's decision-making, not as a formality.
- **Never render all three directions** "to be thorough".
- **Judge against the tenets, not taste.** "This feels cleaner" is not an argument;
  "this puts the most important element at eye level, which the alternative buries" is.
- **Watch for the competitor failure mode.** If a layout is accumulating boxes above the
  actual content, that's the specific thing `docs/INSPIRATION.md` warns about. Name it.
