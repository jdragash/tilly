# Views

A view switcher beside +, and the first view it opens: categories within a month.

## Problem

The timeline answers "what goes out next, and when". It can't answer "where does the money go":
a month is a list of dated rows, and seeing that three streaming services add up to more than the
gym means adding in your head. `PROJECT.md`'s v1 scope promises "enough insight to see where the
money goes", and nothing does that yet. Grouping the timeline by category was tried in the editor
work and turned into half an insights screen, which is why it was set aside rather than built.

## Which tenets are at stake

- **2, minimal for hierarchy's sake.** A second view has to earn its button. Its most important
  element must be nameable, and different from the timeline's.
- **4, never prescriptive.** Categories are the user's, emoji and name, with no colour. A view that
  wants colour must get it without asking the user for one.
- **1, a system that helps.** A view that asks the user to set a budget or confirm anything is wrong.

## Why now

Adding, editing and deleting bills are shipped, so there's enough real data to look at from a
second angle. "Insights, thin" is next on the roadmap and still exploring, and Jake has now given
it a place: a switcher beside +, as Calendar does it.

## What "better" looks like

1. From the timeline, one tap reaches a view that shows each category's total for a month, and
   which category is largest is obvious in under a second.
2. The timeline stays the default, and switching back is the same one tap.
3. The switcher is Calendar's button group, matched by measurement (TASTE 11).
4. The month in the new view follows the grammar: charged and upcoming look different, a month
   holding nothing isn't shown as €0 (TASTE 1), and totals equal the rows (whole units).
5. A category with nothing this month, a very long category name, one large yearly bill and a €0
   charge all read correctly.

## Prior attempts

- A list of every expense grouped by category was rejected for the shell: it "became half an
  insights screen" (`DECISIONS.md`, "The timeline is the only screen").
- A categories button was rejected; categories live in Settings.
- A colour per category was rejected: "a second identity to choose and keep distinct, when the
  emoji already distinguishes". That entry names Insights as its revisit point. **This work
  reopens it**, and what's new is a surface where colour could do work the emoji can't: a bar or
  ring where each category is a segment. Any colour has to be derived or state-based, not chosen.
- A calendar view is on the v1.1 list, deferred as duplicating the timeline, with "a view switch
  beside + is where it would go". This work builds that switch.
- `INSPIRATION.md` takes Dime's proportional distribution bar for v1's breakdown.
- `git log`: no earlier commits on Insights beyond roadmap notes.

## Constraints

- **Calendar's group, measured** on the iPhone 17 simulator (iOS 27, month view, 3x), 2026-09-24:
  - The top buttons are one glass capsule, 44pt tall, holding three icons (view, search, +) in
    158pt: about 52pt per icon, + centred about 21pt from the capsule's right end.
  - It sits 17.5pt from the screen's right edge, top at 62pt. Tilly's + sits at the 20pt gutter:
    a difference to settle, not copy silently.
  - The bottom pair (calendars, inbox) is the only two-icon group on screen: about 110pt wide,
    48pt tall. A two-icon top group would be about 100pt by 44, **estimated, not measured**.
  - The view button opens a **menu** from the group, not a toggle: about 250pt wide, rows 40pt
    apart, icon then label, a checkmark on the current view, and a divider before a different
    kind of view (List). The button's icon changes to show the view you're in.
- Engine: occurrences for any `DateInterval`, with overrides, charged versus upcoming by date,
  a series' end. Categories: emoji and name, nothing else. No budgets, no income.
- Stock SwiftUI behind `Tokens`; the design system pass is Jake's, so directions may use colour
  but won't propose a palette.
- One screen with sheets (`DECISIONS.md`). A second view switches in place, like Calendar's; it
  doesn't push or stack.

## We'll know it worked when

Jake reaches for the category view to answer "what am I paying for streaming" instead of scrolling
the timeline, and the switcher never gets in the way of + on the timeline. Not measurable beyond
his own use; this is a personal app.

## In and out

**In:** the switcher, the category view for one month, and proposals for further views with a
reason to open each.

**Out:** Swift. Editing categories in Settings. Budgets or targets. Periods other than a month
(this month, a 12-month average) are in only as far as a direction needs them; the roadmap's list
of periods may be reshaped by what wins.

## Open questions

1. Does colour enter Tilly here, and if so, derived from the emoji, from state, or not at all?
2. Is the switcher a menu (Calendar) or a two-state toggle, while there are only two views?
3. Does the category view keep the timeline's month, so switching shows the same month?
4. Does tapping a category go anywhere, and is that a sheet (the one-screen rule) or a drill-in?
5. Does "Insights, thin"'s list of periods survive, or does a month-scoped view replace it?

## Sources

`docs/PROJECT.md`, `TASTE.md`, `DESIGN.md`, `DECISIONS.md`, `ROADMAP.md`, `INSPIRATION.md`;
`docs/prototypes/expense-editor-entry.html` (the grouped view set aside);
`Tilly/Models/Expense.swift`, `ExpenseCategory.swift`, `Tilly/DesignSystem/Tokens.swift`;
iOS Calendar on the iPhone 17 simulator, iOS 27.

## Updates

### 2026-09-24: lanes, and its first settled choices

Round 1 of the canvas offered ten directions; Jake chose F, lanes through the month. A working
prototype (`docs/prototypes/views-lanes.html`) then settled these:

- **Lanes**, one per category, over a single month's days. One month at a time, not months stacked.
- **Lane height shrinks to fit** as categories are added, so the month stays on one screen.
- **Lane order is the user's own**, kept in Settings, as Dime does. Settings can't reorder
  categories yet, which this now depends on.
- **A category with nothing this month** folds into one line under the lanes, with its next charge.
- **Each lane ends in its month total.**
- **Dragging across the month** shows a readout above the finger naming that day's charges and
  nothing else, and moves from charge to charge, never stopping on an empty day.

A round adding an options menu (spans, filters, compare with last month) was built and set aside
the same day: it complicated the view.

- **Dragging starts on touch.** With one month on one screen, the lanes never scroll, so a
  touch can only mean reading.
- **Months page with arrows**, a glass pair left of the view button and +. Back stops at the oldest
  charge, ahead at five years; the September button returns.
- **The month's figure sits under its name**, here and on the timeline.
- **Next** lists the three soonest charges, at most one per category, on the current month only.
