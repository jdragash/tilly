# Moving between the year, a month and the days — implementation plan

**Brief:** docs/briefs/calendar-pinch/brief.md
**Settled by:** `DESIGN.md`, "Three levels of one place" and "The month"; `DECISIONS.md`, "Calendar
is three zoom levels" and "Every charge is its own row". Reference: `docs/prototypes/calendar-pinch.html`
(its `land`, `seamFor`, `paint`, `pMove` and `pEnd` are the behaviour to match).

## Already decided — do not reopen

- Every day of a month is a button into the timeline. A day with charges lands as it does now.
- An empty day lands where it would fall in the list, in the middle of what shows, and **nothing
  marks it**: no line, no label, no row. Today, when it has no charge, lands on the Today line, centred
  as the month button centres it.
- The timeline gains no rows, day headings or spacing. Whatever an empty day scrolls to is zero high.
- One pinch moves one level. Spreading goes in, closing goes out; past the year or the days, nothing.
- Pinching in on the year opens the month nearest the fingers; on a month, the day nearest the
  fingers, exactly as tapping it would. Pinching out goes where the back button goes, shrinking into
  the day under the fingers when that day is in the month it lands on.
- A pinch doesn't follow the fingers (Jake, 2026-10-27: simpler). Once the spread or the closing passes
  1.25×, it plays the zoom a tap plays, at once, without waiting for the fingers to lift; the rest of
  that pinch does nothing. Below it, nothing moves. Reduce Motion keeps the crossfade. No haptic.
- Taps, the back buttons, the month button and the pinch all play today's zoom: the same anchor,
  scales, transitions and `Tokens.Motion.zoom`. The transitions stay.
- The All / Extras toggle, settings, the arrows and the bottom row don't zoom.

## Model routing

Steps 1 and 3 are Sonnet's: their tests prove them. Steps 2 and 5 are Opus's: a green suite stays
green with each broken (`CLAUDE.md`; `.claude/rules/swiftui-scrolling.md`, `calendar.md`). Step 6 is
`tilly-ship`.

## Steps

### Step 1 — Say where an empty day sits in its month's rows

Order: first. Step 2 renders it.

**Files:**
- new `Tilly/Timeline/DaySeams.swift`
- new `TillyTests/DaySeamsTests.swift`

**Interface:**
```swift
/// Where each day of a month without a charge would fall among that month's rows, which run newest
/// first. Keyed by the index of the row it sits above; `section.entries.count` means after the last
/// row. A day still to come in the current month sits above the Today divider, a passed one below
/// it. Today itself is left out when the divider shows, since landing on the divider covers it.
enum DaySeams {
    static func seams(for section: MonthSection, today: Date, calendar: Calendar) -> [Int: [Date]]
}
```
Days are `calendar.startOfDay` dates, each list newest first. A day that has a row is in no list.
"The divider shows" means `section.isCurrent && section.hasChargedEntry`, which is
`MonthSectionView.todayDividerIndex`'s condition; the divider sits before the first row dated on or
before today.

**Done when:** the suite passes, with these `DaySeamsTests`: `emptyMonthPutsEveryDayAtZero`,
`dayBetweenTwoRowsSitsAboveTheOlder`, `dayNewerThanEveryRowSitsAtZero`,
`dayOlderThanEveryRowSitsAfterTheLast`, `daysWithRowsAreLeftOut`, `twoChargesOnADayAreOneSeam`,
`futureDayInCurrentMonthSitsAboveTheDivider`, `pastDayInCurrentMonthSitsBelowTheDivider`,
`todayIsLeftOutWhenTheDividerShows`, `todayIsKeptWhenNothingIsChargedYet`,
`thirtyFirstOfAShortMonthDoesNotExist`, `listsRunNewestFirst`. Each builds a `MonthSection` by hand
with a fixed Gregorian calendar in UTC.

**Verify:** `xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0' test`

**Out of scope:** any view. `TimelineLanding` is unchanged.

### Step 2 — Every day opens the timeline, and an empty one lands mid-list (Opus)

Needs step 1.

**Files:**
- modified `Tilly/Calendar/CalendarDayCell.swift`: always a `Button`. VoiceOver keeps
  `CalendarFormatting.dayLabel` (already "Mon 5, no charges"), and the hint becomes "Opens the day"
  for every cell.
- modified `Tilly/Timeline/MonthSectionView.swift`: before row `i` (and after the last row, and at the
  top of a month with no rows), one zero-high `Color.clear` per date in `DaySeams.seams(...)[i]`,
  `.frame(height: Tokens.Size.scrollMarker)`, `.id(OccurrenceRow.dayScrollID(date))`. The same id
  function a day with rows uses, so `openDay` needs one scroll target per day whatever the day holds.
  Placed before the divider when the divider sits at that index, so they stay above it.
