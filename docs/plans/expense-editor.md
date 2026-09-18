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
`.claude/rules/views-and-tokens.md` (all modified); `Tilly/Timeline/DayGroupView.swift` (deleted)

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
- `New category` switches the panel to `.newCategory`: the button row gives way to
  `NewCategoryRow` — an emoji slot (a 48pt circle, dashed `Tokens.Ink.tertiary` stroke with a
  `face.smiling` placeholder, filled `Tokens.Surface.iconWell` once chosen) beside a capsule
  name field — and the emoji keyboard opens. Choosing an emoji moves focus to the name field.
  Return creates the category (emoji and trimmed name both required; with no emoji, focus goes
  back to the slot), inserts it, selects it, and returns the panel to `.category`. Save is
  hidden in this mode.
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

## If a step is wrong

These specs were written before the code existed. If a step turns out to be
ambiguous, impossible, or wrong, **stop and say so** — don't improvise a fix and
don't silently widen the scope. A wrong spec caught in one message costs far less
than a wrong spec followed to completion.
