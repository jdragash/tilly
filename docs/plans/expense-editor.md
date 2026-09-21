# Expense editor, phase 1 — implementation plan

**Brief:** docs/briefs/expense-editor/brief.md
**Settled by:** `DESIGN.md` — "The shell", "The row", "Every charge is its own row", "Getting
back", "The month you're reading stays named", "The editor", "Empty states". `DECISIONS.md` —
"The timeline is the only screen, and everything else is a sheet", "Every expense has a
category, and a category is an emoji and a name", "Every charge is its own row".
**Reference:** `docs/prototypes/expense-editor-entry.html` (behaviour and proportions; the docs
win where they disagree).

Phase 1 is everything designed so far: a person can add a real expense and see it on the
timeline. **Phase 2**, editing an existing expense (tapping a row, "this one or all future",
ending, deleting), is designed next and appended here under `## Updates`. Rows stay untappable
in phase 1.

## Already decided — do not reopen

- Amount, name and category are required; the date starts as today. Save is disabled until all
  three are there.
- A category is an emoji and a name, both required, no colour. The app ships with none.
- The emoji comes from the **system emoji keyboard**, not a custom grid.
- A repeat's end is a **payment count** on the wheel. There is no end-date control. The count
  becomes `endDate` = the date of the last payment.
- Three equal-third buttons: date, repeat, category. Labels have no year. Once a bill ends, the
  repeat button reads `MM/yy` with a one-way arrow.
- Every charge is its own row. No day groups, no day totals.
- The month header pins with its total beside the name; + floats at the right end of that row.
- The month button is always visible and never changes. No threshold, no arrow.
- Everything opens as a sheet. No tab bar, no `NavigationStack` push from the timeline.
- No list of every expense, no categories button, no Insights.
- The row's date line keeps its current format (`Fri 18`), and gains ` · ends 05/27`.
- `isArchived` stays as it is. Its fate belongs to phase 2 (ending a bill).
- Variable amounts, `isEstimate` and the `EST` channel stay untouched and unreachable.

## Model routing

Steps 1–7 prove themselves by tests, previews and screenshots: **Sonnet**. Step 8 is pinning
and scroll geometry, where a green suite stays green with the step broken: **Opus**
(`.claude/rules/swiftui-scrolling.md`).

## Steps

### Step 1 — Let the engine say when the Nth payment falls

**Files:** `Core/Sources/TillyCore/RecurrenceEngine.swift` (modified),
`Core/Tests/TillyCoreTests/RecurrenceEngineNthDateTests.swift` (new)

**Interface:**
```swift
extension RecurrenceEngine {
    /// The date of the payment at `index` (0 = the anchor), generated from the anchor, never
    /// from the previous payment, at start of day. Ignores `rule.endDate`: this is what
    /// *sets* an end.
    public static func date(ofPayment index: Int, for rule: RecurrenceRule, calendar: Calendar) -> Date
}
```
Implement by reusing the month-index and day-offset arithmetic already in `monthBasedDates` and
`dayBasedDates`; factor a shared private helper rather than duplicating it.

**Done when:** these pass, alongside every existing Core test:
- `indexZeroIsTheAnchorAtStartOfDay`
- `twelveMonthlyPaymentsEndElevenMonthsOn` (anchor 2026-06-18, index 11 → 2027-05-18)
- `monthEndClampsWithoutSticking` (anchor Jan 31: index 1 → Feb 28, index 2 → Mar 31)
- `aLeapDayYearlyRuleClampsInOrdinaryYears` (anchor 2024-02-29 yearly: index 1 → 2025-02-28,
  index 4 → 2028-02-29)
- `everyThreeMonthsStepsByTheInterval` (anchor Jul 22, interval 3, index 2 → Jan 22)
- `weeklyAndDailyStepByDays` (weekly index 3 = anchor + 21 days; every 2 days index 5 = + 10)
- `itAgreesWithTheDatesTheRuleGenerates` (for a monthly rule, `date(ofPayment: k)` equals the
  k-th element of `dates(for:in:)` over a two-year range, k = 0…23)

**Verify:** `cd Core && swift test`

**Out of scope:** any change to `dates(for:in:calendar:)` or `occurrences(...)` behaviour.

---

### Step 2 — Give expenses a category

**Files:** `Tilly/Models/ExpenseCategory.swift` (new), `Tilly/Models/Expense.swift`,
`Tilly/Models/TillyStore.swift`, `Tilly/Models/Expense+Timeline.swift`,
`Tilly/Timeline/TimelineModels.swift`, `TillyTests/ModelLayerTests.swift`,
`TillyTests/TimelineBuilderTests.swift` (helpers only) (all modified)

Named `ExpenseCategory`, not `Category`: `ObjectiveC.Category` is already a type in scope.

**Interface:**
```swift
@Model
final class ExpenseCategory {
    var id: UUID = UUID()
    var name: String = ""
    var emoji: String = ""
    var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \Expense.category)
    var expenses: [Expense]?

    init(id: UUID = UUID(), name: String, emoji: String, createdAt: Date = Date())
}

// Expense gains:
var category: ExpenseCategory?          // optional for CloudKit; required by the editor
// and its init gains a trailing `category: ExpenseCategory? = nil`

// TillyStore.schema becomes:
Schema([Expense.self, OverrideRecord.self, ExpenseCategory.self])

// TimelineExpense gains (before `snapshot`):
let emoji: String?                      // nil only for data saved before categories existed

// Expense.timelineExpense passes `emoji: category?.emoji`
```
An expense with no category (only possible in a store from before this change) renders an
empty icon well. That is a data fallback, not a design state.

**Done when:** existing `ModelLayerTests` pass, plus:
- `aCategoryRoundTripsItsNameAndEmoji`
- `anExpenseKeepsItsCategory`
- `deletingACategoryLeavesItsExpensesWithNone` (nullify, not cascade)
- `theTimelineExpenseCarriesTheCategoryEmoji`
- `anExpenseWithNoCategoryHasNoEmoji`

Existing `TimelineBuilderTests` helpers gain `emoji: nil` where they build `TimelineExpense`.

**Verify:** `xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test`

