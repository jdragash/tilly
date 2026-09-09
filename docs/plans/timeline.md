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
insights. The headline number is not a separate thing to build — the current month's header
is it.

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
- **At most two months are expanded at once,** and nothing collapses because of where you
  scrolled. Closing on scroll-back was specified, tested in a prototype, and found to be
  unreachable; see the Updates section and `DECISIONS.md`.
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
- **The current month's header carries what is left** — `−€162 left`, the word included.
  Every other month, and every collapsed bar, carries a plain total. Totals and remainders
  both exclude skipped occurrences. Superseded "headers carry the month's total"; see the
  Updates section.
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

*Superseded 2026-09-08 — see the Updates entry.* Pulling was the primary gesture and tapping
was its accessible equivalent. Pulling is gone: bars either side are gone, and the one bar
that survives, at the top of the list, is tapped and nothing else. The reasoning below is why
tapping had to exist at all, and it is why pull-to-unlock was rejected rather than added
alongside.

~~`DECISIONS.md` says pulling opens a bar. Pulling is the primary gesture and Step 6 builds
it.~~ A pull is invisible to VoiceOver and Switch Control, so the bar is also a `Button` that
does exactly the same thing.

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

Steps 1–4 are built and green. **The second session starts with the landed-code changes in
the Updates section, then Step 5** — the figure and `remaining` have to exist before there is
anything for a pinned header to render.

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

### Step 5 — The sticky header, collapsed bars, and the capped range

*Built 2026-09-07. The bars and the cap are removed again by Step 6 — see the 2026-09-08
Updates entry. Kept as written, because it is what was specified and executed.*

**Depends on:** Step 4, and on the landed-code changes in the Updates section — do those
first, in the same session, since this step renders `headerFigure` and `remaining`.

**Files:**
- `Tilly/Timeline/CollapsedMonthBar.swift` (new)
- `Tilly/Timeline/TimelineView.swift` (new — the screen proper)
- `Tilly/Timeline/MonthHeader.swift` (modified — the pinned treatment)
- `Tilly/RootView.swift` (modified — becomes a thin wrapper, or is deleted and `TillyApp`
  points at `TimelineView`; take whichever leaves less)
- `TillyTests/TimelineRangeTests.swift` (new)

**Interface:**

```swift
struct CollapsedMonthBar: View {
    let section: MonthSection
    let direction: Direction     // .above uses chevron.up, .below uses chevron.down
    let open: () -> Void
}

/// The expanded months, and the bars either side. `high` is the later month and sits
/// above; `low` is the earlier month and sits below. At most `maxOpen` are expanded —
/// opening a third collapses the far end, which is why the openers say which way the
/// reader is travelling.
struct ExpandedRange: Equatable, Sendable {
    static let maxOpen = 2

    private(set) var low: MonthKey
    private(set) var high: MonthKey

    init(anchor: MonthKey)
    var months: [MonthKey] { get }        // descending: high first
    var barAbove: MonthKey { get }        // high.advanced(by: 1)
    var barBelow: MonthKey { get }        // low.advanced(by: -1)

    mutating func openAbove()             // high += 1, then low += 1 while over the cap
    mutating func openBelow()             // low -= 1, then high -= 1 while over the cap
    mutating func includeCurrentMonth(_ month: MonthKey)  // extends upward, then caps
}
```

There is no `closeAbove`/`closeBelow`. Nothing closes except by being pushed out of the cap,
which is the whole point of the decision this step is built on.

**The content, top to bottom:** the bar for `barAbove`, then a `MonthSectionView` for each
month in `months`, then the bar for `barBelow`. Inside a `ScrollView` containing a
`LazyVStack(pinnedViews: [.sectionHeaders])` carrying `.scrollTargetLayout()`, with each
month a `Section` whose header is its `MonthHeader`. Pinning is the framework's, not
hand-rolled — it gives the hand-off between months for free and correctly.

Every month on screen — expanded or collapsed — is a `MonthSection` from
`TimelineBuilder.month(...)`, so a bar and the header it becomes cannot disagree. Sections
are recomputed into `@State` when expenses, the range or `today` change, and not inside
`body`.

**The pinned header.** `MonthHeader` keeps its size when it pins — no condensing. It gains:

- `.background(Tokens.Surface.pinned)` — the system material, so rows visibly pass under it.
- A hairline along its bottom edge **only while pinned**, `Tokens.Size.hairline` in
  `Tokens.Surface.rule`, full width inside the gutter. At rest there is no rule, because
  nothing needs closing; pinned, the rule is closing the header against content moving
  underneath. Detect it with `onScrollGeometryChange(for:)` comparing the header's frame in
  the container's coordinate space against the container's top inset, or with a zero-height
  sentinel above each header and `.onScrollVisibilityChange` — whichever proves stable, and
  say which was used.

Do not attempt a size change on pinning. It was drawn, and it saves one point of height
while dropping the month name from 20 to 17 and landing the pinned header on the same shape
as a collapsed bar — so the month you are in stops being distinguishable from a month you
could open.

