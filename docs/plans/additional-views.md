# Additional views: the calendar as zoom levels, and All bills — implementation plan

**Brief:** docs/briefs/additional-views/brief.md (Updates, 2026-10-01: "round 2 settles it")
**Settled by:** `docs/prototypes/zoom-and-bills.html`, round 2, on its chosen switches. DESIGN.md
and DECISIONS.md change in Step 11, once the app does what they will say.

## Already decided — do not reopen

- **Calendar replaces Timeline in the view menu.** `ViewMode.timeline` keeps its raw value
  (`"timeline"`, stored) and is retitled "Calendar". Categories (the lanes) stay exactly as they
  are: no Extras toggle, their own arrows, their own month button behaviour.
- **Three levels, one place:** the year (the next twelve months from this one, not paged), a
  month (a paged grid), and the day level, which *is* the existing timeline scrolled to that day.
  The app reopens on the level, and the month, it was left on. First run opens on this month.
- **Extras** are charges whose rule doesn't charge in every calendar month
  (`RecurrenceRule.chargesEveryMonth == false`). Weekly and fortnightly bills are usual, not extras.
- **One All / Extras toggle, held at every level,** stored across launches. With Extras, the
  month and the timeline show only extras and their figures read `+€351 on top`.
- **The year with everything shown:** each month labelled with its total, bold when its extras
  reach a fifth of the usual month; a grey dot for a day of only usual charges; an extra as a
  dot in its category's colour, larger when that day's extras reach a fifth of the usual month;
  a ring where an every-month bill starts a record (a new bill, or a price change) or ends, dashed
  at €0. The usual month is the median of the twelve months' usual-charge totals.
- **The month button:** hidden at the year; on a month it pages to this month; on the timeline it
  scrolls back, as now. It stays as it is when already there.
- **All bills is a sheet** from a list button beside settings, bottom right. Monthly / Yearly at
  the top, stored across launches, Monthly first. Monthly is a bill's year ÷ 12. No bill count,
  no "a year" under totals. Cards, chips and rows highest first. Ended bills behind a line under
  the cards that opens a card of them, each with what it cost in all.
- **Tapping a bill opens its next charge in the editor;** an ended bill opens its last charge.
- **No minus sign on any amount,** anywhere. A zero is `€0` as before.
- **Skipped charges** (nothing in v1 writes one) don't appear on the calendar or the year, and
  count toward nothing, as on the timeline. The timeline still lists them.
- **Planned one-offs are out.** The model can't hold one yet; they get their own brief.

## Steps

Order: 1 → 3 → 4, and 1 → 5. 2 is independent. 6 needs 3; 7 needs 6; 8 needs 4 and 7; 9 needs
7 and 8; 10 needs 5. 11 is last. **Steps 7 and 9 change scroll geometry and anchoring: Opus
builds them** (CLAUDE.md, "Implementation splits"). The rest are Sonnet's.

UI steps also verify by screenshot in the Simulator (CLAUDE.md, "Verification"): light, dark, an
accessibility text size, and the developer scenarios with only monthly bills and with renewals.
`.claude/rules/simulator.md` covers booting after a test run and setting `viewMode`.

---

### Step 1 — Teach the rule whether it charges every month, and how often a year

**Files:** `Core/Sources/TillyCore/RecurrenceRule.swift` (modified),
`Core/Tests/TillyCoreTests/RecurrenceRuleTests.swift` (modified)

**Interface:**
```swift
extension RecurrenceRule {
    /// True when every calendar month holds at least one charge while the rule runs: every 1–28
    /// days, every 1–4 weeks, or every month. Every N months for N ≥ 2, and every year, are
    /// extras. Ignores `endDate`: this describes the rhythm, not the span.
    public var chargesEveryMonth: Bool { get }

    /// Charges in a year at this rhythm: 12/N for months, 1/N for years, 52/N for weeks,
    /// 365/N for days. A fixed count, not a calendar walk: All bills normalises a rhythm, it
    /// doesn't count a particular year.
    public var paymentsPerYear: Decimal { get }
}
```

**Done when:** new `@Test`s pass: `monthlyChargesEveryMonth`, `everyTwoMonthsIsExtra`,
`yearlyIsExtra`, `everyFourWeeksChargesEveryMonth`, `everyFiveWeeksIsExtra`,
`every28DaysChargesEveryMonth`, `every29DaysIsExtra`, `paymentsPerYearByUnit` (month 1 → 12,
month 3 → 4, year 1 → 1, year 2 → 0.5, week 2 → 26, day 1 → 365), and every existing Core test.