**Out of scope:** any view. Any migration code: adding an optional relationship and a new model
is a lightweight migration SwiftData performs itself; if the existing simulator store fails to
open, **stop and report** rather than writing a migration plan.

---

### Step 3 — Make every charge its own row, carrying its emoji and its end

**Files:** `Tilly/Timeline/TimelineModels.swift`, `Tilly/Timeline/TimelineBuilder.swift`,
`Tilly/Timeline/MonthSectionView.swift`, `Tilly/Timeline/OccurrenceRow.swift`,
`Tilly/Timeline/TimelineFormatting.swift`, `Tilly/DesignSystem/Tokens.swift`,
`TillyTests/TimelineBuilderTests.swift`, `TillyTests/TimelineFormattingTests.swift`,
`TillyTests/SampleDataTests.swift`, `.claude/rules/views-and-tokens.md` (all modified);
`Tilly/Timeline/DayGroupView.swift` (deleted)

**Interface:**
```swift
struct TimelineEntry: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let emoji: String?
    let date: Date
    let amount: Decimal?
    let state: OccurrenceState
    let endDate: Date?          // the rule's end, start of day; nil when it runs on
}

struct MonthSection: Identifiable, Equatable, Sendable {
    let month: MonthKey
    let entries: [TimelineEntry] // date descending; a day's charges by amount descending,
                                 // ties by name ascending, nil amount last
    let total: Decimal
    let remaining: Decimal
    let isCurrent: Bool
    init(month: MonthKey, entries: [TimelineEntry], total: Decimal, remaining: Decimal, isCurrent: Bool)
    var isEmpty: Bool
    var hasChargedEntry: Bool
}
// DayGroup is deleted.

extension TimelineFormatting {
    /// "Fri 18 · ends 05/27" when the entry has an end; "Fri 18" otherwise. Uses "MM/yy".
    static func dateLine(for entry: TimelineEntry, calendar: Calendar, locale: Locale) -> String
}
// accessibilityLabel(for entry:) appends ", ends May 2027" ("MMMM yyyy") when endDate is set,
// before the state word.
```
`OccurrenceRow` drops `showsDate`, uses `dateLine(for:)`, and draws the entry's emoji centred in
the well at `Tokens.Text.rowEmoji` (new token, `.title2`). Upcoming rows fade the emoji with the
rest of the row: `Tokens.Opacity.upcomingIcon` (new, 0.55, from the prototype). Skipped rows use
the same fade. `MonthSectionView` iterates `section.entries`. Delete the tokens only
`DayGroupView` used (`dayHeading`, `dayTotal`, `Tracking.dayHeading`, `hairlineGap`) after
grepping that nothing else reads them.

In `views-and-tokens.md`, "a day with one charge and a day with several" becomes "a day with
several charges".

**Done when:** the suite passes with these changes to `TimelineBuilderTests`:
- delete `aDayWithOneChargeIsNotGrouped`, `twoChargesOnOneDayGroupWithADayTotal`,
  `aDayHeadingTakesTheDaysOwnState`
- rename `daysDescendSoTheFutureSitsAbove` → `entriesDescendByDateSoTheFutureSitsAbove`
- rename `entriesInADayDescendByAmount`, `entriesOfEqualAmountOrderByName`,
  `anEntryWithNoAmountSortsLast` to keep their meaning over `entries`
- rename `aSkippedOccurrenceStaysInItsDayAndOutOfTheDayTotal` →
  `aSkippedOccurrenceIsListedAndOutOfTheTotal`
- new `twoChargesOnOneDayAreTwoEntries`, `anEntryCarriesItsEmoji`, `anEntryCarriesItsRulesEnd`,
  `anEntryWithNoEndCarriesNone`

`SampleDataTests` asserts the shape this step removes, so it changes with it (step 4 then
deletes the file). Adapt mechanically to `section.entries`, keeping each test's intent:
- `theCurrentMonthShowsEveryStateAtOnce`: `days.flatMap(\.entries)` → `entries`; the
  `isGrouped` assertion becomes "at least two entries share a date"
- `theMovedBillLandsInThisMonthAndLeavesThePreviousOne`: `days` / `day.date` → `entries` /
  `entry.date`
- `theSkippedBillIsListedAndOutOfItsDayTotal` → `theSkippedBillIsListedAndOutOfTheMonthTotal`:
  the day-total assertion becomes "the month's `total` excludes the skipped entry's amount"
- `theBackdatedAnnualSitsBelowTwoEmptyMonths`: `days` → `entries`

and in `TimelineFormattingTests`: `aDateLineWithAnEndAddsItsMonth` (a rule ending 2027-05-18
gives "Fri 18 · ends 05/27" for an entry on Fri 18), `aDateLineWithNoEndIsJustTheDay`,
`anAccessibilityLabelNamesTheEnd`.

Screenshot the seeded timeline (the seed still exists here) in light and dark and at an
accessibility size: two bills on one day show as two rows.

**Verify:** `xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test`

**Out of scope:** the header, the pill, anything in `TimelineView.swift` beyond what the
`MonthSection` shape change forces.

---

### Step 4 — Remove the sample seed

**Files:** `Tilly/Models/SampleData.swift` (deleted), `TillyTests/SampleDataTests.swift`
(deleted), `Tilly/TillyApp.swift` (modified), `Tilly/DesignSystem/PreviewData.swift` (new),
`Tilly/Timeline/TimelineView.swift` (previews only)

**Interface:**
```swift
#if DEBUG
/// Invented expenses for SwiftUI previews only. Compiled out of release builds; nothing
/// seeds a store anyone uses.
enum PreviewData {
    static func insert(into context: ModelContext, today: Date, calendar: Calendar) throws
}
#endif
```
Six categories and about nine expenses, with at least: two charges on one day, one bill that
ends, one yearly bill, one every-3-months bill, one skipped override, one moved override. Every
expense has a category. Names and amounts are invented; the prototype's set is fine.

`TillyApp.init` no longer seeds; the `Logger` import goes if unused.

**Done when:** the suite passes; `grep -rn SampleData Tilly TillyTests` prints nothing; a fresh
simulator install (erase the app first) opens on `TimelineEmptyState`; the previews render.