**The bar.** `Tokens.Size.monthBar` high (`monthBarAccessible` at accessibility sizes), inset
by the gutter, `HStack(spacing: Tokens.Space.tight)` of: a chevron in `Ink.tertiary`, the
month name in `Tokens.Text.barName` / `Ink.secondary`, a spacer, and
`TimelineFormatting.amount(section.total)` in `Tokens.Text.barTotal` / `Ink.secondary`,
monospaced digits. **A bar always shows the plain total, never the word** — including the bar
for the current month, which is reachable once a neighbour is open. A hairline runs along its
**bottom** edge, full-width inside the gutter.

The whole bar is a `Button` with `.buttonStyle(.plain)` calling `open()`. Tapping it is the
accessible equivalent of pulling it; pulling arrives in Step 6.

**This step's resting position** is the current month, expanded, with a bar either side. It
does not persist anything yet — that is Step 7 — so every launch lands on the current month.

**Done when — named cases in `TimelineRangeTests`** (pure, no view):
- `aNewRangeHoldsOnlyItsAnchor` — `months == [anchor]`.
- `theBarsSitOneMonthEitherSideOfTheRange`.
- `openingAboveAddsTheLaterMonth`.
- `openingBelowAddsTheEarlierMonth`.
- `aThirdMonthOpenedAboveDropsTheEarliestOne` — `months.count == 2`, and the dropped month is
  now `barBelow`.
- `aThirdMonthOpenedBelowDropsTheLatestOne` — the symmetric case, dropped month is `barAbove`.
- `openingAcrossADecemberBoundaryLandsInJanuary`.
- `includingTheCurrentMonthExtendsUpwardAndStaysWithinTheCap`.

and, in the simulator:
- Tapping the bar above opens that month above the current one, with a new bar above it.
- Tapping it again collapses the bottom month into the bar below — three taps never yield
  three expanded months.
- Scrolling shows the header pin, take the hairline, and hand off to the next month.
- Screenshots of the rest state, one month opened, and a pinned header mid-scroll, in light
  and dark.

**Verify:**
```
xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test
```
plus the launch and screenshot commands from Step 4, and the Step 1 seam grep.

**Out of scope:** the pull gesture, persistence, midnight rollover.

---

### Step 6 — The list becomes continuous, and history gets a floor

**Revises code that has already landed.** Step 5 built collapsed bars either side and a
two-month cap; `DECISIONS.md` 2026-09-08 removes both. Read "The timeline is one list you
scroll, bounded at both ends" and "History begins at the oldest charge you have entered"
before starting.

**Files:**
- `Tilly/Timeline/TimelineView.swift` (modified — `ExpandedRange` is replaced)
- `Tilly/Timeline/TimelineWindow.swift` (new)
- `Tilly/Timeline/TimelineFloor.swift` (new)
- `Tilly/Timeline/CollapsedMonthBar.swift` (modified — loses `.below`)
- `Tilly/Models/SampleData.swift` (modified — see below)
- `TillyTests/TimelineRangeTests.swift` (deleted, replaced by the two below)
- `TillyTests/TimelineWindowTests.swift`, `TillyTests/TimelineFloorTests.swift` (new)

**Interface:**

```swift
/// Where the list starts and stops. The next month is always expanded; `unlocked`
/// counts months opened beyond it, and Step 7 is the only thing that changes it.
struct TimelineWindow: Equatable, Sendable {
    let floor: MonthKey
    let current: MonthKey
    var unlocked: Int = 0

    var top: MonthKey { current.advanced(by: 1 + unlocked) }

    /// `top` down to `floor`, descending. Pure range arithmetic — filtering out empty
    /// months needs `MonthSection`s and belongs in the view.
    var months: [MonthKey] { get }
}

enum TimelineFloor {
    /// The oldest month any occurrence can land in: the earliest anchor across all
    /// expenses, and any override whose `movedDate` is earlier still. `nil` when there
    /// are no expenses — the caller shows the empty state instead.
    static func month(for expenses: [Expense], calendar: Calendar) -> MonthKey?
}
```

`ExpandedRange`, `maxOpen`, `openAbove`, `openBelow`, `barAbove`, `barBelow` and
`includeCurrentMonth` all go. Nothing caps anything any more.

**A moved override can be the floor.** It is the one way an occurrence lands earlier than
every anchor, and forgetting it hides a row with no symptom other than a month missing from
the bottom. `TimelineFloor` takes the minimum over both.

**The content, top to bottom:** the unlock bar for `window.top.advanced(by: 1)` (Step 7
makes it work; render it now, inert), then a `MonthSectionView` for each month from
`window.top` down to `window.floor`, then the floor line. There is no bar at the bottom.

**Empty months are not listed.** A month strictly below the current one whose `MonthSection`
has no days is skipped entirely. The current month and the next month always render, even
when empty — the current month needs its header and its first-week line.

**The floor line** reads `Nothing before March.` — `MonthKey.name(in:relativeTo:locale:)`
already adds the year when it is not the current one, so a deeper floor reads
`Nothing before December 2025.` It is `Tokens.Ink.tertiary`, centred, on the same treatment
as the first-week line.