**Verify:** `cd Core && swift test`

**Out of scope:** any app-target change.

---

### Step 2 — Drop the minus sign from every amount

**Files:** `Tilly/Timeline/TimelineFormatting.swift` (modified),
`TillyTests/TimelineFormattingTests.swift` and `TillyTests/CategoryFormattingTests.swift`
(modified: this step exists to change what they assert)

**Interface:** `TimelineFormatting.amount(_:locale:)` keeps its signature and returns the
magnitude alone: `"€950"`, `"€0"`, `"—"` for nil. Its doc comment says so. VoiceOver keeps "out".

**Done when:** the existing expectations at `TimelineFormattingTests.swift` lines 19, 144, 149,
154 and `CategoryFormattingTests.swift` lines 86, 98, 104 are rewritten without `\u{2212}` and pass;
no other test changes; `grep -rn 'u{2212}' Tilly` prints nothing.

**Verify:** `xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0' -resultBundlePath /tmp/tilly-step2.xcresult test`

**Out of scope:** DESIGN.md (Step 11). Any other wording.

---

### Step 3 — Carry "extra" and "starts a record" on every entry, and build a month as a grid

**Files:** `Tilly/Timeline/TimelineModels.swift`, `Tilly/Timeline/TimelineBuilder.swift`,
`Tilly/Timeline/TimelineFormatting.swift`, `Tilly/Timeline/TimelineView.swift` (its one
`MonthSection(` call), `Tilly/Categories/CategoryMonthBuilder.swift` (modified);
`Tilly/Calendar/CalendarMonth.swift`, `Tilly/Calendar/CalendarMonthBuilder.swift`,
`Tilly/Calendar/CalendarFormatting.swift` (new); `TillyTests/TimelineBuilderTests.swift`,
`TillyTests/TimelineFormattingTests.swift`, `TillyTests/CategoryFormattingTests.swift`,
`TillyTests/DeveloperScenarioTests.swift` (modified, only to pass the new fields),
`TillyTests/CalendarMonthBuilderTests.swift`, `TillyTests/CalendarFormattingTests.swift` (new)

**Interface:**
```swift
// TimelineEntry gains, with no defaults (every construction site states them):
let isExtra: Bool        // !snapshot.rule.chargesEveryMonth
let startsRecord: Bool   // scheduledDate is its record's anchor, start of day

// MonthSection gains, required in init, no default:
/// Built with only extras: `entries`, `total` and `remaining` count extras alone.
let showsExtrasOnly: Bool

// TimelineBuilder
static func month(_ month: MonthKey, expenses: [TimelineExpense], today: Date,
                  calendar: Calendar, extrasOnly: Bool) -> MonthSection

// TimelineFormatting.headerFigure(for:locale:), when section.showsExtrasOnly:
//   "+€351 on top" (total, current month included), "Nothing on top" when no entries.

// Tilly/Calendar/CalendarMonth.swift
struct CalendarDay: Identifiable, Equatable, Sendable {
    let day: Int               // 1...31
    let date: Date             // start of day
    let entries: [TimelineEntry] // skipped left out; amount descending, ties by name, nil last
    let total: Decimal         // entries' amounts; nil adds nothing
    let isUpcoming: Bool       // date after today
    var id: Int { day }
}
struct CalendarMonth: Equatable, Sendable {
    let section: MonthSection
    let leadingDays: Int       // grid cells before the 1st, from calendar.firstWeekday
    let trailingDays: Int      // cells after the last day, completing the final week
    let days: [CalendarDay]    // every day of the month, empty ones included
}
enum CalendarMonthBuilder {
    static func month(_ section: MonthSection, today: Date, calendar: Calendar) -> CalendarMonth
}

// Tilly/Calendar/CalendarFormatting.swift
enum CalendarFormatting {
    /// headerFigure, except an empty month that isn't the current one: "Nothing this month",
    /// or "Nothing on top" with extras only.
    static func monthFigure(for section: MonthSection, locale: Locale) -> String
    /// "Mon 5, 2 charges, €1,185" — VoiceOver for a day cell.
    static func dayLabel(_ day: CalendarDay, calendar: Calendar, locale: Locale) -> String
}
```