**Verify:** `xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test`,
then install fresh and screenshot.

**Out of scope:** the empty state's own design; the shell.

---

### Step 5 — The editor's draft, as a tested value

**Files:** `Tilly/Editor/ExpenseDraft.swift` (new), `TillyTests/ExpenseDraftTests.swift` (new)

**Interface:**
```swift
enum KeypadKey: Equatable, Sendable { case digit(Int), decimal, delete }

struct ExpenseDraft: Equatable, Sendable {
    var digits: String = ""                  // "1250.5"; "." always, the locale only renders
    var name: String = ""
    var date: Date                           // start of day
    var interval: Int = 1                    // 1...30
    var unit: RecurrenceUnit = .month
    var paymentCount: Int? = nil             // nil = no end; otherwise 2...120
    var categoryID: UUID? = nil

    init(today: Date, calendar: Calendar)

    mutating func press(_ key: KeypadKey)
    // Rules, from the prototype: a leading "0" is replaced by the next digit; one decimal
    // point, inserted as "0." on an empty draft; at most 2 decimals and 7 whole digits; extra
    // presses are ignored; delete removes the last character.

    var amount: Decimal?                     // nil when empty or zero
    func isValid(categoryExists: (UUID) -> Bool) -> Bool   // amount > 0, trimmed name, category
    func isFuture(today: Date, calendar: Calendar) -> Bool  // strictly after today
    func rule(calendar: Calendar) -> RecurrenceRule         // endDate from Step 1 when counted
    func lastPaymentDate(calendar: Calendar) -> Date?       // nil without a count

    func amountText(locale: Locale) -> String       // "€0" empty; "€1,250.5" mid-entry
    func dateLabel(calendar: Calendar, locale: Locale) -> String   // "Oct 31", template "MMMd"
    func repeatLabel(calendar: Calendar, locale: Locale) -> String
    // "Daily" "Weekly" "Monthly" "Yearly" for interval 1; "3 months", "2 weeks" otherwise;
    // "05/27" ("MM/yy" of the last payment) when counted
    func lastPaymentCaption(calendar: Calendar, locale: Locale) -> String?
    // "Last payment Sep 30, 2027" (date style .medium); nil without a count
}

enum EmojiInput {
    /// The last emoji character in `text`, or nil. Keeps multi-scalar emoji (flags, skin
    /// tones, ZWJ sequences) whole.
    static func emoji(from text: String) -> String?
}
```

**Done when:** `ExpenseDraftTests` cover:
- keypad: `digitsAppend`, `aLeadingZeroIsReplaced`, `aDecimalOnEmptyBecomesZeroPoint`,
  `onlyOneDecimalPoint`, `atMostTwoDecimals`, `atMostSevenWholeDigits`, `deleteRemovesTheLast`,
  `deleteOnEmptyDoesNothing`
- `anEmptyOrZeroAmountIsNil`, `amountParsesDecimals`
- validity: `invalidWithoutAmount`, `invalidWithBlankName` ("  "), `invalidWithoutCategory`,
  `invalidWhenTheCategoryNoLongerExists`, `validWithAllThree`
- `todayIsNotFuture`, `tomorrowIsFuture`
- labels: `repeatLabelsForIntervalOne` (all four units), `repeatLabelPluralises`,
  `aCountedRepeatShowsTheLastPaymentMonth` (monthly from 2026-06-18, 12 payments → "05/27"),
  `dateLabelHasNoYear` (a date next year still reads "Mar 3"), `amountTextOnEmptyIsZero`,
  `amountTextKeepsATrailingDecimal`
- `aCountedRuleEndsOnTheLastPayment`, `anUncountedRuleHasNoEnd`,
  `theCaptionNamesTheLastPayment`
- `EmojiInput`: `takesTheLastEmoji`, `keepsAFlagWhole`, `keepsASkinToneWhole`,
  `rejectsPlainLetters`, `emptyGivesNil`

Label tests use `Locale(identifier: "en_US")` and a UTC Gregorian calendar.

**Verify:** `xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test`

**Out of scope:** any view.

---

### Step 6 — The editor sheet: amount, name, three buttons, keypad, date and repeat

**Files:** `Tilly/Editor/ExpenseEditor.swift`, `Tilly/Editor/EditorButtonRow.swift`,
`Tilly/Editor/Keypad.swift`, `Tilly/Editor/RepeatWheel.swift` (all new);
`Tilly/DesignSystem/Tokens.swift` (modified)

**Interface:**
```swift
struct ExpenseEditor: View {
    init(today: Date)            // presented by TimelineView in step 8; previewed standalone here
}

enum EditorPanel: Equatable { case keypad, date, repeat, category, newCategory }

struct EditorButtonRow: View {
    let draft: ExpenseDraft
    let category: ExpenseCategory?
    let today: Date
    @Binding var panel: EditorPanel
}
struct Keypad: View { let onPress: (KeypadKey) -> Void }
struct RepeatWheel: View { @Binding var draft: ExpenseDraft }
```

Layout, top to bottom, from `DESIGN.md` "The editor" and the prototype:
- Close button top leading: stock `Button(role: .close)` in the sheet's own toolbar area. The
  sheet is a default `.sheet` (large, with the system gap above it).
- Amount, centred, `Tokens.Text.editorAmount` (new; `.system(size: 80, weight: .semibold)`
  scaled with `@ScaledMetric(relativeTo: .largeTitle)`), one line, `minimumScaleFactor(0.3)`.
  Empty amount draws at `Tokens.Ink.tertiary`. Tapping it returns the panel to `.keypad`.
- Name: a centred `TextField("Name it")` at `Tokens.Text.editorName` (new, `.title3.weight(.medium)`).
  While it's focused, the panel area gives way to the system keyboard and Save rides above it.
