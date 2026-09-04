# Inspiration — what works, what doesn't, and why

Derived from a close reading of two apps: **Dime** (`rafsoh/dimeApp`), which Tilly is
modelled on, and a freemium competitor that gets several things wrong in instructive ways.

This doc exists to keep the tenets in `PROJECT.md` concrete. "Minimal for hierarchy's
sake" is an argument you can lose to a plausible-sounding counter-argument; a specific
screen that did it right, and a specific screen that didn't, is much harder to talk your
way past. `tilly-explore` and `design-principles` both read this before proposing
anything.

---

## Dime — what it gets right

### Upcoming is a visual state, not a task

Dime's log shows future recurring charges inline with past ones, greyed and
outline-iconed. Nothing is pending. Nothing needs confirming. You just *see* that things
are still coming.

This is the single most important thing Tilly takes from Dime, and it's the origin of
tenet 1. The alternative — a list of things to tick off — turns a visibility tool into a
chore app, and skipped ticks rot the data until you stop trusting it.

**Taken:** charges are assumed. Upcoming and charged are distinguished by rendering, never
by a control.

### Charged means charged

Past entries carry no affordance at all. The charge happened, it matches the card
statement, there is no work to do. The absence of interaction is the point.

**Taken:** a past occurrence is a fact, not a row awaiting input. Editing one is possible
but never suggested.

### Amounts round to whole units

Enter 74.10, see 74. The cents are noise at the altitude the app operates at, and losing
them makes columns of numbers scannable.

**Taken:** whole units in v1. Display-cents becomes a setting in v2, defaulting off.

### The new-transaction screen asks for almost nothing

Amount dominant and centred. A note field that visually invites context without demanding
it. Date and category as small icon-led controls below. That's the whole screen.

The hierarchy does the explaining, so nothing needs a label. This is where tenet 3 comes
from.

**Taken:** the editor's shape. Amount is the screen. Everything else is subordinate and
unlabelled.

### Categories are the user's, with editing where you'd look for it

You make them. Edit sits at the top of the category list, where you'd reach for it.

**Taken, and pushed further.** Dime ships with defaults; Tilly ships with none. A user's
categories may be conventional or may be private shorthand — a starter set is a guess
about someone's life, and it makes the app feel like it has opinions about how you should
think. First run should feel empty and clean, and the empty state should teach.

### A future date looks different from a past one, at the point of entry

Selecting a future date in the editor changes the icon — you're told, before saving, that
this hasn't happened yet.

**Taken:** the temporal state grammar is consistent everywhere a date appears, editor
included, not just on the timeline.

### Opinionated, useful settings

"Display cents", "Time Frames", "Upcoming Logs: shown/hidden". Small quality-of-life
switches, each one clearly answering a real question rather than exposing an
implementation detail.

**Noted for v2.** The Time Frames idea is the seed of Tilly's pay-period headline. Plenty of
people read their money from one payday to the next rather than by calendar month, and the
headline number should eventually be able to say "remaining this pay period".

### The proportional distribution bar

Dime's insights include a single horizontal bar segmented by category share. It reads
instantly, needs no legend to get the gist, and requires no chart library.

**Taken for v1's category breakdown.** More useful than a pie chart at this size, and it
answers the questions that actually matter: what share of my recurring spend is
subscriptions, and did utilities climb this winter?

---

## Dime — what not to copy

These are implementation choices, not design ones. Recorded so the reasoning survives.

### Materialised occurrences

Dime creates a real database row for each occurrence as its date passes, via
`DataController.updateRecurringTransaction()`. Two costs follow, both visible in its
source:

**Drift.** The loop walks forward from the *previous* occurrence rather than a fixed
anchor:

```swift
var holdingDate = transaction.nextTransactionDate
while holdingDate <= Calendar.current.startOfDay(for: Date.now) {
    // ...creates a new Transaction row...
    newDate = Calendar.current.date(byAdding: .month, value: coefficient, to: holdingDate)
}
```

A bill anchored on the 31st goes Jan 31 → Feb 28 → Mar 28 → Apr 28, and never returns to
the 31st. `byAdding: .month` clamps to the shorter month, and because the clamped result
becomes the next input, the clamp is permanent.

**Sync duplication.** `LogView` calls `updateRecurringTransactions()` both on appear and on
CloudKit sync-success, guarded by an `updatedRecurring` flag with a debounce — because two
devices running the pass both write rows.

Tilly computes occurrences from a fixed anchor instead. Neither problem exists, and
retroactive rule edits are correct for free. See `DECISIONS.md`.

### Very large view files

`InsightsView.swift` is 98KB. `BudgetView.swift` is 95KB. `LogView.swift` is 91KB. Single
files, each holding a whole feature.

This is the standing cautionary example behind `tilly-ship`'s file-size check. Large files
are harder for a person to hold in their head and harder for an agent to edit reliably.

### Licence

Dime is GPL-3.0; **Tilly is MIT**. These are incompatible in one direction: GPL code
cannot be included in an MIT-licensed project without relicensing the whole thing.

**Tilly contains no Dime code and never will.** Everything here is original work, and
Dime's contribution is ideas and judgement — which copyright does not cover and which open
source exists to share. The licence difference makes the no-copying rule load-bearing
rather than merely preferred.

---

## The competitor — what to avoid

A freemium recurring-expenses app. Clean-looking, and wrong in ways worth naming, because
each one is a specific failure of a specific tenet.

### The main content is at the bottom of its own home screen

The app is *about* upcoming payments. Upcoming payments appear below a headline number, a
row of four square buttons (Add / Savings / Limit / More), an upsell strip, and a "next
charge" card that is itself a paywall. You scroll to reach the reason you opened the app.

**Violates tenet 2.** Space went to things that could be measured — buttons, cards,
prompts — rather than to the one thing that matters. Adding boxes is not the same as
designing hierarchy.

### Everything is labelled, including the obvious

The new-expense screen labels "Price", "Billing Cycle", "Payment Date" and "Category", and
titles itself "New expense" — on a screen reached by tapping a button that said add. Five
pieces of text that restate what the controls already show, competing with the content for
attention.

**Violates tenet 3.** This is the standing example. When in doubt about a label, this
screen is the argument for deleting it.

### Categories you cannot create

Tapping Category offers a fixed list: Entertainment, Music, Productivity, Utilities, Rent,
Social, Business, News. Sensible buckets — for the developer. There is no way to add your
own.

**Violates tenet 4, worst of all of them.** It imposes one person's mental model on
everyone who uses the app, and there is no way out of it. This is precisely why Tilly
ships with zero categories: the user's way of dividing up their own money is not a thing
to guess at.

### Value held behind a paywall

"1 of 4 free recurring expenses." A padlock on the next-charge card. "We'd warn you before
this one hits. Unlock with Premium" — the app knows something useful about your money and
is declining to tell you.

**Violates tenet 5.** Tilly is free forever. Nothing about the app knows or cares who is
using it, and nothing it can tell you is withheld until you pay.

### A navigation bar that doesn't explain itself

Home / Dashboard / Premium / Calendar / Settings. Home versus Dashboard is unclear.
Premium is a shop. Five destinations for an app with roughly one job.

**Noted for Tilly's navigation:** few destinations, each obviously distinct, and Add
belongs in the tab bar rather than competing for space in the content area.

---

## How to use this doc

When exploring a screen, the question isn't "what would look nice" but "which of these
does this screen resemble". If a layout is drifting toward the competitor's home screen —
boxes accumulating above the content — that's the signal, and it's specific enough to act
on.

When something new is learned about what works, add it here with the same shape: what was
observed, which tenet it bears on, and what Tilly takes from it.
