# Additional views

More ways to read the same bills, beside the timeline and the lanes, in the view menu.

## Problem

Tilly promises forward visibility "day to day, week to week, month to month, year to year"
(`PROJECT.md`, job 1). Two views cover part of that. The timeline answers "what goes out next, and
when", one row at a time. The lanes answer "what does this month look like, and where does it go",
one month at a time. Three questions still mean scrolling and adding up in your head:

- **Is a heavy month coming?** Seeing that a month ahead is unusual means paging the lanes month by
  month, or scrolling the timeline and comparing header figures from memory. The app computes any
  future range already; nothing lays months side by side.
- **What's due soon?** The nearest week or two is a few rows at the top of this month on the
  timeline, mixed with what's already charged, and a dot or two on the lanes. Nothing is close-up.
- **What's about to change?** A price rise from next month, a bill that ends in November, a charge
  set to €0 for one month: each is visible only on the row it touches, if you scroll past it.

"What do I pay in total, per year or per bill" was offered and not chosen.

## Which tenets are at stake

- **2, minimal for hierarchy's sake.** Each view has to earn its row in the menu, and name its most
  important element, which must differ from the timeline's and the lanes'.
- **1, a system that helps.** "What's changed" is one step from an inbox of changes to clear. A view
  that asks to be acknowledged, dismissed or marked seen is wrong.
- **4, never prescriptive.** "Heavy" can't come from a budget the user sets. It has to come from the
  bills themselves.

## Why now

Both existing views are shipped, with a view menu built to hold more. Jake wants
views that make Tilly read as "your recurring expenses at a glance": genuinely new pictures, not a
third list.

## What "better" looks like

1. Each direction names the one question it answers, from the three above, and answers it in under
   a second without scrolling or adding up.
2. Each could not be mistaken for the timeline or the lanes. A direction that is one of them with a
   different filter is out.
3. It holds what the app knows and nothing more (TASTE 1): charged and upcoming look different, a
   month with nothing in it isn't €0, and "heavy" is measured against the user's own months.
4. It asks nothing of the user: no targets, no setup, nothing to clear (tenet 1).
5. It survives the edge cases: one very large yearly bill, a month with nothing, many categories, a
   bill that ends, a €0 charge.

## Prior attempts

- **The first views canvas** (`docs/briefs/views/brief.md`, canvas in round 1, 2026-09-24) had a
  "Further views" page: a strip of the next 12 months, bills ranked by what they cost a year, "a
  normal month" with yearly bills spread evenly, and "what's changed". None was taken further; lanes
  won. This round starts fresh, and any of those four may return only if a new version beats the
  sketch, marked as a return.
- **A year span and a monthly average as lane options** were built in the lanes prototype and set
  aside (`ROADMAP.md`, "Category view"). An options menu of spans and "compare with last month" was
  set aside the same day: it complicated a view Jake liked for its clean picture. Months-ahead
  directions must be their own view, not a span switch on the lanes.
- **Look-ahead nudges** ("next month has a large annual bill") sit on the v1.1 roadmap as "arguably
  the core promise", waiting for real use. A heavy-months view is the same question asked by
  looking rather than by being told.
- **A calendar view** is deferred on v1.1 as duplicating the timeline. A "due soon" direction shaped
  like a calendar reopens it and must say what it shows that the timeline doesn't.
- `git log`: no commits on views beyond the lanes work (`a4baf87` and its merge).

## Constraints

- **In the app's view menu only.** No widgets, lock screen or Live Activities this round; they stay
  under "Someday".
- **What the data can tell "changed" from.** A price rise is knowable, because "future charges"
  starts a new rule in the same series at the new amount. So are an end date, a one-off amount or
  date on a single charge, and a bill's first charge. An expense has no creation date, which matters
  less now that "changed" looks ahead.
- **The engine** computes occurrences for any date range, with overrides, charged versus upcoming by
  date. The timeline runs five years ahead; history to the oldest charge.
- **Categories** have an emoji, a name and a user-chosen colour (8 tokens). A view may use them;
  icons and colour are being explored separately, on `icons-exploration`.
- Stock SwiftUI behind `Tokens`; the design system pass is Jake's, so directions don't propose a
  palette or type scale.
- One screen, switched in place from the view menu, as the lanes are.
- **One view per question.** Each direction answers exactly one of the three.
- **Not far ahead.** Months, not years; a direction proposes its own span and names it (TASTE 10).
- **"What's changed" looks ahead:** what is about to be different, such as a price rise that starts
  next month, a bill ending, a €0 charge coming, a bill's first charge.
- **Each view is its own thing.** Nothing is inherited from the timeline or the lanes: not the
  lanes' dragging or month arrows, nor the timeline's pinned header. Each earns its own interactions.

## We'll know it worked when

Jake picks one or two directions worth a working prototype, and on his phone reaches for one to
answer "is December going to hurt" or "what's coming this week" instead of scrolling. Not
measurable beyond his own use.

## In and out

**In:** directions on the canvas, in light and dark, with the same sample bills throughout: the
views answering the three questions, how they relate to the timeline and the lanes, and a list of
every bill with what each costs a year.

**Out:** Swift. Widgets and anything outside the app. Budgets, income, or targets.

## Open questions

1. What counts as heavy: more than the user's usual month, more than this month, or the biggest
   ahead? Each gives a different answer for a year with one large renewal. Jake isn't sure; the
   directions should show the options side by side rather than pick one silently.

## Sources

`docs/PROJECT.md`, `TASTE.md`, `DESIGN.md`, `DECISIONS.md`, `ROADMAP.md`, `INSPIRATION.md`;
`docs/briefs/views/brief.md`; the first views canvas, "Further views" page;
`Tilly/Models/Expense.swift`, `OverrideRecord.swift`, `ExpenseCategory.swift`,
`Tilly/Shell/ViewMode.swift`.

## Outcome

Shipped 2026-10-02. The three questions became three zoom levels of one calendar rather than three
views: the year answers "is a heavy month coming", the month grid "what's due soon", and the
timeline is the days. All bills, a list of every bill, came into scope on the way. The rules are in
`DESIGN.md` ("The calendar", "All bills"), the choice and its rejected options in `DECISIONS.md`
("Calendar is three zoom levels"). Open question 1 settled on the usual month: the median of the
twelve months' monthly bills, with a month heavy when its extras reach a fifth of it.

Set aside on the canvas, with no other record:

- **Heavy months:** columns against a usual line, split by category (busy, mostly one fixed bill);
  extras as blocks standing on a floor of the every-month bills (liked, overtaken by the year); a
  single headline answer, "January" (clean, but nothing showed why).
- **Due soon:** a countdown list and written sentences (not useful); a day drawn as named pills or
  as a bar (the emoji and total read best); months that scroll rather than page.
- **All bills:** a table sorted by tapping its columns, and a share bar that opens categories.

Still open, tracked in `ROADMAP.md`: what's about to change, as a picture; planned one-offs, which
are extras by this definition; and the two Calendar bugs on its v1 row.
