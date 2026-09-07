---
name: tilly-explore
description: Use when a Tilly brief exists and layout or interaction directions need exploring — "let's explore options for X", "show me some directions", or moving from a brief into visual iteration. Not for small tweaks to already-built UI; that's direct editing via tilly-build.
---

# tilly-explore

## Model

**Opus, throughout.** Every rung of this skill is a design decision — the directions settle
structure, the canvas settles type, spacing, colour and hierarchy. None of it is mechanical
assembly. The switch to Sonnet happens when this skill *ends* and `tilly-build` begins, so
the model boundary sits on a skill boundary rather than inside one.

If Sonnet is active when this triggers, say so before proceeding.

## Overview

Turns a brief into directions Jake can look at. **The canvas is the working surface** —
variants are drawn there, compared there, and iterated there. Describing a layout in prose
and then drawing the winner once puts the argument in the weakest available medium; a design
disagreement is settled by looking, not by reading a description of what you would see.

**Prerequisite:** a brief must exist at `docs/briefs/<slug>/brief.md`. If it doesn't, stop
and run `tilly-brief` — don't improvise one inline.

## Read first

- The brief in full
- `docs/PROJECT.md` — the tenets are the evaluation criteria
- `docs/INSPIRATION.md` — the specific evidence about what works on this kind of surface
- `docs/DESIGN.md` — existing tokens, state grammar, copy rules
- `docs/DECISIONS.md` — what is already settled on this surface, so a "direction" isn't a
  re-run of something rejected months ago

## The gates (both mandatory)

Two stops, and they ask different questions. The first asks *are these the right directions
to draw*; the second asks *which drawn direction wins*. Neither substitutes for the other.

### 1. Name the directions, and wait

**Two or three directions.** For each, one or two lines: what it does differently, which
tenet it serves best, which it strains. A direction that serves no tenet is not a real
option and shouldn't be drawn.

**Then stop and show Jake.** He approves the set, cuts one, adds one, or redirects
entirely. Drawing is cheap but it isn't free, and a canvas full of directions nobody wanted
drawn is the specific waste this stop exists to prevent. It is also the last moment where
changing course costs a sentence rather than a rebuild.

Keep it short — a list of directions, not an essay per direction. The argument gets made on
the canvas, where it can be seen. The old version of this skill drew ASCII wireframes here;
`DECISIONS.md` records why that went and why this stop stayed.

### 2. Build one canvas

Use `/design`. Every named direction as artboards on a **single** canvas — real type scale,
real spacing, real colour, real content. Not lorem: actual expense names and amounts,
including the awkward cases, because those are where layouts fail.

For anything on the timeline, the awkward cases are at minimum:

- a name long enough to truncate
- a day holding more than one charge, and a day holding exactly one
- an occurrence that has been skipped
- the empty state, and the state where nothing has been charged yet
- dark mode, and an accessibility text size

Those last two are not polish. A design that hasn't been drawn at an accessibility size
hasn't been designed; it has been designed for one text size and will be found out in the
simulator, which is a far more expensive place to find it.

**Carry the argument in the canvas's own annotations**, beside the artboard it belongs to,
rather than in chat. The canvas outlives the conversation. When a question is genuinely
open, draw the honest options side by side and let the annotation say what each one costs —
a rejected option drawn next to its winner is worth more than a paragraph explaining the
rejection.

**Then stop and show Jake again.** Wait for a direction to be chosen, or for an instruction
to merge two. Do not proceed to `tilly-plan` until this happens.

### 3. Iterate in place

**One canvas per exploration, revised in place.** `/design` creates or re-seeds a canvas;
an existing one is edited in its published artifact and republished to the same URL. Don't
spawn a second canvas for a second pass — the URL is the thing Jake keeps, links to, and
hands to `tilly-plan`.

As directions get settled, keep them on the canvas as reference rather than deleting them,
on a separate page from whatever is still live. Settled-and-visible is what stops a decision
being relitigated; settled-and-deleted looks like it was never considered.

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

**Then bring the canvas into line with what was decided.** This is the step that gets
skipped. The timeline's canvas kept a `TODAY` badge on its main artboard after
`DECISIONS.md` had rejected it, and `tilly-plan` had to warn the implementer that the
approved-looking reference was wrong in a specific place. Either update the artboard or
annotate it as superseded — a canvas that disagrees with the decisions log is worse than no
canvas, because it looks authoritative.

## Next

An approved design goes to **`tilly-plan`**, not straight to `tilly-build`. The plan turns
the design into ordered step specs while there's still Opus context to make those decisions
well.

If the exploration revised a plan that already exists, say so: unexecuted steps get
rewritten in place, and steps whose code has already landed get a dated `## Updates` entry
instead.

## Hard constraints

- **No code.** This skill ends at an approved design. `tilly-plan` specifies it and
  `tilly-build` implements it.
- **Never draw before the directions are approved.** Both gates are stops. Announcing what
  you are about to draw and then drawing it in the same breath is skipping the first one.
- **Two or three directions, not five.** The constraint is what forces each one to be a real
  argument rather than a permutation. If a fourth genuinely earns its place, say why.
- **Draw the states, not the happy path.** A canvas showing only the ideal case has not
  tested the design.
- **Judge against the tenets, not taste.** "This feels cleaner" is not an argument;
  "this puts the most important element at eye level, which the alternative buries" is.
- **Watch for the competitor failure mode.** If a layout is accumulating boxes above the
  actual content, that's the specific thing `docs/INSPIRATION.md` warns about. Name it.
