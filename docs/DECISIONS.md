# Decisions

Choices that are costly to reverse, or likely to be reopened with a rejected option that still
looks tempting. Nothing else belongs here: design rules live in `DESIGN.md`, taste in `TASTE.md`,
workflow in the skills and `CLAUDE.md`, and lessons in `.claude/rules/`.

An entry is **replaced in place** when it changes, and the commit body says what changed and
why. History lives in git: `git log -p docs/DECISIONS.md`.

---

## Tilly is GPL-3.0, with an App Store exception
**Decided:** 2026-09-04
Copyleft: anyone may fork, modify or sell, but not close the source. `LICENSE` holds the GPL
verbatim; `LICENSE-EXCEPTION.md` holds the section 7 permission for App Store distribution.
- **Rejected — MIT:** permits a closed-source commercial fork, which is the thing to prevent.
- **Rejected — MPL-2.0:** file-level copyleft lets Tilly's files ship inside a closed app.
- **Rejected — non-commercial licences:** not open source, and they block legitimate forks.
- **Revisit when:** an outside contribution arrives, because the exception needs re-granting by every holder.

## `Core/` is a Swift package, `TillyCore`
**Decided:** 2026-09-04
The engine is a local SPM package the app depends on. `swift test` runs in about a second with
no simulator, and "Core must not import SwiftData" is a compile error rather than a convention.
- **Rejected — a folder in the app target:** every engine test boots a simulator, and the boundary rests on discipline.

## Occurrences are computed, never stored
**Decided:** 2026-09-04
The timeline is a pure function of rules, overrides and a date range. Only deviations persist,
as override records keyed on `(expense, scheduledDate)`. Retroactive rule edits are correct for free.
- **Rejected — materialising a row per occurrence (Dime):** drifts when generated from the previous row, and duplicates under sync.

## Recurrence is every N days, weeks, months or years from a fixed anchor
**Decided:** 2026-09-04
Interval, unit, anchor date, optional end date. Month-end clamps without sticking.
- **Rejected — weekday rules ("last Friday"):** a much larger engine and editor for cases not yet needed.
- **Rejected — iCalendar RRULE:** powerful and almost entirely unused here.
- **Revisit when:** a real bill can't be expressed.

## The occurrence window means effective dates
**Decided:** 2026-09-06
A query returns occurrences whose *effective* date falls in the range, days inclusive at both
ends. Moved bills arrive in the month they actually land in. Callers pass every override, unfiltered.
- **Rejected — window on scheduled dates and document it:** pushes the correction to every call site.
- **Rejected — a `.scheduled | .effective` parameter:** a knob with one correct setting.
- **Rejected — pad the window by a month:** still misses long moves, and "how big" has no defensible answer.

## A passed date is charged; nothing is confirmed
**Decided:** 2026-09-04
When an occurrence's date passes, it is charged. Setting a real amount is always available and never demanded.
- **Rejected — the user confirms each occurrence:** turns visibility into a chore, and skipped confirmations rot the data.
- **Rejected — assume, but prompt on variable bills:** the same chore, just rarer.

## Stock SwiftUI in v1, behind a token layer
**Decided:** 2026-09-04
System components supply Liquid Glass, Dynamic Type, dark mode and VoiceOver. Every value
reaches a view through `Tokens`, dimensions included, so the design pass is a one-file change.
- **Rejected — build a design system in v1:** functionality first.
- **Rejected — raw values now, extract tokens later:** the extraction is the expensive part.
- **Revisit when:** the v2 design pass, which is Jake's.

## The timeline is one list, future above and past below, and the future runs five years on
**Decided:** 2026-09-19
Months ahead run continuously above the current one, like Calendar, for as long as any bill does,
out to five years. History runs continuously below to the oldest charge. A month button returns you
to this month.
- **Rejected — a century ahead, so no reader could reach the end:** the reader sits at the bottom of
  one long list, and the scroll back to this month on launch lays out every month above it first.
  Measured: 34s of work at launch, and still ~380ms with each month built only when drawn.
- **Rejected — further ahead as a deliberate unlock that closes itself:** a strange sequence of
  taps to look ahead, and a list that changes on its own.
- **Rejected — past above, future below, as Calendar has it:** puts history at eye level in an app about what's coming.
- **Rejected — a horizon a year ahead with a line saying so:** looking ahead is the app's job.
- **Rejected — collapsed month bars:** made ordinary movement a sequence of taps.
- **Rejected — resting with next month peeking in:** two month names dilute the one being read.

## History begins at the oldest charge you have entered
**Decided:** 2026-09-08
The list stops at the oldest occurrence the rules generate, with a line saying so. Empty months
between there and today aren't listed. Safe because bills are entered for their *next* occurrence.
- **Rejected — start at the install date:** hides a renewal someone deliberately backdated, and needs a stored date plus a migration.
- **Rejected — list empty months at €0:** claims to know what a month cost.

