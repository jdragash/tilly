# Moving between the year, a month and the days

Every day of the month opens the timeline, and a pinch moves between the calendar's three levels.

## Problem

The calendar is three zoom levels of one place (`DECISIONS.md`, "Calendar is three zoom levels"),
but the only ways between them are taps on particular things. Going in from a month needs a day
with a charge: an empty day isn't a button, so a month with nothing in it, or a reader who wants to
see the days around the 12th, has no way into the timeline at all (observation 8). Going out needs
the back button top left. A zoom level that you can only enter through its contents isn't read as a
distance; it reads as a set of pages behind links.

Jake's ask, 2026-10-27: pinch in and out between the year, a month and the timeline, and stop
requiring a charge to reach the timeline from a month.

## Which tenets are at stake

- **3, self-evident over labelled.** Every day in the grid looks alike, so every day should do the
  same thing when tapped. A day that silently ignores a tap is an unlabelled exception.
- **1, a system that helps.** The reader shouldn't have to find a day with a charge to get where
  they're going.
- **2, minimal for hierarchy.** A pinch adds no control to the screen, which is why it fits.

## Why now

The calendar and the timeline are settled in the Drawn look, and the category view is set aside,
so Calendar is the app's only view. Moving between its levels is now the main navigation, and it's
being tested daily.

## What "better" looks like

1. Tapping any day in the month, empty or not, today included, opens the timeline at that day.
2. An empty day lands somewhere that says, truthfully, that nothing charges on it, with its
   neighbours in view (TASTE 1).
3. Pinching in on the year opens the month under the fingers; pinching in on a month opens the
   days at the place under the fingers; pinching out goes back a level, to the same place the back
   button goes.
4. The pinch answers the fingers at once, before it commits (TASTE 12), and a pinch let go early
   springs back to where it was.
5. A pinch never fights scrolling or paging: a one-finger drag still scrolls the year and the
   timeline and pages the month.
6. Reduce Motion: the pinch still moves between levels, as a crossfade.

## Prior attempts

- **Tapping a day** was settled on 2026-10-01 in `docs/prototypes/zoom-and-bills.html`: "tapping a
  day opens the timeline" beat a half sheet over the month. Only days with charges were built as
  buttons (`CalendarDayCell`); the empty day was never discussed, in the prototype or the docs. This
  brief doesn't reopen the choice, it finishes it.
- **The zoom itself** (`8f8b2ee`, then `84e2ccd` and on): a level grows out of the cell that was
  tapped and shrinks back into it. Its lessons are in `.claude/rules/calendar.md`: the zoom's anchor
  is set a turn before the level changes, frames in flight aren't kept, and the timeline stays
  mounted and scales rather than being inserted.
- **Pinching**: no earlier attempt, in git or the prototypes.

## Constraints

- **Landing on a day is two unanimated scrolls**, to the month and then to a zero-high marker that
  only a day with a charge carries (`TimelineView.openDay`, `MonthSectionView`). An empty day has no
  marker, and the timeline lists no empty days or day headings (`DECISIONS.md`, "Every charge is its
  own row"). Whatever marks an empty day must not become a row or a day group.
- **Nothing under the reader's eyes moves** (TASTE 2, 4): anything shown for an empty day appears
  because of the tap and goes away on its own, like the day mark that fades today.
- **The levels zoom by transitions**: the year and the month are inserted and removed with a scale
  transition about the tapped cell; the timeline animates its own scale and opacity. A pinch that
  follows the fingers needs both levels on screen at a scale the gesture drives, which the current
  transitions don't do. A pinch that only triggers the existing zoom past a threshold reuses them.
- **Gestures**: the year and the timeline are `ScrollView`s, and the month pages with a sideways
  drag. A two-finger magnify must run alongside them.
- A browser can't prove how a pinch feels on iOS. The prototype can settle what happens and roughly
  how it follows the fingers; the feel is judged on the phone.

## We'll know it worked when

Jake moves between the levels by pinching without thinking about it, and reaches the timeline from
any day. Not measurable beyond his own use.

## In and out

**In:** every day of the month as a button into the timeline; how an empty day lands; pinching in
and out across all three levels, in both directions; Reduce Motion; VoiceOver for a day cell.

**Out:** pinching to change the timeline's own density, or anything else within a level. Changing
the back button or the month button. Skipping a level in one pinch: one pinch moves one level.
The category view, which is set aside.

## Open questions

1. Where does an empty day land, and what marks it: a short-lived line where the day falls, in the
   middle of the list as the Today button centres today, or under the month's header as a day with
   charges does?
2. Does the pinch follow the fingers the whole way, as Photos does, or follow them a little and then
   play the zoom that a tap plays once it passes a threshold?
3. Pinching in on a month: does it open the day under the fingers, or the month's top (today, in the
   current month)?

## Sources

`docs/PROJECT.md`, `TASTE.md`, `DESIGN.md` ("The calendar", "The timeline"), `DECISIONS.md`,
`ROADMAP.md`, `docs/observations.md` (8); `docs/briefs/additional-views/brief.md`;
`docs/prototypes/zoom-and-bills.html`; `Tilly/Calendar/CalendarDayCell.swift`,
`CalendarMonthView.swift`, `CalendarZoom.swift`, `YearView.swift`; `Tilly/Timeline/TimelineView.swift`
(`setLevel`, `openDay`), `MonthSectionView.swift`; `.claude/rules/calendar.md`;
`git log -- Tilly/Calendar`.

## Updates

### 2026-10-27: the prototype settled the three questions

`docs/prototypes/calendar-pinch.html`, on the phone. The rules are in `DESIGN.md` ("Three levels of
one place").

1. **An empty day lands where it falls, in the middle of what shows, with no mark.** A fading line
   saying "Nothing on Thu 12" was prototyped and dropped: Jake wanted to be taken to the place, not
   told about the absence. Landing it under the month's header lost too.
2. **The pinch follows the fingers the whole way**, as Photos does, finishing past 40% or on a flick
   and springing back otherwise. Nudging a little and then playing the tap's zoom lost.
3. **Pinching in on a month opens the day under the fingers.** Opening the month's top lost.

### 2026-10-27, later: the pinch only triggers the zoom

Mid-build, Jake simplified it: a pinch plays the zoom a tap plays once it passes 1.25×, rather than
following the fingers. Driving the zoom by a progress value (the plan's step 4) was dropped with it.

### 2026-10-28: following the fingers after all

After a day with the trigger version on his phone, Jake asked for the pinch that follows the fingers,
as the prototype first had it, before the work lands.
