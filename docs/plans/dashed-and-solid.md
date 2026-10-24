# Dashed and solid — implementation plan

**Brief:** docs/briefs/dashed-and-solid/brief.md
**Settled by:** `DESIGN.md`, "State grammar", "The look", "The timeline", "The picker is a grid of
category cards", "Saving puts the row in place", "Opening a charge edits it"; `DECISIONS.md`, "The
timeline is dashed and solid, rows drawn like category cards" and "Adding a bill is a card you
complete, and a grid of category cards dresses it".
**Builds on:** branch `claude/project-thread-e5nurj`, which is `tuning` (`8088222`) plus the brief,
the prototype and the docs. `card-motion` and `tuning` never land on their own; this branch carries
what they built that stays.
**Reference:** `docs/prototypes/dashed-and-solid.html` at its defaults, which are Jake's picks:
`rowBg`, `rowPic`, `dateLine`, `endText`, `todayLine`, `renderPicker`, and the CSS for `.r`, `.rb`,
`.nb`, `.tdl`, `.gc`. Its pixel values are the first guesses below, at 1pt = 1px.

## Already decided — do not reopen

- The card's flight, the flips and the landing go entirely: `CardFlightLayer`, `CardFlip`,
  `CardFlight`, `RowHold`, the held row and its slack are deleted, not kept behind a flag.
- What replaces the landing is today's Reduce Motion path, for everyone, with a mark instead of a
  fade: the sheet goes, the row is brought into view behind it, and the row is marked with
  `Surface.pickedLane`, which fades over `Motion.dayMark` as a calendar tap's mark does.
