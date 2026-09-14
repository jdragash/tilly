# Design

The visual and interaction rules as they stand. Present tense, rules only. The tenets they serve
are in `PROJECT.md`, the principles behind them in `TASTE.md`, and the evidence in
`INSPIRATION.md`.

---

## Tokens

Every view refers to `Tokens`, never to a raw value: no literal hex, no literal point sizes, no
bare `.largeTitle`, and no bare numbers in layout modifiers.

```swift
enum Tokens {
    enum Text { static let amount = Font.body }
    enum Surface { static let base = Color(.systemBackground) }
}
```

In v1 tokens alias system values. System components supply Liquid Glass, Dynamic Type, dark mode
and VoiceOver correctly, and the indirection makes the design pass a one-file change. Screens add
the tokens they need, and later screens extend the scale.

Dimension tokens are held to the same rule as fonts and colours from the first view that uses
them. A bare number in `.padding` doesn't look wrong the way a hex literal does, which is why it
gets through.

`DesignSystem/Gallery.swift`, still to come, will render every token and shared component in
light, dark and accessibility sizes.

For the design pass: layer on top of system materials rather than replacing them.

---

## State grammar

| Axis | States | Channel |
|---|---|---|
| **Time** | upcoming / charged | Weight: secondary vs. full |
| **Certainty** | estimated / known | *Not rendered in v1.* Returns with variable bills |

An upcoming row sits back: name, date, icon and amount all at secondary weight. A charged row
comes forward at full weight. A skipped row withdraws further and strikes its amount through:
listed, visibly known about, visibly not counted.

An occurrence dated today is charged. An occurrence with no amount shows an em dash and adds
nothing to any total.

When certainty returns, it takes its own channel, a mark beside the amount, and never lightness.
Lightness already means upcoming, and an estimated past charge would read as upcoming.

The grammar applies wherever a date or amount appears, the editor included: a future date looks
like the future before you save.

---

## The timeline

### The row

Icon well, then name with the date beneath it, then the amount. The leading slot belongs to the
category icon, and it renders as an empty well until categories exist. Never draw a placeholder
glyph: that would be a starter set by the back door.

### Amounts

Every amount carries a minus sign: rows, day totals, month totals. Nothing on this screen is money
arriving, so the sign sets the register. A zero is unsigned (`€0`), because nothing is going out.

Amounts round to whole units before anything is totalled, so a total always equals the figures
above it.

### Rules delimit, they don't decorate

No separator between rows; space does that work. A hairline appears only to open and close a
grouped day, under the unlock bar, and under a pinned month header. A rule means something is
being closed.

### Group a day only when there's a day to group

One charge on a day is an ordinary row carrying its own date. Two or more collapse under a day
heading with a day total, and the rows inside give up their dates. Inside a group, entries descend
by amount, with ties broken by name. The heading takes the ink of the day's temporal state. No
tinted card: it breaks amount alignment down the right edge.

### The month header

The current month's header carries what is still to go, and says so: `−€162 left`. When it runs
out it reads `€0 left`. Every other month carries its plain total with no qualifier. A future
month has nothing charged, and a past month has nothing left.

That header is the headline number, so it doesn't get a second home above the content. Totals
everywhere exclude skipped occurrences. A month name carries its year only when that year isn't
the current one.

### Nothing marks the boundary between upcoming and charged

The last row at secondary weight and the first at full weight are the boundary. No divider. No
`TODAY` badge either: the most recent charge usually isn't today.

### One list, bounded at both ends

The next month is always expanded above the current one, so you reach it by scrolling. History
runs continuously below. There are no collapsed month bars. At rest the list sits flush on the
current month, with next month above the top of the screen.

