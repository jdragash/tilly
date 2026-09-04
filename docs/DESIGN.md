# Design

Visual language and interaction rules. Starts thin on purpose — it grows as decisions get
made, via `tilly-ship`'s merge step. What's here is what's actually been settled.

Evidence for these rules lives in `INSPIRATION.md`. The tenets they serve live in
`PROJECT.md`.

---

## Tokens

Every view refers to `Tokens`, never to a raw value. No literal hex, no literal point
sizes, no bare `.largeTitle`.

```swift
enum Tokens {
    enum Text { static let amount = Font.largeTitle }
    enum Surface { static let base = Color(.systemBackground) }
}
```

In v1 these alias system values. That is deliberate: system components supply Liquid
Glass, Dynamic Type, dark mode and VoiceOver correctly, which is a great deal of
correctness we would otherwise hand-build and get subtly wrong.

The indirection is what makes a real design system cheap later — swapping the token
definitions changes every screen at once. Without it, a design pass means editing every
view. `tilly-ship` checks for hardcoded values for exactly this reason; the rule is not
premature polish, it's what keeps the seam intact.

`DesignSystem/Gallery.swift` renders every token and shared component in one scrollable
view. Xcode's preview variants show it in light and dark at accessibility text sizes
simultaneously, so a token change is verifiable everywhere at a glance.

**For the v2 design pass:** layer on top of system materials rather than replacing them,
or the design system ends up fighting Liquid Glass instead of using it.

---

## State grammar

A row carries two independent states, and they must never be confused for each other.

| Axis | States | Channel |
|---|---|---|
| **Temporal** | not yet charged / charged | Form — outline vs. filled |
| **Certainty** | estimated / known | Typography — approximation marker on the number |

The trap: if estimates are rendered "lighter" and upcoming is also rendered "lighter",
an estimated past charge reads as upcoming. Keeping the two axes on separate perceptual
channels — form for time, typography for certainty — is what prevents that collision.

**Status: hypothesis, not settled.** This is the starting position for the timeline
exploration in Phase 2, to be tested against real layouts rather than assumed correct. If
exploration finds something better, this section changes and `DECISIONS.md` records why.

The grammar applies everywhere a date or amount appears, including the editor — selecting
a future date should show you it's in the future before you save.

---

## Copy rules

**No label that restates its control.** A field on a screen you reached by tapping "+"
does not say "Price". A date picker does not say "Payment Date". A category picker does
not say "Category". The competitor's editor labels all four and titles itself "New
expense"; it is the standing example of what this costs.

Test: remove the label. If nothing is genuinely unclear, it stays removed.

**Amounts round to whole units.** Enter 74.10, see 74. Cents are noise at this altitude,
and losing them makes columns scannable. Display-cents is a v2 setting, defaulting off.

---

## Interaction patterns

### "This occurrence" vs. "all future"

The classic recurring-event trap. When editing something that recurs, which scope is being
changed must be unmistakable *at the moment of choosing* — not inferable afterwards from
what happened.

Changing one occurrence writes an override. Changing the series edits the rule and
retroactively corrects the whole timeline. Those are very different outcomes and the UI
must not let them be confused.

### Nothing to confirm

There is no control anywhere that marks a charge as paid. If a design needs one, the
design is wrong — see tenet 1.

---

## Empty states

Categories ship empty, so first run is doing the teaching. The empty state is not a
placeholder to fill in later; it is the first screen of the product and carries real
weight.

It should feel clean rather than unfinished, and should make the next action obvious
without instructing at length.
