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

## Tilly is Drawn, on the token layer, with the glass left stock
**Decided:** 2026-09-04, the look 2026-10-18
Paper with a grain, colour as a rough-edged wash, SF Pro Rounded, and each category drawn as a
roughened symbol. System components still supply Liquid Glass, Dynamic Type, dark mode and
VoiceOver, and every value reaches a view through `Tokens`, so tuning the look is a one-file change.
Settled in the combined prototype (`docs/prototypes/combined.html`), ahead of the motion and All
bills, which are drawn in it.
- **Rejected — stock until a v2 design pass:** the motion and All bills would be built twice.
- **Rejected — handwriting (`icons-and-type.html`):** words and figures lose their instant read.
- **Rejected — cream cards, and a glass sheet:** tried in the prototype; colour cards and an opaque sheet read best.
- **Rejected — raw values now, extract tokens later:** the extraction is the expensive part.
- **Revisit when:** a value can't be reached through `Tokens`, or a drawn part costs a scroll its frames.

## The timeline is one list, future above and past below, and the future runs five years on
**Decided:** 2026-09-19
The calendar's closest level. Months ahead run continuously above the current one, like Calendar,
for as long as any bill does, out to five years. History runs continuously below to the oldest
charge. A month button returns you to this month.
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
- **Rejected — every bill running back as far as the list goes, or only since the day it was entered (2026-10-25):** the first invents charges the app was never told about; the second hides a bill started in the past on purpose. A bill's own first charge decides, and the editor names that date `First charge`.

## Your place survives a relaunch, to the month rather than the row
**Decided:** 2026-09-09
You return to the month you were reading, at its top, however long you were gone and whether or
not the process survived. The current month decides where you land only on first run.
- **Rejected — return to the current month on launch:** discards your place at a moment you can't predict.
- **Rejected — remember per session:** "next launch" isn't something anyone can observe.
- **Rejected — hold the timeline until the row is restored:** the gap is a few rows in one known direction.
- **Revisit when:** the list's two scroll coordinate spaces are calibrated (`.claude/rules/swiftui-scrolling.md`).

## Views switch in place from a menu beside +, and everything else is a sheet
**Decided:** 2026-09-19, views added 2026-09-24, All bills and the top row 2026-10-02
Laid out like iOS Calendar: a view button and + as one glass pair at the top row's right end, the
month button bottom left, and All bills and settings in one capsule bottom right. The view button's
menu lists Calendar and Categories, so more can join it. The editor, All bills and settings open as
sheets, the editor one the app draws itself so its card can fly into the timeline beneath; categories live in Settings. Over the days the top row holds the back button, and month
headers pin beneath it.
- **Rejected — a toggle that flips between two views:** a tap fewer, but the icon must show where you'd go, and a third view has nowhere to live.
- **Rejected — All bills as a view in the menu:** tried on the prototype's switches; the sheet won, opened from beside settings.
- **Rejected — a categories button:** categories are set up rarely, which is what Settings is for.
- **Rejected — a return pill that appears 240pt away:** a control that comes and goes; the month button is always there.
- **Rejected — pushed pages:** they replace the timeline instead of sitting over it.
- **Rejected — the system sheet for the editor:** it presents in a layer of its own, so its card can't fly into a row, and its timing isn't Tilly's to tune.

