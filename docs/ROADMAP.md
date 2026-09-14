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
| Timeline | Done | One bounded list with a pinned header, unlock ahead, return pill, and saved place. Known drift in the resting-position cache. |
| Expense editor | Next, scoped | Create, edit, end and delete rules. Amount required. Removes the sample seed. `docs/briefs/expense-editor/brief.md`. |
| Occurrence overrides | In the editor | Set a real amount, skip one, move one. "This occurrence" vs. "all future" unmistakable. |
| Categories | In the editor, partly | User-created, ships empty. Inline creation is built; managing categories is designed, not built. |
| Insights, thin | — | Month total, annualised total, category breakdown as a proportional bar. |
| Token gallery | — | `DesignSystem/Gallery.swift`: every token and component in light, dark and accessibility sizes. |

**Done when:** it holds a real set of recurring expenses and gets opened instead of guessed at.

---

## v1.1 — Know what's coming *before* it matters

| Item | Why not v1 |
|---|---|
| Variable bills, with an amount you can leave rough | Needs a design pass, not a checkbox: does a rough amount count toward a month total, and are "I don't know yet" and "roughly this" one state or two? The schema already carries an optional amount and an estimate flag. An estimate gets a mark, never a tilde or lightness. |
| Look-ahead nudges ("next month has a large annual bill") | Arguably the core promise, but the rules need real usage to design well. The engine already computes any future range. No space is reserved for it. |
| Custom and pay-period months | Plenty of people read money from one payday to the next. Cheaper than it looks: "the month starts on the Nth" redefines one interval, and the engine windows on any `DateInterval`. |
| Header figure as a setting (remaining or total) | Remaining is the right default. A switch can wait for a settings screen. |
| Calendar view | Would duplicate the timeline. Live with the timeline first and see whether it's missed. |
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
| An expenses list, and managing categories | Designed with the editor, not scheduled. Both need navigation the app doesn't have. Until then, a bill set up far in the future can't be reached until it charges. |
| Goals and wishlist | A goal without a price drags in rough estimates and a list that clutters fast. Needs its own design pass. |
| History-based amount prediction | Predict a variable bill from its past amounts. Needs a year of data. |
| Widgets and Shortcuts | Obvious fit for "what's next", once the timeline has settled. |

---

## Explicitly never

- Paid tiers, in-app purchases, locked features, ads. Tenet 5.
- Bank connections. Tilly is about rules you declare, not transactions it discovers.