- The editor stays `EditorSheet`, drawn by the app. It already matches the system sheet (measured
  in `card-motion`'s Lessons), and swapping it is churn with nothing to gain now.
- The hand goes entirely: `CategoryHand`, `HandFan`, their tests and the hand's tokens and motion
  values. The flood, the stamp and the dip go with it; a picked category crossfades the card.
- Over the calendar's month or year, a save still drops the charge into its day (`DayArrival`).
  The calendar is out of the brief.
- The badges are SF Symbols: `arrow.clockwise` for a bill that repeats, `arrow.right.to.line` for
  one with a last payment. Not Dime's, and not drawn by hand.
- Dates are a fixed `d MMM` ("24 Oct"), as `dayLine` is a fixed `EEE d` today. The editor's date
  button keeps its own form.
- Every picture boils by default: `BoilSetting` defaults to `.everywhere`.
- Upcoming rows keep their picture on its wash, as charged ones do, at `Opacity.upcomingPicture`.

## Steps

Steps 1, 3, 4 and 5 are Sonnet's. Step 2 is Opus's: it rewires the scroll-anchored list's save and
open, and a green suite would stay green with it broken (`CLAUDE.md`, model routing). Step 3 needs
step 2 (the row loses its flight-only parameters first); step 4 needs step 3's row; step 5 is
independent of 3 and 4 but follows 2.

### Step 1 — Dates and ends read as words

**Files:** `Tilly/Timeline/TimelineModels.swift`, `Tilly/Timeline/TimelineBuilder.swift`,
`Tilly/Timeline/TimelineFormatting.swift`, `Tilly/Timeline/OccurrenceRow.swift` (only to call the new
functions, keeping its current look), `TillyTests/TimelineFormattingTests.swift`,
`TillyTests/TimelineBuilderTests.swift`, and every test that builds a `TimelineEntry` (modified).

**Interface:**
```swift
struct TimelineEntry {
    // …existing fields…
    let isYearly: Bool // the rule repeats in years: the row carries a `Yearly` tag
}

extension TimelineEntry {
    /// This charge is the bill's last: its rule's date is the series' end.
    var isLastPayment: Bool { get }
}

enum TimelineFormatting {
    /// "24 Oct"; within a day of `today`, "Yesterday · 23 Oct", "Today · 24 Oct", "Tomorrow · 25 Oct".
    static func rowDate(_ date: Date, today: Date, calendar: Calendar = .current, locale: Locale = .current) -> String

    /// "Last payment" on the last charge; "ends this month", "ends next month", then "ends 05/27",
    /// counted in calendar months from `today`'s; "ended 08/26" on an earlier charge once the end
    /// has passed; nil with no end.
    static func endLine(for entry: TimelineEntry, today: Date, calendar: Calendar = .current, locale: Locale = .current) -> String?

    /// "Today, 24 Oct", for the divider.
    static func todayDivider(_ today: Date, calendar: Calendar = .current, locale: Locale = .current) -> String

    /// Gains `today`: "Rent, today, Saturday 24 October, 950 US dollars out, yearly, last payment, upcoming".
    /// The near word only within a day; "yearly" only when yearly; the end as `endLine` says it,
    /// spoken ("ends next month", "ends May 2027", "ended August 2026", "last payment").
    static func accessibilityLabel(for entry: TimelineEntry, today: Date, calendar: Calendar, locale: Locale) -> String
}
```
`dateLine(for:)` is deleted. `dayLine(_:)` stays for the calendar. `OccurrenceRow` gains
`let today: Date`, passed down from `TimelineView.today` through `MonthSectionView`; in this step it
shows `rowDate` and `endLine` joined by " · ", in its current look.

**Done when:** these pass, in `TimelineFormattingTests` unless named otherwise:
`aRowDateIsDayThenMonth`, `aRowDateTodayLeadsWithTheWord`, `tomorrowAndYesterdayLeadWithTheirWords`,
`twoDaysOffIsJustTheDate`, `aRowDateNextYearCarriesNoYear`, `anEndThisMonthSaysSo`,
`anEndNextMonthSaysSo`, `anEndAcrossNewYearCountsCalendarMonths` (today 20 Dec, end 5 Jan: next
month), `anEndFurtherOffIsMonthAndYear`, `theLastChargeSaysLastPayment`,
`aPassedLastChargeStillSaysLastPayment`, `anEarlierChargeOfAnEndedBillReadsEnded`, `noEndHasNoEndLine`,
`theTodayDividerNamesTheDate`, `anAccessibilityLabelSaysLastPayment`, `aYearlyChargeIsSpokenAsYearly`,
`aChargeTodayIsSpokenAsToday`; in `TimelineBuilderTests`, `aYearlyRuleMarksItsEntries` and
`aMonthlyRuleIsNotYearly`. Replaced: `aDateLineReadsAsWeekdayThenDay`,
`aDateLineWithAnEndAddsItsMonth`, `aPassedEndReadsEnded`, `aDateLineWithNoEndIsJustTheDay`. Fixed
dates, UTC and `en_IE`, as the existing tests use.

**Verify:** `cd Core && swift test`, then `xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0' test`.

**Out of scope:** the row's look, the divider, the `Yearly` tag and the badge (step 3 and 4).

### Step 2 — Opening and saving stop flying (Opus)

**Files:** `Tilly/Timeline/TimelineView.swift`, `Tilly/Timeline/MonthSectionView.swift`,
`Tilly/Timeline/OccurrenceRow.swift`, `Tilly/Timeline/RowFrames.swift`, `Tilly/Editor/EditorSheet.swift`,
`Tilly/Editor/ExpenseEditor.swift`, `Tilly/Editor/EditorCard.swift`, `Tilly/DesignSystem/MotionTuning.swift`,
`Tilly/DesignSystem/Tokens.swift`, `TillyTests/TimelineLandingTests.swift`, `TillyTests/MotionTuningTests.swift`
(modified); `Tilly/Editor/CardFlightLayer.swift`, `Tilly/Editor/CardFlip.swift`,
`TillyTests/CardFlightTests.swift` (deleted). Anything else that names `CardFlightLayer.space`.

**Interface:**
```swift
// RowFrames.swift
/// The timeline's coordinate space: rows report in it, and `isInView` reads it. Replaces `CardFlightLayer.space`.
enum TimelineSpace { static let name: String }

@MainActor @Observable
final class RowFrames {
    private(set) var frames: [String: CGRect]
    func report(_ id: String, frame: CGRect?)
}   // `fullFrames`, `reportFull` and `RowHold` are gone

enum TimelineLanding {
    static func target(expenseID: UUID, date: Date, in sections: [MonthKey: MonthSection], calendar: Calendar) -> TimelineEntry?
    static func isInView(_ frame: CGRect, listTop: CGFloat, headerHeight: CGFloat, listBottom: CGFloat) -> Bool
}   // `landsInPlace` and `openedRowRemains` are gone

// MonthSectionView: `hold` and `onHeldRowFrame` go; gains
var markedEntryID: String?   // the row a save just put in place, marked until the mark fades

// OccurrenceRow: `heightFraction`, `showsCard`, `morph`, `tucksUnder`, `cardHeight` and `onFullFrame`
// go, with `RowHeightLayout` and `RowHeightClip`. `isMarked` stays.

// EditorSheet: `onCardRest` and `onDragClose` go.
// ExpenseEditor: `onFace` goes; `EditorCardFace` and `\.editorCardHidden` are deleted.

// TimelineView
@State private var markedEntryID: String?
/// A save over the days: refresh, find the target, `editor = nil`, then bring it into view and mark it.
/// Anything else closes the sheet; a save over the month or year still arrives on its day.
private func closeEditor(_ close: EditorClose)
/// Two turns for the rebuilt rows, a `jump` if the row isn't wholly in view, then `done`.
private func bringIntoView(_ entry: TimelineEntry, generation: Int, then done: @escaping () -> Void)
/// Marks the row, then fades the mark on `.easeOut(duration: Tokens.Motion.dayMark)` a turn later.
private func mark(_ entry: TimelineEntry, generation: Int)
```
`openEntry` builds its session and sets `editor = .edit(session)`, nothing else. `jump(to:)` and
`isInView` keep their measured arithmetic; `isInView` reads `frames`. Removed from `TimelineView`:
`flight`, `flyerFace`, `hidesEditorCard`, `hold`, `heldRowHeight`, `holdSlack` and its
`SlackLayout`, `openedEntry`, `openedRowHeight`, `closingDrag`, `editorCardRest`, `lastCardRest`,
`heldFigure`, `landings` and the landing haptic, `hasArrived`, `LandingGate`, `cardRested`,
`awaitCardRest`, `rise`, `finishOpening`, `landBack`, `releaseOpenedRow`, `land`, `drop`, `arrive()`,
`finishFlight`, `fadeIn`, `flyerFront`. `landingGeneration` stays, renamed `markGeneration`. Removed
motion values: `flip`, `flipHold`, `flipLift`, `drop`, `dropBounce`, `open`, `openBounce`; their
`Tokens.Motion.Card` entries go too. `landingRowOffset` stays (`jump` uses it).

**Done when:** the suite is green with `TimelineLandingTests.unmovedChargeLandsInPlace` and
`movedChargeLandsElsewhereAndItsOldPlaceGoes` deleted and the rest unchanged, `MotionTuningTests`
edited for the shorter catalogue, and, measured in the Simulator and logged:
1. A new bill saved for a day off screen (three months back): the list jumps behind the sheet and
   the marked row's top lands `landingRowOffset` under the pinned header (±1pt).
2. A bill saved on a day on screen: the list doesn't move (offset unchanged to 0.5pt).
3. Opening a row and closing with ✕, with a drag down and with an unchanged ✓: the list doesn't
   move, nothing is marked.
4. Editing a charge's date to another month: the new row is marked, the old one is gone, and the
   month being read holds where it was.
5. Deleting: the row goes, nothing is marked.
6. Under Reduce Motion, the same, with the sheet's existing Reduce Motion exit.

**Verify:** both suites, then the six checks in the Simulator, plus the seam grep in
`.claude/rules/views-and-tokens.md`. `grep -rn "CardFlight\|RowHold\|editorCardHidden\|flyer" Tilly TillyTests` prints nothing.

**Out of scope:** the row's look (step 3). The calendar's `DayArrival`. The hand (step 5).

### Step 3 — Rows are dashed and solid

**Files:** `Tilly/Timeline/OccurrenceRow.swift`, `Tilly/Timeline/MonthSectionView.swift`,
`Tilly/DesignSystem/Drawn/Wash.swift`, `Tilly/DesignSystem/Drawn/CategoryPictureView.swift`,
`Tilly/DesignSystem/Tokens.swift` (modified); `Tilly/Timeline/RowBadge.swift`,
`Tilly/Timeline/YearlyTag.swift` (new).

**Interface:**
```swift
// Wash.swift
/// What's charged: a solid paper card, `Drawn.paperCard`, on the rough shape. No colour, no shadow.
struct PaperCard: View { let cornerRadii: RectangleCornerRadii; let seed: UInt64 }
/// What's still to come: paper inside a faint dashed line, `Drawn.dashFaint`, `Stroke.rowDash`.
struct DashedOutline: View { let cornerRadii: RectangleCornerRadii; let seed: UInt64 }
// `DottedOutline` stays only if something else still draws it; otherwise it goes.

// RowBadge.swift
/// The small disc at a row picture's lower right: ↻ for a bill that repeats, an arrow to a bar for
/// one with an end. Paper card with a ring of page paper when charged; page paper with a hairline
/// when still to come.
struct RowBadge: View { let ends: Bool; let state: OccurrenceState }

// YearlyTag.swift
/// "Yearly", outlined in `Drawn.ink2`, after the date.
struct YearlyTag: View {}
```
The row, from the prototype at its defaults: `Size.row` 64pt (was `stackRow`); the card inset
`Space.rowInset` 12pt from each side and `Space.rowGap / 2` (3pt) from the row's top and bottom, so
cards stand 6pt apart; `Radius.row` 14 on every corner. Content `Space.rowLeading` 12pt and
`Space.rowTrailing` 14pt inside the card, centred vertically. Picture `Size.rowPicture` 34pt on its
wash (`onCard: false`) in every state; still to come at `Opacity.upcomingPicture` 0.8. Badge
`Size.rowBadge` 17pt, symbol `Size.rowBadgeSymbol` 11pt in `Drawn.ink2`, its centre
`Space.rowBadgeOffset` 5pt outside the picture's lower right corner. Name and amount at
`Text.rowName`/`Text.rowAmount` (17pt semibold) in `Ink.primary` when charged; still to come
`Text.rowNameSoft`/`Text.rowAmountSoft` (17pt medium) in `Drawn.ink2`. The date line in
`Text.caption`, `Drawn.ink2`: `rowDate`, then a `YearlyTag` when yearly, then " · " and `endLine`.
`YearlyTag`: `Text.tag` (caption2 bold), padding 6pt across, radius 5, a 1.2pt outline. Skipped stays
as it is now, a dashed outline withdrawn to tertiary with its amount struck through. The month's end
spacer becomes `Space.stackMonthBottom` alone. `Drawn.dashFaint`: 0x1C1B19 at 22% light, 0xF2F1EE at
20% dark. `Stroke.rowDash`: 1.6pt, dash 5 4, round caps. Remove the stack tokens nothing uses
(`stackTuck`, `stackTop`, `stackLeading`, `Shadow.stack*`, `Radius.stackCard`, `Ink.onStackSoft`).
`BoilSetting` defaults to `.everywhere` (its motion value's default 2).

**Done when:** the suite is green, and screenshots in the Simulator (iPhone 17 and an iPhone 13 Pro
size, 390 × 844) show, beside the prototype at the same size: charged and upcoming rows, a
`Last payment`, an `ends next month`, a yearly row's tag, `Today · ` and `Yesterday · `, in light, in
dark and at `accessibility3`. Rows don't overlap or clip at the accessibility size.

**Verify:** both suites; the seam grep; the screenshots, posted for Jake beside the prototype's.

**Out of scope:** the divider (step 4), the picker (step 5), the calendar's and category view's looks.

### Step 4 — A squiggle marks today

**Files:** `Tilly/Timeline/MonthSectionView.swift`, `Tilly/DesignSystem/Tokens.swift` (modified);
`Tilly/Timeline/TodayDivider.swift` (new).

**Interface:**
```swift
/// A wave on each side of "Today, 24 Oct", in `Drawn.ink2`: between the current month's last row
/// still to come and its first charged one.
struct TodayDivider: View { let today: Date }

/// A sine-like wave across `rect`'s width, centred, period `Size.squigglePeriod` (12pt) and
/// height `Size.squiggle` (6pt), drawn as quad curves as the prototype's mask is.
struct Squiggle: Shape {}
```
`MonthSectionView` gains `let today: Date` (if step 1 hasn't put it there) and draws the divider
before the first charged row of the current month, before that day's scroll marker, so a calendar
tap's jump still lands on the row. None when the month has no charged row yet. The wave strokes at
`Stroke.squiggle` 1.3pt and `Opacity.squiggle` 0.5; the label in `Text.caption` semibold; 12pt
between label and waves, `Space.dividerVertical` 8pt above and below, `Space.gutter` at the sides.
VoiceOver reads the label as a header-less static text, "Today, 24 October".

**Done when:** the suite is green; screenshots show the divider at the start of a month (no charged
rows: none), mid-month, and with every row charged (at the month's top), in light, dark and
`accessibility3`; a calendar tap on today's day lands the first row 60pt under the header as before
(±1pt), not the divider.

**Verify:** both suites; screenshots; the calendar-tap measurement.

**Out of scope:** anything in the category view's today line.

### Step 5 — The picker is a grid of category cards

**Files:** `Tilly/Editor/ExpenseEditor.swift`, `Tilly/Editor/EditorCard.swift`,
`Tilly/DesignSystem/MotionTuning.swift`, `Tilly/DesignSystem/Tokens.swift`,
`TillyTests/MotionTuningTests.swift` (modified); `Tilly/Editor/CategoryGrid.swift` (new);
`Tilly/Editor/CategoryHand.swift`, `Tilly/Editor/HandFan.swift`, `TillyTests/HandFanTests.swift`
(deleted).

**Interface:**
```swift
/// The categories four across, in the Settings order, each a paper card, and a dashed `New` last.
/// One tap picks; the picked card carries a ring. Scrolls when the cards outgrow the panel.
struct CategoryGrid: View {
    let categories: [ExpenseCategory]   // Settings order
    let selection: UUID?
    let newBreathes: Bool
    let onPick: (UUID) -> Void
    let onNew: () -> Void
}
```
From the prototype: `LazyVGrid` of `Size.pickerColumns` (4) flexible columns, `Space.pickerGap` 10pt
both ways; a card `Size.pickerCard` 98pt tall, `PaperCard` at `Radius.pickerCard` 10 with
`Shadow.pickerCard` (0 1 2 at 10% black, light only); the picture `Size.pickerPicture` 36pt on its
wash, its top `Space.pickerPictureTop` 14pt down; the name in `Text.pickerName` (12pt bold) in
`Ink.primary`, centred, two lines at most, `Space.pickerNameBottom` 12pt above the bottom; a
`Size.pickerStrip` 4pt strip of the colour along the bottom, inside the card's shape. The picked card:
a `Stroke.pickerRing` 2.5pt ring in `Ink.accent`, 4pt outside the card, radius 14. `New`: a 2pt
dashed outline in `Drawn.ink2`, a light plus and `New`, breathing as it does now. Capped at
`.xxxLarge` as the month's grid is. The selected category stays in the grid (the hand hid it).
`ExpenseEditor` replaces `dress` with a pick that sets `draft.categoryID` inside
`withAnimation(.easeInOut(duration: Tokens.Motion.categoryFade))` (0.16s), and keeps its selection
haptic. `EditorCard` loses `flood`, `stamp`, `dip`, `onTileFrame` and `CardFlood`; its existing
crossfade is the only change of colour. Removed motion values: `press`, `pressLift`, `pressScale`,
`neighbourTilt`, `play`, `flood`, `stampScale`, `stampUnder`, `stampDown`, `stampSettle`, `dip`,
`deal`, `dealStagger`; the hand's tokens go (`handStepMax` … `handArcMax`, `Shadow.hand*`,
`Radius.handCard`, `Size.handCard`, `Text.handName`).

**Done when:** the suite is green with `HandFanTests` deleted and `MotionTuningTests` edited; in the
Simulator, with the made-up set of fourteen categories and with one, a screenshot of the picker
shows every name whole or wrapped to two lines, in light, dark and `accessibility3`; picking one
recolours the card in one quick fade; `New` still makes a category and picks it.

**Verify:** both suites; the seam grep; screenshots.

**Out of scope:** the symbol picker behind `New` (`NewCategoryRow`), All bills, Settings' list.

### Step 6 — On the phone

Jake's iPhone 13 Pro, through Remote Control: a build of the branch, compared with the prototype
on the same phone. Light, dark, his text size and an accessibility size. Anything that reads wrong
is a fix on the branch if it's a value, or a question for Jake if it's a choice. Then ask once
before landing.

**Done when:** Jake has seen it on the phone and said to land it.

## Lessons

- **Step 2: a jump to a row needs the row laid out, not just its month.** With the held row gone,
  `jump` reads the row's height, and a turn after the month's scroll the row sometimes hadn't laid
  out: the height read 0 and the row's `scrollTo` did nothing (a lazy list ignores ids it hasn't
  built), leaving the month's top in view and the row 128pt under the header, two rows down.
  `jump` now waits a turn at a time (up to 10) for the row's frame before its second scroll.
  Measured after: 120.00 under the header, and 119.90 under Reduce Motion (target 120).
- **Step 2: a saved row's frame lags its scroll by a turn.** Read when the mark is set, the row
  was still 8pt short of where it rested (127.92, then 119.92). Measure at rest.
- **Step 2: there is no unchanged ✓ to press.** ✓ is disabled while an edit has changed nothing,
  so check 3's third case can't happen; ✕ and a drag down both left the list still (offset to
  0.00) with nothing marked.
- **Step 2's seam grep matches `CategoryHand`'s own `flyer`**, the hand's played card, which
  goes with the hand in step 5. Nothing of the card's flight is left.
- **Step 3: the badge sits by its edges, not its centre.** The spec put the badge's centre 5pt
  outside the picture's corner; the prototype's `.rb` has `right: -5px; bottom: -5px`, its edges
  5pt out. Built as the prototype, for the side-by-side.
- **Step 3: the prototype's charged card has a light-mode shadow** (`drop-shadow(0 1px 1.5px
  rgba(0,0,0,.09))` on `.r.past .bg`); the spec says no shadow, and the build has none. Worth a
  look on the phone.
- **Step 3: skipped keeps its dotted outline**, as it is now, so `DottedOutline` stays.
  `Shadow.stack*` stays too: `WashImage` still draws it under the editor's card.
- **Step 3: at `accessibility3` the date line truncated** ("29 Oct · ends next…"). At accessibility
  sizes the end now takes its own line when the three don't fit (`ViewThatFits`).
- **`simctl ui … appearance` and `content_size` reach the app only after a relaunch.**
- **Step 4: the divider sits before the first row dated today or earlier**, the top of its day, so
  it always comes before that day's scroll marker; a calendar tap on today landed the first row
  59.97pt under the list's top, flush under the 60pt header, with the divider tucked behind it.
- **Step 4: a `Shape` that reads `Tokens.Size` won't build** (main-actor isolation crosses into
  `Shape`): `Squiggle` takes its period and height. The divider's sides use `Space.gutter` (20pt)
  as the spec says, where the prototype's `.tdl` pads 24.
- **Step 4: VoiceOver reads "Today, 24 October"**, from `spokenTodayDivider`, beside `todayDivider`.

## If a step is wrong

These specs were written before the code existed. If a step turns out to be
ambiguous, impossible, or wrong, **stop and say so** — don't improvise a fix and
don't silently widen the scope. A wrong spec caught in one message costs far less
than a wrong spec followed to completion.
