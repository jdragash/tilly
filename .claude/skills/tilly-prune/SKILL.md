---
name: tilly-prune
description: Use to distill Tilly's docs so they stay small, current and sharp — after a feature ships, when scripts/doc-budget.sh fails, when Jake says "prune", "tidy the docs", "the docs are bloated" or "clean up the docs", or when a session notices a doc contradicting what the app or Jake now says. Promotes repeated corrections into TASTE.md, moves plan lessons into .claude/rules, collapses superseded state, and deletes what git already keeps.
---

# tilly-prune

## Model

**Opus.** This is judgement throughout: what generalises, what's a one-off, what can be
forgotten. If Sonnet is active when this triggers, say so before proceeding.

## Why this exists

Unbounded docs don't distill; they sediment. Knowledge here compounds by moving *upward* —
corrections into principles, plan lessons into path-scoped rules — and by being deleted from the
layer below once it has moved. Git keeps every version, so forgetting costs nothing and a budget
is what forces the consolidation.

| Layer | Where | Rule |
|---|---|---|
| Events | git history | Permanent, the only append-only record |
| State | `PROJECT`, `DESIGN`, `DECISIONS`, `ROADMAP`, `.claude/rules/` | Rewritten in place |
| Taste | `docs/TASTE.md` | Small, slow, distilled from repeated evidence |
| Raw corrections | auto memory (private, outside the repo) | Promoted once a pattern repeats |

## Steps

### 1. Measure

Run `scripts/doc-budget.sh` and report the output as printed. Note total size too:
`cat docs/*.md CLAUDE.md | wc -c`.

### 2. Harvest corrections

Read this project's auto memory. Look for places Jake overrode a proposal — proposed, chosen,
why.

- **Two or more pointing the same way** → draft a TASTE principle, or sharpen an existing one.
  One line, one Tilly example, stated generally.
- **A principle Jake's recent choices contradict** → flag it for rewording or removal. Taste
  moves; the file must not fossilise the version of Jake from the project's first month.
- **One correction alone** → leave it in memory. It's an anecdote until something repeats it.

Once a correction has been promoted, update or remove its memory so it isn't counted twice.

### 3. Harvest plans

For each plan in `docs/plans/` whose work has merged to `main`: move its `## Lessons` into
`.claude/rules/<topic>.md` (path-scoped with `paths:` frontmatter, ≤ 60 lines per file), repoint
any code comments that cite the plan, then delete the plan. Its `Plan:` trailers still resolve
through `git log`.

### 4. Collapse state

- `DECISIONS.md`: replace superseded content in place; remove history and "why this changed".
- `DESIGN.md`: remove backstory — "once", "was", "originally", justifying cross-references.
- `ROADMAP.md`: status cells to one line; no dated narrative.
- Anything said in two files keeps only its single right home. Fix the pointers to it.

Check each doc against the code and against what Jake has said since it was written. Where they
disagree and it isn't obvious which is right, ask.

### 5. Demote

- Tuning values → a comment beside the token or constant, unless a user would notice them wrong.
- `DECISIONS.md` entries that no longer meet the bar — costly to reverse, or likely to be
  reopened with a rejected option that still looks tempting → delete, or move the rule to
  `DESIGN.md`.
- Workflow detail that has crept into docs → the skill or `CLAUDE.md` line it belongs to.

### 6. Report, before committing

- What was **promoted**, **demoted** and **deleted**, one line of reason each.
- Every `TASTE.md` change **quoted in full**, with its evidence, for Jake to approve. His wording
  wins.
- Budgets before and after, from the script, and total size before and after.

### 7. Commit, asking first

The standard rule: say what will be committed and the message, and wait. Scope `docs:` or
`meta:`. The body opens with what is now true about the knowledge base, and carries the evidence
behind any TASTE change, since the file itself doesn't.

## Hard constraints

- **Never invent a TASTE principle from a single data point.**
- **Never add personal circumstance to a tracked file.** Principles are stated generally.
- **Never delete a still-binding statement without giving it a new home.**
- **Never soften a principle to cover a contradiction.** Reword it or remove it.
- **Never edit `PROJECT.md` tenets or `CLAUDE.md` hard rules** without Jake saying so explicitly.
- **Consolidate, don't trim.** When over budget, merge and sharpen; shaving words to fit is the
  failure the budget exists to prevent.
