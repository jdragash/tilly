---
paths:
  - "Tilly/Calendar/**"
  - "Tilly/Bills/**"
  - "Tilly/Timeline/TimelineView.swift"
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

- **Every level is drawn from one progress value** (`zoomPair`, `zoomProgress`), not inserted as a
  transition, so a pinch can hold the zoom anywhere. Draw the pair at its start a turn before the
  progress moves. The timeline is never inserted, so its place survives; its scrolls stay
  unanimated underneath the zoom.
- **The month draws above the year**, whichever is arriving: its opaque paper hides the year's
  large end, as the transitions this replaced stacked them. The other way round, recordings of the
  same zoom differed.
- **A scale in flight reports scaled frames**, even after the zoom is declared over (a grid at 3×
  shrank the way back into the wrong cell). Keep a level's frames only while it is the level that
  shows, in a reference holder outside view state. Hold what arrives mid-zoom and keep it once the
  zoom settles: an arriving level's at-rest frames come before the zoom ends, and a year shown once
  had none to pinch from.
- **Year and month are cached with `sections`;** progress is read in `LevelLook` only (controls.md).

## Pinching

- **Fingers lifting off a pinch land as taps** on whatever is under them: closing on a month opened
  two days. Taps wait out a pinch and `pinchQuiet` after it.
- **A level leaving keeps the closures it was drawn with,** and a `@GestureState` read from them is
  the value from then. Mirror it into `@State` for anything a tap reads.
- **Fingers held still send no changes,** so a speed read at the last move made a held pinch a
  flick. A pinch still for `pinchStill` lifts with none.

## Landing a day

- **An empty day lands on a zero-high marker where it falls.** `DaySeams` keys days to the row they
  sit above; at the Today line's own row they straddle it, so the view splits them by date.

## Controls

- A stock segmented `Picker` inside `glassEffect` is 37pt, taller than a `calendarTitle` line, and
  reads as a pill in a pill. Alone it is 32pt and sits beside the title.
- At accessibility sizes a card header's trailing total squeezed the name to a letter a line:
  stack the header there, as `OccurrenceRow` stacks its row.

## Checking

- Look at the year in three developer scenarios: `Typical year`, `Only monthly bills` and `One
  giant bill`. Someone whose bills never vary must still see a full year, never an empty one.
