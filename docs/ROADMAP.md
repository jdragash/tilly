# Roadmap

A forecast, not a contract. Jake reorders it freely, and when he does, this file changes to match
without comment. What the app is and why lives in `PROJECT.md`. Small fixes and tune-ups from using
the app live in `observations.md`; this file holds the features.

Deferred items carry a short reason, so the question isn't re-argued every time someone notices
the gap.

---

## v1 — Know what's coming

The smallest thing that does the job.

| Item | Status | Notes |
|---|---|---|
| Recurrence engine | Done | Every N days, weeks, months or years from a fixed anchor. Pure and tested. A bill's first charge decides its past. |
| App scaffolding | Done | Xcode project, `Expense` and `OverrideRecord`, `TillyStore`, token layer. |
| The look: Tilly, Drawn | Done | Paper ground and grain, rounded type, pictures on a rough wash that boil. The timeline is dashed and solid: a faint dashed card still to come, a solid paper card once charged. |
| Calendar | Done | The year, a month and the days, which are the timeline: one list with a pinned header and saved place, five years ahead or to the last payment. All / Extras holds at every level. The Today button lands the Today line mid-screen, from anywhere. |
| All bills | Done | Read only: a paper card per category, costliest first, its bills listed with their figures, ended bills behind a line. Nothing opens; bills change from the timeline, categories in Settings. |
| Expense editor | Done | A card you complete: tapping a row, "this charge only or future charges", deleting. Categories are picked from a grid of cards. The sheet drags down from anywhere. |
| Occurrence overrides | Done | A different amount or date for one charge, €0 included. Built with editing. Skipping is left out. |
| Categories | Done | A symbol, name and colour, user-created, ships empty, required on every expense. Made, changed and deleted on their own sheet, from the editor or Settings > Categories, with a symbol guessed from the name. Settings sorts them once, with undo. |
| Settings | Done | Top right, in glass. One row so far, Categories. |
| Category view | Set aside | Hidden from the shell while the calendar is tested alone; the code stays. Lanes across one month, a dot per charge; dragging reads a day's charges. Accessibility sizes render without overlap but aren't designed. |
| Developer tools | Done | Debug only: scenarios, motion tuning, and DialKit on a shake to tune layout numbers on the phone. |

**Done when:** it holds a real set of recurring expenses and gets opened instead of guessed at.

---

## v1.1 — Know what's coming *before* it matters

| Item | Why not v1 |
|---|---|
| The year and a month, in the card's language | They take the Drawn ground, type and colours now; their own redesign waits for the timeline to settle. |
| Long category names | A long single word shrinks to stay whole on its card, which works but reads small. Wants a better answer once there are more real names to test. |
| Viewing a charge before editing it | Prototyped and set aside: the editor-first version read better (`DECISIONS.md`). Reopens with variable bills, where the page could show an actual amount beside the estimate. |
| Variable bills, with an amount you can leave rough | Needs a design pass, not a checkbox: does a rough amount count toward a month total, and are "I don't know yet" and "roughly this" one state or two? The schema already carries an optional amount and an estimate flag. An estimate gets a mark, never a tilde or lightness. |
| Planned one-off expenses | A known cost ahead, like a purchase in March, is a bill with one payment. Dated in the future when it's made, so it can never become a log of past spending. Needs a brief: where it's entered (the repeat wheel's smallest count is 2 today) and how it reads in the calendar, where it is an extra, and in All bills. |
| Look-ahead nudges ("next month has a large annual bill") | The year already shows a heavy month to anyone who looks; a nudge tells you unasked, and its rules need real use to design well. No space is reserved for it. |
| Custom and pay-period months | Plenty of people read money from one payday to the next. Cheaper than it looks: "the month starts on the Nth" redefines one interval, and the engine windows on any `DateInterval`. |
| Header figure as a setting (remaining or total) | Remaining is the right default. Settings has room for the switch once someone wants it. |
| Shake to undo a save or delete | Not core to knowing what's coming. SwiftData's own undo can't do it (a revived bill vanishes on the next save, or crashes), so it needs its own snapshot-based undo in `BillEditor`. A shake opens DialKit in Debug builds meanwhile. |
| What's about to change, as a picture | Three directions were all confusing (`docs/briefs/additional-views/brief.md`). Rings on the year carry starts, price changes and ends meanwhile. |
| iCloud sync | The schema is CloudKit-shaped, so this is close to a flag. But it adds container setup, merge conflicts and latency. |

---

## v2 — Make it yours

| Item | Why not sooner |
|---|---|
| **Design system pass**: a type scale and spacing | The look is built; a scale and spacing stay Jake's pass, through `Tokens`, tuned on the phone with DialKit. |
| Holographic category colour | A ninth colour choice: a rainbow foil that shifts as the phone tilts. Delight, not function, so it waits for the function to be trusted. |
| Savings buckets, and the "pre-paid" bridge | A bucket funding an upcoming expense shows it as pre-paid. Only makes sense once the calendar is trusted. |
| Richer insight visualisations | Needs months of real data before it says anything. |
| Quality-of-life settings | Display cents (default off), appearance, week start. Settings exists now; each waits for someone to miss it. |

---

## Someday

| Item | Thinking |
|---|---|
| Goals and wishlist | A goal without a price drags in rough estimates and a list that clutters fast. Needs its own design pass. |
| History-based amount prediction | Predict a variable bill from its past amounts. Needs a year of data. |
| Widgets and Shortcuts | Obvious fit for "what's next", once the calendar has settled. Views stay in the app until then. |
| Symbol guesses from Apple's on-device model | The keyword list and word similarity guess well already; the model only runs on Apple Intelligence phones, so it could only ever be an extra. |
| Token gallery | Every token and component in light, dark and accessibility sizes. DialKit and the Simulator have covered it so far. |

---

## Explicitly never

- Paid tiers, in-app purchases, locked features, ads. Tenet 5.
- Bank connections. Tilly is about rules you declare, not transactions it discovers.
