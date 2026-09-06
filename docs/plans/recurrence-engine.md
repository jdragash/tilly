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
- Every-3-months anchored 30 Nov yields 28/29 Feb, then **30 May** — anchor day restored
  since May has 31 days ≥ 30. (**Build note, 2026-09-06:** this bullet originally read "31
  May", which doesn't follow from a 30 Nov anchor — 31 only appears if the anchor day were
  31, and November has no 31st. Corrected to 30 May during `tilly-build`. **Confirmed on
  review, 2026-09-06:** correct, and it keeps the case discriminating — an accumulating
  engine would return 28 May here, so the corrected expectation still catches the bug the
  bullet exists to catch.)
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

**Superseded in part by Step 6:** this step left unsaid whether `range` filters on
`scheduledDate` or `effectiveDate`. Step 6 settles it as `effectiveDate`.

---

### Step 6 — The occurrence window means effective dates

**Decision:** "The occurrence window means effective dates" in `docs/DECISIONS.md`,
2026-09-06. Read it first; this step implements it and nothing more.

**Why this step exists:** review of the Steps 1–5 implementation found `occurrences()`
windowing on `scheduledDate` while sorting on `effectiveDate`, so the range means one thing
and the order another. Demonstrated: a bill anchored 31 Jan 2027 with an override moving it
to 2 Feb returns only the 28 Feb occurrence for a February window, and returns an occurrence
dated 2 Feb for a January one. Step 5 wasn't implemented wrongly — it never said what the
range filters on. This step settles it.

**Files:** `Core/Sources/TillyCore/RecurrenceEngine.swift` (modified),
`Core/Tests/TillyCoreTests/OccurrenceWindowTests.swift` (new),
`Core/Tests/TillyCoreTests/RecurrenceEngineDayWeekTests.swift` (one test added)

#### Part A — day-granular bounds in `dates(for:in:calendar:)`

Signature unchanged. Normalise all three bounds to start-of-day in `calendar` and compare
candidates against the normalised values:

- `rangeStart = calendar.startOfDay(for: range.start)`
- `rangeEnd = calendar.startOfDay(for: range.end)`
- `ruleEnd = rule.endDate.map { calendar.startOfDay(for: $0) }`

Both range bounds stay inclusive, and an occurrence falling on `ruleEnd` stays included.
Generated candidates are already start-of-day, so this changes behaviour only for a caller
passing a bound with a time-of-day — today such a caller silently loses that day. Update the
doc comment to say the range selects *scheduled* dates, at day granularity, both ends
inclusive.

#### Part B — effective-date windowing in `occurrences(for:overrides:in:calendar:)`

Signature unchanged. Order the body as:

1. `guard !expense.isArchived else { return [] }`.
2. `windowStart` / `windowEnd` — start-of-day of `range.start` / `range.end`.
3. Build `overridesByDate` keyed on `calendar.startOfDay(for: $0.scheduledDate)`, as now.
   Look the key up with `calendar.startOfDay(for: scheduledDate)` as well; the current
   lookup passes the raw generated date, which happens to work but isn't symmetric.
4. `scheduledDates` — `dates(for: expense.rule, in: range, calendar: calendar)`, as a `Set`.
5. **Pull-ins.** For each override with a non-nil `movedDate` whose start-of-day falls in
   `windowStart...windowEnd`, and whose start-of-day `scheduledDate` is not already in
   `scheduledDates`: admit that `scheduledDate` only if the rule genuinely produces it —
   test `dates(for: expense.rule, in: DateInterval(start: sod, end: sod), calendar: calendar)`
   for non-emptiness. This is exact rather than padded, and rejects strays, pre-anchor dates
   and post-`endDate` dates for free.
6. Map every date in the set to an `Occurrence`, applying its override exactly as now.
7. **Filter.** Keep only occurrences whose `calendar.startOfDay(for: effectiveDate)` falls in
   `windowStart...windowEnd`. Skipped occurrences are kept — Step 5's rule that they appear
   flagged is unchanged.
8. Sort by `effectiveDate`, tie-breaking on `scheduledDate` so ties have a defined order.

**Done when:**

- `movedIntoWindowAppears` — monthly anchored 31 Jan 2027, override moving 31 Jan to 2 Feb;
  a 1–28 Feb window returns it, with `scheduledDate` 31 Jan and `effectiveDate` 2 Feb.
- `movedOutOfWindowDisappears` — same expense and override; a 1–31 Jan window does **not**
  return it.
- `movedOccurrenceAppearsInExactlyOneOfTwoAdjacentWindows` — January and February queried
  separately return it once in total, and their concatenation equals one 1 Jan–28 Feb query.
- `strayOverrideWithMovedDateInWindowIsNotConjured` — an override whose `scheduledDate` is
  not an occurrence of the rule (15 Jan, for a 31st-anchored monthly rule) but whose
  `movedDate` is inside the window adds nothing to the result.