**The top inset.** The scroll view extends under it and nothing covers it, so rows — and
the outgoing month's header, which pins to the bottom of its own section as that section
leaves — render behind the clock. Fill it with `Tokens.Surface.base`, opaque, full width.

*Corrected 2026-09-08, after this step was executed. The snippet originally specified here
did not work, and neither did the fallback named beside it. Both failures are recorded
because both are easy to retry:*

```swift
// WRONG — this was specified and does not work.
.overlay(alignment: .top) {
    Tokens.Surface.base.frame(height: 0).ignoresSafeArea(edges: .top)
}
```

`ignoresSafeArea` does not *add* height; it permits a view that would otherwise be inset to
extend. A view explicitly framed to zero height is zero points tall wherever it is attached —
including at the root of `body`, outside the scroll view entirely, which was tested and
still bleeds.

The named fallback — a `GeometryReader` inside that same `.overlay` — fails for a different
and real reason: `safeAreaInsets` on a proxy reports what is still *un-consumed* at that
point in the layout, and a `ScrollView` consumes the top inset by turning it into content
insets. Anything layered onto the scroll view therefore reads zero.

**What works:** measure once above that consumption and pass the value down.

```swift
var body: some View {
    GeometryReader { proxy in content(topInset: proxy.safeAreaInsets.top) }
}
// ...then, on the ScrollView:
.overlay(alignment: .top) {
    Tokens.Surface.base
        .frame(height: topInset)
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
}
```

Note the cost, and leave it: a root `GeometryReader` claims all available space and
top-leading aligns its content. Harmless for a full-screen root view; it would not be for a
view sized to its content. Do not reach for a material or a gradient — `DECISIONS.md`
records both being built and both leaking where the outgoing header sits.

**The list rests flush on the current month.** *Added 2026-09-08 — omitted when this step
was written.* With the next month always expanded above, the resting position no longer falls
out of "scroll offset zero"; it has to be set. On first appearance, scroll so the current
month's header sits at the top of the visible area, with next month above the fold.

This belongs here rather than in Step 9 because **Step 7's latch measures distance from the
resting position** and cannot be built or tested while there isn't one. Step 9 restores a
*saved* place; this is where the place comes from when there is none.

**Sections are still computed into `@State`,** now over the whole window. That is one engine
call per expense per month, and the window is normally a handful of months. It is unbounded
only if someone backdates deeply. **Measure it with the seed and report the figure**; if
scrolling stutters, say so rather than paging it speculatively.

**The seed changes with this step.** `SampleData` currently anchors the insurance three
years back, which is not how anyone enters a bill and is what produced twenty-seven empty
months. Two changes:
- The annual insurance anchors **nine months before the current month**. It is then a
  deliberately backdated entry — the case the floor rule exists for — and it puts two empty
  months above itself, which the skip rule then has to hide.
- Every monthly and quarterly anchor moves **six months back**, so history exists to scroll
  through. The current month's composition is unchanged: same rows, same grouped days, same
  skipped bill, same moved bill from the previous month.

Update `SampleDataTests` accordingly, and add `theSeedHasHistoryBelowTheCurrentMonth` and
`theBackdatedAnnualSitsBelowTwoEmptyMonths`.

**Done when — named cases:**

`TimelineWindowTests`: `theTopIsOneMonthAheadWhenNothingIsUnlocked`,
`unlockingRaisesTheTop`, `theWindowRunsFromTheTopDownToTheFloor`,
`aWindowCrossingDecemberLandsInJanuary`.

**`theWindowRunsFromTheTopDownToTheFloor` must call `window.months`,** not rebuild the loop
inside the test and assert on its own local. A test that reimplements the thing it tests
passes while the real code is broken, which is what the first pass at this step produced.

`TimelineFloorTests`: `theFloorIsTheEarliestAnchor`,
`anOverrideMovedEarlierThanEveryAnchorBecomesTheFloor`,
`noExpensesHasNoFloor`, `theFloorIsTheAnchorsMonthNotItsDay`,
`anArchivedExpensesAnchorDoesNotSetTheFloor` — the engine never generates an occurrence for
an archived expense, so counting its anchor would put the floor below anything the list can
show.

and in the simulator:
- Nothing renders behind the clock or the Dynamic Island at any scroll position, including
  mid-hand-off between two months. **Screenshot the hand-off specifically**, light and dark.
- The app opens resting on the current month, with next month above the fold. Screenshot.
- Scrolling down reaches the floor line and stops. No month shows €0.
- The two empty months above the backdated insurance are absent, and the list runs
  ...March, then December 2025.
- Screenshots of the rest position, the floor, and a pinned header mid-scroll, light and dark.

**Verify:**
```
xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test
```
plus the Step 1 seam grep. `cd Core && swift test` must still report 54 — the engine is
untouched.

**Out of scope:** the unlock bar doing anything, the latest control, persistence.

---

