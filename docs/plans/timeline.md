# Timeline — implementation plan

**Brief:** `docs/briefs/timeline/brief.md`
**Dimensions:** `docs/briefs/timeline/dimensions.md` — measured off the canvas, snapped to a
4-point grid. This plan turns those numbers into named tokens.
**Design canvas:** https://claude.ai/code/artifact/78215267-24f8-4d21-9a48-a59d37be83c1
**Decisions:** the twelve entries dated 2026-09-07 in `docs/DECISIONS.md`, plus "The
occurrence window means effective dates" (2026-09-06).
**Builds on:** `docs/plans/app-scaffolding.md` — the project, the model layer and the token
file all exist and are green.

Replaces `Tilly/RootView.swift` with the timeline screen. No editor, no categories, no
insights, no headline number.

---

## Already decided — do not reopen

Every one of these is in `DECISIONS.md` or `DESIGN.md`. A step that finds itself weighing one
of them has misread the plan.

- **Weight carries time; a mark carries certainty.** Upcoming sits back, charged comes
  forward, skipped withdraws further and strikes its amount through. `EST` is a bordered
  mark beside the amount — never a tilde, never lightness.
- **One month expanded, its neighbours as collapsed bars.** Not one uninterrupted list.
  Months do *not* arrive indefinitely as you scroll — the brief's scope answer on that is
  superseded.
- **A day groups only when it holds more than one charge.** One charge is an ordinary row
  carrying its own date. Two or more collapse under a heading with a day total and give up
  their individual dates.
- **Rules exist to close a group.** No separator between rows. A hairline appears above and
  below a grouped day, and along the bottom edge of a collapsed month bar. Nowhere else.
- **No tinted card around a group.** Tried, drawn, rejected — it broke amount alignment and
  made an upcoming group heavier than a charged row.
- **Nothing marks the boundary between upcoming and charged.** No divider, no `TODAY` badge.
  **The `TODAY` badge visible on the canvas's "At rest" artboard is the rejected option** —
  page 2 of the canvas is where that question was still open, and `DECISIONS.md` closed it
  against the badge. Build the canvas minus the badge.
- **A moved occurrence appears at its new date and nowhere else.** No ghost row, no "moved
  from the 1st" line.
- **Month headers and collapsed bars both carry that month's total,** excluding skipped
  occurrences, marked `EST` when the month contains an estimate.
- **Every amount carries a minus sign** — rows, day totals, month totals.
- **The row leads with a fixed-size icon slot,** and the date moves beneath the name.
  Categories ship empty, so **the slot renders as an empty well with no glyph in v1.** Any
  glyph in a mockup is illustrative of the slot; shipping one is a starter set by the back
  door, and tenet 4 forbids it.
- **No look-ahead slot is reserved.** The collapsed bar already answers "is something big
  coming".
- **The timeline never resets your position.** You return to the month you left, opened as
  you left it, at the scroll position you left it at, whether or not the process survived.
  The current month decides where you land exactly once, on first run.
- **Where an estimated amount comes from is not this screen's problem.** `EST` means the user
  entered a rough figure and will correct it. Nothing predicts anything. That belongs to the
  editor and the overrides UI.
- **The system owns the top.** Nothing paints into the status bar / Dynamic Island inset.

And the two traps, both already written down:

- **Fetch every override, unfiltered by date.** A bill can be moved *into* a month from
  outside it, and filtering overrides by the query window drops exactly those. `Expense`
  already exposes `overrideSnapshots` unfiltered for this reason — use it and do not narrow it.
- **Skipped occurrences come back flagged, not removed.** Excluding them from totals is the
  caller's job, and the caller is this plan.

---

## Decisions this plan makes

These were genuinely open. Each is settled here so no step stops to ask; each is a small,
reversible change if Jake disagrees; and `tilly-ship` should record the ones marked ★ in
`DECISIONS.md`, because they are product decisions rather than implementation detail.

### ★ An occurrence dated today is charged

`effectiveDate <= today` at day granularity is charged; strictly later is upcoming. The
alternative — today's bill stays upcoming until midnight — puts a row in a state that looks
like it is waiting for you for up to 24 hours, which is what tenet 1 exists to prevent.
Skipped overrides both: a skipped occurrence is `.skipped` whether its date has passed or not.

### ★ A collapsed bar can also be tapped

`DECISIONS.md` says pulling opens a bar. Pulling is the primary gesture and Step 6 builds it.
But a pull is invisible to VoiceOver and Switch Control, so the bar is also a `Button` that
does exactly the same thing. This is an accessibility affordance, not a second interaction
model — nothing about the bar's appearance changes.

### ★ Amounts round to whole units at the boundary, before anything is totalled

`DESIGN.md` says amounts round to whole units. Rounding at display time and summing the
unrounded values would let a total differ by a unit from the rows visibly above it, which
reads as a bug. So `TimelineEntry.amount` is already whole (`NSDecimalRound`, `.plain`), and
every total is an exact sum of the figures on screen.

### ★ A zero total carries no minus sign

A month or day totalling zero renders as `€0`, not `−€0`. The sign sets the register for
money going out; there is none.

### ★ Within a grouped day, entries descend by amount

Ties break on name, ascending, so the order is deterministic. The canvas shows this in both
grouped days it draws (95 before 22; 11 before 3). The engine's own order — effective date,
then scheduled date — says nothing useful inside a single day.

### ★ A day heading takes the ink of the day, and a day total marks `EST` on the same rule as a month total

The canvas draws an upcoming day's heading at tertiary and a charged day's at secondary, so
the heading follows the day's temporal state like everything else. `DECISIONS.md` gives the
`EST` rule for month totals only; a day total containing an estimate is soft for exactly the
same reason, so it carries the same mark.

### ★ A month name carries its year only when that year is not the current one

"September" in 2026; "September 2025" once you have scrolled back far enough for the
ambiguity to be real.

### ★ The "first week" line appears when the expanded current month holds nothing charged

`This fills in as bills go out.` — the canvas's copy, rendered at the bottom of the current
month's section when no entry in it is charged. It explains the space rather than leaving it
blank, and it reads correctly on the 1st of any month, not only in a genuine first week.

### There is no `+` button in v1

