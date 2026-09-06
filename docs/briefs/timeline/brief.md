# Timeline

## Problem

Tilly can't show you anything yet. The engine knows, precisely and correctly, what's due
between any two dates — but nothing puts that on a screen. There is no app: no Xcode
project, no views, no database. The first job in `PROJECT.md` is forward visibility, and
right now nothing delivers it.

The evidence for how badly this can go is in `INSPIRATION.md`. The competitor is an app
*about* upcoming payments where upcoming payments sit below a headline number, a row of four
square buttons, an upsell strip and a card that's itself a paywall. You scroll to reach the
reason you opened the app. Space went to things that were easy to count — buttons, cards,
prompts — rather than to the one thing that matters.

Dime gets the same screen right, and the reason is instructive: future charges sit inline
with past ones, greyed and outlined. Nothing is pending. Nothing needs confirming. You just
see that things are still coming.

## Which tenets are at stake

Tenets 1, 2 and 3 from `PROJECT.md`.

Tenet 2 is the hard one here, and this is the screen it was written for. Tenet 1 is the one
most easily lost by accident — a "mark as paid" control is the obvious thing to reach for on
a list of payments, and adding one would quietly turn the app into the thing it exists not to
be.

## Why now

The engine is finished and verified, and it was the only thing the timeline was waiting on.
Every other v1 item either depends on this screen existing or is a smaller piece of it.

Two things also come due with it. There is still no Xcode project — the "Core is a Swift
package" decision meant Phase 1 ran entirely from the command line, and this is the work that
finally creates the app. And `DESIGN.md`'s state grammar has been sitting since kickoff
explicitly labelled a hypothesis, waiting for a real layout to be tested against. It can't be
settled in the abstract, and everything downstream inherits it.

## What "better" looks like

1. Opening the app puts the next thing due at eye level. No scrolling to reach the point.
2. You can tell an upcoming charge from one that's already happened, and an estimate from a
   known amount, without reading any words.
3. Nothing on the screen asks you to do anything. There is no control that marks a charge as
   paid, and no state that looks like it's waiting for you.
4. Scrolling keeps working in both directions — months keep arriving as you go, forward
   indefinitely and back through real history.
5. A skipped bill is visibly still known about, and visibly not counted.
6. First run looks deliberate rather than broken.

## Prior attempts

None. The timeline has never been built — no code, no branches, no reverts anywhere in the
history. This is a clean slate, which is worth stating plainly rather than leaving the
section empty.

The one piece of prior thinking is `DESIGN.md`'s state grammar, written at kickoff and never
tested: temporal state (charged / not yet) carried by *form*, certainty (estimated / known)
carried by *typography*. Its own section says it's a starting position, not a settled rule.
The trap it's guarding against is real — if estimates render "lighter" and upcoming also
renders "lighter", an estimated past charge reads as upcoming.

## Constraints

**From the engine.** It answers "what happens between these two dates", windowed on the date
money actually leaves — so month-by-month paging is the natural unit, and it's proven correct
under exactly that access pattern. One trap comes with it: when fetching the records that
move or skip a bill, the fetch must include ones belonging to a *neighbouring* month, because
a bill can be moved into this one from outside it. Get that wrong and the month still looks
plausible, which is why it's written down.

**From the decisions already made.** Future above, past below, resting on the most recent
actual charge. Charges are assumed, never confirmed. Amounts in whole units. Occurrences are
computed on the fly, never stored — only deviations get saved.

**From the roadmap.** Look-ahead nudges ("next month you have a large annual bill") are v1.1,
but the slot for them is reserved in v1. The layout has to leave room for something it won't
yet contain.

**Technical.** This work creates the Xcode project, the SwiftData models and
`DesignSystem/Tokens.swift`. Models must stay CloudKit-compatible — optional or defaulted
properties, no unique constraints, optional relationships — even though sync is off. Views
reference tokens only, never raw values. iOS 26, Swift 6, no third-party dependencies.

## We'll know it worked when

Mostly not measurable, and worth being honest about rather than inventing a metric. This is a
single-user app; there is no funnel and no cohort.

The real test is the one already written in `ROADMAP.md`: it holds a real set of recurring
expenses and gets opened instead of guessed at. That takes weeks of actual use, not a demo.

Two things *are* checkable at the end of the work: the screen reads correctly in dark mode and
at accessibility text sizes, and every occurrence state can be told apart at a glance by
someone who hasn't been told what the states are.

## In and out

**In.** The timeline screen. Month headers with individual days listed beneath them. All four
occurrence states rendered — upcoming, charged, estimated, skipped. Lazy loading in both
directions as you scroll. The empty state for first run. The Xcode project, the SwiftData
models, and the token file, because this is the work that creates them.

**Out.** Creating or editing expenses — the editor is its own piece of work, so this screen
runs on seeded sample data. That data needs to include a moved bill, a skipped one and an
estimate, or three of the four states never appear. Also out: categories, insights, the
headline number, look-ahead nudges, the calendar view, and the "this occurrence versus all
future" choice, which belongs with the overrides UI.

## Open questions

These gate exploration and shouldn't be settled here.

1. **Does a moved bill leave any mark on the date it was originally due?** The engine now
   reports it only at its new date. Showing a trace at the old one is possible — the original
   date is still carried — but it's a design call, and it's new as of today.
2. **Does the state grammar survive a real layout?** Form for time, typography for certainty.
   Untested since kickoff.
3. **Where does the reserved look-ahead slot actually live** on the screen, given it stays
   empty through v1?
4. **What is the resting position on first open, precisely** — and what does it rest on when
   there is no most recent charge yet, which is every user's first week?
5. **Does a month header carry that month's total?** It would be useful and it overlaps the
   headline-number item, so the boundary between them needs drawing before both are built.

## Sources

- `docs/PROJECT.md` — jobs to be done, tenets 1–5
- `docs/ROADMAP.md` — v1 scope; look-ahead slot reserved; calendar view deferred to v1.1
- `docs/DECISIONS.md` — "Timeline runs future-above, past-below, resting on the last actual
  charge"; "Past charges are assumed, not confirmed"; "Occurrences are computed, never
  stored"; "Headline is calendar month in v1"; "The occurrence window means effective dates"
- `docs/DESIGN.md` — state grammar (flagged hypothesis), copy rules, empty states
- `docs/INSPIRATION.md` — Dime's upcoming-as-state and absent affordances; the competitor's
  buried content and its navigation
- `docs/plans/recurrence-engine.md` — what the engine actually provides
- `git log` — no prior timeline work exists in the history
- Scope decisions in this brief were answered directly by Jake, 2026-09-06: lazy loading in
  both directions; month headers with day rows; skipped shown de-emphasised and excluded from
  totals; empty state in scope, editor out.