## Calendar is three zoom levels: the year, a month, and the days
**Decided:** 2026-10-01
Looking ahead reads at three distances of one place, as in Calendar: the next twelve months as small
calendars, one month as a grid, and the timeline as the days. Extras are bills that don't charge in
every calendar month, and one All / Extras toggle holds at every level, so the levels always show the
same charges. A month is heavy when its extras reach a fifth of the usual month, the median of its
twelve months' monthly bills.
- **Rejected — a view per question (heavy months, due soon, what's changing):** looking months ahead is occasional, and three views of one calendar crowd the menu.
- **Rejected — the year showing only what comes on top:** the levels stopped reading as one set of data.
- **Rejected — lanes beneath the calendar:** overload; the lanes stay a view of their own.
- **Rejected — "heavy" against a budget or this month:** a budget is a target the user must set (tenet 4); the usual month is their own.
- **Rejected — what's about to change as its own picture:** three directions, all confusing; rings on the year carry the plain cases.
- **Revisit when:** planned one-offs arrive; they are extras by this definition.

## Every expense has a category, and a category is a symbol, a name and a colour
**Decided:** 2026-09-19, colour and order added 2026-09-24, the symbol 2026-10-18
Amount, name, category and date are all required. The app ships with no categories, so the first
expense makes the first. The picture is a symbol from Tilly's own set, searched by word in the
keypad's place, and drawn roughened (`DESIGN.md`, the look). A category made before symbols keeps its
emoji until one is picked. The colour is one of eight tokens, checked so neighbours stay distinct for
colour-blind readers, and a new category starts on the next one unused. Categories keep an order the
user sets in Settings.
- **Rejected — the emoji keyboard, with a symbol matched to each emoji:** any emoji without a match shows a mixed row.
- **Rejected — keeping emoji under the Drawn look:** the one part of every row that wouldn't draw alike.
- **Rejected — pictures made on the phone (L), or Tilly's own hand (G):** prototyped in `icons-in-app.html`; I won.
- **Rejected — Tilly assigning colours in the order categories were made:** a colour the user didn't pick means nothing to them.
- **Rejected — a colour taken from the picture:** 🏠 and 🚗 landed on orange and red, too close to tell apart as dots.
- **Rejected — ordering by size or by name:** an order that reshuffles as bills change, where the user's own holds still.
- **Rejected — an optional category:** the row's picture and any insight by category would need a stand-in that means nothing.
- **Rejected — a starter set:** the user's categories are theirs (tenet 4).
- **Revisit when:** someone can't find a symbol for a category they mean; the set grows, or emoji return beside it.

## The category view is lanes across one month
**Decided:** 2026-09-24
A lane per category, a dot per charge on its day, sized by amount; one month at a time, paged by
arrows; dragging reads charges one at a time. Chosen from ten directions and a working prototype
(`docs/prototypes/views-lanes.html`) because it shows what the month looks like, where and when together.
- **Rejected — rows filled to their share of the month (recommended at the time):** ranks well, but no picture of the month.
- **Rejected — one merged line of coloured dots, and a running total over the lanes:** tried in the prototype; plain lanes read best.
- **Rejected — months stacked like the timeline:** dragging a lane would fight scrolling for the same touch.
- **Rejected — an options menu of spans, filters and a comparison with last month:** built and set aside; it complicated the view.
- **Rejected — a readout with a running total, stopping on every day:** clutter, and most days hold nothing.

## Every charge is its own row
**Decided:** 2026-09-19
Two charges on one day are two rows, each with its date. The timeline has no day groups.
- **Rejected — grouping a day under a heading with a day total:** the list changes shape, and rows inside lose their dates.

## The timeline is dashed and solid, rows drawn like category cards
**Decided:** 2026-10-24
A charged bill is a solid paper card, one to come a faint dashed outline; the colour lives only in
the picture. Dates read as words near today, a squiggle marks today, and a badge on the picture says
whether a bill repeats or ends. Chosen on the phone in `docs/prototypes/dashed-and-solid.html`.
- **Rejected — the Wallet stack, every row a full-colour card (built 2026-10-18):** on the phone a list of coloured cards read as things to tap, and a bill is rarely edited once made. The colour drowned the amount.
- **Rejected — a row drawn as a category card with a colour strip (recommended at the time), or colour only in a solid tile:** Jake kept the plain paper card with the picture on its wash.
- **Rejected — a colour line down a row's edge:** redundant once the picture carries the colour.
- **Rejected — weekday dates (`Tue 20`) and numeric ends (`ends 05/27`) everywhere:** mechanical. Words near today, a date further off.
- **Rejected — Today and Tomorrow as coloured badges:** tried in several styles; Jake chose plain words.
- **Revisit when:** All bills becomes folders, which reuses the row.

## Adding a bill is a card you complete, and a grid of category cards dresses it
**Decided:** 2026-10-16, the picker and the motion 2026-10-24
The sheet is a card whose missing parts are dashed, and the input for whichever part you tap opens
in the keypad's place. The category is one tap on a grid of category cards, and the card's colour
fades in. On ✓ the sheet slides away and the row is marked in place. Chosen from canvas rounds,
`docs/prototypes/edit-revisit-card.html`, then on the phone in `dashed-and-solid.html`.
- **Rejected — a form that leads, one step at a time, or the bill as a sentence:** each version still read as filling out a form, and a next button that moves leaves nothing clear to press.
- **Rejected — pockets the card files into on ✓ (built in v0.6.0):** the bill ended in a pocket, away from the timeline where it lives.
- **Rejected — a fanned hand of categories, played onto the card (built 2026-10-18):** at the phone's size with real categories the fan hid every name and most symbols. It was judged at desktop size.
- **Rejected — the card flipping, flying and landing in its row (built 2026-10-18):** it made adding and opening a bill feel slow. Snappy beats a story here.
- **Rejected — folders or a plain list as the picker:** folders leave no room for the name; a list stops looking like the rows it dresses.
- **Revisit when:** a grid of four across can't hold someone's categories without scrolling past a screen.

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