### Step 7 — The unlock bar, and the month that puts itself away

**Depends on:** Step 6.

**Files:**
- `Tilly/Timeline/TimelineView.swift` (modified)

**Unlocking.** The bar at the top is the existing `CollapsedMonthBar` with `direction:
.above`. Tapping it increments `window.unlocked`; the bar then names the next month along.
It stays a `Button`, so it is reachable by VoiceOver and Switch Control — which is why
pull-to-unlock was rejected rather than added alongside.

**The anchor, which is the whole risk in this step and was in the last draft too.** Opening
a month inserts a screenful *above* the viewport. Anchor on the month under the **middle** of
the viewport — the one being read — and restore its position afterwards, computing the offset
in points from a live frame rather than a rounded position. A prototype of this drifted half
a point per gesture by rounding.

Two anchors look right and are not: the top-most visible item is the bar you are about to
tap, so preserving its position expands downward and shoves the month you were reading off
screen; total content height fails whenever one change adds at one end and removes at the
other.

**The tidy-up.** An unlocked month closes once the reader returns to the current month.
Two things make it safe, and both are load-bearing:

1. **A latch.** Set it when the reader scrolls more than a screenful above the resting
   position — i.e. they have actually gone up into the unlocked month. Only a latched
   window closes, and only on the way back. Without this the close fires in the frame the
   month opens in, because a month opens *outside* the viewport and is therefore instantly
   "not visible". That was observed happening and is why the earlier trigger was rejected.
2. **No closing during a programmatic scroll.** Step 8's control animates the reader home;
   the close sets scroll position directly, and doing that mid-animation fights it. Suppress
   the close while an animated return is in flight and run it once the scroll settles.

Set `unlocked` back to 0 through the same anchored path, so the current month does not move
while a screenful disappears above it.

**Never attach a modifier to a `Section` inside the pinned `LazyVStack`, and know that fixing
this changes what `scrollTo` anchors to.** Found by bisection on 2026-09-08 and confirmed by
instrumented measurement the same day: an `.onGeometryChange` on the `Section` silently breaks
`pinnedViews: [.sectionHeaders]` — the month header stops pinning entirely, so scrolling two
months into history leaves no month name on screen at all. `.id(_:)` is safe; the geometry
modifier is not.

**The two faults are coupled, which is the part that cost a round trip.** `.id(_:)` sits on
the `Section`, but what `scrollTo(_:anchor:)` resolves it to depends on whether pinning is
working:

| Pinning | `scrollTo` resolves the id to | Correct `targetHeight` in `restoreAnchor` |
|---|---|---|
| Working | the pinned header alone | the **header's** height (47pt at default sizes) |
| Broken by a modifier on `Section` | the whole section | the section's height (~672pt) |

So the pre-fix build was wrong twice in a way that cancelled: the header did not pin, *and*
the section height in `desiredOffset = f × (viewportHeight − targetHeight)` was the right
number for a list in that state. Restoring pinning without changing that expression leaves a
section height where a header height belongs, and the anchor overshoots — measured at 287
points low, against a desired offset of 48.5. Both test suites stayed green throughout, in
both directions.

**So measure the header, on the header.** `MonthHeader` already carries a geometry modifier
for its offset; read the whole `CGRect` there and take `minY` and `height` from it. No derived
section heights are needed anywhere.

**Done when:**
- The month header still pins. Scroll two months into history, let it settle, and confirm the
  month name is there with its ground and hairline. This is the regression above; it does not
  show up in any test.
- **Check the anchor again after any change to pinning, and vice versa.** They are one
  mechanism, not two. A green suite says nothing about either.
- Tapping the bar opens the month above; the bar then names the month after it.
- The opened month is genuinely above the viewport afterwards — the reader scrolls up to
  reach it and did not see the screen change.
- **It never closes in the frame it opens in.** Tap the bar and stay put: nothing happens.
- Unlock, scroll up into the month, scroll back down: it closes, and the current month does
  not move while it does. Verify by noting which row sits at a fixed point on screen,
  performing the whole sequence, screenshotting, and confirming the same row is in the same
  place. **Report both screenshots.**
- Unlock twice, then return: both close.
- No unit tests beyond `TimelineWindowTests` — what this step changes is scroll behaviour,
  and a test asserting it would be asserting a mock.

**If the anchoring will not hold** — if content jumps after the anchor is keyed to the middle
month — **stop and report it rather than shipping a jumping list.**

**Carried forward from the 2026-09-08 review — known, unfixed, and not blocking.** Each was
reasoned about rather than observed failing, so none is worth pre-emptive machinery; they are
here so the next symptom is recognised rather than rediscovered.

- ~~**`restoreAnchor`'s `f` goes outside [0,1] and relies on `UnitPoint` extrapolating.**~~
  ~~**The `abs(denominator) > 0.5` fallback jumps.**~~ **Both retired on 2026-09-08.** They
  were symptoms of the section height being in that expression at all. With the header's
  height there instead, `H − h` is about 731 points and barely moves — `f` stays inside
  `[0, 0.53]`, the denominator never approaches zero, and the fallback is unreachable. The
  "month taller than the viewport" concern goes with them: a header never approaches the
  viewport's height, at any Dynamic Type size.