- The button row, equal thirds (`Tokens.Space.tight` apart, `Tokens.Size.editorButton` 40pt
  tall, `Tokens.Radius.editorButton` 12, a 1pt `Tokens.Ink.quaternary` stroke, filled
  `Tokens.Surface.editorButtonActive` = `Color(.tertiarySystemFill)` while its panel is open).
  Tapping the open panel's button again returns to `.keypad`.
  - date: `calendar.badge.clock` when `isFuture`, else `calendar`; label `dateLabel`
  - repeat: `repeat`, or `arrow.right.to.line` when counted; label `repeatLabel`
  - category: the emoji at `Tokens.Text.rowEmoji`, or `tag` when none
  - At `dynamicTypeSize.isAccessibilitySize` the three stack full width, same order.
- The panel area, fixed at `Tokens.Size.editorPanel` (new; start at 340 and tune so the
  graphical calendar is not clipped, then note the measured value in the token's comment).
  Every panel fills exactly this height, so the amount never moves.
  - `.keypad`: `Keypad`, a 3×4 grid (1–9, the locale's decimal separator, 0, `delete.left`),
    rows sharing the height.
  - `.date`: stock `DatePicker(selection:displayedComponents: .date).datePickerStyle(.graphical)`,
    writing start of day.
  - `.repeat`: `RepeatWheel` — a static "Every", then three `.wheel` pickers: interval 1…30,
    unit (singular or plural by interval), end ("no end", then "2 payments"…"120 payments").
    `lastPaymentCaption` under it, `Tokens.Ink.secondary`.
  - `.category` / `.newCategory`: a placeholder `Text` in this step; step 7 fills them.
- Save: full width at the bottom, stock `.buttonStyle(.borderedProminent)`,
  `.controlSize(.extraLarge)`, tint `Tokens.Ink.primary`, disabled until `isValid`. Saving
  inserts `Expense` (trimmed name, `amount`, anchor `draft.date`, interval, unit,
  `rule(...).endDate`, category) into the model context, saves, and dismisses.

**Done when:** the suite passes; previews of the editor render empty, filled with a future date
and a counted repeat, and at an accessibility size; screenshots in light and dark show the
amount at the same height with each panel open.

**Verify:** `xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test`,
then previews and simulator screenshots.

**Out of scope:** presenting the editor from the timeline (step 8); the category panel (step 7);
editing an existing expense (phase 2).

---

### Step 7 — Choosing and making a category

**Files:** `Tilly/Editor/CategoryPicker.swift`, `Tilly/Editor/NewCategoryRow.swift`,
`Tilly/Editor/EmojiTextField.swift` (all new); `Tilly/Editor/ExpenseEditor.swift` (modified)

**Interface:**
```swift
struct CategoryPicker: View {
    @Binding var selection: UUID?
    let onNew: () -> Void
}
/// A UITextField whose keyboard opens on the system emoji keyboard: `textInputMode` returns
/// the active input mode whose `primaryLanguage == "emoji"`. Where the person has no emoji
/// keyboard enabled it falls back to their default keyboard, and `EmojiInput` still filters.
struct EmojiTextField: UIViewRepresentable {
    @Binding var emoji: String?
    @Binding var isFocused: Bool
}
struct NewCategoryRow: View {
    let onCreate: (ExpenseCategory) -> Void
    let onCancel: () -> Void
}
```
- `CategoryPicker` fills the panel: a list of `@Query(sort: \ExpenseCategory.name)` rows (emoji,
  name, a checkmark on the selected one), then a tinted `New category` row with `plus`. Tapping
  a row selects it (tapping the selected one keeps it selected).
- `New category` switches the panel to `.newCategory`: the button row stays, and
  `NewCategoryRow` takes the panel's place above the keyboard (as in the prototype) — an emoji slot (a 48pt circle, dashed `Tokens.Ink.tertiary` stroke with a
  `face.smiling` placeholder, filled `Tokens.Surface.iconWell` once chosen) beside a capsule
  name field — and the emoji keyboard opens. Choosing an emoji moves focus to the name field.
  Return creates the category (emoji and trimmed name both required; with no emoji, focus goes
  back to the slot), inserts it, selects it, and returns the panel to `.category`. Save is
  hidden in this mode. The category button stays active, and tapping it is the visible way
  back: it returns to `.category` (that is `onCancel`).
- The editor's category button now shows the chosen emoji.

**Done when:** the suite passes; in the simulator, from an empty store, you can make a category
from the emoji keyboard, see it selected, and Save enables once amount and name are there.
Screenshot the list, the new-category row with the emoji keyboard up, and the button showing the
emoji, in light and dark.

**Verify:** `xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test`,
then the simulator walk-through above.

**Out of scope:** renaming or deleting categories; a custom emoji grid.

---

### Step 8 — The shell: + in the header row, the month button, settings (Opus)

**Files:** `Tilly/Timeline/TimelineView.swift`, `Tilly/Timeline/MonthHeader.swift`,
`Tilly/Timeline/CollapsedMonthBar.swift`, `Tilly/DesignSystem/Tokens.swift` (modified);
`Tilly/Timeline/MonthButton.swift` (new, replaces `LatestButton.swift`, deleted);
`Tilly/Settings/SettingsSheet.swift` (new)

**Interface:**
```swift
struct MonthButton: View {       // "September", stock .glass; VoiceOver "Back to September"
    let month: MonthKey
    let today: Date
    let action: () -> Void
}
struct SettingsSheet: View {}    // a sheet: close button, "Settings", one Categories section
```
- **Header row.** `MonthHeader`'s standard layout becomes name, then total beside it
  (`Tokens.Space.tight` apart), then `Spacer`, with trailing clearance
  `Tokens.Space.headerTrailingClearance` (new: the + button's width plus the gutter plus
  `gap`) so the total never runs under +. It takes a fixed `Tokens.Size.headerRow` minimum
  height (new, 52) with the text vertically centred, replacing its top and bottom padding. The
  accessibility-size layout keeps stacking, with the same trailing clearance.
  `CollapsedMonthBar` takes the same clearance and puts its total beside its name, because at
  the very top of the list it passes under + too.
- **+.** A stock glass circle (`Tokens.Size.floatingButton`, new, 44; `plus`), overlaid top
  trailing on the scroll view and vertically centred in the `headerRow` band where headers pin.
  It never moves; headers hand off beneath it. VoiceOver: "Add an expense". It presents
  `ExpenseEditor` as a sheet. It is also present over `TimelineEmptyState`.
- **Bottom.** One overlay row: `MonthButton` leading, a stock glass circle `gearshape` trailing
  (VoiceOver "Settings", presents `SettingsSheet`), `Tokens.Space.gutter` from the edges.
  Always visible, over the empty state too. Its measured height plus `Tokens.Space.section`
  sets the list's bottom `contentMargins` (replacing `pillClearance`, same measuring approach,
  and `restoreAnchor`'s denominator keeps using it).
- **Month button.** Always visible, no opacity, no direction. It calls `returnToResting()`,
  which keeps its distance-scaled duration (with `returnDistance == nil`, the minimum). Delete
  `returnDirection`, `isReturnVisible`, the visibility animation, and the tokens
  `returnThreshold`, `pill`, `pillHorizontal`; add `Tokens.Space.monthButtonHorizontal`.
  Update the doc comments that describe the pill.
- **First expense.** When `expenses` goes from empty to non-empty, `window` is still nil and the
  list would stay blank: `onChange(of: expenses)` calls `setUpIfNeeded()` when `window == nil`,
  and the first-run restore lands on the current month.
- **SettingsSheet.** A stock `List` (inset grouped) with one section headed "Categories": each
  category's emoji and name, sorted by name; "None yet." when there are none; section footer
  "New categories are made while adding an expense." Rows aren't tappable. Close button top
  leading, title "Settings" inline.

**Done when:** the suite passes, and on device or simulator, measured, not assumed:
- at rest, the current month's header sits in the + row, and + is centred on it within 1pt
- scrolling into history, each header hands off beneath + with no jump, and the hairline shows
  only while pinned
- the unlock bar, scrolled to the very top, has no text under +
- the month button returns from deep history and from an unlocked month; opening and closing a
  month still anchors on the month under the middle (re-check per the rules file, since the
  header height changed)
- a relaunch still restores to the saved month
- first run: + → editor → make a category → save → the timeline appears on the current month
  with the new row, its emoji in the well
- light, dark, and an accessibility text size, each screenshotted

**Verify:** `xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test`,
then the checks above in the simulator, with screenshots.

**Out of scope:** a view switch beside + (calendar view is v1.1); tapping rows (phase 2);
editing categories; anything else in Settings.

---

## Lessons

- **Step 9:** how far the list reaches ahead is paid at launch, because the reader sits at its
  bottom: `scrollTo` the current month lays out every month above it first. At 1,200 months ahead
  (Typical year, 9 expenses) that was 34.4s eagerly — most of it `monthBasedDates` walking from the
  anchor on every call, which made the build quadratic until the engine learned to jump to the
  window. With that fixed it was still 380ms, and the reader saw September 2126 for half a second
  before the list landed. Building a month's rows only when drawn didn't help (`scrollTo` builds
  them all anyway), `.defaultScrollAnchor(.bottom)` was worse, and a `List` was worse again: it
  built all 1,200 before the first frame, 1,145ms against 367ms. Jake chose five years. At 60 months
  ahead: 22ms to build 70 months, first frame 382–424ms against a 361–373ms baseline, and the list
  lands 34ms after it appears, so nothing else is ever seen.
- **Step 9:** a relaunch two years ahead returned at the *shortest* duration, because
  `restingContentOffset` is only ever set by the current month's header being laid out, and that far
  off screen it never is. Scrolling to the current month first and then on to the saved place does
  not fix it: two `scrollTo` calls a turn apart still fight, the second landing at 0.0 or nowhere,
  because the first is still settling. An unknown distance now takes the longest duration.
- **Step 9:** measured in the simulator with step 8's method. Five hard flings ran Oct 2026 → Nov
  2028 with no reversal and 47 hand-offs, every one exactly 52.0pt. First run rests at 0.05pt. The
  month button lands 0.0 from two years ahead (0.9s) and from deep history (1,780pt, 0.59s). A
  relaunch two years ahead restored to 225.333 against 225.333 saved. `Nothing after November.`
  sits above a bill ending after three payments, with nothing above it.

- **Step 8:** the `.glass` button style pads around its label: a 44pt label measured 58pt. For a
  control that has to sit exactly in the header row, `glassEffect(.regular.interactive(), in:)` on a
  plain button gives the size asked for (44.0 measured).
- **Step 8:** measured with temporary `print`s of global frames, read through
  `simctl launch --console-pty`, more precise than pixels. At rest the current header's band is
  global y 62–114 and + is 66–110: centred to 0.0pt. In a hand-off the outgoing header sits exactly
  one header height (52.0) above the incoming one on every frame. Unlock held October at 48.5 → 48.5
  and 56.5 → 56.5 at `accessibility-extra-large`. The automatic close held September at 0.0, and a
  relaunch restored July at 178.5, as saved.
- **Step 8:** Save dismisses the editor when it's presented for real, and a first expense makes the
  timeline appear. But one month of history is shorter than the screen, so nothing can scroll the
  current month flush to the top: first run shows the unlock bar and next month above it.
- **Step 8:** at `accessibility-extra-large` the unlock bar doesn't stack, and with the + clearance
  its name truncates (`Nov…`). The stacked month header has no vertical padding now that
  `headerRow` replaced it, so its total sits close to the hairline.
- **Step 8:** the bottom row follows the keyboard in the timeline behind the editor (the gear moved
  to y 422 while the emoji keyboard was up). It's hidden by the sheet.

- **Step 7:** overriding `textInputMode` on a `UITextField` subclass to return the active mode whose
  `primaryLanguage == "emoji"` opens the keyboard directly on the system emoji keyboard, checked
  in the simulator. The field draws nothing (clear text and tint) and the slot draws the emoji
  around it, so no UIKit font is needed. `EmojiInput` filters what arrives.
- **Step 7:** the amount-and-name block centres in whatever height is left, so it sits about 30pt
  lower while the emoji or text keyboard is up than at rest. The amount is fixed across panels,
  not across keyboards.
- **Step 7:** `NewCategoryRow.onCancel` is the category button, still shown above the row: tapping
  it goes back to `.category`. VoiceOver's escape gesture does the same.
- **Step 7:** walked through in the simulator with real taps: emoji chosen, focus moved to the name,
  Return created the category and selected it, Return with a blank name stayed on the name, Return
  with no emoji went back to the slot, the category button cancelled, and Save stored the expense.
  Two notes: the emoji keyboard shows a one-time skin-tone tip on the first tap of a variant emoji
  (👍) that swallows the tap, so dismiss it with OK; and choosing the *same* emoji again changes
  nothing, so focus stays on the emoji keyboard. A filled slot shows no focus ring while it is
  being changed.
- **Step 7:** a temporary `.sheet(isPresented: .constant(true))` can't be dismissed, so Save's
  `dismiss()` can't be seen with it; check dismissal once step 8 presents the editor for real.
- **Step 7:** `EmojiTextField.updateUIView` must act on a *change* of `isFocused`, tracked as the last
  value it saw, not on its state: in the emoji-to-name handoff the binding is briefly stale, and
  re-asserting focus from state pulls it back. Don't track it from the delegate either: there the
  delegate's `false` against a stale `true` reads as a fresh request and does the same.
- **Step 7:** a focused UIKit field doesn't make a SwiftUI `ScrollView` follow it (only a SwiftUI
  `TextField` does), so at `accessibility-extra-large` the emoji keyboard covered the new-category
  row. `ScrollViewReader` with an `.id` on the row, scrolled to with anchor `.bottom` from an
  `onChange(of: panel)` a turn later (`Task { @MainActor in }`, animated), puts it just above the
  keyboard; the default size doesn't move.
