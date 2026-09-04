# Recurrence engine — implementation plan

**Decisions:** "Occurrences are computed, never stored"; "Recurrence is every N units from a
fixed anchor"; "Core is a Swift package, not a folder in the app target" — all in
`docs/DECISIONS.md`.

Phase 1 of `docs/ROADMAP.md`. Everything here lives in the `Core/` package. No Xcode project
is needed; no UI or persistence work happens in this plan.

## Already decided — do not reopen

- **Generation is anchored, never incremental.** Every occurrence is derived from
  `rule.anchorDate`, never by adding an interval to the previously generated date. This is
  the whole reason the engine exists as a separate thing — see the Dime drift bug in
  `docs/DECISIONS.md`.
- **Month-end clamps without sticking.** A rule anchored on the 31st yields Feb 28 and then
  Mar 31. Clamping applies per-occurrence and never becomes permanent.
- **`TillyCore` imports neither SwiftData nor SwiftUI.** The package doesn't link them.
- **`Calendar` is injected, never `Calendar.current`.** Every public function takes one.
  Tests pin both calendar and timezone.
- **Core defines its own plain value types.** SwiftData `@Model` types live in the app and
  are mapped into `ExpenseSnapshot` / `OccurrenceOverride` at the boundary. Core never sees
  a persistence type.
- **Dates are start-of-day** in the injected calendar. Time-of-day is not modelled.

## Steps

### Step 1 — RecurrenceRule

**Files:** `Core/Sources/TillyCore/RecurrenceRule.swift` (new),
`Core/Tests/TillyCoreTests/RecurrenceRuleTests.swift` (new)

**Interface:**
```swift
public struct RecurrenceRule: Equatable, Sendable, Codable {
    public let interval: Int
    public let unit: RecurrenceUnit
    public let anchorDate: Date
    public let endDate: Date?

    public init(interval: Int, unit: RecurrenceUnit, anchorDate: Date, endDate: Date? = nil)
}
```

`interval` clamps to a minimum of 1 in `init` — a zero or negative interval would loop
forever, and silently correcting it is preferable to throwing at every call site.

**Done when:**
- `interval` of 0 and of -3 both store as 1
- `interval` of 1 and of 5 store unchanged
- Two rules with identical fields are `==`
- Round-trips through `Codable` unchanged

**Verify:** `cd Core && swift test`

**Out of scope:** any date generation.

---

### Step 2 — Date generation for day and week

**Files:** `Core/Sources/TillyCore/RecurrenceEngine.swift` (new),
`Core/Tests/TillyCoreTests/RecurrenceEngineDayWeekTests.swift` (new)

**Interface:**
```swift
public enum RecurrenceEngine {
    /// Occurrence dates for `rule` falling within `range`, ascending.
    /// Both bounds of `range` are inclusive. All dates are start-of-day in `calendar`.
    public static func dates(
        for rule: RecurrenceRule,
        in range: DateInterval,
        calendar: Calendar
    ) -> [Date]
}
```

Handle `.day` and `.week` only. Return `[]` for `.month` and `.year` for now — Step 3
replaces that.

Compute the occurrence index from the anchor and generate from the anchor by
`index * interval` units. Do not accumulate onto the previous result.

**Done when:**
- Daily from an anchor over a 10-day range returns 10 ascending dates
- Every-3-days returns only the 1st, 4th, 7th… from the anchor
- Weekly and every-2-weeks land on the same weekday as the anchor
- A range starting mid-series excludes earlier occurrences and includes the first one at or
  after `range.start`
- An occurrence falling exactly on `range.start` is included; likewise `range.end`
- A range entirely before the anchor returns `[]`
- **DST:** a daily rule spanning a spring-forward and an autumn-back transition in
  `Europe/London` returns one occurrence per day, each at start-of-day. Adding 86,400
  seconds fails this; `Calendar` components pass it.
- **Performance:** a daily rule over 366 days completes in well under a second

**Verify:** `cd Core && swift test`

**Out of scope:** month and year units, `endDate`, overrides.

---

### Step 3 — Month and year, with anchored clamping

**Files:** `Core/Sources/TillyCore/RecurrenceEngine.swift` (modified),
`Core/Tests/TillyCoreTests/RecurrenceEngineMonthYearTests.swift` (new)

Extend `dates(for:in:calendar:)` to handle `.month` and `.year`.

For each occurrence index, take the anchor's day-of-month, add `index * interval` months (or
years) to the anchor's month, and clamp the day to that target month's last valid day. The
clamp must be recomputed from the anchor every time — never carried forward.