**Done when:** new tests pass — `TimelineBuilderTests`: `monthlyEntryIsNotExtra`,
`quarterlyEntryIsExtra`, `firstChargeStartsRecord`, `laterChargeDoesNotStartRecord`,
`extrasOnlyDropsUsualEntries`, `extrasOnlyTotalsCountExtrasAlone`; `CalendarMonthBuilderTests`:
`everyDayIsPresent` (a 31-day month gives 31), `leadingDaysFollowFirstWeekday` (Monday-first and
Sunday-first calendars), `trailingDaysCompleteTheWeek`, `dayEntriesSortByAmount`,
`skippedChargeLeavesTheDay`, `nilAmountAddsNothing`, `todayIsNotUpcoming`;
`CalendarFormattingTests`: `emptyMonthSaysNothing`, `emptyCurrentMonthKeepsLeft`,
`extrasFigureHasPlusAndOnTop`, `extrasEmptySaysNothingOnTop`, `dayLabelReadsChargesAndTotal`
(and a non-euro locale). Every existing test passes, edited only to pass the new fields.

**Verify:** the Step 2 command, with `-resultBundlePath /tmp/tilly-step3.xcresult`.

**Out of scope:** any view. Every existing caller passes `extrasOnly: false`.

---

### Step 4 — Build the year overview

**Files:** `Tilly/Calendar/YearOverview.swift`, `Tilly/Calendar/YearBuilder.swift` (new);
`Tilly/Calendar/CalendarFormatting.swift` (modified); `TillyTests/YearBuilderTests.swift` (new),
`TillyTests/CalendarFormattingTests.swift` (modified)

**Interface:**
```swift
enum YearMark: Equatable, Sendable {
    case quiet                                   // nothing charged: a faint dot
    case usual                                   // only usual charges: a grey dot
    case extra(CategoryColour?, isLarge: Bool)   // the day's costliest extra's colour
    case change(CategoryColour?, isZero: Bool)   // a usual bill starts a record or ends: a ring
    case today
}
struct YearMonth: Identifiable, Equatable, Sendable {
    let month: MonthKey
    let total: Decimal         // every non-skipped charge
    let extrasTotal: Decimal
    let isHeavy: Bool          // extrasTotal ≥ usualMonth × YearBuilder.heavyShare, and > 0
    let leadingDays: Int
    let marks: [YearMark]      // one per day of the month
    var id: Int { month.id }
}
struct YearOverview: Equatable, Sendable {
    let months: [YearMonth]    // twelve, the current month first
    let total: Decimal
    let extrasTotal: Decimal
    let usualMonth: Decimal    // median of (total − extrasTotal) over the twelve; mean of the middle two
    let hasExtras: Bool
}
enum YearBuilder {
    /// A fifth of the usual month: what makes a month's label bold and a day's dot large. Relative,
    /// so it holds in any currency and for any size of bills (tenet 4: measured against your own).
    static let heavyShare: Decimal = 0.2
    /// `sections`: the twelve months from the current one, built with `extrasOnly: false`.
    /// `extrasOnly` changes the marks only: usual days become `.quiet`; rings stay.
    static func overview(sections: [MonthSection], categoryOf: [UUID: UUID],
                         categories: [CategoryInfo], extrasOnly: Bool,
                         today: Date, calendar: Calendar) -> YearOverview
}
// CalendarFormatting adds:
static func yearRange(_ overview: YearOverview, calendar: Calendar, locale: Locale) -> String  // "Sep – Aug"
static func yearFigure(_ overview: YearOverview, extrasOnly: Bool, locale: Locale) -> String
//   "€19,610 · usual month €1,402"; extras: "+€2,775 on top · usual month €1,402";
//   extras with none: "Nothing on top · usual month €1,390"
static func monthLabel(_ month: YearMonth, extrasOnly: Bool, locale: Locale) -> String
//   total, "" for a month with no charges; extras: "+€351", "" for none
```
Mark priority on a day: today, extra, change, usual, quiet. A ring is an `entry.startsRecord`
dated in or after the current month, an entry whose date is its `endDate`, or an amount of 0.