- **Step 7:** SwiftUI drops a `TextField`'s focus after `onSubmit`, so a refocus inside `submit()`
  loses; do it in a `Task { @MainActor in }`. A `UIViewRepresentable`'s delegate must not write its
  binding synchronously either, because `resignFirstResponder()` in `updateUIView` fires
  `didEndEditing` mid-update.

- **Step 6:** a wheel `Picker`'s natural width is effectively unbounded, so `fixedSize(horizontal:)`
  on one pushes the whole layout wider than the screen. Give the narrow wheels explicit widths
  (`Tokens.Size.wheelInterval`, `wheelUnit`) and let the end column take the rest. Equal thirds
  truncate "12 payments".
- **Step 6:** `.borderedProminent` tinted with `Ink.primary` draws a white button in dark mode
  with a white label, so the label vanishes. Set the label's colour to the opposite ground
  (`Tokens.Surface.base`).
- **Step 6:** to see the editor before step 8 presents it, use a temporary file that reads
  environment variables (`SIMCTL_CHILD_…` with `simctl launch`) and a one-line `.sheet` in
  `TillyApp`, and delete both after. Don't `git checkout` a file to remove the hook while it also
  holds uncommitted work.
- **Step 6:** to make content fill a `ScrollView` (a flexible block that pushes the rest down to a
  bottom `safeAreaInset`), give the content `frame(minHeight:)` from
  `onScrollGeometryChange { $0.containerSize.height }`. That is the visible height net of the
  insets: `visibleRect.height` overshoots, so the last rows hide under the inset, and subtracting
  `contentInsets` as well undershoots, so nothing stretches.
