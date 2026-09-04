---
name: design-principles
description: Use when pressure-testing a Tilly design against established design principles — critiquing an existing exploration, screen or PR ("critique this against the principles", "what's this violating"), or advising while a problem is still open ("what does the canon say about this", "which principles apply here"). Draws on Lidwell's Universal Principles of Design (125 principles). Pairs with tilly-explore and tilly-ship; also works standalone.
---

# design-principles

Applies the 125 principles in *Universal Principles of Design* (Lidwell, Holden, Butler)
to Tilly — as a **critique lens** on something that exists, or as **advice** while a
problem is still open. One skill, two modes, same engine.

## The cheap-first rule (this is the whole point)

The book is 271 pages. **Never load the book to decide which principle applies.** The index
does that for a fraction of the cost — the same philosophy as `tilly-explore`'s wireframe
gate.

1. **Read `references/index.md`** — 125 principles, each with a short summary,
   when-to-use, category tags, and printed page number. Plus the book's own five routing
   questions.
2. **Name 1-3 candidate principles BEFORE retrieving anything.** Say which and why. Three
   is a ceiling, not a target — one sharp principle beats three loose ones.
3. **Retrieve only those principles' full text.**
4. **Escalate to the diagram only when it earns its cost.**

Loading the full book, or retrieving five principles "to be thorough", is the exact cost
this skill exists to cut.

## Retrieving a principle's text

Each principle is a two-page spread: an even printed page (definition, description,
guidelines) and the facing odd page (diagrams and examples).

**Page math: `PDF page = printed page − 2`.** The index gives the printed page.

```bash
pdftotext -f $((N-2)) -l $((N-2)) ~/code-projects/Resources/UniversalPrinciplesOfDesign.pdf - 2>/dev/null | grep -v '^Syntax'
```

Requires poppler (`brew install poppler`). If `pdftotext` is missing, say so and install it
rather than falling back to reading PDF pages as images — that fallback is precisely the
cost this skill avoids.

Text alone is enough to *apply* a principle. Quote the specific guideline you're leaning
on; don't paraphrase from memory.

## When to escalate to the diagram

The diagram deepens understanding but costs far more than text.

- **Yes** for spatial and perceptual principles where the picture carries what prose only
  names — the Gestalt family (Figure-Ground, Closure, Good Continuation, Proximity, Common
  Fate, Uniform Connectedness, Prägnanz), plus Alignment, Hierarchy, Layering,
  Signal-to-Noise Ratio, Symmetry, Rule of Thirds.
- **Yes** when Jake says "show me", or when you're about to make a concrete spatial
  recommendation and want a reference to pattern-match against.
- **No** for conceptual and behavioural principles (Cost-Benefit, Framing, Satisficing,
  Hierarchy of Needs). The image is usually just a photo illustrating the idea.

```
Read tool, file: ~/code-projects/Resources/UniversalPrinciplesOfDesign.pdf, pages: "N-1"
```

## Selecting principles

The index ends with the book's five routing questions. Map the situation to the matching
bucket, then pick from that shortlist:

- **Influence perception** — how something reads, groups, stands out
- **Help people learn** — comprehension, memory, onboarding, teaching through UI
- **Enhance usability** — findability, efficiency, error-proofing, control
- **Increase appeal** — aesthetics, desirability, emotional resonance
- **Make better decisions** — process and trade-offs, more about how Jake works than the UI

Prefer the bucket whose *definition* matches the mechanism at play, not just a keyword.

## Mode: critique (something exists)

Point it at a design canvas, a simulator screenshot, a PR, or described UI.

1. Read the index; name the 1-3 principles most at stake.
2. Retrieve their text.
3. For each: **honoured or violated?** Cite the specific guideline, quote the tell in the
   design, give the concrete fix. **No fix without a citation** — that's the difference
   between this and generic design feedback.
4. Rank by impact. Lead with the one that most changes the design.

## Mode: advise (problem still open)

Point it at a brief, a question, or a direction being weighed.

1. Read the index; name the 1-3 principles the canon brings to bear.
2. Retrieve their text.
3. Summarise what each says about *this* problem and the guideline it implies — as input to
   the decision, not a verdict. Note where two principles pull against each other (Horror
   Vacui versus Signal-to-Noise, say) and what the trade-off turns on.

## Tilly context

Read `docs/PROJECT.md` and `docs/INSPIRATION.md` first. **A book principle that contradicts
a Tilly tenet loses to the tenet** — say so rather than pushing the book. The canon informs
Tilly's choices; it doesn't override them.

`INSPIRATION.md` is the second source here: it holds specific evidence about what works on
these surfaces. A critique that cites both a principle and the observed screen it maps to
is much stronger than one citing either alone.

## Hard constraints

- **Index before book, always.** About to run `pdftotext` without having read
  `references/index.md`? Stop.
- **Name candidates before retrieving.** No silent "let me check a few".
- **Cite, don't recall.** The book's precise wording is the value. Applying a principle
  from memory is how you get it subtly wrong.
- **1-3 principles.** Breadth is not thoroughness; a wrong-but-plausible principle is worse
  than a missing one.
- **PDF stays at `~/code-projects/Resources/`.** Reference by path; never copy it into the
  repo.
