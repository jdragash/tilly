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
| Timeline | Done | One list with a pinned header and saved place, five years ahead or to the last payment. The month button returns from anywhere, mid-flick included. |
| Expense editor | Creating done; editing designed | Adding an expense is built, in the Calendar-style shell. Editing an existing one is designed and planned: tapping a row, "this charge only or future charges", deleting. `docs/plans/expense-editor-editing.md`. |
| Occurrence overrides | In the editor | A different amount or date for one charge, €0 included. Planned with editing. Skipping is left out. |
| Categories | In the editor, partly | Emoji and name, user-created, ships empty, required on every expense. Created in the editor; listed in Settings. Editing them there isn't designed yet. |
| Insights, thin | Exploring | A category breakdown over a chosen period (this month, last month, monthly average, next 12 months, this year). Early ideas on the editor canvas. |
| Token gallery | — | `DesignSystem/Gallery.swift`: every token and component in light, dark and accessibility sizes. |

**Done when:** it holds a real set of recurring expenses and gets opened instead of guessed at.

---

## v1.1 — Know what's coming *before* it matters

| Item | Why not v1 |
|---|---|
| Viewing a charge before editing it | Prototyped and set aside on 2026-09-22 (the "view first" switch in `docs/prototypes/expense-editor-entry.html`): the editor-first version read better. Worth reopening with variable bills, where the page could show an actual amount beside the estimate. |
| Variable bills, with an amount you can leave rough | Needs a design pass, not a checkbox: does a rough amount count toward a month total, and are "I don't know yet" and "roughly this" one state or two? The schema already carries an optional amount and an estimate flag. An estimate gets a mark, never a tilde or lightness. |
| Look-ahead nudges ("next month has a large annual bill") | Arguably the core promise, but the rules need real usage to design well. The engine already computes any future range. No space is reserved for it. |
| Custom and pay-period months | Plenty of people read money from one payday to the next. Cheaper than it looks: "the month starts on the Nth" redefines one interval, and the engine windows on any `DateInterval`. |
| Header figure as a setting (remaining or total) | Remaining is the right default. A switch can wait for a settings screen. |
| Shake to undo a save or delete | Not core to knowing what's coming. SwiftData's own undo can't do it (a revived bill vanishes on the next save, or crashes), so it needs its own snapshot-based undo in `BillEditor`. |
| Calendar view | Would duplicate the timeline. Live with the timeline first and see whether it's missed. A view switch beside + is where it would go. |
| iCloud sync | The schema is CloudKit-shaped, so this is close to a flag. But it adds container setup, merge conflicts and latency. |

---

## v2 — Make it yours

| Item | Why not sooner |
|---|---|
| **Design system pass**: typography, colour, spacing | Jake's pass. Stock SwiftUI and the token layer make it a one-file change, with the gallery as the workbench. |
| Savings buckets, and the "pre-paid" bridge | A bucket funding an upcoming expense shows it as pre-paid. Only makes sense once the timeline is trusted. |
| Richer insight visualisations | Needs months of real data before it says anything. |
| Quality-of-life settings | Display cents (default off), appearance, week start. |

---

## Someday

| Item | Thinking |
|---|---|
| Goals and wishlist | A goal without a price drags in rough estimates and a list that clutters fast. Needs its own design pass. |
| History-based amount prediction | Predict a variable bill from its past amounts. Needs a year of data. |
| Widgets and Shortcuts | Obvious fit for "what's next", once the timeline has settled. |

---

## Explicitly never

- Paid tiers, in-app purchases, locked features, ads. Tenet 5.
- Bank connections. Tilly is about rules you declare, not transactions it discovers.
