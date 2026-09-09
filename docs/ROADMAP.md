# Roadmap

What's next and in what order. Changes often — the stable "what and why" lives in
`PROJECT.md`.

Every deferred item carries the reason it was deferred, so the decision doesn't get
re-argued each time someone notices it's missing.

---

## v1 — Know what's coming

The smallest thing that does the job. Nothing here is optional.

**Where things stand, 2026-09-07:** the engine is done, the app scaffolding is done, and the
timeline is next. The Xcode project exists with a live SwiftData store — `Expense` and
`OverrideRecord` map totally onto `TillyCore`'s value types — and `DesignSystem/Tokens.swift`
holds the token layer for the timeline to extend. Built to `docs/plans/app-scaffolding.md`.

| Item | Status | Notes |
|---|---|---|
| Recurrence engine | **Done** | Every N days / weeks / months / years from a fixed anchor. Pure, tested, no SwiftData. Built to `docs/plans/recurrence-engine.md`; 54 tests. |
| App scaffolding | **Done** | Xcode project, `Expense`/`OverrideRecord`, `TillyStore`, token layer. Built to `docs/plans/app-scaffolding.md`; 11 tests. |
| Timeline | Shipped 2026-09-09 | One list you scroll, bounded at both ends: next month always open above, history continuous below down to the oldest charge. A pinned header carries what is left this month. A deliberate unlock looks further ahead and puts itself away; a pill returns you to the current month; your place survives a relaunch. Built to `docs/plans/timeline.md`, all nine steps. Polished 2026-09-09 after first real use: the return pill appears at the right distance, points the right way on arrival, and travels at a readable speed; pinned headers are opaque paper rather than a grey material, which also removed the background-lag limitation. Two known limitations remain, recorded in `DECISIONS.md` — a saved place remembers the month rather than the row, and the cached "where the current month rests" drifts by up to several hundred points, which now matters because the pill's threshold is smaller than that error. |
| Expense editor | Next · scoped | Create and edit rules. Amount is required; variable bills are deferred to v1.1 and the reason is below. **The timeline's empty state already invites this and there is nothing behind it** — until the editor exists, the app can only show data it was seeded with. Scoped in `docs/briefs/expense-editor/brief.md`, which also moves the two rows beneath this one; those rows are corrected after exploration, when the shapes are known. |
| Occurrence overrides | Engine done, UI to come | Set the real amount on an estimate, skip one, move one. "This occurrence" vs "all future" unmistakable. |
| Categories | — | User-created only. Ships empty. |
| Insights, thin | — | Month total, annualised total, category breakdown as a proportional bar. |
| Token layer + gallery | Tokens started | `DesignSystem/Tokens.swift` aliases system values for text, ink and surface. `DesignSystem/Gallery.swift` still to come, and so does a spacing/dimension scale — the timeline introduces both when it needs them. |

**Done when:** it holds a real set of recurring expenses and gets opened instead of guessed at.

---

## v1.1 — Know what's coming *before* it matters

| Item | Why not v1 |
|---|---|
| Variable bills — an amount you can leave rough | Deferred out of the editor deliberately, not dropped. The pieces exist already: the schema carries an optional amount and an estimate flag, and the timeline renders both the `EST` mark and an em dash for an unknown figure — built, tested, and unreachable from real input until this lands. What is missing is the thinking. Whether a rough amount counts toward a month total, what a month total means when part of it is a guess, and whether "I don't know yet" and "roughly this" are one state or two. That is a design pass, not a control bolted onto the amount field. |
| Look-ahead nudges — "next month you have a €500 annual bill" | Arguably the app's core promise, but the rules need real usage to design well. The engine already computes arbitrary future ranges, so this is a query plus a UI slot — and the slot is reserved in v1. |
| Custom & pay-period months | Plenty of people read their money from one payday to the next rather than by calendar month. Deferred, and cheaper than it looks: the version worth copying is "the month starts on the Nth", which is a redefinition of the month interval rather than a new paging model — the engine already windows on any `DateInterval`, so month-by-month paging survives it intact. |
| Month header count as a setting — remaining or total | The header carries what's left, which is the right default and the only one v1 needs. A switch is a preference, not a decision, and it can wait for the settings screen to exist. |
| Calendar view | A month grid duplicates what the timeline already carries. Live with the timeline first and find out whether it's actually missed. |
| iCloud sync | Schema is CloudKit-shaped from day one, so this is close to a flag. Turning it on adds container setup, merge conflicts and sync latency — not what a first Swift project needs. |

---

## v2 — Make it yours

| Item | Why not sooner |
|---|---|
| **Design system pass** — typography, colour, spacing | v1 uses stock SwiftUI deliberately: it supplies Liquid Glass, Dynamic Type, dark mode and VoiceOver for free. The token layer means this becomes a one-file change with the gallery as its workbench. Functionality first. |
| Savings buckets, and the "pre-paid" bridge | Allocate real savings to intended purposes; a bucket funding an upcoming expense shows it as pre-paid on the timeline. Elegant, but it only makes sense once the timeline exists and is trusted. |
| Richer insight visualisations | Seeing subscriptions vs BNPL vs utilities over time, or heating climbing through winter. Needs months of real data before it says anything. |
| Quality-of-life settings | Display cents on/off, appearance, week start. Genuine polish, zero urgency. |

---

## Someday

Not scheduled. Recorded so they're not re-invented from scratch.

| Item | Thinking |
|---|---|
| Goals and wishlist | "Saving for a new laptop" is a goal without a price. Real, but it drags in rough estimates and a list that clutters fast. Would need its own design pass to not violate tenet 2. |
| History-based amount prediction | Predict a variable bill's next amount from its previous ones. Needs a year of data to be worth anything. |
| Widgets and Shortcuts | Obvious fit for "what's next". Only worth it once the timeline has settled. |

---

## Explicitly never

- Paid tiers, IAP, locked features, ads. Tenet 5.
- Bank connections. Tilly is about rules you declare, not transactions it discovers.