- **Step 6:** at accessibility text sizes the sheet scrolls, the keypad's last row and the repeat
  caption sit under Save until you scroll, and the end wheel truncates ("12 pay…"). Unsolved, as
  the prototype's notes say.

- **Step 4:** `#Preview` blocks are not stripped from Release builds. A preview that uses
  `PreviewData` (which is `#if DEBUG`) has to sit inside `#if DEBUG` itself, or the Release
  configuration stops compiling. Check with `xcodebuild -scheme Tilly -configuration Release build`.

- **Step 3:** `Tokens.Text.rowEmoji` is `.title2`, which scales with Dynamic Type, while the well
  (`Tokens.Size.iconAccessible`, 44pt) is fixed. At `accessibility-extra-large` the emoji fills the
  well to its edges. Fine to read, but a fixed-size well is the reason it can't grow further.
- **Step 3:** the seeded store has no categories or end dates, so the emoji, the fade and
  `· ends 05/27` can't be seen on the seeded timeline. Check them with a temporary local edit to
  `SampleData` and revert it; `PreviewData` (step 4) will make this ordinary.

## Updates — 2026-09-19: revisions from testing on a phone

Steps 1–8 are built on `expense-editor-build`, with the Developer panel on `developer-scenarios`
above it. These steps revise phase 1 from Jake's testing on his iPhone and continue on
`developer-scenarios`. Phase 2 is still next after this.

**Settled by:** `DESIGN.md` — "One list, and the future runs on", "Getting back", "The month you're
reading stays named", "The editor". `DECISIONS.md` — "The timeline is one list, future above and
past below, and the future has no end", rewritten today.

### Already decided — do not reopen

- **The future is still up.** You reach next month by scrolling up, as now. Only the way further
  ahead changes: no unlock bar, no tap, no months that close themselves. You keep scrolling.
- **Scrolling ahead has no end the reader can reach** while any bill runs on. When every bill has an
  end, the list stops at the month of the last payment with `Nothing after May 2027.`, mirroring the
  history floor.
- **An empty month ahead isn't listed**, as in history, except next month, which is always there.
- **The month button** always returns to the current month, whether the list is scrolling or still.
  Nothing closes on the way, because nothing is open.
- **The editor's buttons are date, category, repeat**, in that order, stacked in the same order at
  accessibility sizes.
- **Save is the system's confirm button**, a prominent checkmark top right, with close top left. It
  is disabled until amount, name and category are all there. The full-width bottom Save goes.
- **The keyboard covers the editor rather than pushing it**: amount, name and buttons stay where
  they are when the name keyboard opens.
- **+ gets 8pt of clear space above and below it** in the header row.
- **The floating buttons are the system's size**, measured from iOS Calendar, not guessed. The
  month button's label is `.headline`, as Calendar's is weightier than `.callout`.

### Model routing

