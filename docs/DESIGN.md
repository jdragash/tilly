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

**Dimension tokens are the seam's blind spot.** Fonts and colours are conspicuous — a raw
`.largeTitle` or a hex literal reads as obviously wrong in a view. A bare number in a layout
modifier (`.padding(8)`, `VStack(spacing: 8)`, `cornerRadius(4)`) does not; it reads as
incidental rather than as a value that escaped the token layer. When a spacing or dimension
scale is introduced, hold it to the same rule as fonts and colours from the first view that
uses it, not the second — the seam check `tilly-ship` runs already greps for spacing,
padding, corner radius and fixed frames for exactly this reason.

**For the v2 design pass:** layer on top of system materials rather than replacing them,
or the design system ends up fighting Liquid Glass instead of using it.

---

## State grammar

A row carries two independent states, and they must never be confused for each other.

| Axis | States | Channel |
|---|---|---|
| **Temporal** | not yet charged / charged | Weight — secondary vs. full |
| **Certainty** | estimated / known | A mark beside the amount — `EST` |

An upcoming row sits back: name, date, icon and amount all at secondary weight. A charged
row comes forward at full weight. A skipped one withdraws further still and strikes through
its amount — listed, visibly known about, visibly not counted.

The trap this table exists to prevent: if estimates render "lighter" and upcoming also
renders "lighter", an estimated past charge reads as upcoming. Keeping the two axes on
separate perceptual channels is what prevents that collision. The test case is an estimate
that has already been charged sitting directly beneath one that has not — if those two read
alike, the grammar has failed.

**Settled 2026-09-07** by the timeline exploration, which replaced the kickoff position
(form — outline vs. filled). `DECISIONS.md` records why: the outline/filled dot worked, and
paid a permanent column for a distinction that stops carrying information as soon as you
scroll away from today. Weight satisfies the separate-channels requirement without a column.

The grammar applies everywhere a date or amount appears, including the editor — selecting a
future date should show you it's in the future before you save.

---

## The timeline

The rules the timeline settled. They are written here because they generalise past it —
the editor and the insights screens inherit the same vocabulary.

### The row

Icon, then name with the date beneath it, then the amount. The leading slot belongs to the
category icon; the date does not compete for it. Amounts are negative — nothing on this
screen is money arriving, so the sign sets the register rather than distinguishing anything.

### Rules delimit, they do not decorate

No separator between rows; space does that work. A hairline appears only to open and close
a grouped day, and under a collapsed month bar. Seeing a rule therefore means something is
being closed, which is the only reason to draw one.

### Group a day only when there is a day to group

One charge on a day is an ordinary row carrying its own date. Two or more collapse under a
day heading with a day total, and the rows inside give up their individual dates — which is
where the heading's vertical space comes from. A day total on a day holding one charge is
that charge's amount written twice.

### The header says what is left, and only the current month does

An expanded month header carries a figure, and which figure depends on the month. The
current month carries what is **still to go** and says so — `−€162 left`. Every other month
carries its plain total, unqualified: a future month has nothing charged so the two
coincide, and a past month has nothing left. When the current month runs out, the sentence
finishes rather than changing — `€0 left`, unsigned, because there is nothing going out.

The word is the one label on this screen that survives the copy rule, and it survives
because deleting it leaves a real ambiguity rather than an imagined one. A total sitting on
a month you know is finished does not read as unclear; it reads as a number the app failed
to update.

The current month's header is therefore the headline number. It does not get a second home
above the content.

Totals everywhere exclude skipped occurrences.

### One month at a time, with its neighbours collapsed

The current month is expanded. The months either side are slim bars carrying a name and a
total; pulling or tapping opens one. **At most two months are expanded at once** — opening a
third collapses the far end, off screen, at the opposite end from where the reader is
looking. Nothing collapses because of where you scrolled.

That last rule is not a simplification of a nicer one. Closing an opened month by scrolling
away from it cannot work: pushing it off the top needs a screenful of content below it, and
below it there is one month and a 48-point bar. `DECISIONS.md` has the measurement.

### The month you are reading stays named

The month header pins to the top of the list while its rows scroll under it, over a
translucent ground, and hands off when the next month's header arrives beneath it. It keeps
its size when it pins — condensing to bar height saves one point and costs three points of
type, and lands the month you are *in* on the same shape as a month you could *open*.

The hairline under it appears only while it is pinned, which is the same rule the rest of
the screen follows: a rule is drawn because something needs closing. It earns an affordance
for free — a rule under the month name means the list is scrolled.

### Nothing under the reader's eyes may move

When months open and collapse, the anchor is the month under the **middle** of the viewport —
the one being read — and it holds its position across the change, following that month even
when it collapses into a bar.

The two intuitive anchors are both wrong, and worth naming because one of them was specified
before it was tested. Anchoring on the top-most visible item fails at rest, where that item
is the collapsed bar about to be opened: preserving its position expands it downward and
pushes the month being read off screen. Anchoring on total content height fails as soon as
one gesture adds a month at one end and drops one at the other, because the deltas cancel.

### Never lose the reader's place

You return to the month you left, opened as you left it, at the scroll position you left it
at — regardless of how long you were gone or whether the process survived. The current month
decides where you land once, on first run. See `DECISIONS.md` for why a session-scoped
compromise is worse than either alternative.

### The system owns the top

The status bar and Dynamic Island are drawn by iOS over the app. Mockups leave that inset
empty rather than painting it, or a real device shows two of everything.

---

## Copy rules

**No label that restates its control.** A field on a screen you reached by tapping "+"
does not say "Price". A date picker does not say "Payment Date". A category picker does
not say "Category". The competitor's editor labels all four and titles itself "New
expense"; it is the standing example of what this costs.

Test: remove the label. If nothing is genuinely unclear, it stays removed.

**The test cuts both ways, and the month header is the standing example of the other
direction.** `−€162 left` keeps its word because removing it leaves the same slot meaning
two different things on different months, with nothing to say which. The rule is not "fewer
words wins" — it is that a word must be doing work no other channel is doing. The same
header does *not* say "left this month", because "September" is already sitting beside it.

**The app never says a bill was paid.** It says *charged*. Tilly knows a date passed; it
does not know what left your account, and language that implies otherwise is one step from a
control that asks you to confirm it. See tenet 1.

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
