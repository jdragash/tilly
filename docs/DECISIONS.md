# Decisions

Dated log of what was decided, what was rejected, and why each rejected option lost. The
rejections matter as much as the choices — they're what stops the same debate recurring in
three months.

Format: one entry per decision. Newest at the top.

---

## Implementation plans are a written artifact, not an implicit step

**Decided:** 2026-09-04 · **From:** project kickoff

**Chosen:** A fifth skill, `tilly-plan` (Opus), sits between `tilly-explore` and
`tilly-build` and writes `docs/plans/<slug>.md` — ordered steps, each with exact file paths,
exact type signatures, named test cases, a verification command, and an explicit out-of-scope
line. `tilly-build` executes one step at a time and stops when a spec is wrong.

**Why:** the chain previously ran brief → explore → build. Explore ends at an approved
*design*; build starts writing code. The decisions in between — file layout, signatures,
build order, what "done" means per piece — had no home, so they were made ad hoc during
implementation by the model with the least context and no way to ask first.

The gap was demonstrated rather than theorised: the first Phase 1 handoff was a
hand-written step spec typed directly into chat. That decomposition was the right work
happening in the wrong place — invisible, unreviewable, and thrown away after one use.

**Secondary benefit:** the plan is a review artifact. Reviewing a plan before code exists is
far cheaper than reviewing a diff.

**Rejected — richer briefs instead of separate plans.** A brief answers *what and why* and
is read by a person deciding whether to do the work. A plan answers *how* and is read by a
model executing it. Merging them makes both worse.

**Rejected — leaving implementation decisions to `tilly-build`.** This is what was already
happening. Sonnet is strong enough to make these calls, but making them in the executing
session means they're never reviewed and never recorded.

**Guardrail:** every plan ends with an escape hatch instructing the executor to stop rather
than improvise when a spec is wrong. Specs detailed enough to remove decisions are detailed
enough to be confidently wrong; without the hatch, over-specification turns a bad guess into
a faithfully executed bad guess.

---

## Core is a Swift package, not a folder in the app target

**Decided:** 2026-09-04 · **From:** project kickoff

**Chosen:** `Core/` is a standalone SPM package, `TillyCore`, which the app target depends
on locally. Engine tests run with `cd Core && swift test`.

Two reasons, both practical:

*Speed.* `swift test` completes in about a second against the host, with no simulator boot.
An `xcodebuild test` cycle is 30-60 seconds. Across the hundreds of red-green iterations
test-driven development actually involves, that gap decides whether TDD is sustainable.

*Enforcement.* "Core must not import SwiftData" becomes a compile error rather than a
convention someone has to remember. The package simply doesn't link it.

**Rejected — a plain folder inside the app target.** Simpler layout on paper, but every
engine test would boot a simulator, and the architectural boundary would rest on discipline
alone.

**Consequence:** the Xcode project isn't needed until UI work begins. Phase 1 runs entirely
from the command line.

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

**Decided:** 2026-09-04 · **Supersedes:** "Licence: MIT", same day

**Chosen:** GPL-3.0, plus an additional permission under section 7 for App Store
distribution. `LICENSE` holds the GPL verbatim so licence detection works;
`LICENSE-EXCEPTION.md` holds the permission.

**Why this changed:** the requirement was restated as "build in the open, let people fork
and modify, but keep the app from being copied and sold". That is a description of
copyleft. MIT gives no such protection — it permits a fork to close the source and sell it.

**What GPL actually does**, since this is commonly misread: it does *not* prohibit selling.
Anyone may charge for GPL software. What it prohibits is closed-source distribution — a
commercial fork must ship complete corresponding source under the GPL, so any buyer can
pass it on freely. That removes the commercial moat without banning commerce, and it is the
mechanism behind the protection wanted here.

**Rejected — MIT.** Zero friction, maximum freedom for others, and no protection at all.
Chosen earlier the same day on the mistaken premise that Dime's GPL created some obligation
to avoid; it doesn't, since copyright covers code rather than ideas and Tilly contains no
Dime code.

**Rejected — MPL-2.0.** File-level copyleft with no App Store friction, but too weak here:
someone can combine Tilly's files with proprietary code and ship a closed commercial app,
provided they publish changes to Tilly's files specifically.

**Rejected — non-commercial licences** (PolyForm Noncommercial, CC BY-NC). These do
literally forbid selling, but they are not open source, they block the legitimate forking
that building in public is for, and they carry field-of-use restrictions that sit badly
with the project's goals.

**Cost accepted:** the exception is only effective when granted by *every* copyright
holder. Accepting outside contributions later means re-granting it from each contributor.
Noted in `CLAUDE.md`.

---

## Licence: MIT  ·  SUPERSEDED

**Decided:** 2026-09-04 · **Superseded the same day** by the GPL-3.0 entry above.
**From:** project kickoff

**Chosen:** MIT. Anyone can use, learn from, or build on Tilly with no obligations — the
same openness that made Dime useful to this project in the first place.

**Context:** Dime's GPL-3.0 does not oblige anything here. Copyright covers code, not
ideas, and Tilly contains no Dime code. The licence was a free choice.

**Rejected — GPL-3.0 with an App Store exception.** Briefly chosen earlier the same day
and reversed. The appeal was making "free forever" structural: copyleft means nobody can
take Tilly closed-source or sell it. Three things outweighed it. GPL's terms conflict with
the restrictions app stores place on people who download software — VLC was pulled from
the App Store in 2011 over exactly this — which needs an explicit additional-permission
clause to work around. That clause is only effective when granted by *every* copyright
holder, so accepting any outside contribution later would require re-granting it by each
contributor. And copyleft restricts what other people can do with work that is meant to be
freely learned from.

**Consequence, stated plainly:** tenet 5 is now a commitment rather than a guarantee. MIT
permits someone to fork Tilly, close the source, and sell it. Nothing stops that except
the decision recorded in `PROJECT.md`, which is where it belongs.

**Follow-on:** MIT and GPL-3.0 are incompatible in one direction — GPL code cannot enter an
MIT project without relicensing everything. This makes the never-copy-Dime rule in
`CLAUDE.md` load-bearing rather than merely preferred.

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