## Your place survives a relaunch, to the month rather than the row
**Decided:** 2026-09-09
You return to the month you were reading, at its top, however long you were gone and whether or
not the process survived. The current month decides where you land only on first run.
- **Rejected — return to the current month on launch:** discards your place at a moment you can't predict.
- **Rejected — remember per session:** "next launch" isn't something anyone can observe.
- **Rejected — hold the timeline until the row is restored:** the gap is a few rows in one known direction.
- **Revisit when:** the list's two scroll coordinate spaces are calibrated (`.claude/rules/swiftui-scrolling.md`).

## The timeline is the only screen, and everything else is a sheet
**Decided:** 2026-09-19
Laid out like iOS Calendar: + in the pinned header's row, the month button bottom left, settings
bottom right. The editor and settings open as sheets over the timeline. Categories live in Settings.
- **Rejected — a list of every expense:** the timeline is that list, and grouped by category it became half an insights screen.
- **Rejected — a categories button:** categories are set up rarely, which is what Settings is for.
- **Rejected — the buttons in their own strip above the pinned header:** gives up a row of the screen for good.
- **Rejected — a return pill that appears 240pt away:** a control that comes and goes; the month button is always there.
- **Rejected — pushed pages:** they replace the timeline instead of sitting over it.

## Every expense has a category, and a category is an emoji and a name
**Decided:** 2026-09-19
Amount, name, category and date are all required. The app ships with no categories, so the first
expense makes the first. Both fields are required and there is no colour. The emoji comes from the
system emoji keyboard.
- **Rejected — an optional category:** the row's icon and any insight by category would need a stand-in that means nothing.
- **Rejected — a colour per category:** a second identity to choose and keep distinct, when the emoji already distinguishes.
- **Rejected — a starter set:** the user's categories are theirs (tenet 4).
- **Rejected — a custom emoji grid:** a curated set, and weaker than the system keyboard's search.
- **Revisit when:** managing categories in Settings, or Insights, is designed.

## Every charge is its own row
**Decided:** 2026-09-19
Two charges on one day are two rows, each with its date. The timeline has no day groups.
- **Rejected — grouping a day under a heading with a day total:** the list changes shape, and rows inside lose their dates.

## Editing a charge is Calendar's: edit first, then this charge or future ones
**Decided:** 2026-09-22
Tapping a row opens the editor for that charge, keypad up. When the amount or date changed, ✓ asks
"this charge only" or "future charges". Future starts at the opened charge, and the past never
changes, except from a bill's first charge. The wheel's payment count counts the whole bill.
- **Rejected — a page about the charge first, with Edit and "Change this charge" (prototyped, the "view first" switch):** the button you press picks the scope so ✓ never asks, and a charge that differs shows "usually €25". Lost on an extra tap every edit, for five fields the editor already shows.
- **Revisit when:** variable bills are designed. That page is the natural home for a bill's actual amount beside its estimate.
- **Rejected — the editor opening at rest, actions where the keypad goes:** opening a charge is editing it.
- **Rejected — choosing the scope first:** a control on every tap, and its default is the one people save by accident.
- **Rejected — a third answer, "all charges":** every price rise gets a one-line route to rewriting what the past cost.
- **Rejected — a series edit that corrects the whole timeline:** the same rewrite, with no way to avoid it.
- **Rejected — counting only the payments left:** the number would change with the charge you opened.
- **Rejected — scrolling to a bill saved out of sight:** the list stays where you were.

## Deleting asks Calendar's question, and €0 is an ordinary amount
**Decided:** 2026-09-22
A red trash button beside ✓ asks `Delete All Future Charges`, which ends the bill and keeps its
past, or `Delete All Charges`. One charge can be €0, for a free month; nothing skips a charge.
- **Rejected — separate skip, stop and delete actions:** ending a subscription is deleting what's ahead.
- **Rejected — a skip, as a button or as €0 drawn struck through:** a second idea for a case met once or twice a year, when a plain `€0` keeps the total right.
- **Rejected — a ⋯ menu holding Delete:** its only item, a tap further away.
- **Revisit when:** a view mode for a charge is designed (`ROADMAP.md`); skipping could be one of its actions.

## A bill is a series of rules, and "future charges" starts the next one
**Decided:** 2026-09-22
Saving for future charges ends the open charge's rule at the charge before and starts a new
`Expense` at this one, sharing a `seriesID`. The engine is unchanged. Name, category, the payment
count, "ends 08/26" and deleting all read the series; one-off changes to later charges move to the
new rule when it still generates their date.
- **Rejected — rule versions inside one `Expense`:** a new model and engine work for what two rows already express.
- **Rejected — editing the one rule in place:** rewrites every past charge.
- **Rejected — a required `seriesID`:** a migration would give every existing bill the same default, so `nil` means "its own series".