- **The latch cannot fire when months are short.** `currentOffset > viewportHeight` needs the
  current month's header a full viewport down; an unlocked empty month above an empty next
  month never gets there, so it never closes. Only reachable once rules carry an `endDate`.
- **`isUnlockLatched` can stick true.** `closeUnlockedMonths()` guards on `unlocked > 0` before
  clearing the latch, so an early return leaves it set. No path reaches it yet — Step 8's
  control adds one, so clear the latch before the guard when you get there.
- **The nested `DispatchQueue.main.async` pair is timing-dependent, not sufficient in
  principle.** One run-loop turn is not guaranteed to cover a SwiftUI layout pass. Held in
  every trial. The principled fix keys off observed geometry and is more machinery than this
  step warrants.

**Verified working on 2026-09-08, so a later regression here is a regression.** Re-verified
after the pinning fix, on device, against the corrected `restoreAnchor`:

- The header pins five months into history, light and dark.
- The anchor is exact — four landmarks came back at identical pixel positions across an
  unlock, and again across a second unlock, and again at `accessibility-large` in dark mode
  where the header is more than twice as tall.
- It never closes in the frame it opens in; three seconds of stillness changes nothing.
- The tidy-up completes end to end from one unlock and from two, with the bar returning to
  its pre-unlock month.
- The current month does not move while the close happens. Measured against a control: the
  same synthesised drag moves the list 822 pixels whether or not a close fires during it, so
  the small shortfall against the drag distance is pan-gesture slop, not the anchor.

**Out of scope:** the latest control, persistence, midnight rollover.

---

### Step 8 — Getting back

**Depends on:** Step 7.

**Files:**
- `Tilly/Timeline/LatestButton.swift` (new)
- `Tilly/Timeline/TimelineView.swift` (modified)
- `Tilly/DesignSystem/Tokens.swift` (modified)

**The control.** A floating pill, bottom-centre, over the list: a chevron and the current
month's name. It points the way — up from below, down from above — and appears only once the
reader is more than a screenful from the resting position, fading in and out rather than
appearing abruptly. Tapping it animates back to the resting position, and Step 7's tidy-up
then closes anything unlocked.

`Tokens` gains the pill's dimensions and `Space.floatingClearance`. **The list carries a
bottom inset of that clearance** — `contentMargins(.bottom, …, for: .scrollContent)` — or the
floor line sits underneath the control, which the prototype demonstrated.

**Copy.** The month name alone, no verb. `September` beside an arrow is not ambiguous, and
`Back to September` restates the arrow — the same test `DESIGN.md`'s copy rule applies to
labels. It reads its name from the same formatter the header uses, so the year appears
when it is not the current one.

**Accessibility.** A `Button` with the label "Back to September" spoken in full, since
VoiceOver has no arrow to read. Hidden from the accessibility tree while it is invisible.

**Done when:**
- It is absent at rest, appears when scrolled away in either direction, points correctly.
- Tapping it returns to the current month, and any unlocked months close afterwards without
  the current month moving.
- The floor line is fully readable with the pill on screen. **Screenshot the bottom of
  history with the control visible.**
- Light and dark, plus one accessibility text size — the pill must not cover content or
  overflow its own bounds.

**Watch for the pinned-header lag while you are in here.** Observed independently twice
during Step 6 — once by the implementer, once in review — a frame during fast momentum
scrolling where a pinned header carries neither its `Surface.pinned` ground nor its hairline,
so a day heading draws straight through it. Every settled position is correct, and neither
observation reproduced deliberately. It is the background lagging the pin by a frame or two,
`isPinned` being derived from geometry that updates a beat behind the sticky placement. Fix
it here if it is cheap; report it and leave it if it is not.

**It now has a trigger you can aim at.** Reading `pinnedMonth` shortly after a programmatic
jump showed it naming October while the reader had already arrived at September; the settled
frame was correct. That is the same lag, reachable deliberately for the first time — the
scroll animation moves faster than any thumb, so the geometry is further behind. Anyone
hunting it should look there rather than trying to flick fast enough by hand.

**Two geometry caches, and why only one of them needed replacing.** Recorded from the
2026-09-08 review, because the reasoning is not visible in the code that survived.

`LazyVStack` stops laying out a header once it is far enough off screen, and therefore stops
calling `onGeometryChange` on it, so `headerOffsets` entries for distant months freeze at
whatever they last were. Seen twice: a frozen offset made a derived section height come out
at −596.7 during Step 7, and it left the current month's entry stuck near −110pt in the
first draft of this step, so a distance check against it never tripped.

