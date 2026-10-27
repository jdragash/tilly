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
- The pinch follows the fingers the whole way: all the way in at a 2.2× spread, finishing on lift past
  40% or on a flick faster than 1.5 of the way per second, springing back otherwise. Reduce Motion
  keeps the crossfade, following the fingers. No haptic.
- Taps, the back buttons and the month button keep today's motion: the same anchor, scales and
  `Tokens.Motion.zoom`. Their look must not change in step 4.
- The All / Extras toggle, settings, the arrows and the bottom row don't zoom.

## Model routing

Steps 1 and 3 are Sonnet's: their tests prove them. Steps 2, 4 and 5 are Opus's: a green suite stays
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

### Step 3 — The zoom and the pinch, as numbers

Order: before 4 and 5, which draw with it.

**Files:**
- modified `Tilly/Calendar/CalendarZoom.swift`
- modified `Tilly/DesignSystem/Tokens.swift`: in `Scale`, `pinchFull: CGFloat = 2.2` (the spread
  that goes all the way) and `pinchStart: CGFloat = 1.04` (before which a pinch has no direction);
  in `Motion`, `pinchFinish: CGFloat = 0.4`, `pinchFlick: CGFloat = 1.5` (of the way per second) and
  `pinchSettleMin: TimeInterval = 0.14`. Each with a comment naming `calendar-pinch.html`.
- new `TillyTests/CalendarZoomTests.swift`

**Interface:**
```swift
extension CalendarZoom {
    /// How far in a change of level is: 0 shows the further level, 1 the closer.
    /// The closer level's scale and opacity at `t`: from `scale` and 0 to 1 and 1.
    func closer(at t: CGFloat) -> (scale: CGFloat, opacity: Double)
    /// The further level's: from 1 and 1 to `outerScale` and 0.
    func further(at t: CGFloat) -> (scale: CGFloat, opacity: Double)
}

enum PinchDirection: Equatable { case `in`, out }

/// One pinch, from the gesture's magnification, as the prototype's `pMove` and `pEnd` read it.
struct PinchProgress: Equatable {
    /// nil until the magnification leaves 1/pinchStart...pinchStart.
    static func direction(magnification: CGFloat) -> PinchDirection?
    /// How far along its direction: ln(spread) / ln(pinchFull), clamped to 0...1, where spread is the
    /// magnification going in and its inverse going out.
    static func progress(magnification: CGFloat, direction: PinchDirection) -> CGFloat
    /// The same per second, from the gesture's magnification velocity.
    static func speed(magnification: CGFloat, velocity: CGFloat, direction: PinchDirection) -> CGFloat
    /// Whether a lifted pinch finishes: past pinchFinish, or faster than pinchFlick.
    static func finishes(progress: CGFloat, speed: CGFloat) -> Bool
    /// How long the rest takes: zoomDuration times the distance left, at least pinchSettleMin.
    static func settleDuration(from t: CGFloat, to end: CGFloat) -> TimeInterval
}
```

**Done when:** the suite passes, with `CalendarZoomTests`: `closerStartsAtCellScaleAndClear`,
`closerEndsFullAndOpaque`, `furtherEndsAtOuterScaleAndClear`, `outerScaleCapsAtZoomMax`,
`noDirectionInsideTheDeadZone`, `spreadingIsIn`, `closingIsOut`, `progressIsFullAtPinchFull`,
`progressClampsBothEnds`, `progressOutUsesTheInverse`, `finishesPastFortyPercent`,
`flickFinishesEarly`, `slowShortPinchSpringsBack`, `settleDurationScalesWithDistance`,
`settleDurationHasAFloor`.

**Verify:** the step 1 command.

**Out of scope:** views and gestures.

### Step 4 — Zoom between levels by a progress value, not by transitions (Opus)

Needs step 3. Today the year and the month arrive and leave as `.transition`s, which can't be
scrubbed. Drive every level from one value instead, so step 5 can hand it to the fingers.

**Files:** modified `Tilly/Timeline/TimelineView.swift` (and `CalendarZoom.swift` only if a helper
is needed).

**Shape:**
- New state: `zoomPair: (further: CalendarLevel, closer: CalendarLevel)?` and `zoomProgress: CGFloat`.
  While `zoomPair` is set, both its levels are mounted and drawn with `levelZoom.closer(at:)` and
  `levelZoom.further(at:)` as `scaleEffect` (about `levelZoom.anchor`) and `opacity`; under Reduce
  Motion the scale is 1. At rest (`zoomPair == nil`) only `level` is mounted, at full size, as now.
  The timeline stays mounted throughout and takes the same values when it is in the pair.
