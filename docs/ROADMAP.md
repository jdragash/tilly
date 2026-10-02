# Roadmap

A forecast, not a contract. Jake reorders it freely, and when he does, this file changes to match
without comment. What the app is and why lives in `PROJECT.md`.

Deferred items carry a short reason, so the question isn't re-argued every time someone notices
the gap.

---

## v1 — Know what's coming

The smallest thing that does the job.

| Item | Status | Notes |
|---|---|---|
| Recurrence engine | Done | Every N days, weeks, months or years from a fixed anchor. Pure and tested. |
| App scaffolding | Done | Xcode project, `Expense` and `OverrideRecord`, `TillyStore`, token layer. |
| Calendar | Done | The year, a month and the days, which are the timeline: one list with a pinned header and saved place, five years ahead or to the last payment. All / Extras holds at every level. On an iPhone, the month button and the toggle may still lose to a flick in progress (open). In the year, a month past the last payment opens the last one with charges (open). |
| All bills | Done | A sheet of category cards, Monthly or Yearly, ended bills behind a line; a bill opens its next charge. No sorting or search. |
| Expense editor | Done | Adding and editing a bill, in the Calendar-style shell: tapping a row, "this charge only or future charges", deleting. Shake to undo deferred. Making a category lifts the amount 20pt over the emoji keyboard, against "never moves" (open). |
| Occurrence overrides | Done | A different amount or date for one charge, €0 included. Built with editing. Skipping is left out. |
| Categories | Done, partly | Emoji, name and colour, user-created, ships empty, required on every expense. Created in the editor; ordered, and recoloured, in Settings. Renaming, changing an emoji and deleting there aren't designed yet. |
| Category view | Done | Lanes across one month, a dot per charge, beside the calendar in the view menu; dragging reads a day's charges. Other periods (a year, a monthly average) were tried and set aside. Accessibility sizes render without overlap but aren't designed. |
| Token gallery | — | `DesignSystem/Gallery.swift`: every token and component in light, dark and accessibility sizes. |

**Done when:** it holds a real set of recurring expenses and gets opened instead of guessed at.

---

## v1.1 — Know what's coming *before* it matters

| Item | Why not v1 |
|---|---|
| Viewing a charge before editing it | Prototyped and set aside: the editor-first version read better (`DECISIONS.md`). Reopens with variable bills, where the page could show an actual amount beside the estimate. |
| Variable bills, with an amount you can leave rough | Needs a design pass, not a checkbox: does a rough amount count toward a month total, and are "I don't know yet" and "roughly this" one state or two? The schema already carries an optional amount and an estimate flag. An estimate gets a mark, never a tilde or lightness. |
| Planned one-off expenses | A known cost ahead, like a purchase in March, is a bill with one payment. Dated in the future when it's made, so it can never become a log of past spending. Needs a brief: where it's entered (the repeat wheel's smallest count is 2 today) and how it reads in the calendar, where it is an extra, and in All bills. |
| Look-ahead nudges ("next month has a large annual bill") | The year already shows a heavy month to anyone who looks; a nudge tells you unasked, and its rules need real use to design well. No space is reserved for it. |
| Custom and pay-period months | Plenty of people read money from one payday to the next. Cheaper than it looks: "the month starts on the Nth" redefines one interval, and the engine windows on any `DateInterval`. |
| Header figure as a setting (remaining or total) | Remaining is the right default. A switch can wait for a settings screen. |
| Shake to undo a save or delete | Not core to knowing what's coming. SwiftData's own undo can't do it (a revived bill vanishes on the next save, or crashes), so it needs its own snapshot-based undo in `BillEditor`. |
| What's about to change, as a picture | Three directions were all confusing (`docs/briefs/additional-views/brief.md`). Rings on the year carry starts, price changes and ends meanwhile. |
| iCloud sync | The schema is CloudKit-shaped, so this is close to a flag. But it adds container setup, merge conflicts and latency. |

---

## v2 — Make it yours

| Item | Why not sooner |
|---|---|
| **Design system pass**: typography, colour, spacing | Jake's pass. Stock SwiftUI and the token layer make it a one-file change, with the gallery as the workbench. |
| Savings buckets, and the "pre-paid" bridge | A bucket funding an upcoming expense shows it as pre-paid. Only makes sense once the calendar is trusted. |
| Richer insight visualisations | Needs months of real data before it says anything. |
| Quality-of-life settings | Display cents (default off), appearance, week start. |

---

## Someday

| Item | Thinking |
|---|---|
| Goals and wishlist | A goal without a price drags in rough estimates and a list that clutters fast. Needs its own design pass. |
| History-based amount prediction | Predict a variable bill from its past amounts. Needs a year of data. |
| Widgets and Shortcuts | Obvious fit for "what's next", once the calendar has settled. Views stay in the app until then. |

---

## Explicitly never

- Paid tiers, in-app purchases, locked features, ads. Tenet 5.
- Bank connections. Tilly is about rules you declare, not transactions it discovers.