**`pinnedMonth` and `monthUnderMiddle` still read that dictionary, and are safe.** Both scan
for a threshold among months near the viewport, and a stale entry can only mislead them if it
belongs to a month *below* the one being selected in document order — a month that got from
at-or-above the top edge to far below it without ever being laid out in between. Scrolling
cannot do that: the content has to travel through the viewport. Nor can the animated jump, for
the same reason. Both were exercised after returns from five and more months of history and
picked the right month every time. **What would break them** is a scroll that teleports rather
than travels, so if a future step ever sets a scroll position without animating across the
distance, re-check these two first.

The pill's check was different in kind — it compares against the current month from an
unbounded distance, exactly where the dictionary has nothing live to say — which is why it,
and only it, needed `scrollOffset` off the `ScrollView` instead.

**The resting cache has a race, and it is closed by hand.** `restingContentOffset` is
normally written as `scrollOffset + frame.minY`, combining two geometry callbacks that arrive
independently; during an animated scroll they are sampled at different instants. Measured on
device across three otherwise identical returns, the cache was left 702, 493 and 0.2 points
wrong. The pill hides within one viewport of resting, so a 702-point error still leaves 76
points of margin, and the next manual scroll corrects it — but an error reaching 778 would
leave the pill on screen at rest pointing the wrong way. `returnToResting` therefore sets the
cache to `scrollOffset` outright once the animation is done, which is true there by
construction. The general race is untouched and does not need touching: everywhere else the
two callbacks converge within a frame because nothing is animating.

**`restoreAnchor`'s denominator is the container, not the viewport.** Found on 2026-09-09,
after this step had landed. The `contentMargins(.bottom, …)` above makes the scroll container
shorter than the viewport by `pillClearance`, and `scrollTo` aligns within the container — so
dividing by the viewport lands every anchored restore at `(710 − 47) / (778 − 47) = 0.907×`
what was asked. Invisible here, because the offsets this step deals in are small enough for
the error to be a few points; plainly visible at the depths Step 9 restores from. **A
correcting second pass is not the fix** — one was written against the symptom before the
cause was found, and it converged, which is exactly how a missing term hides.

**Out of scope:** persistence, midnight rollover.

---

### Step 9 — Never lose the reader's place

**Depends on:** Step 8. This is the old Step 7, simplified by the new structure.

**Files:**
- `Tilly/Timeline/TimelinePlace.swift` (new)
- `Tilly/Timeline/TimelineView.swift` (modified)
- `TillyTests/TimelinePlaceTests.swift` (new)

**Interface:**

```swift
struct TimelinePlace: Codable, Equatable, Sendable {
    var anchorMonthID: Int      // MonthKey.id, the month under the middle of the viewport
    var anchorOffset: Double    // its top, in points, relative to the container's top
}

struct TimelinePlaceStore: Sendable {
    init(defaults: UserDefaults = .standard)
    func load() -> TimelinePlace?
    func save(_ place: TimelinePlace)
    func clear()
}
```

**What no longer needs storing, and why that is the point.** The old draft saved `lowID` and
`highID` because months stayed open until something closed them. Unlocked months now close
themselves, so there is no expanded state to restore — a place is a scroll position and
nothing else. If a reader backgrounds the app while looking two months ahead, they return to
that scroll position with the month still unlocked for the current session only.

Store the same anchor Step 7 uses, so restoring and gesturing put the reader back by the
same rule. A month always resolves — it is a computed key, not a stored row.

**Use `ScrollViewReader`, not `ScrollPosition`.** Found in Step 6 and recorded here because
this step scrolls to a restored position and would otherwise rediscover it: the newer
`ScrollPosition` / `.scrollPosition(_:)` API produced *no visible scroll at all* in this
view — logging confirmed `scrollTo` being called with the right id every time, to no effect.
A `ScrollViewProxy` from `ScrollViewReader` works. The call also has to be deferred one
run-loop turn (`DispatchQueue.main.async`, not a timed delay): when the sections first
populate, `ScrollViewReader`'s own `onAppear` has not yet set the proxy.

Step 6 sets its one-shot flag *before* that deferred call runs, so if the proxy were still
nil a turn later the scroll would be skipped and never retried. It does not happen in
practice. This step replaces that logic, so fold the guard in properly rather than inheriting
it: only mark the position as restored once a scroll has actually been issued.

**Restoring.** On first appearance, load the place. With none — the first run after
installing — rest on the current month. With one, scroll so `anchorMonthID` sits at
`anchorOffset`, clamped into the window in case the floor has moved since.

**Saving.** On scroll idle (`onScrollPhaseChange` reaching `.idle`) *and* whenever
`scenePhase` leaves `.active`. Both, deliberately: the scene-phase write covers a clean
background and the idle write covers a process killed without one. `DECISIONS.md` is explicit
that the two cannot be told apart, so neither may be the only writer.

**Crossing midnight into a new month.** Observe `NSCalendarDayChangedNotification` and
recompute `today`, which reclassifies every row that has passed and moves the header figure.
When the *month* changes, `window.current` moves up — and because the next month was already
expanded, **the month the reader is now in is already on screen and already open.** Nothing
is inserted above them; what changes is which month carries the word "left", and a new month
appears above the top. This is strictly simpler than the old model, where a month had to be
opened above the reader at rollover.