**Done when — the critical cases:**
- Monthly anchored **31 Jan 2027** yields **28 Feb**, then **31 Mar**, then **30 Apr**, then
  **31 May**. If March returns the 28th, generation is accumulating rather than anchoring;
  this is the exact Dime bug and this test is the reason the engine exists.
- Monthly anchored **31 Jan 2028** (leap year) yields **29 Feb**, then **31 Mar**
- Monthly anchored on the 15th is unaffected by clamping across a full year
- Every-3-months anchored 30 Nov yields 28/29 Feb, then 31 May… anchor day restored whenever
  the month allows
- Yearly anchored **29 Feb 2028** yields **28 Feb** in 2029, 2030, 2031, and **29 Feb** again
  in 2032
- Yearly anchored 3 Mar returns 3 Mar every year
- Range windowing behaves as in Step 2 for both units

**Verify:** `cd Core && swift test`

**Out of scope:** `endDate`, overrides.

---

### Step 4 — End dates and archived rules

**Files:** `Core/Sources/TillyCore/RecurrenceEngine.swift` (modified),
`Core/Tests/TillyCoreTests/RecurrenceEngineBoundsTests.swift` (new)

**Done when:**
- No occurrence after `rule.endDate` is returned, for every unit
- An occurrence falling exactly on `endDate` **is** included
- `endDate` earlier than `anchorDate` returns `[]`
- `endDate` of `nil` is unbounded, limited only by `range`

**Verify:** `cd Core && swift test`

**Out of scope:** archived expenses — that's a property of the expense, handled in Step 5,
not of the rule.

---

### Step 5 — Occurrences with overrides applied

**Files:** `Core/Sources/TillyCore/Occurrence.swift` (new),
`Core/Sources/TillyCore/ExpenseSnapshot.swift` (new),
`Core/Sources/TillyCore/OccurrenceOverride.swift` (new),
`Core/Sources/TillyCore/RecurrenceEngine.swift` (modified),
`Core/Tests/TillyCoreTests/OccurrenceTests.swift` (new)

**Interface:**
```swift
public struct OccurrenceOverride: Equatable, Sendable {
    public let scheduledDate: Date      // identity: which occurrence this overrides
    public let actualAmount: Decimal?
    public let movedDate: Date?
    public let isSkipped: Bool
}

public struct ExpenseSnapshot: Equatable, Sendable, Identifiable {
    public let id: UUID
    public let amount: Decimal?         // nil when genuinely unknown
    public let isEstimate: Bool
    public let rule: RecurrenceRule
    public let isArchived: Bool
}

public struct Occurrence: Equatable, Sendable, Identifiable {
    public let expenseID: UUID
    public let scheduledDate: Date      // what the rule generated
    public let effectiveDate: Date      // scheduledDate, or movedDate when overridden
    public let amount: Decimal?
    public let isEstimate: Bool
    public let isSkipped: Bool
    public var id: String { get }       // expenseID + scheduledDate
}

extension RecurrenceEngine {
    public static func occurrences(
        for expense: ExpenseSnapshot,
        overrides: [OccurrenceOverride],
        in range: DateInterval,
        calendar: Calendar
    ) -> [Occurrence]
}
```

Overrides match on `scheduledDate` (same start-of-day in `calendar`). Results sort by
`effectiveDate`.

**Done when:**
- An expense with no overrides produces one `Occurrence` per generated date, carrying the
  expense's `amount` and `isEstimate`
- An override with `actualAmount` replaces the amount **and** sets `isEstimate` to `false`
- An override with `isSkipped` still appears in the result, flagged — callers decide whether
  to exclude it, so totals and the timeline can differ
- An override with `movedDate` changes `effectiveDate` but leaves `scheduledDate` unchanged,
  so the override still matches on re-run
- A moved occurrence sorts by its `effectiveDate`
- An override whose `scheduledDate` matches nothing is ignored, not an error
- `isArchived == true` returns `[]` regardless of the rule
- An expense with `amount == nil` yields occurrences with `amount == nil`

**Verify:** `cd Core && swift test`

**Out of scope:** totals, grouping by date, and anything about how the timeline renders.

---

## Cleanup

Delete `Core/Tests/TillyCoreTests/ScaffoldTests.swift` once Step 1's tests exist. It only
proves the harness runs.

## If a step is wrong

These specs were written before the code existed. If a step turns out to be ambiguous,
impossible, or wrong, **stop and say so** — don't improvise a fix and don't silently widen
the scope. A wrong spec caught in one message costs far less than a wrong spec followed to
completion.

The same applies to anything not covered here. A gap is a signal to ask, not licence to
decide.