The canvas draws one. The editor does not exist, and a control that does nothing when tapped
is worse than an absent one. The trailing slot at the top is where it goes; nothing occupies
it now, so v1 has no navigation chrome at all.

### An occurrence with no amount renders an em dash and contributes nothing

`Expense.amount` is optional so variable bills fit. Nothing can create one until the editor
lands, so this is defensive only, and the seed does not include one.

### Sample data seeds once, when the store is empty

Guarded by a `UserDefaults` flag so a reinstall re-seeds. It comes out when the editor lands.
Because the app would therefore always have data, a launch argument suppresses the seed so
that first run can be looked at on a real screen rather than only in a preview — Step 3 has
the mechanism.

### Sections are computed into state, not recomputed per frame

Building one month is a handful of engine calls, but the timeline's body re-evaluates on
every scroll-position change. Steps recompute into `@State` when the inputs change
(expenses, expanded range, today) rather than computing inside `body`. No cache beyond that —
if scrolling ever stutters, this is the place to look first.

---

## How month paging maps onto the engine

Stated once, here, so no step re-derives it.

A month is a `DateInterval` from the first day of that month to its last day, both at
start-of-day, in `Calendar.current`. The engine compares range bounds at day granularity with
both ends inclusive, so that interval means exactly "this calendar month" with no off-by-one
at either end.

For each non-archived expense the builder calls
`RecurrenceEngine.occurrences(for:overrides:in:calendar:)` with that interval and the
expense's **complete, unfiltered** override set. The engine windows on *effective* dates, so
a bill moved in from a neighbouring month arrives and one moved out disappears — which is the
whole reason the timeline can be paged a month at a time at all.

The results are joined back to their expense by `expenseID` (the engine's value types carry
no name), grouped by the start of day of `effectiveDate`, and ordered so the future sits above
the past.

**A collapsed month bar's total comes from the same function as an expanded month header's.**
A bar renders a `MonthSection` built by `TimelineBuilder.month(...)` for its own month and
shows only that section's `total` and `containsEstimate`. There is no second summing path, so
a bar and the header it turns into cannot disagree.

---

## Steps

**Run these as two sessions, split between Steps 4 and 5.** Steps 1–4 end with a screen that
can be looked at — tokens, the builder, the seed, the static month. Steps 5–7 are the
scrolling behaviour, and they need a settled-looking month to build on more than they need
the conversation that produced one. Neither half carries context the other wants.

### Step 1 — Extend `Tokens` with the dimension scale the timeline needs

**Files:**
- `Tilly/DesignSystem/Tokens.swift` (modified)
- `Tilly/RootView.swift` (modified — only to keep compiling against the re-cut `Text` set)

**Interface:**

```swift
import SwiftUI

enum Tokens {
    enum Text {
        static let monthName: Font    // .title3 semibold   — 20/25
        static let monthTotal: Font   // .subheadline        — 15/20
        static let barName: Font      // .callout            — 16/21
        static let barTotal: Font     // .callout            — 16/21
        static let name: Font         // .body               — 17/22
        static let amount: Font       // .body               — 17/22
        static let dayHeading: Font   // .footnote semibold  — 13/17
        static let dayTotal: Font     // .footnote           — 13/17
        static let caption: Font      // .footnote           — 13/17, the row's date line
        static let badge: Font        // .caption2 semibold  — 10
        static let body: Font         // .body
        static let emptyTitle: Font   // .title2 semibold    — 22/28
    }

    enum Tracking {
        static let badge: CGFloat       // 0.5
        static let dayHeading: CGFloat  // 0.3
    }

    enum Ink {
        static let primary: Color      // .primary
        static let secondary: Color    // .secondary
        static let tertiary: Color     // Color(.tertiaryLabel)
        static let quaternary: Color   // Color(.quaternaryLabel)
    }

    enum Surface {
        static let base: Color      // Color(.systemBackground)
        static let iconWell: Color  // Color(.quaternarySystemFill)
        static let rule: Color      // Color(.separator)
    }

    enum Space {
        static let gutter: CGFloat            // 20 — screen edges, everywhere
        static let section: CGFloat           // 16 — above a month header
        static let gap: CGFloat               // 12 — icon↔text, text↔amount, above a day group
        static let tight: CGFloat             //  8 — below a month header, below a day group,
                                              //      before a badge, inside the month bar
        static let hairlineGap: CGFloat       //  4 — day heading ↔ the rule under it
        static let badgeInset: CGFloat        //  6 — badge side padding (the 2pt half-step's sibling)
        static let badgeInsetVertical: CGFloat//  2 — badge top/bottom padding
        static let rowVerticalAccessible: CGFloat // 12 — replaces the fixed row height at AX sizes
    }

    enum Size {
        static let row: CGFloat              // 52 — minimum, not fixed; see below
        static let monthBar: CGFloat         // 48
        static let monthBarAccessible: CGFloat // 56
        static let icon: CGFloat             // 40
        static let iconAccessible: CGFloat   // 44
        static let hairline: CGFloat         // 0.5 — the thinnest line the display draws
        static let badgeStroke: CGFloat      // 1   — the badge's border, which is not a hairline
    }

    enum Radius {
        static let icon: CGFloat            // 10
        static let iconAccessible: CGFloat  // 12
        static let badge: CGFloat           //  4
    }
}
```

**Every value stays a system alias or a grid number.** No hex, no `Color(red:green:blue:)`,
no `.system(size:)`. The fonts are the styles `dimensions.md` names, so Dynamic Type keeps
working and the point sizes in that table are what they resolve to at the default size.

**Three notes on the shape:**

`Tokens.Text.amount` changes from `.largeTitle` to `.body`. It was scaffolding standing in
for "an amount"; the timeline's amount is 17-point body. The headline number is v1.1 and gets
its own token when it exists. `tilly-ship` should update the snippet in `DESIGN.md`, which
still prints the old value.

`Size.row` is a **minimum height**, applied with `.frame(minHeight:)`. `dimensions.md` calls
52 fixed and explains why — content centres inside it, so vertical padding is not a token.
That holds at every non-accessibility size. It cannot hold at accessibility sizes, where two
lines of text exceed 52 on their own and a fixed frame would clip them.