- modified `Tilly/Timeline/TimelineView.swift`, `openDay(_:)`:
  - A day with rows: unchanged (`fraction = headerHeight / room`).
  - Today with no row while the divider shows: the divider's id, `dividerAnchor(height:in:)`, with the
    divider's height from `rowFrames.frames[TodayDivider.scrollID]` read after the month scroll;
    if it hasn't reported, land as an empty day.
  - Any other day: its marker, centred: `f = ((headerHeights[month] ?? 0) + containerHeight) / 2 /
    containerHeight`, clamped to 0...1. That is `dividerAnchor`'s middle with a zero-high target.
  - A day whose month isn't listed (empty, and neither this month nor next): the nearest listed month
    below it, its first marker or row id, landed the same centred way. Below the floor month: the
    floor line. Add `TimelineFloor`'s id if it has none.
  - `markedDay` only marks a day with rows. Nothing new is drawn.

**Done when:** the suite passes, and on the iPhone 17 simulator, logged with `NSLog` as
`simulator.md` describes, a tapped empty day's marker sits within 1pt of the middle of what shows
(halfway between the pinned header's bottom and the bottom row's clearance) for: an empty day in this
month above and below Today, an empty day three months back, one four months ahead, the first of a
month whose first row is later, the last day of the floor month, and a month that isn't listed.
Today with no charge lands the divider where the month button does (within 1pt). A day with charges
lands as before (59.86 under a 60pt header). Nothing in the list moves or gains height: compare the
content height before and after with `onScrollGeometryChange`. Screenshots in light, dark and at
`accessibility3`.

**Verify:** the step 1 command, then the measurements above.

**Out of scope:** the pinch, the zoom's code, any mark or label for an empty day.

### Step 3 — The pinch's trigger, as a number

Built first as a pinch that follows the fingers (`a6c03af`). **Revised 2026-10-27**: the pinch now only
triggers the zoom, so this step shrinks to the trigger. Remove what only a scrubbed zoom needed.

**Files:**
- modified `Tilly/Calendar/CalendarZoom.swift`: remove `closer(at:)`, `further(at:)` and
  `PinchProgress`; keep `PinchDirection`; add `PinchTrigger`.
- modified `Tilly/DesignSystem/Tokens.swift`: remove `pinchFull`, `pinchStart`, `pinchFinish`,
  `pinchFlick`, `pinchSettleMin`; add in `Scale` `pinchTrigger: CGFloat = 1.25`, commented as the
  spread (or its inverse, closing) at which a pinch plays the zoom, from `calendar-pinch.html`.
- modified `TillyTests/CalendarZoomTests.swift`: drop the removed functions' tests.

**Interface:**
```swift
enum PinchTrigger {
    /// The way a pinch goes once its magnification reaches `pinchTrigger` spreading or
    /// `1 / pinchTrigger` closing; nil before either.
    static func direction(magnification: CGFloat) -> PinchDirection?
}
```

**Done when:** the suite passes, with `CalendarZoomTests`: `nothingInsideTheTrigger`,
`spreadingPastTheTriggerIsIn`, `closingPastTheTriggerIsOut`, `exactlyAtTheTriggerCounts`.

**Verify:** the step 1 command.

**Out of scope:** views and gestures.

### Step 4 — Dropped

Driving the zoom by a progress value was only needed for a pinch that follows the fingers.

### Step 5 — The pinch plays the zoom (Opus)

Needs steps 2 and 3.

**Files:** modified `Tilly/Timeline/TimelineView.swift`; `CalendarMonthView.swift` only if its paging
drag needs to step aside.

**Shape:**
- One `MagnifyGesture`, `.simultaneousGesture` on the levels' `ZStack`, so one finger still scrolls
  and pages. Its `startLocation` is in `CalendarZoom.space`; check that it and `TimelineSpace`
  share an origin, and convert if they don't.
- On change, the first time `PinchTrigger.direction` is non-nil, act once, exactly as the matching
  tap or back button, choosing from what is nearest the start location:
  - year, in: the month in `zoomFrames.months` nearest it, as `openMonth`.
  - month, in: the day in `zoomFrames.days`, among the shown month's days, nearest it, as `openDay`.
  - day, out: the back button's action, except that the row under the location gives the day to
    shrink into when that day is in the month it lands on and `zoomFrames.days` has its frame.
  - month, out: the back button's action.
  - year out, day in: nothing.
  The rest of that pinch does nothing; the next pinch starts fresh.