Steps 9–11 are scroll geometry, pinning and anchoring, where a green suite stays green with the
step broken: **Opus** (`.claude/rules/swiftui-scrolling.md`). Step 12 proves itself by tests and
screenshots: **Sonnet**. Step 12 is independent of 9–11 and may be built first.

---

### Step 9 — Scroll ahead without end (Opus)

**Files:** `Core/Sources/TillyCore/RecurrenceEngine.swift`,
`Core/Tests/TillyCoreTests/RecurrenceEngineMonthYearTests.swift`,
`Tilly/Timeline/TimelineWindow.swift`, `Tilly/Timeline/TimelineView.swift`,
`Tilly/Timeline/TimelineFormatting.swift`, `Tilly/Timeline/TimelinePlace.swift` (doc comment only),
`Tilly/DesignSystem/Tokens.swift`, `TillyTests/TimelineWindowTests.swift`,
`TillyTests/TimelinePlaceTests.swift`, `TillyTests/TimelineFormattingTests.swift` (modified);
`Tilly/Timeline/TimelineCeiling.swift`, `TillyTests/TimelineCeilingTests.swift` (new);
`Tilly/Timeline/CollapsedMonthBar.swift` (deleted)

**Interface:**
```swift
struct TimelineWindow: Equatable, Sendable {
    /// How far ahead the list is built when no bill ends: five years, dozens of flings away.
    static let monthsAhead = 60
    let floor: MonthKey
    let ceiling: MonthKey
    let current: MonthKey
    init(floor: MonthKey, ceiling: MonthKey, current: MonthKey)
    var months: [MonthKey]      // ceiling down to floor, descending
}
// `unlocked` and `top` are deleted.

enum TimelineCeiling {
    /// The month of the last payment when every expense has an end, never before
    /// `current + 1`; `current + monthsAhead` when any expense runs on. nil with no expenses.
    static func month(for expenses: [Expense], current: MonthKey, calendar: Calendar) -> MonthKey?
    /// True when the ceiling is a real last payment, so the list says so.
    static func isLastPayment(_ ceiling: MonthKey, for expenses: [Expense], current: MonthKey, calendar: Calendar) -> Bool
}
```

**Mechanism: one window built once, never prepended to.** The list holds every month from the
ceiling down to the floor from the start, so nothing is ever inserted above the reader and no
anchoring is needed. `LazyVStack` renders only what is on screen, but the reader sits at the bottom
of it, and the launch scroll back to this month lays out every month above first — so how far ahead
the window reaches is a launch cost, and five years is what that buys (Lessons).

- **Engine first, test first.** `monthBasedDates` starts its walk at the window instead of at the
  anchor, as `dayBasedDates` already does, so a month far from the anchor costs what a near one
  does. New tests: a window in February 2126 on a rule anchored 31 January 2026 gives 28 February
  2126, a 3-month interval keeps its phase there, and a leap-day yearly rule clamps. The existing
  tests stay green unedited.
- `visibleMonths` keeps the current month and the one after, and drops any other month whose
  section is empty.
- `rebuildSections()` builds every month from the ceiling down to the floor, eagerly, as it builds
  history now. **Measure** the cold launch to first frame with Typical year against the 370ms
  baseline (Lessons). If launch is more than 100ms slower, stop and report rather than trimming
  `monthsAhead`.
- An unknown return distance takes the longest duration, not the shortest: it is unknown exactly
  when the current month's header has never been laid out, which means the reader is far from it.
- Above the ceiling, when `isLastPayment`: `Nothing after <month>.`, styled as `floorLine`. With no
  last payment, nothing is drawn above the top month.
- Delete `unlockMonthAbove`, `updateLatch`, `isUnlockLatched`, `closeUnlockedMonths`, and the call
  to it in `returnToResting`, plus `CollapsedMonthBar`. `anchorAndSettle` and `restoreAnchor` stay,
  because restoring a place uses them. Delete `Tokens.Size.monthBar`, `monthBarAccessible` and
  `Tokens.Text.barTotal` after grepping that nothing else reads them. `barName` stays until step 11
  renames it.
- `handleDayChange` rebuilds the window with the new current month and a recomputed ceiling. The
  month the reader is in was already listed, but the ceiling rises by a month far above and an
  empty month can join or leave, so the month under the middle is held with `anchorAndSettle`.
- Update every doc comment that describes unlocking or next month "always expanded" to say what is
  true now, including the type comment on `TimelineView` and the one on `TimelinePlace`.

**Done when:** the suite passes with these tests.
- `TimelineWindowTests`: delete `theTopIsOneMonthAheadWhenNothingIsUnlocked` and
  `unlockingRaisesTheTop`. `theWindowRunsFromTheTopDownToTheFloor` becomes
  `theWindowRunsFromTheCeilingDownToTheFloor`. Keep `aWindowCrossingDecemberLandsInJanuary`.
- `TimelineCeilingTests`: `aBillWithNoEndRunsFarAhead`, `whenEveryBillEndsTheCeilingIsTheLastPayment`,
  `oneBillWithoutAnEndOutweighsOnesThatEnd`, `aLastPaymentBeforeNextMonthStillShowsNextMonth`,
  `noExpensesMeansNoCeiling`, `isLastPaymentOnlyWhenEveryBillEnds`.
- `TimelineFormattingTests`: delete `aBarsLabelIsAlwaysThePlainTotal` with the bar's own label.

In the simulator, measured the way step 8's Lessons describe:
- From rest, five hard flings upward travel continuously through months ahead: no stop, no jump,
  and each header hands off beneath + exactly one header height apart.
- At rest the current month is flush, header at the top to within 0.5pt, as before.
- The month button returns flush from two years ahead and from deep history, at the distance-scaled
  duration, which is the maximum from far ahead.
- A relaunch while reading a month a year ahead restores to that month.
- Typical year's cold launch time, measured against the baseline.
- `One expense`, edited to end after three payments, shows `Nothing after <month>.` above its last
  payment, and nothing above that.

**Verify:** `xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test`,
then the checks above.

**Out of scope:** the month button's behaviour mid-scroll (step 10); the header's padding and a
short list resting flush (step 11).

---

### Step 10 — The month button answers mid-scroll (Opus)