No `iconGlyph` token. `dimensions.md` records the 20-point glyph, and nothing renders one
until categories exist; an unused token is dead code that will drift before it is used.

**Done when:**
- Every value in `Tokens.swift` is a system alias or a number from the 4-point grid
- `RootView` still contains no font, colour or size literal
- The existing 11 app tests and 54 engine tests still pass

**Verify:**
```
xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test
```
and the seam check:
```
grep -REn '#[0-9A-Fa-f]{6}|Color\(red:|\.font\(\.(largeTitle|title|title2|title3|headline|subheadline|body|callout|footnote|caption|caption2)|\.font\(\.system|\.padding\([0-9]|spacing: [1-9]|cornerRadius\([0-9]|frame\((width|height|minHeight): [0-9]' Tilly --include='*.swift' | grep -v 'DesignSystem/'
```
This must print nothing.

**Out of scope:** any view. `DesignSystem/Gallery.swift` — it is its own roadmap line.
Animation, state and category colour tokens.

---

### Step 2 — `MonthKey`, the timeline's value types, and the pure month builder

**Depends on:** Step 1 (for nothing but ordering — this step touches no view).

**Files:**
- `Tilly/Timeline/MonthKey.swift` (new)
- `Tilly/Timeline/TimelineModels.swift` (new)
- `Tilly/Timeline/TimelineBuilder.swift` (new)
- `Tilly/Models/Expense+Timeline.swift` (new)
- `TillyTests/TimelineBuilderTests.swift` (new)

**Interface:**

```swift
// MonthKey.swift
struct MonthKey: Hashable, Comparable, Identifiable, Sendable {
    let year: Int
    let month: Int                                   // 1...12

    var id: Int { year * 12 + (month - 1) }

    init(year: Int, month: Int)
    init(containing date: Date, calendar: Calendar)

    func advanced(by months: Int) -> MonthKey        // handles year boundaries
    func interval(in calendar: Calendar) -> DateInterval   // first day ... last day, both start-of-day
    func name(in calendar: Calendar, relativeTo today: Date, locale: Locale) -> String
}
```

```swift
// TimelineModels.swift
enum OccurrenceState: Sendable {
    case upcoming, charged, skipped
}

struct TimelineEntry: Identifiable, Equatable, Sendable {
    let id: String            // Occurrence.id — stable across launches
    let name: String
    let date: Date            // effectiveDate, start of day
    let amount: Decimal?      // already rounded to whole units
    let isEstimate: Bool
    let state: OccurrenceState
}

struct DayGroup: Identifiable, Equatable, Sendable {
    let date: Date            // start of day
    let entries: [TimelineEntry]
    let total: Decimal        // excludes skipped entries
    let containsEstimate: Bool
    let state: OccurrenceState   // .charged or .upcoming — the day's own temporal state

    var id: Date { date }
    var isGrouped: Bool { entries.count > 1 }
}

struct MonthSection: Identifiable, Equatable, Sendable {
    let month: MonthKey
    let days: [DayGroup]      // descending by date: the future sits above
    let total: Decimal        // excludes skipped entries
    let containsEstimate: Bool

    var id: Int { month.id }
    var isEmpty: Bool { days.isEmpty }
    var hasChargedEntry: Bool
}

/// One expense reduced to what the timeline needs, so the builder is pure and testable
/// without SwiftData.
struct TimelineExpense: Equatable, Sendable {
    let name: String
    let snapshot: ExpenseSnapshot
    let overrides: [OccurrenceOverride]
}
```

```swift
// TimelineBuilder.swift
enum TimelineBuilder {
    static func month(
        _ month: MonthKey,
        expenses: [TimelineExpense],
        today: Date,
        calendar: Calendar
    ) -> MonthSection
}
```

```swift
// Expense+Timeline.swift
extension Expense {
    /// Carries `overrideSnapshots` whole — unfiltered by date, deliberately.
    var timelineExpense: TimelineExpense { get }
}
```

**Ordering and state rules the builder implements:**

- Days descend; within a day, entries descend by amount, ties broken by name ascending.
  An entry with no amount sorts last.
- `state` is `.skipped` when the occurrence is skipped, regardless of date; otherwise
  `.charged` when `effectiveDate <= today` at day granularity, `.upcoming` when later.
- `DayGroup.state` is `.charged` when the day is today or earlier, `.upcoming` otherwise —
  it never takes `.skipped`, because a day is not a charge.
- Amounts are rounded to whole units on the way into `TimelineEntry`
  (`NSDecimalRound(&result, &value, 0, .plain)`), and every total is a plain sum of those.
- Totals exclude entries whose state is `.skipped`. `containsEstimate` counts an estimate
  whatever its state, but ignores skipped entries — a skipped estimate contributes nothing to
  a total, so marking that total soft would be a lie.
- A `nil` amount contributes nothing to any total.

**Done when — named cases in `TimelineBuilderTests`,** using a gregorian calendar pinned to
UTC and a fixed `today`, matching `Core/Tests/TillyCoreTests/OccurrenceTests.swift`:

*Shape and ordering*
- `aMonthWithNoExpensesHasNoDays` — empty input gives no days, total 0, `containsEstimate`
  false.
- `daysDescendSoTheFutureSitsAbove` — occurrences on the 2nd, 15th and 28th come back in the
  order 28, 15, 2.
- `aDayWithOneChargeIsNotGrouped` — `isGrouped == false`.
- `twoChargesOnOneDayGroupWithADayTotal` — one `DayGroup` holding both, total is their sum.
- `entriesInADayDescendByAmount` — 3 and 11 on the same day come back 11 first.
- `entriesOfEqualAmountOrderByName` — two 20s come back alphabetically.
- `anEntryWithNoAmountSortsLast`.

*Time*
- `anOccurrenceDatedTodayIsCharged`.
- `anOccurrenceDatedTomorrowIsUpcoming`.
- `anOccurrenceDatedYesterdayIsCharged`.
- `aDayHeadingTakesTheDaysOwnState` — a future day's `DayGroup.state` is `.upcoming` even
  when it holds a skipped entry.