- The month's paging `DragGesture` ignores a drag that was part of a pinch.

**Done when:** the suite passes, and on the simulator (⌥-drag pinches about the centre) and then a
device:
- Each of the four directions plays the same zoom its tap or back button plays, about the cell
  under the fingers, once the pinch passes 1.25×, before the fingers lift; a smaller pinch moves nothing.
- Pinching in on a month at an empty day lands it as step 2 measured; at a day with charges, as a tap
  does, marked.
- One-finger scrolling of the year and the days, and paging the month by a swipe, still work.
- A pinch past the year or the days does nothing; a long pinch never moves two levels.

**Verify:** the step 1 command, then the checks above, reported with what was seen.

**Out of scope:** following the fingers, density within a level, haptics.

### Step 6 — Ship

`tilly-ship`: move observation 8 to Done in `docs/observations.md`, carry this plan's Lessons into
`.claude/rules/calendar.md`, delete the plan, tag.

## Updates

### 2026-10-28: three fixes before landing (observations 9, 10, 11)

Jake tried the build on his phone: the pinch is fine as it is. Before it lands, in this order, then
step 6. All three are Opus's: each proves itself only on screen.

**Step 7 — Today without overshoot (10).** Tapping Today over the days overshoots the Today line and
springs back. Find why before changing anything: log the scroll offset every frame of a return
(`simulator.md`) from this month, three months back and a year ahead, and from rest and mid-fling.
Suspects, unconfirmed: the two animated scrolls a turn apart in `returnToResting` (month, then
divider) fighting, a `GlideStopper` restart, or the divider's frame read under a zoom. **Done when:**
the logged offset moves one way only and stops at the line, in all six cases, and the line lands
where it does now (within 1pt). Add to Lessons what caused it.

**Step 8 — Why the sheet feels laggy (9).** Measure before changing: Instruments' Animation Hitches
(or `CADisplayLink` frame times logged) while opening the editor's sheet, adding and opening a
bill, on Jake's phone or the simulator, in **both** Debug and Release (`-configuration Release`).
Report the hitch ratio and the longest frames for each, and what the profile blames (the boil, the
drawn edges, the grain, layout). Fix what is cheap and plainly ours; anything that would change a
look goes to Jake as a finding with numbers, not a change. If Debug alone is slow, say so and
suggest Jake runs Release on his phone. **Done when:** a before and after table of hitch ratios.

**Step 9 — Transition kinds to try (11).** Debug-only, in Settings' tuning, beside the motion steps
that exist (`MotionTuningSection`, `MotionGroup`): a picker of kinds for the sheet opening and one
for Today. The kind is stored like the other tuning, read through `Tokens.Motion`, and what ships
stays the default. Sheet: the current rise (spring), a critically damped spring with no bounce,
an ease-out slide as the system sheet moves (0.35s), and a fade with a slight scale-up from 0.96.
Today: the current animated scroll, one spring scroll with no bounce, and a quick crossfade
(the list jumps under a 0.2s fade). The existing duration and bounce steps keep working within each
kind. **Done when:** every kind runs on the simulator from rest and mid-motion without a hitch the
current one doesn't have, and the suite passes. Under Reduce Motion, every kind is a fade.

## Lessons

- **Step 1's map can't place a passed day at the divider's own index.** Days keyed to the row the
  Today line sits before straddle the line; `MonthSectionView` splits them by date, future above.
- **Read the divider's height from its size, not its frame,** when landing under a zoom: the
  timeline is scaled then, and the frame read 6.3pt for a 31.7pt line, putting it 1.3pt off.
- **An empty day near either end of the list lands as near the middle as the content allows**:
  in a floor month the list was already at its end (marker at 184, 469 and 608 for a 420 middle).

- **A level leaving reports scaled frames after `isZooming` clears**: the month grid kept its day
  cells at 3× (150pt wide), and the back button and the pinch shrank into the wrong cell. Keep a
  level's frames only while it is the level that shows.
- **A pinch's fingers lifting land as taps** on whatever is under them: closing on the month
  opened two days. Taps wait out a pinch and 0.35s after it, as the prototype's `quietUntil` does.
- **A level leaving keeps the closures it was drawn with,** and a `@GestureState` read from them
  is the value from then. Mirror it into `@State` for anything a tap reads.

## If a step is wrong

These specs were written before the code existed. If a step turns out to be
ambiguous, impossible, or wrong, **stop and say so** — don't improvise a fix and
don't silently widen the scope. A wrong spec caught in one message costs far less
than a wrong spec followed to completion.
