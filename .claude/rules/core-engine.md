---
paths:
  - "Core/**"
  - "Tilly/Models/**"
  - "Tilly/Timeline/TimelineBuilder.swift"
---

# The recurrence engine and its callers

`TillyCore` is pure logic over `Calendar`. It must not import SwiftData (CLAUDE.md), and the
package boundary makes that a compile error.

## Generating dates

- **Generate from the anchor, never from the previous occurrence.** Month-end clamps without
  sticking: a rule anchored on the 31st gives 31 Jan, 28 Feb, 31 Mar. Walking forward from the
  last result is Dime's drift bug.
- **Add `Calendar` components, never `TimeInterval`.** 86,400 seconds is wrong twice a year.
- `Occurrence.id` uses seconds since epoch, and that's fine. It's identity, not date arithmetic.

## Windows and overrides

- `occurrences(for:overrides:in:calendar:)` windows on **effective** dates. A bill moved into
  the range arrives, and one moved out leaves. `dates(for:in:calendar:)` windows on scheduled
  dates, because a bare rule has nothing else.
- Range bounds compare at day granularity, **both ends inclusive**, and time of day is ignored.
- **Callers pass every override for the expense, unfiltered by date.** A date-filtered fetch
  drops exactly the override that moves a bill in from outside the window, and the month still
  looks plausible. `Expense.overrideSnapshots` exists for this.
- An override is admitted only if the rule actually generates its `scheduledDate`. Overrides
  key on the scheduled date, not the date on screen.
- Skipped occurrences come back **flagged, not removed.** Excluding them from totals is the
  caller's job.

## Robustness

- `RecurrenceRule`'s interval clamp (≥ 1) must survive decoding. Synthesised `Decodable`
  bypasses `init`, so `init(from:)` delegates to it, and the engine clamps again.
- Mapping `Expense` → `ExpenseSnapshot` is total. An unknown unit falls back to `.month`,
  because a bill with a defaulted unit is visible and a vanished one isn't.

## Tests

- Pin the calendar and timezone in every test. Swift Testing (`@Test`, `#expect`).
- Use a clamp-sensitive anchor (the 31st, not the 15th) wherever windowing is tested. An engine
  that reseeded from the range start passes every 15th-anchored test.
- Cover DST for every unit, not just days and weeks.
- A test may be edited only when the step exists to change what it asserts, and the step says
  so. Any other failing test is a stop.