*Certainty and skipping*
- `aSkippedOccurrenceStaysInItsDayAndOutOfTheDayTotal` — the group holds two entries; the
  total is the unskipped one alone.
- `aSkippedOccurrenceIsOutOfTheMonthTotal`.
- `aSkippedOccurrenceInTheFutureIsStillSkipped` — `.skipped`, not `.upcoming`.
- `aMonthContainingAnEstimateIsMarked`.
- `aDayContainingAnEstimateIsMarked`.
- `anEstimateThatHasAlreadyBeenChargedIsStillMarked` — state `.charged`, `isEstimate` true.
  This is the state grammar's trap case and the reason the two axes are on separate channels.
- `aMonthWhoseOnlyEstimateIsSkippedIsNotMarked`.

*Amounts*
- `amountsRoundToWholeUnitsBeforeTotalling` — 74.10 and 74.60 render 74 and 75, and the month
  total is 149.
- `anEntryWithNoAmountContributesNothingToTheTotal`.

*The neighbouring-month trap*
- `aBillMovedInFromThePreviousMonthAppearsInThisOne` — an override whose `scheduledDate` is
  the 28th of the previous month and whose `movedDate` is the 3rd of this one produces an
  entry dated the 3rd, in this month's section.
- `aBillMovedOutOfThisMonthIsAbsentFromIt` — the mirror case; the month is short by one and
  the day it was scheduled on holds nothing.
- `aBillMovedWithinTheMonthAppearsOnlyAtItsNewDate` — no trace at the original date.

*Boundaries*
- `anArchivedExpenseNeverAppears`.
- `aMonthIntervalCoversEveryDayInclusive` — February 2027 spans the 1st to the 28th; February
  2028 to the 29th.
- `aMonthKeyAdvancesAcrossAYearBoundary` — December advanced by 1 is January of the next
  year; January advanced by −1 is December of the previous.
- `aMonthInThisYearIsNamedWithoutItsYear`, and `aMonthInAnotherYearCarriesItsYear`.

**Verify:**
```
xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test
```
Report the actual test count. Then:
```
cd Core && swift test
```
must still report 54 tests passing — an unchanged number is the proof that nothing in this
step reached into `Core/`.

**Out of scope:** every view. Sample data. Any caching. Adding anything to `TillyCore` — in
particular, do not add `name` to `ExpenseSnapshot`; the join by `expenseID` belongs on this
side of the boundary.

---

### Step 3 — Seeded sample data

**Depends on:** Step 2 (its tests assert against `TimelineBuilder`).

**Files:**
- `Tilly/Models/SampleData.swift` (new)
- `Tilly/TillyApp.swift` (modified — seeds on launch)
- `Tilly.xcodeproj/xcshareddata/xcschemes/Tilly.xcscheme` (modified — one disabled launch
  argument; see below)
- `TillyTests/SampleDataTests.swift` (new)

**Interface:**

```swift
enum SampleData {
    /// Inserts the sample set when `context` holds no expenses and the seed has not run
    /// before. Anchors are computed relative to `today`, so the data lands in whatever month
    /// the app is first opened in.
    static func seedIfNeeded(
        into context: ModelContext,
        today: Date = Date(),
        calendar: Calendar = .current,
        defaults: UserDefaults = .standard
    ) throws

    /// The same rows without the guard, for previews and tests.
    static func insert(into context: ModelContext, today: Date, calendar: Calendar) throws
}
```

**The set.** Eleven expenses, all anchored on a day of the *current* month so that wherever
today falls, the month is populated on both sides of it. Names are generic — no brands, no
real-world figures, nothing that says anything about anyone. The repo is public.

| Name | Amount | Rule | Day | What it is there to prove |
|---|---|---|---|---|
| Rent | 950 | every 1 month | 1 | the largest figure; day-group member |
| Streaming video | 18 | every 1 month | 1 | **skipped** this month; day-group member |
| Music streaming | 11 | every 1 month | 2 | day-group member |
| Cloud storage | 3 | every 1 month | 2 | day-group member; the smallest figure |
| Gym membership | 32 | every 1 month | 4 | day-group member |
| Electricity | 85, **estimate** | every 1 month | 4 | day-group member — a mixed-certainty day, so a day total carries `EST` |
| Home & contents insurance | 240 | every 1 **year** | 12 | the long name, and an annual rule |
| Water | 38, **estimate** | every **3** months | 20 | a quarterly rule, and an estimate late in the month |
| Home internet | 45 | every 1 month | 22 | the **moved** one |
| Council tax | 95 | every 1 month | 25 | day-group member |
| Mobile phone | 22 | every 1 month | 25 | day-group member |

Anchors: monthly rules anchor on their day in the current month; the annual insurance anchors
on the 12th of the same month three years ago; the quarterly water bill anchors on the 20th
of the current month.

**Two overrides, and both matter:**

1. **Skipped** — `OverrideRecord(scheduledDate: 1st of this month, isSkipped: true)` on
   Streaming video. It shares a day with Rent, so the 1st is a grouped day whose total
   excludes one of its own rows — the strongest single demonstration of the skipped rule.
2. **Moved** — `OverrideRecord(scheduledDate: 22nd of the *previous* month, movedDate: 3rd of
   this month)` on Home internet. This is the neighbouring-month trap made visible: the
   previous month is short one bill on its 22nd, and this month gains one on a date its rule
   never generates. Fetch overrides with a date predicate and this row silently disappears
   while the month still looks plausible.

With today mid-month this yields, on one screen: upcoming rows above, charged below, a
charged estimate and an upcoming estimate, a skipped row, a long name, and four grouped days
(the 1st, 2nd, 4th and 25th).

**`TillyApp`** calls `SampleData.seedIfNeeded(into:)` once against the container's
`mainContext` before the window renders. A seeding failure is not fatal — the app runs, the
timeline shows its empty state, and the error is logged.

**Seeing first run.** `seedIfNeeded` does nothing when `defaults.bool(forKey:
"tillyEmptyStore")` is true. Reading it from the injected `UserDefaults` rather than from
`ProcessInfo` means one mechanism covers both callers: iOS's argument domain sets the key
from a `-tillyEmptyStore YES` launch argument, and tests set it directly on their own suite.