**Done when:** `YearBuilderTests`: `twelveMonthsFromCurrent`, `usualMonthIsMedian`,
`steadyUserHasNoExtrasAndUsualDots`, `extraTakesCostliestColour`, `largeExtraAtHeavyShare`,
`monthIsHeavyAtShare`, `emptyMonthIsNotHeavy`, `ringOnPriceChange` (a "future charges" split),
`ringOnLastCharge`, `dashedRingOnZero`, `extrasOnlyQuietsUsualDays`, `todayWins`; formatting
tests for each string above, one in a non-euro locale. Every existing test passes.

**Verify:** the Step 2 command, `-resultBundlePath /tmp/tilly-step4.xcresult`.

**Out of scope:** any view.

---

### Step 5 — Build All bills

**Files:** `Tilly/Bills/AllBills.swift`, `Tilly/Bills/AllBillsBuilder.swift`,
`Tilly/Bills/BillsFormatting.swift` (new); `Tilly/Models/Expense+Timeline.swift` (modified);
`TillyTests/AllBillsBuilderTests.swift`, `TillyTests/BillsFormattingTests.swift` (new)

**Interface:**
```swift
/// One record of a bill, reduced for the builder.
struct BillInput: Equatable, Sendable {
    let seriesKey: UUID
    let expenseID: UUID
    let name: String
    let categoryID: UUID?
    let snapshot: ExpenseSnapshot
    let overrides: [OccurrenceOverride]
}
extension Expense { static func billInputs(_ expenses: [Expense]) -> [BillInput] }

enum BillPeriod: String, CaseIterable, Sendable { case month, year }  // stored: never rename

struct ChargeRef: Equatable, Sendable { let expenseID: UUID; let scheduledDate: Date }

enum BillState: Equatable, Sendable {
    case runs
    case starts(Date)                       // its first charge is after today
    case changes(Date, from: Decimal?)      // a later record starts after today
    case ends(Date)                         // the series' last charge, after today
    case ended(Date)                        // the series' last charge, today or earlier
}
struct BillRow: Identifiable, Equatable, Sendable {
    let id: UUID                 // seriesKey
    let name: String             // the latest record's
    let categoryID: UUID?
    let charge: Decimal?         // the latest record's amount
    let rule: RecurrenceRule     // the latest record's
    let figure: Decimal?         // per period, whole units; nil when the amount isn't known
    let state: BillState
    let paidInAll: Decimal       // non-skipped charges up to today, across the series
    let opens: ChargeRef?        // next charge after today, else the last charge
}
struct BillCard: Identifiable, Equatable, Sendable {
    let category: CategoryInfo?  // nil: bills saved before categories existed
    let rows: [BillRow]          // figure descending, ties by name, nil last
    let total: Decimal           // sum of its rows' figures
    var id: String { category?.id.uuidString ?? "uncategorised" }
}
struct AllBills: Equatable, Sendable {
    let cards: [BillCard]        // bills still running; total descending, ties in Settings order
    let ended: [BillRow]         // paidInAll descending
    let total: Decimal
}
enum AllBillsBuilder {
    static func bills(_ inputs: [BillInput], categories: [CategoryInfo], period: BillPeriod,
                      today: Date, calendar: Calendar) -> AllBills
}
enum BillsFormatting {
    /// "€640 yearly", "€41 every 2 months", "€15 every 2 weeks", "Monthly" when the figure *is*
    /// the charge (monthly in Monthly, yearly in Yearly), joined to the state with " · ":
    /// "€25 until Nov 10", "from Oct 18", "ends 12/26". A plain "Monthly"/"Yearly" gives way to
    /// the state alone. An ended row: "ended 08/26".
    static func note(for row: BillRow, period: BillPeriod, calendar: Calendar, locale: Locale) -> String
    static func total(_ value: Decimal, period: BillPeriod, locale: Locale) -> String  // "€1,563 a month"
}
```
Figures: yearly = charge × `rule.paymentsPerYear`, rounded to whole units; monthly = that ÷ 12,
rounded. Round each row, then sum (DESIGN.md, "Amounts"). Archived records are left out.

**Done when:** `AllBillsBuilderTests`: `seriesIsOneRow`, `latestRecordNamesTheRow`,
`yearlyFigureNormalises`, `monthlyFigureIsYearOverTwelve`, `totalsSumRoundedRows`,
`cardsSortByTotal`, `rowsSortByFigure`, `endedBillLeavesCards`, `endedOnTodayIsEnded`,
`paidInAllSkipsSkipped`, `opensNextCharge`, `endedOpensLastCharge`, `changeStateNamesOldAmount`,
`startsStateForFutureFirstCharge`, `nilAmountRowHasNoFigure`, `archivedLeftOut`;
`BillsFormattingTests` for each note form above, in both periods, and one non-euro locale.

