---
name: tilly-plan
description: Use after a Tilly brief exists and any design is approved, before implementation begins — turning agreed intent into an ordered implementation plan of step specs precise enough to execute without further decisions. Triggers on "let's plan this out", "write the implementation plan", "break this into steps", or moving from an approved design toward code.
---

# tilly-plan

## Model

**Opus.** This skill exists to concentrate the decisions here, so that execution needs none.
Every judgement call the plan fails to make becomes a judgement call made mid-implementation
by a model with less context and no ability to ask you first.

If Sonnet is active when this triggers, say so before proceeding.

## Why this exists

`tilly-explore` ends at an approved design. `tilly-build` implements. Between them sits the
work of deciding *how*: file layout, type signatures, build order, what "done" means for
each piece.

Left unwritten, those decisions get made ad hoc during implementation — invisibly, without
review, by whoever is executing. Written down, they can be checked before any code exists,
which is far cheaper than reviewing code.

The plan is also the review artifact. Jake reads the plan, not the diff, to know whether the
work is going to be right.

## Read first

- The brief at `docs/briefs/<slug>/brief.md`
- Relevant `docs/DECISIONS.md` entries — the plan must not reopen settled questions
- `docs/DESIGN.md` for anything touching UI
- `CLAUDE.md` for the standing constraints every step inherits
- The actual code being changed. Never plan against an assumed structure.

## Output

```
docs/plans/<slug>.md
```

Same slug as the brief. If a plan exists there, read it first — append a dated `## Updates`
section rather than rewriting, unless Jake asks for a fresh one.

## Structure

```markdown
# <Title> — implementation plan

**Brief:** docs/briefs/<slug>/brief.md
**Decisions:** <the DECISIONS.md entries this implements>

## Already decided — do not reopen
[Bulleted. Anything a step might otherwise be tempted to re-litigate.]

## Steps

### Step N — <imperative title>

**Files:** [exact paths, marked new or modified]

**Interface:**
```swift
// exact signatures, not descriptions of them
```

**Done when:** [specific, checkable — the tests that must pass, named]

**Verify:** [the literal command to run]

**Out of scope:** [what this step must not touch]
```

## What makes a step spec good

**Exact over descriptive.** Write the type signature; don't describe it. "A function taking
a rule and a range" leaves five decisions open. The signature leaves none.

**Named test cases, not "add tests".** For anything with logic, enumerate the cases the
step must cover, including the awkward ones. The tests are the specification.

**Independently verifiable.** Each step ends green and could be committed on its own. A step
that only makes sense alongside the next one is one step, not two.

**Right-sized.** Roughly one focused sitting. A step spanning a whole feature isn't a step;
a step changing one line usually isn't either.

**Ordered by dependency, and say so.** If step 4 needs step 2's type, note it.

**Scoped negatively too.** "Out of scope" prevents the most common failure — a step quietly
growing to cover the next one.

## The escape hatch (put this in every plan)

A plan detailed enough to remove decisions is also detailed enough to be confidently wrong.
Every plan ends with:

```markdown
## If a step is wrong

These specs were written before the code existed. If a step turns out to be
ambiguous, impossible, or wrong, **stop and say so** — don't improvise a fix and
don't silently widen the scope. A wrong spec caught in one message costs far less
than a wrong spec followed to completion.
```

This matters more than any individual step. Over-specification without an escape hatch
turns a bad guess into a confidently executed bad guess.

## Hard constraints

- **No code.** The plan contains signatures and test case names. Implementations belong to
  `tilly-build`.
- **Never plan against assumed structure.** Read the files first. A plan referencing a type
  that doesn't exist, or a path that moved, is worse than no plan.
- **Don't restate `CLAUDE.md`.** Steps inherit those constraints. Repeating them makes them
  drift; reference them instead.
- **Don't settle product or design questions here.** If a step needs a decision that
  `DECISIONS.md` doesn't record, that's a gap — go back to `tilly-brief` or `tilly-explore`
  rather than deciding it inside an implementation plan.
- **Every step names its verification command.** A step whose completion can't be checked
  isn't specified yet.