Add that argument to the shared scheme as a `CommandLineArgument` with `isEnabled = "NO"`, so
it appears unticked under Run ▸ Arguments and is one checkbox away in Xcode. From the command
line it is:
```
xcrun simctl launch 'iPhone 17' com.jdragash.Tilly -tillyEmptyStore YES
```
This is scheme and build configuration, not a source-file reference — the project file's
"never touch it to add files" invariant is untouched.

**Done when — named cases in `SampleDataTests`,** with a pinned UTC gregorian calendar and
`today` fixed at 15 September 2026:

- `seedingAnEmptyStoreInsertsTheWholeSet` — 11 expenses, 2 overrides.
- `seedingTwiceInsertsNothingTheSecondTime` — with a `UserDefaults` suite created for the test
  and removed after.
- `theCurrentMonthShowsEveryStateAtOnce` — build the current month from the seeded rows and
  assert it contains at least one `.upcoming`, one `.charged`, one `.skipped`, one estimate
  that is charged, one estimate that is upcoming, and at least one grouped day.
- `oneSeededNameIsLongEnoughToTruncate` — some name exceeds 20 characters.
- `theMovedBillLandsInThisMonthAndLeavesThePreviousOne` — this month holds a Home internet
  entry on the 3rd; the previous month holds none on its 22nd.
- `theSkippedBillIsListedAndOutOfItsDayTotal` — the 1st holds two entries and totals 950.
- `everySeededExpenseSurvivesASaveAndFetch`.
- `theEmptyStoreFlagSuppressesSeeding` — with `tillyEmptyStore` set true on the test's own
  suite, `seedIfNeeded` inserts nothing and the store stays empty.

**Verify:**
```
xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test
```

**Out of scope:** any view. Deleting or editing seeded data. A settings toggle for the seed.

---

### Step 4 — The static screen: row, badge, day group, month header, empty and first-week states

**Depends on:** Steps 1–3.

This step draws one month and nothing else. No bars, no scrolling behaviour, no paging. It
ends with the app rendering the seeded current month in the simulator, which is the first
point at which the design can be looked at rather than reasoned about.

**Files:**
- `Tilly/Timeline/TimelineFormatting.swift` (new)
- `Tilly/Timeline/EstimateBadge.swift` (new)
- `Tilly/Timeline/OccurrenceRow.swift` (new)
- `Tilly/Timeline/DayGroupView.swift` (new)
- `Tilly/Timeline/MonthHeader.swift` (new)
- `Tilly/Timeline/MonthSectionView.swift` (new)
- `Tilly/Timeline/TimelineEmptyState.swift` (new)
- `Tilly/RootView.swift` (modified — renders one `MonthSectionView`)
- `TillyTests/TimelineFormattingTests.swift` (new)

**Interface:**

```swift
// TimelineFormatting.swift
enum TimelineFormatting {
    /// "−€950". A zero renders unsigned. A nil renders "—".
    static func amount(_ value: Decimal?, locale: Locale = .current) -> String

    /// "Mon 28"
    static func dayLine(_ date: Date, calendar: Calendar = .current, locale: Locale = .current) -> String

    /// Row label: "Rent, Saturday 12 September, 950 euro out, upcoming"
    static func accessibilityLabel(for entry: TimelineEntry, calendar: Calendar, locale: Locale) -> String

    /// Bar / header label: "September, total 1,521 euro out, estimated"
    static func accessibilityLabel(for section: MonthSection, calendar: Calendar, today: Date, locale: Locale) -> String
}
```

```swift
struct EstimateBadge: View { let ink: Color }

struct OccurrenceRow: View { let entry: TimelineEntry }

struct DayGroupView: View { let group: DayGroup }

struct MonthHeader: View { let section: MonthSection; let today: Date }

struct MonthSectionView: View {
    let section: MonthSection
    let today: Date
    let showsFirstWeekLine: Bool
}

struct TimelineEmptyState: View {}
```

**Layout, from `dimensions.md` and the canvas — exact, so nothing is eyeballed:**

*The row.* `HStack(spacing: Tokens.Space.gap)` of: the icon well, a leading-aligned
`VStack(spacing: 0)` of name then date line, then `HStack(spacing: Tokens.Space.tight)` of
badge then amount. Inset by `Tokens.Space.gutter` on both sides, `.frame(minHeight:
Tokens.Size.row)`, content vertically centred.

- The icon well is a `RoundedRectangle(cornerRadius: Tokens.Radius.icon, style: .continuous)`
  filled with `Tokens.Surface.iconWell`, `Tokens.Size.icon` square. **Empty. No glyph.**
- The name is `Tokens.Text.name`, `lineLimit(1)`, `.truncationMode(.tail)` — this is what the
  long seeded name exercises. The amount and badge keep their intrinsic width; the name gives
  way.
- The date line is `Tokens.Text.caption`, and is **omitted entirely when the row is inside a
  grouped day** — that is where the day heading's vertical space comes from.
- The amount uses `.monospacedDigit()` so figures align down the right edge.
- A skipped row's amount is struck through.

*Ink, one rung per state.* Name and amount take the first colour; the date line takes the
second:

| State | Name + amount | Date line |
|---|---|---|
| `.charged` | `Ink.primary` | `Ink.secondary` |
| `.upcoming` | `Ink.secondary` | `Ink.tertiary` |
| `.skipped` | `Ink.tertiary` | `Ink.quaternary` |

Put this ladder on `OccurrenceState` as two computed properties rather than branching in the
view, so the grammar is stated once and every later screen inherits it.

*The badge.* Text `EST`, `Tokens.Text.badge`, `.tracking(Tokens.Tracking.badge)`, padded
`Space.badgeInset` horizontally and `Space.badgeInsetVertical` vertically, inside a
`RoundedRectangle(cornerRadius: Tokens.Radius.badge)` stroked at `Tokens.Size.badgeStroke` in
the same ink as its text. No fill. No fixed height — `dimensions.md` records 16 points, and a
fixed frame would clip the mark at accessibility sizes; sizing it from its own text lands on
16 at the default size and scales for free.

