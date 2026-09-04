---
name: tilly-brief
description: Use when starting, scoping, or writing a brief for a piece of Tilly work — a new feature, a change to an existing flow, or design context before implementation. Triggers on "brief for X", "let's scope this", "what are we actually building here", or beginning work on a named feature. Not for bug fixes or small mechanical edits.
---

# tilly-brief

## Model

**Opus.** A brief is judgement throughout: deciding what's genuinely unanswerable versus
inferable, deciding whether something is in scope, deciding whether a stated want is the
actual need. If Sonnet is active when this triggers, say so first: "This is brief work —
worth switching to Opus?" Don't silently run it on whatever happens to be loaded.

## Overview

Produces one text-only brief before any wireframe or code. The job is routing and
determinism, not originality — go to the known sources in a fixed order, write to a fixed
path, never silently overwrite.

A brief can scope a whole feature or a single change. It does not have to be a project.

## Fixed lookup order (before asking Jake anything)

1. **`docs/PROJECT.md`** — read in full. The tenets are the frame for everything that
   follows. Do not ask what this already answers.
2. **`docs/ROADMAP.md`** — is this already scheduled? Is it explicitly deferred, and if so
   does the stated reason still hold? A brief for something the roadmap defers must say
   why that's changing.
3. **`docs/DECISIONS.md`** — has this been decided before? A brief that reopens a settled
   decision must name the entry and say what new information justifies revisiting it.
4. **`docs/INSPIRATION.md`** — is there existing evidence about this surface? Usually yes
   for anything touching the timeline or the editor.
5. **`docs/briefs/`** — list it. If a brief for this topic exists, go to "Existing brief"
   below instead of starting fresh.
6. **`git log`** on the relevant files — `git log --oneline -- <path>`. Prior attempts and
   reverts are findings, not trivia. Surface them prominently.
7. **Only now**, ask Jake what survives. Usually 3-6 questions, one at a time. Never ask
   what a source already answered.

Stop once these are exhausted. Don't keep pulling threads — a brief is allowed open
questions.

## Output

```
docs/briefs/<slug>/brief.md
```

`<slug>` is the kebab-case topic (`timeline`, `occurrence-overrides`). Nothing else, ever.

### If a brief already exists there

Never silently overwrite. Read it, then:

- Nothing material changed → say so and stop. Don't rewrite for its own sake.
- New information → append a dated entry under `## Updates`. The history is useful.
- Jake explicitly asks to redo it → the one case you overwrite, and even then keep the
  "Prior attempts" content.

## Structure

```markdown
# <Title>

## Problem
[with evidence — a real friction, a screen that fails, a tenet being violated]

## Which tenets are at stake
[name them from PROJECT.md; a brief that touches none is suspect]

## Why now
[what makes this the moment]

## What "better" looks like
[3-6 concrete criteria, not vibes]

## Prior attempts
[anything tried before on this surface, and what happened]

## Constraints
[technical, data, scope — what will actually shape the design]

## We'll know it worked when
[measurable if possible; say explicitly if it isn't and why]

## In and out
[explicit scope boundary — most work fails by not having one]

## Open questions
[what the lookup order couldn't answer — these gate exploration, don't bury them]

## Sources
[files read, commits, decisions referenced — so this is checkable]
```

## Next

`tilly-explore` if the work needs design decisions. `tilly-plan` directly if it doesn't —
engine and logic work usually goes straight there.

## Hard constraints

- **Text only.** No wireframes, no code, no screens. That's `tilly-explore`.
- **Don't create `DECISIONS.md` entries from a brief.** A brief raises questions; it
  doesn't settle them. Decisions get recorded when they're actually made.
- **Don't restate the tenets.** Reference them. They live in `PROJECT.md` and duplicating
  them means they drift.
- **An empty answer is a finding.** If the roadmap defers this and nobody remembers why,
  say that plainly rather than inventing a rationale.