Two visible side effects are correct: the upcoming/charged boundary moves into the new month,
and anything still upcoming in the old one becomes charged.

**Done when — named cases in `TimelinePlaceTests`,** each with a `UserDefaults` suite created
for the test and removed afterwards:
- `anEmptyStoreLoadsNothing`, `aSavedPlaceRoundTrips`, `savingTwiceKeepsTheLatest`,
  `clearingRemovesThePlace`, `aPlaceBelowTheFloorIsClampedIntoTheWindow`.

and in the simulator:
- Scroll so a month header sits in the upper half of the screen, background the app, kill it,
  relaunch: every row is in the same place, to the pixel. Screenshot before and after.
- Do the same from partway down a month: you come back to that month, at its top. This is the
  accepted v1 behaviour, not a failure — see "A saved place remembers the month, not the row"
  in `docs/DECISIONS.md`, and the section above for what was measured. **Anything other than
  the right month at its top is a regression.**
- Delete and reinstall: it lands on the current month. Screenshot.

**Verify:**
```
xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test
```
then `cd Core && swift test` — still 54.

**What a saved place cannot say yet — found on device, 2026-09-09.** `TimelinePlace` stores a
month and that month's top in points from the container's top. That works whenever the anchor
month begins at or below the top of the screen, and cannot express the reader being *inside* a
month. The reason is the primitive, not the data shape:

- A pinned header is translated to stay at the container's top, so its measured `minY` reads
  exactly `0` however deep the reader is — `0.0` while that same month's content sat at
  `-394.2`. The offset saved mid-month therefore collapses to zero, and the restore lands on
  that month's first row.
- Measuring the section's *content* fixes the reading. Content is never pinned, and a month's
  own top is one header height above it, giving a true negative offset. Verified: a position
  the old scheme recorded as `0` was recorded as `-155.6`.
- `restoreAnchor` cannot consume a negative one. `scrollTo(_:anchor:)` positions a target by a
  fraction of that target's own frame and does not extrapolate outside the unit square: asked
  for `-155.6` it delivered `+139.0`. So the honest measurement is deliberately *not* wired
  in — it makes the failure worse, not better.

**Point-based scrolling is not the way out, on this view.** A spike confirmed
`ScrollPosition`'s `scrollTo(y:)` moves a list of this shape exactly, cold or warm, on a rig
built to match. It does not survive contact with the real one. Measured here:

- Binding `.scrollPosition($position)` alone is harmless — a fresh install renders and behaves
  normally with it attached.
- Driving it is not. A two-stage restore — `scrollTo(_:anchor: .top)` to place the month
  exactly, then `scrollTo(y:)` to add the depth — **rendered the list blank**, with the app
  alive and not crashed. The second stage was a 187-point move from an already-mounted
  position, not a long jump into unrendered content.
- Note also that `contentOffset.y` reads `-62.0` at the top of this list, so the reported
  offset and any `y` passed in do not share an origin. The rig showed the same 62. That alone
  would be a fixed correction; it does not explain a blank screen.

So the rig reproduced the API and not the view. Whatever is wrong involves this list's own
combination — `LazyVStack`, pinned headers, `scrollTargetLayout()`, `contentMargins` — and
finding it is a fresh investigation, not a last step. **Anyone picking this up should start by
calibrating the two coordinate spaces against each other from a settled position, before
trying to restore anything.**

That leaves the two options that were never blocked: anchor on a boundary that is on screen so
the offset stays positive — which needs a fallback for a month taller than the container, and
with the current seed most months are — or accept for v1 that a relaunch from mid-month returns
to that month's top, which contradicts `DECISIONS.md`'s "the scroll position you left it at"
and so needs a decision entry rather than silence.

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
- **A separate headline number.** Deleted from the roadmap rather than deferred: the current
  month's header carries "remaining this month" already, and pinning keeps it on screen. A
  second one would be the same figure in a box above the content.
- **Where an estimated amount comes from.** The editor and the overrides UI.

---

---

## Updates

### 2026-09-08 — the timeline scrolls; the bars and the cap come out

Steps 1–5 are built. `tilly-explore` reopened two questions and the answers replaced the
navigation model, so Steps 6 and 7 above are rewritten and a Step 8 and 9 are added. Five
entries in `DECISIONS.md` carry the reasoning; `DESIGN.md`'s timeline section is rewritten
to match.

**What changed, in one paragraph.** Tapping bars to move between months was clunky: reaching
next month cost a tap that expanded a screenful above the reader, and coming back from three
months out meant loading each month again on the way down. Scrolling down ran into `€0`
months forever, because the engine generates nothing before an anchor. The timeline is now
one list — next month always open above, history continuous below down to the oldest charge
entered — bounded at both ends, with a control that returns you to the current month.