*The day group.* Top to bottom: `Space.gap` of space, the heading row (heading leading,
total trailing, both inset by the gutter, both in the day's ink — `Ink.secondary` when
charged, `Ink.tertiary` when upcoming), `Space.hairlineGap`, a hairline, the rows, a
hairline, `Space.tight` of space. Both hairlines are `Tokens.Size.hairline` high in
`Tokens.Surface.rule`, inset by the gutter on both sides. The heading is
`Tokens.Text.dayHeading` with `.tracking(Tokens.Tracking.dayHeading)`; the total is
`Tokens.Text.dayTotal`, monospaced digits, carrying an `EST` badge before it when the day
contains an estimate.

An *ungrouped* day renders its single row directly, with its date line, and no heading, no
hairlines and no extra space. `DayGroupView` branches on `isGrouped`.

*The month header.* `Space.section` above, `Space.tight` below, inset by the gutter. Month
name leading in `Tokens.Text.monthName` / `Ink.primary`; trailing an
`HStack(spacing: Tokens.Space.tight)` of the `EST` badge (when
`containsEstimate`) and the total in `Tokens.Text.monthTotal` / `Ink.secondary`, monospaced
digits.

*The first-week line.* When `showsFirstWeekLine`, `This fills in as bills go out.` centred
below the last row of the section, `Tokens.Text.monthTotal` in `Ink.tertiary`, with
`Space.section` above and generous horizontal inset.

*The empty state.* Centred, `Nothing recurring yet` in `Tokens.Text.emptyTitle` /
`Ink.primary`, and `Add a bill or a subscription and it shows up here before it goes out.` in
`Tokens.Text.name` / `Ink.secondary` beneath it.

**Accessibility.** Each row is one element (`.accessibilityElement(children: .combine)`)
carrying `TimelineFormatting.accessibilityLabel(for:)`, so VoiceOver reads name, date, amount
and state as a sentence rather than four fragments. The icon well is
`.accessibilityHidden(true)` — it says nothing yet. A day heading and its total combine into
one element too.

**Dynamic Type at accessibility sizes** reflows the row, exactly as the canvas's "Large text"
artboard draws it: the icon stays leading and top-aligned, and name / date / (badge + amount)
stack vertically beside it. Branch on `dynamicTypeSize.isAccessibilitySize`, and in that
branch use `Size.iconAccessible`, `Radius.iconAccessible`, vertical padding
`Space.rowVerticalAccessible` in place of the row's minimum height, and drop the name's
`lineLimit` so it wraps.

**`RootView`** becomes a `ScrollView` containing a single `MonthSectionView` for the current
month, built from `@Query`'d expenses through `TimelineBuilder`, computed into `@State` on
change rather than inside `body`. When there are no expenses at all it renders
`TimelineEmptyState` instead. Background `Tokens.Surface.base`, content inside the safe area
— nothing paints into the status-bar inset.

**Previews to write, because they are how this step is reviewed:** the seeded current month;
the empty state on an empty in-memory container; a month with nothing charged, showing the
first-week line. Each with dark-mode and accessibility-size variants.

**Done when:**
- Named cases in `TimelineFormattingTests`, with `Locale(identifier: "en_IE")` pinned:
  `anAmountCarriesAMinusAndNoDecimals` (950 → `−€950`); `aZeroTotalCarriesNoSign`;
  `aMissingAmountRendersAnEmDash`; `aDateLineReadsAsWeekdayThenDay`;
  `anAccessibilityLabelNamesTheStateAndTheEstimate` (an upcoming estimate's label contains
  both "upcoming" and "estimated"); `aSkippedRowsLabelSaysSkipped`;
  `aSectionLabelCarriesTheMonthAndItsTotal`.
- The seam grep from Step 1 still prints nothing.
- The app builds, installs and launches in the iPhone 17 simulator showing the seeded
  September, and a screenshot is reported — light and dark, default and accessibility text
  size. Four screenshots, not a claim.
- Relaunched with `-tillyEmptyStore YES`, the same build shows the empty state. One more
  screenshot, in light and dark.

**Verify:**
```
xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test
```
then, for the screen itself:
```
xcrun simctl boot 'iPhone 17'; xcrun simctl install 'iPhone 17' "$(find ~/Library/Developer/Xcode/DerivedData/Tilly-*/Build/Products/Debug-iphonesimulator -maxdepth 1 -name Tilly.app | head -1)" && xcrun simctl launch 'iPhone 17' com.jdragash.Tilly
```
Dark mode and text size are set with:
```
xcrun simctl ui 'iPhone 17' appearance dark
xcrun simctl ui 'iPhone 17' content_size accessibility-extra-large
```

**Out of scope:** collapsed bars, paging, scrolling behaviour, persistence, the `+` button,
any glyph inside the icon well, `Gallery.swift`.

---

### Step 5 — Neighbour months as collapsed bars, and the expanded range

**Depends on:** Step 4.

**Files:**
- `Tilly/Timeline/CollapsedMonthBar.swift` (new)
- `Tilly/Timeline/TimelineView.swift` (new — the screen proper)
- `Tilly/RootView.swift` (modified — becomes a thin wrapper, or is deleted and `TillyApp`
  points at `TimelineView`; take whichever leaves less)
- `TillyTests/TimelineRangeTests.swift` (new)

**Interface:**

```swift
struct CollapsedMonthBar: View {
    let section: MonthSection
    let direction: Direction     // .above uses chevron.up, .below uses chevron.down
    let today: Date
    let open: () -> Void
}

/// The expanded months, and the bars either side of them. `high` is the later month and
/// sits above; `low` is the earlier month and sits below.
struct ExpandedRange: Equatable, Sendable {
    private(set) var low: MonthKey
    private(set) var high: MonthKey

    init(anchor: MonthKey)
    var months: [MonthKey] { get }        // descending: high first
    var barAbove: MonthKey { get }        // high.advanced(by: 1)
    var barBelow: MonthKey { get }        // low.advanced(by: -1)

    mutating func openAbove()             // high += 1
    mutating func openBelow()             // low -= 1
    mutating func closeAbove()            // high -= 1, never below low
    mutating func closeBelow()            // low += 1, never above high
    mutating func includeCurrentMonth(_ month: MonthKey)  // extends, never contracts
}
```