- `overrideBeforeAnchorIsNotPulledIn` and `overrideAfterEndDateIsNotPulledIn` — the same, for
  a `scheduledDate` earlier than `anchorDate` and one later than `rule.endDate`.
- `moveWithinWindowChangesDateNotMembership` — moving 2 Feb to 20 Feb inside a February
  window returns the same occurrence count as the same expense with no override.
- `nonMidnightRangeStartStillIncludesThatDay`, in the day/week suite — daily rule anchored
  1 Jan 2027, range 5 Jan 14:00 → 8 Jan, returns the 5th, 6th, 7th and 8th.
- The existing 40 tests pass, Part A being identity for all of them since they pass midnight
  bounds. (**Build note, 2026-09-06:** this bullet originally demanded they pass *unchanged*
  and treated any edit as a signal to stop. Too strong, and wrong here: two of them —
  `movedDateChangesEffectiveDateButNotScheduledDate` and `movedOccurrenceSortsByEffectiveDate`
  — move an occurrence to a date outside their own query window, which is precisely the
  semantics this step replaces, so Step 6 correctly drops it. Their intent survives intact;
  only the move targets were brought inside the window. An existing test that asserts the
  behaviour a step exists to change is the one legitimate reason to edit one, and the bar is
  that its intent must survive the edit unchanged.)

**Verify:** `cd Core && swift test`. Report the actual test count and output.

**Out of scope:** the caller-side obligation to pass every override that could bear on the
window, including ones scheduled outside it. That's app-layer work, recorded as a consequence
in the decision and picked up when the timeline is built. Also out of scope: whether the
timeline draws a trace at a moved occurrence's original slot — a `DESIGN.md` question, not an
engine one.

### Step 7 — Review fixes: the clamp invariant, and the coverage the earlier steps missed

**From:** the 2026-09-06 review of Steps 1–5. No decisions are open here; each item is a
correction with one right answer.

**Files:** `Core/Sources/TillyCore/RecurrenceRule.swift` (modified),
`Core/Sources/TillyCore/RecurrenceEngine.swift` (modified),
`Core/Sources/TillyCore/Occurrence.swift` (comment only),
`Core/Tests/TillyCoreTests/RecurrenceRuleTests.swift` (modified),
`Core/Tests/TillyCoreTests/RecurrenceEngineMonthYearTests.swift` (modified),
`Core/Tests/TillyCoreTests/OccurrenceTests.swift` (modified)

#### A — the interval clamp must survive decoding

`interval` clamps to a minimum of 1 in `init`, but synthesized `Decodable` writes stored
properties directly and never runs it. A persisted or migrated rule can therefore arrive with
`interval` 0 or negative, and the engine then either traps converting an infinite `Double` to
`Int`, or loops forever appending the anchor. Nothing decodes a rule yet; the type is
`Codable` precisely because persistence will.

Give `RecurrenceRule` an explicit `CodingKeys` and a hand-written `init(from:)` that delegates
to the memberwise `init`, so one clamp covers both paths. Then clamp defensively in the engine
as well — `max(1, rule.interval)` where the step is computed — because a hang is a bad way to
find out about a third path. Replace the `ceil` in the start-index calculation with integer
ceiling division, which removes the `Int(Double.infinity)` trap outright.

#### B — `Occurrence.id` stays seconds-since-epoch

Flagged in review as a possible breach of the Calendar-only rule, then cleared: that rule is
about date *arithmetic*, and an identity built from an absolute instant is timezone-free and
stable, where a formatted date string would need a timezone and be more fragile, not less.
Leave the code as it is and add a one-line comment saying so, so the next reader doesn't
re-open it.

#### C — coverage the earlier steps left open

- `windowedMonthQueryPreservesAnchorClamping` — a March–June window on a 31 Jan anchor returns
  31 Mar, 30 Apr, 31 May, 30 Jun. The existing windowing tests use the 15th, which is
  clamp-immune, so an engine that reseeded from `range.start` instead of the anchor would pass
  the whole suite today. This is the missing discriminator.
- `monthlyAcrossDSTInLondonStaysAtStartOfDay` — month generation spanning both London
  transitions returns dates at hour 0. Only day and week units have DST cover today.
- `decodedIntervalOfZeroClampsToOne` and `decodedNegativeIntervalClampsToOne` — the A fix,
  through `JSONDecoder`.
- `decodedZeroIntervalRuleGeneratesDailyThroughTheEngine` — a rule decoded from
  `{"interval":0,…}` driven through `dates()`, which used to trap or hang. Note this exercises
  the decode fix end to end; the engine's own `max(1,)` is defence in depth against a third
  path and, with both other clamps in place, isn't independently reachable from a test.
- `multipleOverridesOnOneExpenseEachApply` — several overrides on one expense, each landing on
  its own occurrence.

**Done when:** all of the above pass, and the tests carried over from Steps 1–5 pass unchanged.

**Verify:** `cd Core && swift test`. Report the actual test count and output.

**Out of scope:** anything in the app target. This is still a `Core/`-only plan.

---

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
