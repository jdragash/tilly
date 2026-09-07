# Timeline dimensions

Measured off the approved design canvas, then snapped to a 4-point grid. This exists so
`tilly-plan` starts from numbers rather than from eyeballing a mockup, and so the later
design pass has a scale with logic in it rather than a set of nudges.

**Status:** input to the plan, not a token file. The plan decides the names, the Swift
shape, and which of these become tokens versus stay local. `DECISIONS.md`, "The timeline
introduces spacing and dimension tokens", is the decision this serves.

## The grid

4-point base: **4, 8, 12, 16, 20, 24, 32**. A 2-point half-step exists for the inside of
small components only — a badge's side padding, not a layout gap. Anything reaching for a
value outside this set is a signal to check whether the layout is right, not a reason to
add a number.

Snapping moved seven values, none by more than 2 points, so nothing about the approved
design changes visibly:

| | Canvas | Grid |
|---|---|---|
| Icon container | 38 | 40 |
| Icon glyph | 21 | 20 |
| Collapsed month bar height | 46 | 48 |
| Month header, space above | 14 | 16 |
| Group, space above | 10 | 12 |
| Month bar, internal gap | 9 | 8 |
| Row vertical padding | 6 | *removed — see below* |

## Spacing

| Value | Where |
|---|---|
| **20** | Screen gutter, both edges. Everything on the timeline starts and ends here. |
| **16** | Above a month header. |
| **12** | Between icon and text, and between text and amount. Above a day group. |
| **8** | Below a month header. Below a day group. Before a badge. Inside the month bar. |
| **4** | Between a day heading and the rule under it. |
| **0.5** | Hairline. Not a spacing value; the thinnest line the display draws. |

## Sizes

| Value | Where |
|---|---|
| **52** | Row height, fixed. Content centres inside it, so vertical padding is not a token — the height is. Clears the 44-point hit target with room for two lines of text. |
| **48** | Collapsed month bar height. |
| **40** | Category icon container. Radius **10**. |
| **20** | Icon glyph inside that container. |
| **16** | Badge height (`EST`, and anything like it). Radius **4**, side padding **6**. |

## Type

Already expressible as system text styles, which is the point — Dynamic Type keeps working
and the values below are what those styles resolve to at the default size. The plan should
reference styles, not these numbers.

| Size / leading | Where | System style |
|---|---|---|
| 20 / 25, semibold | Month name | `.title3`, semibold |
| 17 / 22 | Expense name, amount | `.body` |
| 16 / 21 | Month bar name and total | `.callout` |
| 15 / 20 | Month total | `.subheadline` |
| 13 / 17 | Date line, day heading | `.footnote` |
| 10, semibold, +0.5 tracking | Badge | `.caption2`, semibold |

## What this does not cover

Colour. The timeline uses system label, secondary label, tertiary label and separator
throughout, and introduces no colour of its own. Category colour is deferred with categories
themselves.