**The content, top to bottom:** the bar for `barAbove`, then a `MonthSectionView` for each
month in `months`, then the bar for `barBelow`. Inside a `ScrollView` with a `LazyVStack`
carrying `.scrollTargetLayout()`. Every month on screen — expanded or collapsed — is a
`MonthSection` from `TimelineBuilder.month(...)`, so a bar and the header it becomes are the
same number by construction.

Sections are recomputed into `@State` when expenses, the range or `today` change, and not
inside `body`.

**The bar.** `Tokens.Size.monthBar` high (`monthBarAccessible` at accessibility sizes), inset
by the gutter, `HStack(spacing: Tokens.Space.tight)` of: a chevron in `Ink.tertiary`, the
month name in `Tokens.Text.barName` / `Ink.secondary`, a spacer, the `EST` badge in
`Ink.tertiary` when the month contains an estimate, and the total in `Tokens.Text.barTotal` /
`Ink.secondary`, monospaced digits. A hairline runs along its **bottom** edge, full-width
inside the gutter — the canvas draws it on both bars, and it is the rule that closes the bar
against the content.

The whole bar is a `Button` with `.buttonStyle(.plain)` calling `open()`. Tapping it is the
accessible equivalent of pulling it; pulling arrives in Step 6.

**This step's resting position** is the current month, expanded, with a bar either side. It
does not persist anything yet — that is Step 7 — so every launch lands on the current month.

**Done when — named cases in `TimelineRangeTests`** (pure, no view):
- `aNewRangeHoldsOnlyItsAnchor` — `months == [anchor]`.
- `theBarsSitOneMonthEitherSideOfTheRange`.
- `openingAboveAddsTheLaterMonthAndMovesTheBarUp`.
- `openingBelowAddsTheEarlierMonthAndMovesTheBarDown`.
- `closingAboveReturnsExactlyTheBarThatWasOpened` — open then close gives a range equal to
  the original, and a `barAbove` equal to the original's.
- `aRangeNeverClosesPastItsLastMonth` — `closeAbove` on a single-month range is a no-op, in
  both directions.
- `openingAcrossADecemberBoundaryLandsInJanuary`.
- `includingTheCurrentMonthExtendsUpwardAndNeverContracts`.

and, in the simulator:
- Tapping the bar above opens that month above the current one, with a new bar above it.
- Tapping the bar below does the same downward.
- A screenshot of the rest state and of one month opened.

**Verify:**
```
xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test
```
plus the launch and screenshot commands from Step 4, and the Step 1 seam grep.

**Out of scope:** the pull gesture, closing on scroll, persistence, midnight rollover.

---

### Step 6 — Pull to open, and closing on the way back

**Depends on:** Step 5.

**Files:**
- `Tilly/Timeline/TimelineView.swift` (modified)

This step adds the two gestures that make the bars behave as the design describes, and it is
the riskiest in the plan. Read the escape hatch at the bottom before starting.

**Pulling.** Overscroll past either end by `Tokens.Size.monthBar` opens the month in that
direction. Observe it with `onScrollGeometryChange(for:)` on the container's content offset
relative to its insets, and fire once per gesture — latch on crossing the threshold, and
release the latch when the offset returns inside the content. `onScrollPhaseChange` gives the
gesture end if a latch reset needs one.

**Closing.** The outermost expanded month collapses back to a bar when it is no longer
visible: track the visible items with `.onScrollTargetVisibilityChange(idType:)`, and when no
visible item belongs to `range.high`, call `closeAbove()`. Symmetrically for `range.low`.

**The thing that must not happen** is the content jumping. Collapsing `high` removes a
screenful of content from above the viewport and puts a 48-point bar in its place; without
compensation everything under the reader's eyes leaps upward. Bind the scroll container's
position to the id of the top-most visible item (`ScrollPosition` /
`.scrollPosition(_:anchor: .top)`) so SwiftUI keeps that item pinned across the content
change. That binding is also what Step 7 persists, so it earns its place twice.

**Done when:**
- Pulling down at the top opens the month above; pulling up at the bottom opens the month
  below. Both take one deliberate pull, not a flick.
- Opening the month above, then scrolling back down into the month you started in, closes it
  again and returns exactly the bar you opened — the canvas's frames 1 and 4.
- **Nothing under the reader's eyes moves when a month collapses.** Verify this concretely:
  note which row sits at a fixed point on screen, cross the collapse threshold, screenshot,
  and confirm the same row is at the same place. Report both screenshots.
- Neither gesture fires twice for one pull.
- The existing test suites still pass unchanged; this step adds no unit tests, because what
  it changes is scroll behaviour and a test that asserted it would be asserting a mock.

**Verify:**
```
xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test
```
then drive the gestures in the simulator and report the screenshots described above.

**If the pinning will not hold** — if the content jumps on collapse and the scroll-position
binding does not fix it — **stop and report it rather than shipping a jumping list, and
rather than quietly dropping the close behaviour.** Months that open and never close is a
coherent fallback and a real design change; it is Jake's to make, not this step's.

**Out of scope:** persistence, midnight rollover, animating the open and close.

---

### Step 7 — Never lose the reader's place

**Depends on:** Step 6.

**Files:**
- `Tilly/Timeline/TimelinePlace.swift` (new)
- `Tilly/Timeline/TimelineView.swift` (modified)
- `TillyTests/TimelinePlaceTests.swift` (new)

**Interface:**

```swift
struct TimelinePlace: Codable, Equatable, Sendable {
    var lowID: Int          // MonthKey.id
    var highID: Int
    var topItemID: String?  // the id of the item at the top of the viewport
}

struct TimelinePlaceStore: Sendable {
    init(defaults: UserDefaults = .standard)
    func load() -> TimelinePlace?
    func save(_ place: TimelinePlace)
    func clear()
}
```

**Restoring.** On first appearance, load the place. If there is none — the first run after
installing — the anchor is the current month and nothing is scrolled. If there is one,
rebuild the range from `lowID`/`highID` and scroll to `topItemID` with a `.top` anchor. If
that id no longer resolves to anything (the data changed underneath), fall back to the top of
the range's `high` month rather than to today — being returned somewhere plausible beats
being thrown to a different month.