Needs step 9.

**Files:** `Tilly/Timeline/TimelineView.swift`, `Tilly/Timeline/MonthButton.swift` (modified)

**The bug, as it was hit:** while the list is still moving after a flick, tapping `September` does
nothing, and it works only once the list has stopped. In Calendar, Today works mid-flick.

**Diagnose before fixing** (`.claude/rules/swiftui-scrolling.md`, "Diagnosing"). With a temporary
`print` in the button's action, fling and tap. Find out which of these is true:
1. the action never runs, because the tap goes to the scroll view, which stops the fling;
2. the action runs, but `scrollTo` loses to the deceleration still in progress;
3. something else.

Fix the cause the logging shows, and record what it was, and what fixed it, in Lessons. The fix
must not add a second tap, a delay the reader can feel, or a check on the scroll phase that ignores
taps. If the only fix found needs UIKit introspection of the scroll view, stop and report it
instead, as it is a decision that wants discussing.

**Done when:** in the simulator, one tap on the month button lands the current month flush, with
its header at the top to within 0.5pt, in each of these, five times each:
- mid-fling up from history
- mid-fling down from a year ahead
- at rest, from both directions (no regression)

and a place saved after each landing is the current month.

**Verify:** the step 9 command, then the checks above.

**Out of scope:** the button's look (step 11).

---

### Step 11 — The header row breathes, the buttons match the system, a short list rests flush (Opus)

Needs step 9.

**Files:** `Tilly/DesignSystem/Tokens.swift`, `Tilly/Timeline/MonthHeader.swift`,
`Tilly/Timeline/MonthButton.swift`, `Tilly/Timeline/TimelineView.swift` (modified)

**Measure the system first.** On the iPhone 17 simulator, open Calendar in the month list view and
screenshot it. Measure the diameter of its top glass circle buttons and the height of its bottom
Today button, in points (divide pixels by the screen scale). Note both, and the screenshot's path,
in the token comments.

- `Tokens.Size.floatingButton` becomes Calendar's circle diameter. If Today is a different
  height, the month button takes Today's height through a new `Tokens.Size.monthButton`.
  Otherwise it keeps sharing `floatingButton`.
- `Tokens.Text.barName` is renamed `Tokens.Text.monthButton` and becomes `.headline`.
- `Tokens.Space.headerRowInset` (new): 8. `Tokens.Size.headerRow` is now derived:
  `floatingButton + 2 × headerRowInset`.
- The stacked accessibility layout in `MonthHeader` takes `headerRowInset` of vertical padding, so
  its total no longer touches the hairline.
- **A short list rests flush.** A list with one month of history is shorter than the screen, so the
  current month can't reach the top. Add clear space after `floorLine`, measured live:
  `max(0, containerHeight − (distance from the current header's top to the floor line's bottom))`.
  Measure the floor line on the line itself, never on a `Section`.
- **The bottom row ignores the keyboard** (`.ignoresSafeArea(.keyboard)`), so it no longer
  moves behind the editor sheet.

**Done when:** the suite passes, and in the simulator, measured:
- + is centred in the header band to within 0.5pt, with `headerRowInset` above and below it
- a hand-off beneath + is still exactly one header height, at the new height
- restoring a saved place still lands to within 0.5pt, rechecked because the header height changed
- `One expense` on first run rests flush on the current month, with next month above the screen.
  With more history, the added space is 0.
- with the emoji keyboard up in the editor, the gear's global frame hasn't moved
- at `accessibility-extra-large` the stacked header has clear space above and below
- screenshots beside Calendar's at the same scale, light and dark, and at an accessibility size

**Verify:** the step 9 command, then the checks above.

**Out of scope:** the editor; any other token.

---

### Step 12 — The editor: date, category, repeat; a checkmark to save; the keyboard covers (Sonnet)

Independent of steps 9–11.

**Files:** `Tilly/Editor/ExpenseEditor.swift`, `Tilly/Editor/EditorButtonRow.swift`,
`Tilly/DesignSystem/Tokens.swift` (modified)

**Interface:** no new types. `saveButton` is deleted; `save()` stays.

- `EditorButtonRow` lays out `dateButton`, `categoryButton`, `repeatButton`, in both layouts.
- **Save.** `ToolbarItem(placement: .confirmationAction)` holding `Button(role: .confirm)` calling
  `save()`, stock, with no tint override. VoiceOver reads "Save". It is disabled until `isValid`, and
  while `panel == .newCategory`: a half-made category is finished or cancelled first. Delete the
  bottom `safeAreaInset`, and any token only Save used, after grepping.
- **The keyboard covers.** At standard text sizes the editor's content ignores the keyboard's safe
  area, so opening the name keyboard moves nothing. `NewCategoryRow` still sits directly above the
  emoji keyboard, as now. At accessibility sizes, keyboard avoidance stays as it is, because the
  name field would otherwise be covered.
- The `ScrollViewReader` scroll to `newCategoryRowID` stays only if the accessibility-size check
  below still needs it. Remove it if not.

**Done when:** the suite passes, and in the simulator:
- the amount's global y is the same, to within 0.5pt, with the keypad, the name keyboard and the
  date panel open
- the checkmark is disabled on open, stays disabled with only amount and name, and enables once a
  category is chosen. Tapping it saves the expense and dismisses the editor.
- making a new category: the checkmark is disabled, the row sits above the emoji keyboard, and
  Return still creates and selects the category
- at `accessibility-extra-large` the name field and the new-category row stay visible while typing
- screenshots in light and dark, and at an accessibility size

**Verify:** `xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test`,
then the checks above.

**Out of scope:** the amount, keypad or pickers themselves; editing an existing expense (phase 2).

---

### Open checks, for tilly-ship

Unchecked on the phone from the Developer panel: Reset scenario, Forget my place, and switching back
to Your data. `tilly-ship` checks all three with real taps before merging.

## If a step is wrong

These specs were written before the code existed. If a step turns out to be
ambiguous, impossible, or wrong, **stop and say so** — don't improvise a fix and
don't silently widen the scope. A wrong spec caught in one message costs far less
than a wrong spec followed to completion.