When the current month's expanded section holds nothing charged, it ends with `This fills in as
bills go out.`

### Further ahead is asked for, and puts itself away

One bar sits at the very top. It opens the month after next, then offers the one after that.
An unlocked month closes on its own once the reader has gone up into it and come back to the
current month. Nothing accumulates, and there's no control to clear anything.

### History stops where your oldest charge does

The list runs down to the oldest occurrence the rules generate and stops, with one line: `Nothing
before March.` A month between there and today that holds nothing isn't listed at all. No month
ever shows €0 for a month the app knows nothing about.

Expenses are entered for their next occurrence, not their historical start. Backdating stays
possible, and a deliberately backdated bill is shown.

### No reserved space

No slot is held open for features that don't exist yet, such as look-ahead nudges. An empty box
above the content is the competitor's defining mistake.

### A moved occurrence appears at its new date only

No ghost row at the original date, and no "moved from the 1st". Whether an edit applies to this
occurrence or the series is asked at the moment of editing.

### Getting back

A floating pill appears once the reader is **240 points** from the current month's resting
position, in either direction: about a third of a screen, so it arrives as soon as the month is
behind you. Showing it the instant the header leaves would flicker at the boundary.

It names the month and points the way: `↑ September` from below, `↓ September` from above.
VoiceOver reads "Back to September". The arrow follows which side the reader is on at every
distance, including while the pill is hidden, so it never turns around as it fades in.

Tapping it scrolls back rather than jumping, with a duration that scales with distance, and closes
any unlocked months on the way. The pill uses the stock glass button style. The list carries a
bottom inset of the pill's height plus its margin, so the last line of history clears it.

### The month you're reading stays named

The month header pins to the top while its rows scroll under it, and hands off when the next header
arrives. Its ground is opaque and the same paper as the page, so content passing beneath is hidden
rather than tinted, and it carries that ground at rest too. Glass is for things that float over
content; a full-bleed sticky header doesn't float.

It keeps its full size when pinned. Condensing would save a point, cost three points of type, and
make the month you're *in* the same shape as a month you could *open*. The hairline under it appears
only while it's pinned.

### Nothing under the reader's eyes moves

When a month opens or closes above the reader, the month under the middle of the viewport holds its
position on screen. Crossing midnight into a new month moves the header figure and reclassifies
passed rows, but inserts nothing above the reader: next month was already open.

### Your place survives

You return to the month you left, at its top, however long you were gone and whether or not the
process survived. The current month decides where you land only on first run. Returning from a
month boundary, where the unlock and the pill both leave you, restores exactly.

### The app fills the top inset

The area behind the status bar and Dynamic Island carries the page's own background, opaque and full
width. Content scrolls under it and is hidden. It has to hide a month header, not just a row: during a
hand-off the outgoing header sits in that inset. iOS 26's scroll edge effect had no visible effect
here, and a scrim or progressive blur leaks exactly where that header sits.

Mockups leave the inset empty rather than painting a clock into it.

---

## Copy rules

**No label that restates its control.** A field reached by tapping "+" doesn't say "Price". A date
picker doesn't say "Payment Date". Remove the label; if nothing is genuinely unclear, it stays
removed.

**The test cuts both ways.** A word stays when removing it leaves a slot meaning two things. `−€162
left` keeps "left", and drops "this month" because the month name sits beside it. The pill says
`September`, not `Back to September`, because the arrow already says "back".

**The app never says a bill was paid.** It says *charged*. Tilly knows a date passed, not what left
an account.

**Amounts display in whole units.** Enter 74.10, see 74. Cents may be entered.

---

## Interaction patterns

### "This occurrence" vs. "all future"

When editing something that recurs, the scope being changed is unmistakable *at the moment of
choosing*, not inferable afterwards. One occurrence writes an override. The series edits the rule and
corrects the whole timeline.

### Nothing to confirm

No control anywhere marks a charge as paid. A design that needs one is wrong.

### A setting takes effect when it's set

No "restart the app to apply". If a setting is too expensive to apply live, it doesn't ship yet.

---

## Empty states

Categories ship empty, so first run is doing the teaching. The empty state is the first screen of the
product, not a placeholder. It feels clean rather than unfinished, and makes the next action obvious
without instructing at length.