**Saving.** Write on scroll idle (`onScrollPhaseChange` reaching `.idle`) and whenever
`scenePhase` leaves `.active`. Both, deliberately: the scene-phase write covers a clean
background, and the idle write covers a process that is killed without one. `DECISIONS.md` is
explicit that the two cases cannot be told apart, so neither may be the only writer.

**Crossing midnight into a new month.** Observe `NSCalendarDayChangedNotification`. When the
day changes, recompute `today` — which alone reclassifies every row that has passed from
upcoming to charged. When the *month* also changes, call `range.includeCurrentMonth(...)`,
which extends the range upward. The new month therefore opens **above** the reader, in space
they were not occupying, and the scroll-position pinning from Step 6 keeps everything under
their eyes still. Both visible side effects are correct and expected: the upcoming/charged
boundary moves into the new month, and anything still upcoming in the old one becomes charged.

**Done when — named cases in `TimelinePlaceTests`,** each with a `UserDefaults` suite created
for the test and removed afterwards:
- `anEmptyStoreLoadsNothing` — a fresh install has no place.
- `aSavedPlaceRoundTrips`.
- `savingTwiceKeepsTheLatest`.
- `clearingRemovesThePlace`.
- `aRangeRebuiltFromASavedPlaceMatchesTheOneSaved`.

and in the simulator:
- Open the month above, scroll to a distinguishable row, background the app, kill it from
  Xcode, relaunch: the same month is open at the same row. Screenshot before and after.
- Delete and reinstall the app: it lands on the current month. Screenshot.

**Verify:**
```
xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test
```
plus the kill-and-relaunch check above, with both screenshots reported. Then:
```
cd Core && swift test
```
must still report 54 tests — the engine has not been touched by any step in this plan.

**Out of scope:** iCloud, migrations, syncing the place between devices, animating the
rollover.

---

## What this leaves undone, on purpose

Stated so it is not mistaken for an oversight:

- **The `+` button and the editor.** The empty state's copy invites an action that does not
  exist yet. That is the next piece of work, not a gap in this one.
- **Anything inside the icon well.** The slot is reserved and empty until categories ship.
- **`DesignSystem/Gallery.swift`.** Its own roadmap line, and it is worth much more now that
  there are real components and a real dimension scale to render.
- **The headline number.** A month header totals the whole month; the headline is "remaining
  this month". Different quantities, and the boundary between them is already drawn.
- **Where an estimated amount comes from.** The editor and the overrides UI.

---

---

## Updates

### 2026-09-07 — `EST` is deferred, and two corrections

Steps 1–4 are built. Three changes, recorded here rather than by rewriting the steps above,
so the plan still reads as what was specified and this reads as what changed.

**The `EST` mark comes out of v1 entirely.** Jake's call, and the reasoning is the one this
plan already half-made: it flagged "where an estimated amount comes from" as deliberately
unresolved, and a mark whose meaning is unresolved is a mark that shouldn't ship. The design
and the logic behind a variable amount are more work than either `DECISIONS.md` or this plan
allowed for, so both move down the roadmap together.

What that removes: `EstimateBadge`, `TimelineEntry.isEstimate`, `DayGroup.containsEstimate`,
`MonthSection.containsEstimate`, the badge tokens (`Text.badge`, `Tracking.badge`,
`Space.badgeInset`, `Space.badgeInsetVertical`, `Size.badgeStroke`, `Radius.badge`), the word
"estimated" from the accessibility labels, and five tests. Steps 5–7 inherit it: **a collapsed
month bar carries a name and a total, and no mark.**

What it deliberately does *not* touch: `Expense.isEstimate` and `ExpenseSnapshot.isEstimate`
stay, and `TillyCore` is untouched. The flag is real information about a bill; only its
rendering is deferred. The seed still marks Electricity and Water as estimates for the same
reason — they genuinely are variable, and the data is right even while nothing draws it.

Two consequences for `tilly-ship` when the timeline lands, neither of them this plan's to
write: **"Estimates are marked, not approximated" (2026-09-07) needs superseding**, and
`DESIGN.md`'s state grammar drops to a single axis — which also retires the trap that
section exists to name, since an estimate no longer renders at all.

**Two bugs found in review, fixed in place.** At accessibility text sizes neither
`OccurrenceRow.accessibleLayout` nor `MonthHeader`'s accessible branch filled the available
width, so every row floated centred at its own inset and a wide one overflowed both edges;
both now carry `.frame(maxWidth: .infinity, alignment: .leading)`. And the VoiceOver labels
hardcoded "euro" while the screen beside them rendered the device's own currency — they now
speak the currency in full from the same locale, with a non-euro test case so the suite would
catch it again.

**The seam grep now looks for `spacing: [1-9]`, not `spacing: [0-9]`.** `spacing: 0` is the
absence of a gap rather than a design value that escaped the token layer — there is no
neighbouring number that would be right-but-wrong — and Step 4's own spec writes it
literally. A check that reports three known-good matches on every run is a check people learn
to wave past, which costs more than the zero ever could.

### Still open, and blocking Step 5

Two of Jake's notes change the model Steps 5–7 are built on, so they go to `tilly-explore`
before Step 5 rather than being absorbed here:

1. **A sticky month header.** The month name pins while you scroll its month and hands off to
   the next. Coherent with the expanded-range model, but it interacts with Step 6's
   close-on-scroll-back and needs a background treatment the header does not currently have.
2. **The month total becomes a remaining amount.** Meaningful looking forward — a future
   month has nothing charged, so remaining and total coincide — and empty looking back: a
   past month's remaining is always zero, which would leave the collapsed bar *below* the
   current month reading zero permanently, destroying the thing that justifies its space. It
   also collides with why `DECISIONS.md` chose a total in the first place, which was that a
   total and the roadmapped "remaining this month" headline are different quantities. If the
   header becomes remaining, that roadmap item needs redefining or deleting.

## If a step is wrong

These specs were written before the code existed. If a step turns out to be ambiguous,
impossible, or wrong, **stop and say so** — don't improvise a fix and don't silently widen
the scope. A wrong spec caught in one message costs far less than a wrong spec followed to
completion.

Step 6 is the one most likely to be wrong, and it says so in its own text. Steps 1–5 and 7
are ordinary work.