**What this does to code that has landed.** `ExpandedRange` and `TimelineRangeTests` are
deleted, not amended: the cap, `maxOpen`, `openAbove`/`openBelow`, `barAbove`/`barBelow` and
`includeCurrentMonth` all described a model that no longer exists. `CollapsedMonthBar`
survives with `.above` only, doing one job instead of two — it is the unlock bar at the top
of the list. `MonthHeader`, `MonthSectionView`, `OccurrenceRow`, `DayGroupView`,
`TimelineBuilder`, `TimelineFormatting` and `TillyCore` are all untouched.

**Three things `tilly-explore` found that were not in any brief.**

The `€0` bar was not a first-run problem. `ExpandedRange.openBelow()` had no floor, so *any*
timeline scrolled past its oldest anchor ran into `€0` months indefinitely — a permanent
property, not a symptom of empty sample data.

The content passing behind the status bar is not only rows. A month header pins to the
bottom edge of its own section as that section exits, so during every hand-off a second
month name sits in the inset above the pinned one. That is why a scrim and a progressive
blur both failed and a solid ground is specified.

The seed's own annual anchor is the worst input the design has. Anchored three years back so
that an annual rule recurs into view at all, it drags the floor back thirty-six months and
turns two empty months into twenty-seven. Step 6 changes it.

**One decision reversed on new evidence, flagged so it does not read as drift.** "An opened
month closes by cap, not by scrolling" (2026-09-07) rejected a scroll-based close on
arithmetic — there was never a screenful below an opened month to push it off the top. Under
this structure there is next month, the current month and all of history below it, so the
trigger is reachable. The second fault in that entry is real and survives: a month opens
outside the viewport, so a naive trigger fires as it opens. Step 7 specifies the latch that
prevents it.

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

### 2026-09-07 — the header pins, and carries what is left

Both of Jake's notes went to `tilly-explore` and came back settled. `DECISIONS.md` has "The
month header carries what is left, and says so" and "An opened month closes by cap, not by
scrolling". Steps 5–7 are rewritten above; the changes below touch code that has already
landed and are specified here instead.

**`MonthSection` gains `remaining`** — `Tilly/Timeline/TimelineModels.swift`:

```swift
let total: Decimal      // excludes skipped
let remaining: Decimal  // sum of .upcoming entries only; excludes skipped
```

`TimelineBuilder.month(...)` already walks every entry and knows each one's state, so
`remaining` is one accumulator alongside the existing total — add it in the same pass rather
than filtering afterwards. Two new cases in `TimelineBuilderTests`:
`aFutureMonthsRemainingEqualsItsTotal`, `aPastMonthsRemainingIsZero`, and
`aSkippedOccurrenceCountsTowardsNeitherFigure`.

**`MonthSection` gains `isCurrent`,** computed by the caller from `today` rather than derived
inside the builder — the builder has `today` for state, but "is this the month we are in" is
a question about the *screen's* anchor and belongs where the sections are assembled.

**The header figure moves into `TimelineFormatting`:**

```swift
/// "−€162 left" for the current month; "−€1,539" for every other month.
/// A current month with nothing left reads "€0 left" — unsigned, per the zero rule.
static func headerFigure(for section: MonthSection, locale: Locale = .current) -> String
```

A collapsed bar does **not** use this — a bar always shows `amount(section.total)`. The word
appears in one place on the screen and only ever in the expanded current month.

Named cases in `TimelineFormattingTests`, `en_IE` pinned:
`theCurrentMonthsFigureCarriesTheWord`, `aPastMonthsFigureIsAPlainTotal`,
`aFutureMonthsFigureIsAPlainTotal`, `aSpentOutCurrentMonthReadsZeroLeft`.

**`MonthHeader` renders `headerFigure` instead of `amount(section.total)`,** and gains the
pinned treatment specified in Step 5. Its accessibility label changes with it: the current
month reads "September, 162 euro left" and every other month "August, total 1,539 euro out".
Update `aSectionLabelCarriesTheMonthAndItsTotal` and add
`theCurrentMonthsLabelSaysWhatIsLeft`.

**`Tokens` gains the pinned ground** — `Surface.pinned: Material = .bar`. It is a system
material deliberately: it is what makes rows visibly pass *under* the header rather than
stopping at it, and the system draws it correctly in both appearances for free.

**What does not change.** `TimelineBuilder`'s ordering, grouping, rounding and skipped
handling; `OccurrenceRow`; `DayGroupView`; the seed; `TillyCore`.

## If a step is wrong

These specs were written before the code existed. If a step turns out to be ambiguous,
impossible, or wrong, **stop and say so** — don't improvise a fix and don't silently widen
the scope. A wrong spec caught in one message costs far less than a wrong spec followed to
completion.

**Step 7 is the one most likely to be wrong**, and it says so in its own text. Two things in
it were found by building them and watching them fail rather than by reasoning: the anchor
(two obvious choices, both wrong) and the latch (without it the month closes in the frame it
opens in). Step 6 is large but ordinary. Steps 8 and 9 are ordinary work.

Step 6 also revises code that has already landed, which is the one place a spec can be wrong
in a way that looks like it is working — deleting `ExpandedRange` and its tests removes the
things that would have failed. If the window does not behave as specified, the symptom will
be in the simulator rather than in the suite.
