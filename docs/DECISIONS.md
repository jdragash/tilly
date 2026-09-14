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

## The timeline is one list, future above and past below, bounded at both ends
**Decided:** 2026-09-08
Next month is always open above the current one; history runs continuously below. Further
ahead is a deliberate unlock that closes itself once you come back. A pill returns you to this month.
- **Rejected — collapsed month bars:** made ordinary movement a sequence of taps.
- **Rejected — past above, future below:** puts history at eye level in an app about what's coming.
- **Rejected — resting with next month peeking in:** two month names dilute the one being read.
- **Rejected — pull past the top to unlock:** hidden, and invisible to VoiceOver and Switch Control.
- **Rejected — a "hide" control, or letting unlocked months accumulate:** a mess for the reader to tidy.

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
