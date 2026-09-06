# Roadmap

What's next and in what order. Changes often — the stable "what and why" lives in
`PROJECT.md`.

Every deferred item carries the reason it was deferred, so the decision doesn't get
re-argued each time someone notices it's missing.

---

## v1 — Know what's coming

The smallest thing that does the job. Nothing here is optional.

**Where things stand, 2026-09-06:** the engine is done and the timeline is next. There is no
Xcode project yet — everything so far runs from the command line, as the "Core is a Swift
package" decision anticipated. The first UI item creates it.

| Item | Status | Notes |
|---|---|---|
| Recurrence engine | **Done** | Every N days / weeks / months / years from a fixed anchor. Pure, tested, no SwiftData. Built to `docs/plans/recurrence-engine.md`; 54 tests. |
| Timeline | Next | Future above, past below, resting on the most recent actual charge. Sectioned by date. |
| Expense editor | — | Create and edit rules. Amount optional so variable bills fit. |
| Occurrence overrides | Engine done, UI to come | Set the real amount on an estimate, skip one, move one. "This occurrence" vs "all future" unmistakable. |
| Categories | — | User-created only. Ships empty. |
| Insights, thin | — | Month total, annualised total, category breakdown as a proportional bar. |
| Headline number | — | Calendar month — "remaining this month". |
| Token layer + gallery | — | `DesignSystem/Tokens.swift` aliasing system values, plus a gallery screen. Cheap now, expensive to retrofit. |

**Done when:** it holds a real set of recurring expenses and gets opened instead of guessed at.

---

## v1.1 — Know what's coming *before* it matters

| Item | Why not v1 |
|---|---|
| Look-ahead nudges — "next month you have a €500 annual bill" | Arguably the app's core promise, but the rules need real usage to design well. The engine already computes arbitrary future ranges, so this is a query plus a UI slot — and the slot is reserved in v1. |
| Custom & pay-period headline | Plenty of people track spending from one payday to the next rather than by calendar month. Real, but it changes what the headline *means*, and shouldn't gate shipping. |
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