**Verify:** the Step 2 command, `-resultBundlePath /tmp/tilly-step5.xcresult`.

**Out of scope:** any view.

---

### Step 6 — Show the Calendar view's month

**Files:** `Tilly/Shell/ViewMode.swift`, `TillyTests/ViewModeTests.swift`,
`Tilly/Timeline/TimelineView.swift`, `Tilly/DesignSystem/Tokens.swift` (modified);
`Tilly/Calendar/CalendarLevel.swift`, `Tilly/Calendar/CalendarMonthView.swift`,
`Tilly/Calendar/CalendarDayCell.swift` (new)

**Interface:**
```swift
// ViewMode.timeline: title "Calendar", systemImage "calendar". Raw value unchanged.
enum CalendarLevel: String, Sendable { case year, month, day }  // stored: never rename

struct CalendarMonthView: View {
    @Binding var month: MonthKey
    let window: TimelineWindow      // floor and ceiling bound paging
    let calendarMonth: CalendarMonth
    let today: Date
    let onOpenDay: (Date) -> Void
}
```
`TimelineView` gains `@AppStorage("calendarLevel") level: CalendarLevel = .month` and
`@AppStorage("calendarMonthID")` for the month shown, clamped into the window as `categoryMonth`
is. With `mode == .timeline` and `level == .month`, `CalendarMonthView` lies over the timeline,
which stays mounted, hidden, exactly as `CategoryView` does. The header row carries `MonthArrows`
left of `HeaderControls`, as on the lanes. The month's sections come from `TimelineBuilder` with
`extrasOnly: false`, built on demand for the month shown.

The view, under the header row: the month's name in a new `Tokens.Text.calendarTitle`
(`.title.weight(.bold)`) over `CalendarFormatting.monthFigure`; a row of very short weekday
symbols from `calendar.firstWeekday`; the grid. A cell: the day number (today in a red circle,
new `Tokens.Ink.today`); the costliest charge's emoji, or two overlapped and `+N` beyond two; the
day total in a new `Tokens.Text.dayTotal`. An upcoming cell sits back as an upcoming row does
(`Tokens.Opacity.upcomingIcon`, `Ink.secondary`). Days of the neighbouring months show their
number only, `Ink.tertiary`. Row height `Tokens.Size.calendarRow` 80pt, or
`calendarRowSixWeeks` 68pt in a six-week month. The grid caps Dynamic Type at
`.xxxLarge`, as Calendar's grid does, and each charged cell is a button with
`CalendarFormatting.dayLabel` for VoiceOver.

Paging: the arrows, and a horizontal swipe past `Tokens.Size.pageSwipe` (60pt). Tapping a day
with charges sets `level = .day` and scrolls the timeline to that day's month with the existing
`scrollTo(month.id, anchor: .top)`; the month button there returns to the month level. On the
month level the month button pages to this month.

**Done when:** `ViewModeTests` asserts the new title and the unchanged raw value; a new
`CalendarLevelTests.rawValuesAreStable`; every existing test passes; the seam check in
`.claude/rules/views-and-tokens.md` prints nothing; screenshots of September and a six-week month,
light, dark and at AX size, and of a day tap landing on the timeline.

**Verify:** the Step 2 command, `-resultBundlePath /tmp/tilly-step6.xcresult`, then screenshots.

**Out of scope:** the year, back buttons, the top row over the timeline, transitions, the Extras
toggle. Categories untouched.

---

### Step 7 — The timeline as the day level (Opus)

**Files:** `Tilly/Timeline/TimelineView.swift` (modified), `Tilly/Shell/BackButton.swift` (new),
`Tilly/Timeline/OccurrenceRow.swift` (modified: a row id for scrolling)

**Interface:**
```swift
/// A glass capsule: chevron and a level's name, "‹ October". `Tokens.Size.floatingButton` high.
struct BackButton: View {
    let title: String
    let action: () -> Void
}
```
On the day level, a top row of `Tokens.Size.headerRow` holds `BackButton` (the month under the
middle of the viewport, live, "‹ October") and the glass pair; the list's pinned month headers
pin beneath that row, not in it. The back button returns to the month level on that month. A day
tap scrolls so that day's first row sits under the pinned header, briefly marked
(`Tokens.Surface.pickedLane`, fading out over a new `Tokens.Motion.dayMark`, 1.2s). The month
button on the day level goes back to scrolling the timeline to this month, as it does today,
replacing Step 6's interim return to the month level. The restore, the anchoring on a window change and the floor
spacer all account for the new row: re-measure each, as `.claude/rules/swiftui-scrolling.md` says.

