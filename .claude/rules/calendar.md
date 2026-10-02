---
paths:
  - "Tilly/Calendar/**"
  - "Tilly/Bills/**"
---

# The calendar's levels and All bills

Learned building the year, the month grid, the zoom between them and All bills. Invisible to
tests: each was found on screen.

## Grids

- **Blocks sharing one `LazyVGrid` need distinct id spaces.** Neighbouring days counted `0..<n`
  collided with the days' own `1...31`, and the trailing cells drew 29, 30 where 1, 2 belonged.
- **Lay a calendar cell out from the top.** Centred in a fixed row, a cell whose content ran long
  at `.xxxLarge` lifted its day number off the week's line. Frame cells `alignment: .top`.

## Zooming between levels

- **A view leaving takes the transition it last drew with.** Set the zoom's anchor and scale a
  turn before the level changes, or the level leaving zooms about the old place.
- **A scale in flight reports scaled frames** through `onGeometryChange`. Keep cells' frames only
  while no zoom runs, in a reference holder outside view state, or the year's scroll redraws all.
- The timeline is never inserted: it stays mounted and animates `scaleEffect` and opacity, so its
  place survives. Its scrolls stay unanimated underneath the zoom.

## Controls

- A stock segmented `Picker` inside `glassEffect` is 37pt, taller than a `calendarTitle` line, and
  reads as a pill in a pill. Alone it is 32pt and sits beside the title.
- At accessibility sizes a card header's trailing total squeezed the name to a letter a line:
  stack the header there, as `OccurrenceRow` stacks its row.
