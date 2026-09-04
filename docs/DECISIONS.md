# Decisions

Dated log of what was decided, what was rejected, and why each rejected option lost. The
rejections matter as much as the choices — they're what stops the same debate recurring in
three months.

Format: one entry per decision. Newest at the top.

---

## Occurrences are computed, never stored

**Decided:** 2026-09-04 · **From:** project kickoff

**Chosen:** The timeline is a pure function — `occurrences(rules, overrides, dateRange) →
[Occurrence]`. Only deviations persist, as `OccurrenceOverride` records keyed on
`(expense, scheduledDate)`.

**Rejected — materialising rows** (Dime's approach: create a real row for each occurrence
as its date passes). Two costs, both visible in Dime's source:

*Drift.* `DataController.updateRecurringTransaction()` walks forward from the previous
occurrence, not a fixed anchor:

```swift
newDate = Calendar.current.date(byAdding: .month, value: coefficient, to: holdingDate)
```

A bill anchored on the 31st goes Jan 31 → Feb 28 → Mar 28 → Apr 28 and never recovers,
because the clamped result becomes the next input.

*Sync duplication.* `LogView` must call `updateRecurringTransactions()` on appear and on
CloudKit sync-success, guarded by an `updatedRecurring` flag and a debounce, because two
devices running the pass both write rows.

Computing from a fixed anchor removes both, and makes retroactive rule edits correct for
free. It also puts the app's hardest logic in a pure function with no UI and no database —
the best possible thing to test-drive.

---

## Past charges are assumed, not confirmed

**Decided:** 2026-09-04 · **From:** project kickoff

**Chosen:** When an occurrence's date passes, it is charged. Rendering distinguishes
upcoming from charged; no control marks anything as paid.

**Rejected — user confirms each occurrence.** Would make the past view a true record
rather than a projection, but turns a visibility tool into a chore app. Skipped
confirmations rot the data until it can't be trusted. Directly against tenet 1.

**Rejected — auto-assume but prompt on variable bills.** Kept the chore, just rarer.
Setting the real amount stays available; it is never demanded.

---

## Categories ship empty

**Decided:** 2026-09-04 · **From:** project kickoff

**Chosen:** No default categories, no starter set, no first-run suggestions. The app may
hint subtly; it never imposes.

**Rejected — ship a suggested starter set** (Dime's approach). A starter set is a guess
about someone's life. The competitor's fixed, uneditable list is the same mistake taken
further, and shows where it leads. Tenet 4.

**Consequence:** the empty state carries real weight — first run is doing the teaching.

---

## Recurrence is every N units from a fixed anchor

**Decided:** 2026-09-04 · **From:** project kickoff

**Chosen:** interval + unit (day/week/month/year) + anchor date. Month-end clamps to the
last valid day *without sticking* — always generated from the anchor's day-of-month.

**Rejected — weekday rules** ("every second Tuesday", "last Friday of the month"). Real for
some payroll-linked costs, but a meaningfully larger engine and UI for cases that aren't
currently needed.

**Rejected — full iCalendar RRULE.** Powerful, reusable, and almost entirely unused here.
Over-engineering for v1.

---

## Timeline runs future-above, past-below, resting on the last actual charge

**Decided:** 2026-09-04 · **From:** project kickoff

**Chosen:** Opening the app puts what's next at eye level, with the most recent real charge
as the resting anchor — so you see where you are and what's coming from there.

**Rejected — past above, future below** (bank-statement order). Conventional, but it puts
history at eye level in an app whose entire job is forward visibility.

**Rejected — today pinned mid-screen, scrolling both ways.** More novel and more to build,
and "today" is less meaningful than "the last thing that actually happened".

---

## Licence: GPL-3.0 with an App Store exception

**Decided:** 2026-09-04 · **From:** project kickoff

**Chosen:** GPL-3.0, plus an additional permission under section 7 for App Store
distribution. Makes "free forever" structural rather than a promise — nobody can take
Tilly closed-source or sell it.

**Context:** Dime's GPL-3.0 does not oblige this. Copyright covers code, not ideas, and
Tilly contains no Dime code. The choice is deliberate reciprocity.

**Rejected — MIT.** Maximum freedom for others, but permits someone to take Tilly
closed-source and sell it, which sits badly against tenet 5.

**Rejected — plain GPL-3.0, no exception.** GPL's terms conflict with Apple's distribution
restrictions; VLC was pulled from the App Store in 2011 over exactly this. As sole
copyright holder Jake can grant the needed permission, so he does, up front.

**Watch:** the exception is only effective if granted by *all* copyright holders. Accepting
outside contributions means re-granting it. Noted in `CLAUDE.md`.

---

## Stock SwiftUI in v1, behind a token layer from day one

**Decided:** 2026-09-04 · **From:** project kickoff

**Chosen:** V1 uses system components. `DesignSystem/Tokens.swift` exists immediately but
initially just aliases system values; views reference tokens, never raw values.

**Rejected — build a design system in v1.** Functionality first. Stock SwiftUI supplies
Liquid Glass, Dynamic Type, dark mode and VoiceOver correctly for free.

**Rejected — raw values now, extract tokens later.** The extraction is the expensive part.
Adding the seam up front costs an afternoon; retrofitting it means editing every view.

---

## Headline is calendar month in v1

**Decided:** 2026-09-04 · **From:** project kickoff

**Chosen:** "Remaining this month". Pay-period and custom timeframes go on the roadmap.

**Rejected — pay-period headline in v1.** Tracking from one payday to the next is a common
mental model, and it's the clearest differentiator from Dime. But it changes what the headline means and
shouldn't gate v1 shipping. Roadmapped for v1.1 rather than dropped.