**Done when:** every existing test passes; on device or Simulator, measured: a day tap lands its
first row under the pinned header within a point; the back button's name follows the month under
the middle; a relaunch on the day level restores the month; the month button still returns from
deep history and two years ahead; screenshots light, dark, AX.

**Verify:** the Step 2 command, `-resultBundlePath /tmp/tilly-step7.xcresult`, then measurement.

**Out of scope:** the year, transitions, the Extras toggle.

---

### Step 8 — The year, and moving between levels

**Files:** `Tilly/Calendar/YearView.swift`, `Tilly/Calendar/YearMonthCell.swift` (new);
`Tilly/Calendar/CalendarMonthView.swift`, `Tilly/Timeline/TimelineView.swift`,
`Tilly/Timeline/MonthButton.swift`, `Tilly/DesignSystem/Tokens.swift` (modified)

**Interface:**
```swift
struct YearView: View {
    let overview: YearOverview
    let extrasOnly: Bool
    let today: Date
    let onOpenMonth: (MonthKey) -> Void
}
```
The year: top row with the glass pair alone; the range (`calendarTitle`) over `yearFigure`; a
three-column grid of the twelve months, each its short name (this month in `Ink.today`) and
`monthLabel` (semibold and `Ink.primary` when `isHeavy`), over its days as marks: quiet a 2.6pt
`Ink.tertiary` dot, usual 5pt `Ink.secondary`, extra 7pt or large 11pt filled in
`Tokens.CategoryColour`, change a 7pt ring, dashed at €0. Under the grid, a key: the extra dot,
the ring, and the usual dot, each with its line from the prototype (without "or one you planned");
for a steady user, the usual dot and "Every month is €1,390. A yearly renewal would show in
colour." New tokens for every size here. The month level gains `BackButton("Year")` at the top
row's leading end. Tapping a month opens it.

Moving between levels zooms: in, scale from 0.93 and fade; out, from 1.07 (new
`Tokens.Motion.zoom`, 0.28s); a crossfade under Reduce Motion. The month button is hidden on the
year (`MonthButton` takes an optional action; nil hides it and its accessibility element).

**Done when:** every existing test passes; screenshots of the year for the sample, monthly-only
and one-giant-bill developer scenarios, light, dark, AX; the round trip year → month → day →
month → year by taps.

**Verify:** the Step 2 command, `-resultBundlePath /tmp/tilly-step8.xcresult`, then screenshots.

**Out of scope:** the Extras toggle (the year shows everything until Step 9).

---

### Step 9 — The Extras toggle, held at every level (Opus)

**Files:** `Tilly/Calendar/ExtrasToggle.swift` (new); `Tilly/Timeline/TimelineView.swift`,
`Tilly/Calendar/YearView.swift`, `Tilly/Calendar/CalendarMonthView.swift` (modified)

**Interface:**
```swift
/// "All" / "Extras": a stock segmented `Picker` on glass, under the top row's trailing end at
/// every Calendar level, floating over the pinned header on the timeline.
struct ExtrasToggle: View {
    @Binding var extrasOnly: Bool
}
```
`@AppStorage("showsExtrasOnly")` in `TimelineView`. Every builder call passes it. On the
timeline, a change rebuilds the sections and the month under the middle holds where it is
("Nothing under the reader's eyes moves"), with `anchorAndSettle`; an empty month drops out as
any empty month does. If stock segmented-on-glass reads as glass on glass, stop and show it
rather than restyling.

**Done when:** every existing test passes; measured: toggling on the timeline mid-history keeps
the month under the middle within a point; the toggle reads the same at all three levels;
screenshots both states, light, dark, AX.

**Verify:** the Step 2 command, `-resultBundlePath /tmp/tilly-step9.xcresult`, then measurement.

**Out of scope:** Categories.

---

### Step 10 — The All bills sheet

