# Editing an existing expense — implementation plan

**Brief:** docs/briefs/expense-editor/brief.md (phase 2: the part it puts "In" that phase 1 didn't build)
**Settled by:** `DESIGN.md` → "The row" (ends and ended), "Nothing under the reader's eyes
moves", "The editor" → "Opening a charge edits it", "This charge, or future charges", "Deleting
asks which". `DECISIONS.md` → "Editing a charge is Calendar's", "Deleting asks Calendar's
question, and €0 is an ordinary amount", "A bill is a series of rules, and "future charges" starts the next
one". Canvas page "Round 6 · Editing an expense (settled)"; working prototype
`docs/prototypes/expense-editor-entry.html` in its "edit" mode, whose `applyThis` / `applyFuture` /
delete handlers are the reference behaviour where this plan is silent on a detail. Its "view
first" mode was prototyped and set aside (`DECISIONS.md`); don't build it.

## Already decided — do not reopen

- Tapping a row opens `ExpenseEditor` for that charge, keypad up, filled in. No detail page.
- ✓ is disabled until something changed. A red trash button sits left of ✓, edit mode only.
- On ✓: a repeat change (interval or unit) saves as future charges without asking. €0 saves for
  this charge alone without asking; it is an ordinary amount, and nothing skips a charge. Otherwise an amount or date change asks `Save for this charge only` /
  `Save for future charges` when a later charge exists, and saves for this charge when none does.
  Name, category and payment count alone save to the whole bill without asking.
- "Future charges" never changes a charge before the open one. From a bill's first charge it is
  the whole bill, edited in place.
- Later one-off overrides survive a future-charges save when the new rule still generates their
  scheduled date; the rest are deleted.
- The wheel's payment count is the whole bill's, and offers no count that ends before the open
  charge.
- Trash asks `Delete All Future Charges` / `Delete All Charges`; on a bill's first charge only
  `Delete <name>`. Shaking undoes the last save or delete (step 8).
- A row of a bill whose last payment is today or past reads `ended 08/26`; otherwise `ends 05/27`.
- After a save or delete the timeline stays where it was. It never scrolls to the edited charge.
- A split writes a second `Expense` sharing `seriesID`; the engine (`Core/`) does not change.
- `isArchived` stays on the model, unused. Removing a stored property is a migration for no gain.

## Model routing

Steps 1–6 and 8 prove themselves with tests: Sonnet. Step 7 is scroll anchoring, which a green suite
can't see (`.claude/rules/swiftui-scrolling.md`): Opus.

## Steps

### Step 1 — Bills as series, and entries that know their charge

Depends on nothing.

**Files:** `Tilly/Models/Expense.swift` (modified), `Tilly/Models/Expense+Timeline.swift`
(modified), `Tilly/Timeline/TimelineModels.swift` (modified), `Tilly/Timeline/TimelineBuilder.swift`
(modified), `Tilly/Timeline/TimelineFormatting.swift` (modified), `TillyTests/TimelineFormattingTests.swift`
(modified), `Tilly/Timeline/TimelineView.swift` (modified: `rebuildSections` only),
`TillyTests/ModelLayerTests.swift`, `TillyTests/TimelineBuilderTests.swift` (modified)

**Interface:**
```swift
// Expense
/// Optional so a migrated store gives existing bills no shared default: nil is "its own series".
var seriesID: UUID?
var seriesKey: UUID { seriesID ?? id }

extension Expense {
    /// One `TimelineExpense` per record, each carrying its series' end: the end of the
    /// latest-anchored record sharing its `seriesKey`, nil when that record runs on.
    static func timelineExpenses(_ expenses: [Expense]) -> [TimelineExpense]
}

// TimelineExpense gains, after `overrides`:
let seriesEndDate: Date?

// TimelineEntry gains, after `id`:
let expenseID: UUID
let scheduledDate: Date // the rule's date, start of day; `date` stays the effective one
// and, after `endDate`:
let endHasPassed: Bool // endDate is today or earlier

// TimelineFormatting.dateLine: "Fri 18 · ends 05/27", or "Fri 18 · ended 08/26" when
// `entry.endHasPassed`. The accessibility label says "ended" the same way.
```
`TimelineBuilder` sets `endDate` from `expense.seriesEndDate` (start of day) instead of the rule's
own end. `TimelineView.rebuildSections` calls `Expense.timelineExpenses(expenses)`. Keep
`var timelineExpense` only if something else uses it; otherwise delete it.

**Done when:** new and edited tests pass:
- `ModelLayerTests`: `seriesIDDefaultsToNil`, `seriesKeyFallsBackToID`, `seriesIDRoundTrips`,
  `timelineExpensesCarryTheSeriesEnd` (two records, one series: the earlier ended, the later
  open → both carry nil), `aSeriesEndingLaterCarriesTheLaterEnd`, `separateSeriesKeepTheirOwnEnds`.
- `TimelineBuilderTests`: `anEntryCarriesItsExpenseIDAndScheduledDate`,
  `aMovedEntryCarriesItsScheduledDateNotItsNewOne`, `anEndOnTodayHasPassed`,
  `anEndBeforeTodayHasPassed`, `anEndAfterTodayHasNot`. The existing `anEntryCarriesItsRulesEnd` and
  `anEntryWithNoEndCarriesNone` are edited to read `seriesEndDate` and renamed
  `anEntryCarriesItsSeriesEnd` / `anEntryWithNoSeriesEndCarriesNone`; this step exists to change
  what they assert. The `expense(...)` helper gains `seriesEndDate: Date? = nil`.
- `TimelineFormattingTests`: `aPassedEndReadsEnded`, `aPassedEndIsSpokenAsEnded`; existing tests
  that build a `TimelineEntry` gain the new fields and keep what they assert.

**Verify:** `xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test`

**Out of scope:** editing, row taps, anything in `Core/`.

### Step 2 — The draft knows it's editing

Depends on nothing; pure logic in `ExpenseDraft`.

**Files:** `Tilly/Editor/ExpenseDraft.swift` (modified), `TillyTests/ExpenseDraftTests.swift` (modified)

**Interface:**
```swift
/// The draft as it was when an existing charge opened, and where that charge sits in its bill.
struct EditBaseline: Equatable, Sendable {
    let digits: String
    let name: String
    let date: Date                 // the charge's effective date, start of day
    let interval: Int
    let unit: RecurrenceUnit
    let paymentCount: Int?         // the whole bill's; nil = no end
    let categoryID: UUID?
    let ruleAnchor: Date           // anchor of the record this charge belongs to
    let paymentsBeforeRule: Int    // charges generated by the series' earlier records
    let chargeIndex: Int           // this charge's index within its record, 0-based
}

struct DraftChanges: Equatable, Sendable {
    var amount = false, date = false, name = false, category = false, repeatRule = false, paymentCount = false
    var any: Bool { get }
}

enum SaveIntent: Equatable, Sendable {
    case nothing, askScope, thisCharge, futureCharges, wholeBill
}

// ExpenseDraft gains:
var baseline: EditBaseline? = nil
init(editing baseline: EditBaseline)          // copies every field from the baseline
static func digits(for amount: Decimal) -> String // 950 → "950", 74.1 → "74.1", 12.50 → "12.5"
var isZero: Bool { get }                      // non-empty and parses to 0
var changes: DraftChanges { get }             // all false when not editing; name compared trimmed
var minimumPaymentCount: Int { get }          // 2, or max(2, paymentsBeforeRule + chargeIndex + 1)
func saveIntent(hasLaterCharge: Bool) -> SaveIntent
```
`isValid(categoryExists:)` accepts a zero amount when editing, unless the repeat also changed (a
whole rule at €0), and never when adding.
`saveIntent`, in order: no change → `.nothing`; repeat changed → `.futureCharges`; zero and amount
changed → `.thisCharge`; amount or date changed → `hasLaterCharge ? .askScope : .thisCharge`;
otherwise `.wholeBill`.
`lastPaymentDate(calendar:)` when editing: if interval, unit and date are unchanged, payment
`paymentCount − paymentsBeforeRule − 1` of the rule anchored at `ruleAnchor`; otherwise payment
`paymentCount − paymentsBeforeRule − chargeIndex − 1` of the rule anchored at `date`. So
`repeatLabel` and `lastPaymentCaption` follow unchanged.

**Done when:** these tests pass, and every existing `ExpenseDraftTests` test still does:
`digitsForWholeAmount`, `digitsForOneDecimal`, `digitsDropATrailingZero`,
`editingCopiesTheBaseline`, `anUntouchedEditHasNoChanges`, `retypingTheSameAmountIsNoChange`,
`aTrailingSpaceInTheNameIsNoChange`, `zeroIsValidWhenEditing`, `zeroIsInvalidWhenAdding`,
`intentIsNothingWithoutAChange`, `aRepeatChangeIsFutureWithoutAsking`,
`zeroWithARepeatChangeIsInvalid`, `zeroSavesForThisChargeWithoutAsking`, `anAmountChangeAsksWhenAChargeFollows`,
`anAmountChangeOnTheLastChargeIsThisCharge`, `aDateChangeAsks`, `aNameChangeIsTheWholeBill`,
`aCountChangeIsTheWholeBill`, `theMinimumCountIncludesTheOpenCharge`,
`theMinimumCountIsNeverBelowTwo`,
`lastPaymentCountsTheWholeBill` (one record anchored Jun 18, count 12, 0 before the rule, opened
on its fourth charge, Sep 18, chargeIndex 3 → May 18 next year),
`lastPaymentCountsEarlierRecords` (count 12, 4 before the rule, this record anchored Jun 18 →
it makes the remaining 8, so Jan 18 next year),
`lastPaymentFromAMonthEndAnchorDoesNotDrift` (anchor Jan 31, opened on Feb 28, count unchanged →
last payment on the 31st of its month),
`lastPaymentAfterARepeatChangeCountsFromTheCharge` (one record anchored Jun 18 2026, count 12, opened
on Sep 18, chargeIndex 3, unit changed to weekly → 9 payments from Sep 18, so the 9th weekly
date from Sep 18 2026: Nov 13 2026).

**Verify:** `xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test`

**Out of scope:** SwiftData, views. `RepeatWheel` reads `minimumPaymentCount` in step 5.

### Step 3 — Writing edits to the store

Depends on step 1 (`seriesID`) and step 2 (`ExpenseDraft`, `EditBaseline`).

**Files:** `Tilly/Models/BillEditor.swift` (new), `TillyTests/BillEditorTests.swift` (new)

**Interface:**
```swift
/// Every write phase 2 makes, on a context, so the rules are tested against an in-memory store.
@MainActor
enum BillEditor {
    /// The records sharing `expense.seriesKey`, ascending by anchor.
    static func series(of expense: Expense, in context: ModelContext) throws -> [Expense]
    /// How many charges a record generates; nil when it runs on.
    static func paymentCount(of expense: Expense, calendar: Calendar) -> Int?
    static func hasLaterCharge(than scheduledDate: Date, in series: [Expense], calendar: Calendar) -> Bool
    static func isFirstCharge(_ scheduledDate: Date, of expense: Expense, in series: [Expense], calendar: Calendar) -> Bool

    static func saveThisCharge(_ draft: ExpenseDraft, expense: Expense, scheduledDate: Date,
                               category: ExpenseCategory, context: ModelContext, calendar: Calendar) throws
    static func saveFutureCharges(_ draft: ExpenseDraft, expense: Expense, scheduledDate: Date,
                                  category: ExpenseCategory, context: ModelContext, calendar: Calendar) throws
    static func saveWholeBill(_ draft: ExpenseDraft, expense: Expense,
                              category: ExpenseCategory, context: ModelContext, calendar: Calendar) throws
    static func deleteFutureCharges(from scheduledDate: Date, of expense: Expense,
                                    context: ModelContext, calendar: Calendar) throws
    static func deleteAllCharges(of expense: Expense, context: ModelContext) throws
}
```
Behaviour, each ending in `context.save()`:
- Every save applies the draft's trimmed name and category to every record in the series, then
  the whole-bill payment count (below).
- **This charge:** find or create the `OverrideRecord` keyed on `scheduledDate` (start of day).
  `actualAmount` = the draft amount, or nil when it equals the record's amount; `movedDate` = the
  draft date, or nil when it equals `scheduledDate`; `isSkipped` = false. Delete the override when
  all three are empty.
- **Future charges:** if the charge is its record's first (`chargeIndex` 0), edit that record in
  place: amount, interval, unit, `anchorDate` = draft date. Otherwise end the record at payment
  `chargeIndex − 1` (`RecurrenceEngine.date(ofPayment:for:calendar:)`), insert a new `Expense`
  anchored on the draft date with the draft's amount, interval, unit and category, and give both
  `seriesID = old.seriesKey`. In both cases: delete records in the series anchored after the open
  one; for each override scheduled after the open charge, on the open record or a deleted later
  one, keep it on (or reassign it to) the record now carrying the new rule if that rule generates
  its `scheduledDate`, else delete it; delete the open charge's own override. Never write
  `isSkipped`; nothing in v1 skips.
- **Whole-bill payment count:** nil → the last record's `endDate` = nil. A count N → walk the
  series in order, counting each ended record's charges; in the record where charge N falls, set
  `endDate` to that charge's date and delete every record after it. If N runs past the last record,
  extend its `endDate` to the charge N falls on.
- **Delete future charges:** if the charge is its record's first, delete that record and every
  later one; otherwise end the record at payment `chargeIndex − 1`, delete later records, and
  delete its overrides scheduled on or after `scheduledDate`.
- **Delete all charges:** delete every record in the series. Overrides cascade.

**Done when:** `BillEditorTests` passes with these cases, each against an in-memory
`TillyStore.container(inMemory: true)` and a pinned UTC Gregorian calendar, using a month-end
anchor (the 31st) wherever dates are generated:
`thisChargeWritesAnAmountOverride`, `thisChargeBackToTheRuleAmountRemovesTheOverride`,
`thisChargeWritesAMove`, `editingAMovedChargeReusesItsOverride`, `zeroIsStoredAsAnAmount`,
`futureFromTheFirstChargeEditsInPlace`,
`futureFromALaterChargeSplitsTheBill`, `futureLeavesEveryPastChargeAsItWas` (engine query over
the months before the split returns the old amounts), `futureSharesTheSeriesID`,
`futureFromAnAlreadySplitBillReplacesTheLaterRecord`, `aLaterFreeMonthSurvivesAPriceChange`,
`aLaterFreeMonthIsDroppedWhenItsDayNoLongerExists`, `futureDropsTheOpenChargesOwnOverride`,
`aRenameReachesEveryRecord`,
`aCategoryReachesEveryRecord`, `aCountEndingInAnEarlierRecordDeletesTheLaterOnes`,
`noEndReopensTheLastRecord`, `aLongerCountExtendsTheLastRecord`,
`deleteFutureFromALaterChargeKeepsThePast`, `deleteFutureFromARecordsFirstChargeRemovesIt`,
`deleteFutureRemovesOverridesFromThatChargeOn`, `deleteAllRemovesTheWholeSeries`,
`deleteAllLeavesOtherBillsAlone`, `hasLaterChargeIsFalseOnTheLastPayment`,
`hasLaterChargeIsTrueWhenTheBillRunsOn`, `theFirstChargeOfALaterRecordIsNotTheBillsFirst`.

**Verify:** `xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test`

**Out of scope:** views, `Core/`. If a case seems to need an engine change, stop: the decision
says it doesn't.

### Step 4 — Opening a charge

Depends on steps 1–3.

**Files:** `Tilly/Editor/EditSession.swift` (new), `TillyTests/EditSessionTests.swift` (new)

**Interface:**
```swift
/// Everything the editor needs to edit one charge, built from the timeline's entry.
struct EditSession: Identifiable, Equatable {
    let expenseID: UUID
    let scheduledDate: Date
    let draft: ExpenseDraft           // baseline set
    let hasLaterCharge: Bool
    let isFirstCharge: Bool
    let previousChargeDate: Date?     // for "keeps Aug 28 and earlier"; nil on the first charge
    var id: String { get }            // expenseID + scheduled seconds, as Occurrence.id

    @MainActor
    static func make(expenseID: UUID, scheduledDate: Date, context: ModelContext,
                     calendar: Calendar) throws -> EditSession?
}
```
`make` builds the baseline: digits from the override's amount, else the record's (`"0"` when the
override is a skip, which only older data could hold); date = the override's `movedDate` or `scheduledDate`; whole-bill
`paymentCount` = sum of the series' counts when its last record has an end, else nil;
`chargeIndex` = the number of the record's dates from its anchor to `scheduledDate`, minus one.

**Done when:** `EditSessionTests`: `aPlainChargeOpensWithTheRuleAmount`,
`anOverriddenChargeOpensWithItsAmount`, `aFreeChargeOpensAtZero`,
`aMovedChargeOpensOnItsNewDate`, `theCountIsTheWholeBills`, `aBillWithNoEndHasNoCount`,
`theChargeIndexCountsFromTheRecordsAnchor`, `paymentsBeforeRuleCountsEarlierRecords`,
`thePreviousChargeOfARecordsFirstIsTheEarlierRecordsLast`, `anUnknownExpenseGivesNil`.

**Verify:** `xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test`

**Out of scope:** presenting it.

### Step 5 — The editor in edit mode

Depends on steps 2–4.

**Files:** `Tilly/Editor/ExpenseEditor.swift`, `Tilly/Editor/RepeatWheel.swift`,
`Tilly/DesignSystem/Tokens.swift` (all modified)

**Interface:**
```swift
// ExpenseEditor
init(today: Date, draft: ExpenseDraft? = nil, panel: EditorPanel = .keypad, session: EditSession? = nil)
// Tokens
enum Ink { static let destructive: Color /* aliases .red */ }
```
With a session: the draft is `session.draft`; ✓ is disabled unless `isValid && draft.changes.any`
and no category is half made. A trash `ToolbarItem(placement: .topBarTrailing)` sits before ✓,
`Image(systemName: "trash")` tinted `Tokens.Ink.destructive`, separated from ✓ by a
`ToolbarSpacer(.fixed)` so the two read as separate circles, as drawn.
✓ calls `draft.saveIntent(hasLaterCharge:)` and routes: `.askScope` presents a
`confirmationDialog` attached to the ✓ button with `Save for this charge only` /
`Save for future charges`; the others call the matching `BillEditor` function directly. Trash
presents a `confirmationDialog` attached to the trash button: on the first charge, title
`Delete <name>?`, message `Every charge goes, past ones too.`, one destructive button
`Delete <name>`; otherwise title `<name> repeats every month.` (`every 3 months`, `every week`…),
message `Deleting future charges keeps <Aug 28> and earlier.` from `previousChargeDate`, and
destructive buttons `Delete All Future Charges`, `Delete All Charges`. Every path dismisses after
a successful save and logs a failure, as `save()` does now.
`RepeatWheel`'s counts run `draft.minimumPaymentCount...120`.

**Done when:** it builds; both suites stay green; previews "Editing a charge", "Editing, scope
question" and "Editing, dark, accessibility size" render. Screenshot in the Simulator (reached
from step 6's row tap once it exists, otherwise from the previews), light and dark, at an
accessibility size, per CLAUDE.md. If iOS 26 draws either dialog as a bottom sheet rather than
out of its button, that's acceptable: say so in Lessons.

**Verify:** both commands in CLAUDE.md's Verification section.

**Out of scope:** rows, the timeline.

### Step 6 — Rows open their charge

Depends on steps 1, 4 and 5.

**Files:** `Tilly/Timeline/MonthSectionView.swift`, `Tilly/Timeline/TimelineView.swift`,
`Tilly/Timeline/OccurrenceRow.swift`, `Tilly/Editor/ExpenseEditor.swift` (all modified)

**Interface:**
```swift
// MonthSectionView
let onOpen: (TimelineEntry) -> Void
// TimelineView
@State private var editing: EditSession?
```
Each row is a `Button` with `.buttonStyle(.plain)` and a full-row `contentShape`, calling
`onOpen`. `TimelineView` builds `EditSession.make(...)` from the entry's `expenseID` and
`scheduledDate` and presents `.sheet(item: $editing) { ExpenseEditor(today: today, session: $0) }`.
VoiceOver keeps the row's combined label and adds the hint "Edits this charge".

Also fix in `ExpenseEditor.swift`: the trash dialog's title, message and `Delete <name>` button
describe the bill as saved, so read name, interval and unit from `draft.baseline`, not the
draft. Otherwise renaming a bill to "Gym2" and then tapping trash asks to delete "Gym2", as the
prototype's `askDelete` doesn't.

**Done when:** in the Simulator: tap a charged row, an upcoming row, a €0 row, a moved row;
each opens with its own amount and date. Change an amount and save for this charge only; the row
changes and nothing else does. Save for future charges on a charge mid-series; earlier rows keep
their amounts. Type 0 on an upcoming charge; it saves without asking, reads `€0`, and its old amount drops out of the header total.
Delete all future charges on a bill; its earlier rows read "ended MM/YY" once that date is past. Screenshots light, dark
and at an accessibility size. Both suites green.

**Verify:** both commands in CLAUDE.md's Verification section, then the Simulator walk above.

**Out of scope:** where the list sits after the change; step 7 owns that.

### Step 7 — The list stays put when bills change (Opus)

Depends on step 6.

**Files:** `Tilly/Timeline/TimelineView.swift` (modified)

**Interface:** none public. `onChange(of: expenses)` recomputes floor and ceiling; when the
`TimelineWindow` changes it replaces it and anchors on the month under the middle of the viewport,
as `handleDayChange` does. With no expenses left, `window` becomes nil and the empty state shows.
`onChange(of: expenses)` misses edits that only change fields, such as delete-future ending a
record (Lessons, step 6), so the edit sheet's `onDismiss` runs the same recompute.

**Done when:** measured in the Simulator (method in `.claude/rules/swiftui-scrolling.md`), the
month header in view holds its position within 1pt in each of: deleting all future charges on the
only bill that runs on, so the ceiling collapses to the last payment; adding a bill backdated
before the floor; deleting all charges of a bill whose charges are the oldest, so the floor rises;
saving an amount on a row in a month above the one in view. Deleting the last bill shows the
empty state, and adding one after that lands on the current month. Both suites green.

**Verify:** both commands in CLAUDE.md's Verification section, then the measurements above,
with their numbers written into Lessons.

**Out of scope:** scrolling to an edited charge (decided against), place-saving changes.

### Step 8 — Shake to undo

Depends on step 3; independent of 7.

**Files:** `Tilly/TillyApp.swift`, `Tilly/Developer/DeveloperSession.swift` if it builds the debug
container, `Tilly/Models/BillEditor.swift`, `TillyTests/BillEditorTests.swift` (all modified)

**Interface:** both `.modelContainer(...)` calls in `TillyApp` pass `isUndoEnabled: true`, which
hands the main context the window's `UndoManager`, so the system's shake gesture reaches it. Each
`BillEditor` save and delete names its undo action, `context.undoManager?.setActionName("Save")`
or `("Delete")`, so the system offers "Undo Delete".

**Done when:** `BillEditorTests` gains, each with a context whose `undoManager` is a fresh
`UndoManager`: `undoingADeleteBringsTheWholeSeriesBack`, `undoingAFutureSaveRejoinsTheBill`
(one record again, its old end and overrides restored), `undoingAThisChargeSaveRestoresTheAmount`,
`oneSaveIsOneUndo`. In the Simulator (Device → Shake), deleting a bill then shaking offers
"Undo Delete" and brings its rows back. Adding an expense becomes undoable too, as a side effect;
that's fine.

**Verify:** both commands in CLAUDE.md's Verification section, then the shake above.

**Out of scope:** an undo button or toast; the keypad's own typing. If one save needs manual
`beginUndoGrouping` to be one undo, do it inside `BillEditor` and say so in Lessons. If shaking
shows nothing on the timeline, stop and report rather than building an undo control.

## Lessons

- Step 5: both the scope `confirmationDialog` (attached to ✓) and the delete `confirmationDialog`
  (attached to trash) draw as a menu off their button on iOS 26, not as a bottom sheet. Confirmed
  on device.
- Step 6: saving an edit (an `OverrideRecord` insert, or a field change on an existing `Expense`)
  left the row showing its old value until the app relaunched. `@Query`'s array compares by model
  identity, not by the fields within it, and a relationship-only write doesn't reliably trigger
  its own change notification either — so `.onChange(of: expenses)` never fired. Fixed by giving
  the edit sheet its own `onDismiss: rebuildSections`, unconditional on what `@Query` noticed.
- Step 6: a `.plain` button hit-tests its label's shape, so `.contentShape(Rectangle())` goes on
  the label. Put on the `Button` it did nothing: the gap between a row's name and amount was
  dead, and a tap there looked like a broken automation tool. `.onTapGesture` honours an outer
  `contentShape`, which is why swapping to it "fixed" the row.

## If a step is wrong

These specs were written before the code existed. If a step turns out to be
ambiguous, impossible, or wrong, **stop and say so** — don't improvise a fix and
don't silently widen the scope. A wrong spec caught in one message costs far less
than a wrong spec followed to completion.
