---
name: tilly-explore
description: Use when a Tilly brief exists and layout or interaction directions need exploring — "let's explore options for X", "show me some directions", or moving from a brief into visual iteration. Not for small tweaks to already-built UI; that's direct editing via tilly-build.
---

# tilly-explore

## Model

**Opus, throughout.** Every rung of this skill is a design decision — the wireframes settle
structure, the canvas settles type, spacing, colour and hierarchy, the prototype settles
motion. None of it is mechanical assembly. The switch to Sonnet happens when this skill
*ends* and `tilly-build` begins, so the model boundary sits on a skill boundary rather than
inside one.

If Sonnet is active when this triggers, say so before proceeding.

## Overview

Turns a brief into concrete directions, cheapest artifact first. The expensive mistake this
prevents: drawing every direction on a canvas to settle a question a wireframe answers for
a fraction of the cost.

A wireframe can't win an argument about colour or type. It can win one about layout,
hierarchy and ordering — which is what a *direction* is at this stage. The canvas is where
the winner becomes a real design.

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

Two stops, and they ask different questions. The first asks *which direction is worth
drawing*; the second asks *whether the drawn thing is right*. Neither substitutes for the
other.

### Rung 1 — wireframes

**Two or three** ASCII/box-drawing wireframes, roughly 15-25 lines each, plus one short
trade-off paragraph. **Under 500 output tokens for all of them combined.** That budget is
the whole point; don't let it balloon into an essay per variant.

For each variant, name which tenet it serves best and which it strains. A variant that
serves none is not a real option.

Wireframes are weak at colour, type scale and spacing polish — don't try to represent
those. They settle layout, hierarchy, ordering, density and how things collapse, which is
most of what a design argument is actually about.

**Then stop and show Jake.** Wait for a choice, or an instruction to merge two directions.
Do not proceed until this happens. This is the last point where changing course costs a
sentence rather than a rebuild.

### Rung 2 — design canvas

**Only the chosen direction** (plus at most one contender if Jake explicitly wants a
side-by-side). Never all of them — that's the exact cost rung 1 exists to cut.

Use `/design` to build artboards: real type scale, real spacing, real colour, real content.
Not lorem — actual expense names and amounts, including the awkward cases, because those
are where layouts fail.

For anything on the timeline, the awkward cases are at minimum:

- a name long enough to truncate
- a day holding more than one charge, and a day holding exactly one
- an occurrence that has been skipped
- upcoming and charged, estimated and known
- the empty state, and the state where nothing has been charged yet
- dark mode

Dark mode is not polish. Contrast and weight are the whole design argument on this surface,
and both change when the ground goes dark — so a direction drawn only in light has been
half drawn, and the other half gets found out in the simulator.

**Carry the argument in the canvas's own annotations**, beside the artboard it belongs to,
rather than in chat. The canvas outlives the conversation. When a question is genuinely
open, draw the honest options side by side and let the annotation say what each one costs —
a rejected option drawn next to its winner is worth more than a paragraph explaining the
rejection.

**Then stop and show Jake again.** Wait for approval, or for the changes he wants. Do not
proceed to `tilly-plan` until this happens.

### Rung 3 — a working prototype, when the question is motion

**Conditional.** Most explorations stop at the canvas. This rung exists for the cases where
the thing being decided is *what happens over time* rather than what sits where.

**The trigger is in the argument.** If describing a direction needs the words "as you
scroll", "when you open", "hands off to", "closes again", "returns you to" — that direction
cannot be settled by a still image, and drawing more artboards will not fix it. Three
frames of a sequence are three still images of a thing whose whole nature is that it moves.

**The form.** One self-contained HTML file, no libraries, no build step, no server — it
must open by double-clicking. Match the real dimensions and the real token values so it
reads as the app rather than as a diagram.

**Put the variants on controls, not in separate files.** The point is flipping between them
mid-interaction, at the same scroll position, without losing your place. Same for
appearance: light and dark are a toggle.

**Give it a control for whatever the design actually depends on.** This is the part that
earns the rung. The timeline's header turned on two quantities — where "today" falls in the
month, and how many things someone has recurring — and a slider for each was worth more
than any artboard, because it let Jake find the *boundary* rather than be shown one point
on one side of it.

**Say what it lies about, in the prototype itself.** A browser has no rubber-band
overscroll, no Liquid Glass, no Dynamic Type, and no momentum that feels like iOS. Put that
list on the page next to the controls, not only in chat, so the prototype cannot be
mistaken for a promise about how the built thing will feel.

**It is throwaway.** Untracked, outside `docs/`, deleted when the decision lands. What
survives is the `DECISIONS.md` entry — a prototype kept around goes stale the same way a
canvas does, and it looks even more authoritative because it runs.

**Expect it to find things.** The timeline's prototype established that a month of eleven
recurring expenses is one screenful, so the header barely pins and an opened month can
never scroll far enough out of view to close itself again. That is a fact about the design
that three artboards, a canvas and a written plan had all missed, and it surfaced in about
twenty minutes.

### Rung 4 — iterate in place

**One canvas per exploration, revised in place.** `/design` creates or re-seeds a canvas;
an existing one is edited in its published artifact and republished to the same URL. Don't
spawn a second canvas for a second pass — the URL is the thing Jake keeps, links to, and
hands to `tilly-plan`.

As parts get settled, keep them on the canvas as reference rather than deleting them, on a
separate page from whatever is still live. Settled-and-visible is what stops a decision
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
- **Never skip rung 1** because the render is already imaginable. The gate exists for
  Jake's decision-making, not as a formality — and the canvas is the most expensive place
  to discover that a layout was the wrong shape all along.
- **Never draw every direction on the canvas** "to be thorough".
- **Never settle a motion question with more artboards.** If the argument needs the words
  "as you scroll", build rung 3 instead of drawing a fourth frame of the sequence.
- **Two or three directions, not five.** The constraint is what forces each one to be a real
  argument rather than a permutation. If a fourth genuinely earns its place, say why.
- **Draw the states, not the happy path.** A canvas showing only the ideal case has not
  tested the design.
- **Judge against the tenets, not taste.** "This feels cleaner" is not an argument;
  "this puts the most important element at eye level, which the alternative buries" is.
- **Watch for the competitor failure mode.** If a layout is accumulating boxes above the
  actual content, that's the specific thing `docs/INSPIRATION.md` warns about. Name it.