- `setLevel(_:zoom:)` keeps its signature: set the pair and the progress to where the level now is,
  a turn later `withAnimation(Tokens.Motion.zoom)` the progress to the other end, and when
  `zoomDuration` has passed set `level`, clear the pair and `zoomFrames.isZooming`. Remove the year's
  and the month's `.transition`s.
- `level` changes as the zoom starts, so the controls answer at once (TASTE 12): the arrows, the
  month button and the top row's back button switch on the tap, as they do now.
- A tap during a zoom finishes the running one at once and starts the new one.

**Done when:** the suite passes, and screen recordings on the simulator of year → month → day → month
→ year, by taps and back buttons, match recordings of `main` frame for frame at the start, middle and
end (same anchor, same sizes, same fades), in light, dark and Reduce Motion. The timeline keeps its
place across a round trip (the month under the middle and its offset, logged, unchanged). The rules'
traps still hold: frames in flight aren't kept.

**Verify:** the step 1 command, then the recordings.

**Out of scope:** the gesture. No change a reader could see.

### Step 5 — The pinch (Opus)

Needs steps 2 and 4.

**Files:** modified `Tilly/Timeline/TimelineView.swift`; `CalendarMonthView.swift` and `YearView.swift`
only to hand the gesture's location in, if the frames already reported aren't enough.

**Shape:**
- One `MagnifyGesture`, `.simultaneousGesture` on the levels' `ZStack`, so one finger still scrolls
  and pages. Its `startLocation` is in `CalendarZoom.space`; check that it and `TimelineSpace`
  share an origin, and convert if they don't.
- On the first change outside the dead zone (`PinchProgress.direction`), choose the pair, the zoom
  and the target, exactly as the taps and back buttons do, from what is nearest the start location:
  - year, in: the month in `zoomFrames.months` nearest it; set `calendarMonthID`; zoom from its frame.
  - month, in: the day in `zoomFrames.days`, among the shown month's days, nearest it; land the
    timeline on it as `openDay` does, without marking the day or saving the place yet; zoom from
    its frame.
  - day, out: the month under the middle, as the back button; the row under the location gives a
    day, used when it is in that month and `zoomFrames.days` has its frame; otherwise
    `zoomFrames.openedDay` as now, otherwise `.centre`.
  - month, out: the month's frame in the year, as the back button.
  - year out, day in: nothing, for the rest of this pinch.
- On change: `zoomProgress` = the progress, or 1 − it going out, set without animation.
- On end: `PinchProgress.finishes`, then animate to the end with
  `.timingCurve(0.2, 0.8, 0.2, 1, duration: PinchProgress.settleDuration(...))`. Finishing sets the
  level when the pinch commits (as `setLevel` does), marks the day and saves the timeline's place
  when it lands in the days. Springing back restores the level it started on and clears what it
  prepared, and the timeline's place is put back if the pinch had moved it.
- The month's paging `DragGesture` ignores a drag while a pinch is under way.

**Done when:** the suite passes, and on a device (two-finger pinch needs one; the simulator's
⌥-drag pinches about the screen's centre and is enough for a first pass):
- Each of the four directions follows the fingers, finishes past 40%, springs back below it, and a
  quick flick finishes from about 15%.
- Pinching in on a month at an empty day lands it as step 2 measured; at a day with charges, as a tap
  does, marked.
- Pinching in on the year opens the month under the fingers.
- One-finger scrolling of the year and the days, and paging the month by a swipe, still work.
- A pinch past the year or the days does nothing.
- Reduce Motion crossfades with the fingers.
- Screenshots of a pinch half-way, in light and dark, beside the prototype's at the same progress.

**Verify:** the step 1 command, then the checks above, reported with what was seen.

**Out of scope:** density within a level, haptics, the key's copy.

### Step 6 — Ship

`tilly-ship`: move observation 8 to Done in `docs/observations.md`, carry this plan's Lessons into
`.claude/rules/calendar.md` (the transition notes there change with step 4), delete the plan, tag.

## Lessons

## If a step is wrong

These specs were written before the code existed. If a step turns out to be
ambiguous, impossible, or wrong, **stop and say so** — don't improvise a fix and
don't silently widen the scope. A wrong spec caught in one message costs far less
than a wrong spec followed to completion.