**Files:** `Tilly/Bills/AllBillsSheet.swift`, `Tilly/Bills/BillCardView.swift`,
`Tilly/Shell/BottomTrailingControls.swift` (new); `Tilly/Timeline/TimelineView.swift`,
`Tilly/DesignSystem/Tokens.swift` (modified)

**Interface:**
```swift
/// All bills and settings: one glass capsule, bottom right, in every view.
struct BottomTrailingControls: View {
    let onBills: () -> Void
    let onSettings: () -> Void
}
struct AllBillsSheet: View {
    let today: Date
    // @Query expenses and categories; @AppStorage("billsPeriod") period: BillPeriod = .month
}
```
A sheet at the large detent. Toolbar: close leading, the Monthly / Yearly segmented `Picker` as
the principal item. Then the title (`All bills`, or the picked category's name) over
`BillsFormatting.total`; a row of chips (All, then each category with running bills, in card
order); the cards, filtered by the chip. A card: emoji, name, total on one line; its rows,
name, note (`Ink.secondary`, truncating), figure. Under the cards: "2 ended bills" with
Show / Hide, opening a card of ended rows (emoji and name, "ended 08/26", paid in all), filtered
by the chip too. Rows are buttons: `EditSession.make` with the row's `opens`, the editor as a
sheet over this one, and the sheet rebuilds on its `onDismiss` (`.claude/rules/swiftui-controls.md`,
`@Query`). Built in `body` from the builder, as `CategoryView` is.

**Done when:** every existing test passes; seam check prints nothing; screenshots in both periods,
a chip picked, ended open, light, dark, AX; a tapped bill opens the right charge and a saved edit
shows on dismiss.

**Verify:** the Step 2 command, `-resultBundlePath /tmp/tilly-step10.xcresult`, then screenshots.

**Out of scope:** sorting controls, searching, an ended chip.

---

### Step 11 — Bring the docs into line (Opus)

**Files:** `docs/DESIGN.md`, `docs/DECISIONS.md`, `docs/ROADMAP.md`, `docs/PROJECT.md` as needed;
the brief's Updates; this plan's Lessons.

DESIGN.md gains "The calendar" (levels, the year, the month, the toggle) and "All bills"; "The
shell", "Amounts", "Getting back" and copy rules change; DESIGN.md is already 252/250, so
consolidate rather than trim. DECISIONS.md: replace "Views switch in place…" (a list of every
expense now exists, as a sheet; the timeline's top row is back as the home for the back button)
and "The timeline is one list…" where it names the timeline as the view.

**Done when:** `scripts/doc-budget.sh` passes.

**Verify:** `scripts/doc-budget.sh`

**Out of scope:** TASTE.md (`tilly-prune`).

## Lessons

- The minus sign also sat as a literal `−` in doc comments, which a grep for `u{2212}` misses.
- `#expect(decimal == 950 * 12)` failed while the value printed 11400. State Decimal expectations
  as `Decimal(11400)`.
- Adding fields with no default to `TimelineEntry` and `MonthSection` makes every missed
  construction site a compile error: `TimelineView` (3), `CategoryMonthBuilder` (3), tests.
- A failing `xcodebuild test` can outrun a 600s tool timeout (`simctl diagnose`, `simulator.md`);
  read the failures from the log rather than waiting on the summary.
- Blocks sharing one `LazyVGrid` need distinct id spaces: `0..<n` for neighbouring days collided
  with the days' own `1...31` and the trailing cells drew 29, 30 where 1, 2 belonged.
- **A lazy list resolves only ids it has laid out.** `scrollTo` a row in a month it hadn't built
  didn't move. Scroll to the month, then to the row a turn later; both unanimated, the second
  landed (59.86 under a 60pt header). A zero-high marker as the target needs no row height.
- **A header the list stops drawing keeps its last offset,** which then lies: after a jump the
  month under the middle read June from a stale entry. Clear it in the header's `onDisappear`.
- `ScrollGeometry.containerSize.height` already excludes the bottom `contentMargins` (660 =
  718 − 58). The list's height is the viewport less the top row, derived, not measured.
- The Simulator tool's screenshots lag about a second behind a tap; `simctl io booted
  screenshot` doesn't.

## If a step is wrong

These specs were written before the code existed. If a step turns out to be ambiguous,
impossible, or wrong, **stop and say so** — don't improvise a fix and don't silently widen the
scope. A wrong spec caught in one message costs far less than a wrong spec followed to completion.
