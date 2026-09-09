# Expense editor

## Problem

Nothing in Tilly creates an expense. The timeline reads `Expense` records out of SwiftData
and renders them correctly, and the only thing that has ever put a record there is
`SampleData.swift` — eleven invented bills seeded on first launch.

Two consequences, and the second is worse than the first.

The app cannot hold anyone's actual money. Everything downstream of the timeline — overrides,
categories, insights — is waiting on a screen that does not exist.

And the empty state, which `DECISIONS.md` says is "doing the teaching", is unreachable in
ordinary use. The seed fires before anyone sees it. So first run is not a clean invitation;
it is somebody else's expenses, presented as though they were yours. The screen already
says *"Add a bill or a subscription and it shows up here before it goes out"* — an
instruction with no control behind it, on a screen most people will never reach.

## Which tenets are at stake

Tenets 1, 2, 3 and 4 from `PROJECT.md`. This is the first screen that takes input, so it is
the first screen where any of them can be broken by adding a field rather than by drawing
something badly.

Tenet 4 is the one under most pressure and the one this brief spends most of its effort on.
Every field is a claim that the app cannot function without that information. Name, amount,
category, start date, interval, end date is six claims, and `INSPIRATION.md` already records
what that screen looks like when someone makes all six — the competitor's new-expense screen
is the standing counter-example in this repo, and it is an editor.

Tenet 1 is the one most easily lost by accident here, for the same reason it was on the
timeline. An editor is where a maintenance obligation gets into an app: a field that must be
kept current is a chore with a text box around it.

## Why now

The timeline shipped on 2026-09-09 and is on `main`. It was the only thing this work was
waiting on, and it is the thing that makes the gap visible — the app now demonstrates
forward visibility convincingly, using data nobody entered.

There is no engine work in this. `TillyCore` already supports every N days, weeks, months or
years from a fixed anchor, an optional end date, and per-occurrence overrides carrying an
amount, a moved date or a skip. The editor is a question about what to ask a person and how,
not about what the app can compute.

The seed also has to go, and it can only go once something else can fill the store.
`DECISIONS.md` — "History begins at the oldest charge you have entered" — already said *"the
seed changes with this work"* about the timeline; it did not, and this is where that debt
comes due.

## What "better" looks like

1. A person can enter a real recurring expense and see it on the timeline, having been asked
   for nothing the app does not need in order to work.
2. Changing an amount on something that recurs makes the scope unmistakable at the moment of
   choosing — this occurrence, or from now on. Never inferable afterwards from what happened.
3. Ending a bill stops it going forward and leaves its past intact. Deleting is a separate
   action with a visibly different meaning.
4. First run is the empty state. No invented data, ever, in a build anyone uses.
5. A future date looks like the future at the point of entry — the state grammar holds in the
   editor, not only on the timeline.
6. Nothing on the screen creates an ongoing obligation. No confirming, no marking paid, no
   field that rots if left alone.

## Prior attempts

**None.** No editor code, no branch, no revert anywhere in the history. The screen has never
been attempted. Worth stating plainly rather than leaving the section empty.

One prior *position* is being overturned, though, and it is easy to miss because it is
already built and green. `DESIGN.md`'s state grammar carries a certainty axis — estimated
versus known, marked `EST` — settled on 2026-09-07, rendered by the timeline, covered by
tests, and reachable today only because the sample seed contains estimates. The decision
below to leave variable bills out of v1 makes that axis unreachable from real input. It is
not being removed; it is being left standing with nothing able to produce it.

## Constraints

**The engine is finished and shapes the vocabulary.** A rule is interval, unit, anchor date
and optional end date. A deviation is an `OccurrenceOverride` keyed on `(expense,
scheduledDate)` carrying an actual amount, a moved date, or a skip. The editor's job is to
produce those values; it cannot ask for anything they cannot express. In particular there are
no weekday rules — "last Friday of the month" is not expressible, by a decision made at
kickoff.

**Overrides key on the scheduled date, not the visible one.** An occurrence that has already
been moved still shows at its moved date while matching an override at its original one.
Editing a moved occurrence a second time has to reach for the scheduled date, and the date on
screen is not it.

**Expenses are entered forward.** "History begins at the oldest charge you have entered"
rests on this explicitly: anchors sit at or after the point someone starts using the app, so
the history floor is normally days or weeks back. A date field that defaults to anything
earlier than the next occurrence would generate history nobody asked for and quietly
undermine that decision.

**There is no navigation.** `TimelineView()` is the root of the `WindowGroup` — no
`NavigationStack`, no tab bar. Timeline rows have no tap handler of any kind. Whatever gets a
person into the editor has to be introduced by this work.

**The bottom edge is already spent.** The return-to-this-month pill floats there and the list
reserves a bottom inset for it. An add control wants the same corner.

**Reaching an existing rule runs through its past, not its future.** History scrolls freely;
looking ahead is a deliberate unlock that puts itself away. So the reliable route to a
recurring expense is its most recent charge, which for anything monthly is a short scroll
back. The hole this leaves is named under "In and out".

**`isArchived` is the wrong instrument and is now in the way.** It exists on `Expense`,
nothing sets it, and the engine returns *no* occurrences for an archived expense — so
archiving erases a bill's past from the timeline exactly as deleting would. That is the
opposite of what ending a bill has to do. `endDate` already does the right thing and needs no
engine work. Whether `isArchived` survives at all is for the plan to settle.

**There is no category on the model.** Adding one is a schema change, and it stays
CloudKit-compatible: optional or defaulted, no unique constraints, relationships optional.

**Amounts display in whole units and may be entered with cents** — `DESIGN.md`, already
settled, not an open question.

**Views reference `Tokens`.** The timeline introduced the spacing and dimension scale; the
editor extends it rather than reaching for raw numbers.

## We'll know it worked when

`SampleData.swift` is gone from the app target and the timeline is showing a real set of
recurring expenses that were typed into it — which is the roadmap's own done-when for v1,
reached for the first time.

The softer half is not measurable and should not be dressed up as though it were: whether the
screen asks for too much is a judgement made by using it, and the honest test is whether
adding a second and third expense feels like less work than the first, or the same amount.

## In and out

**In.** Creating an expense. Editing the rule behind one. Ending a bill so it stops going
forward and keeps its past. Deleting one outright, as a separate and visibly destructive
action. Per-occurrence overrides — a different amount, a skip, a move — with the scope choice
presented at the moment of editing. Categories, created inline in the editor and nowhere
else. The schema change that category needs. An entry point on the timeline, and timeline
rows becoming tappable. Removing the sample seed.

**Explored and prototyped, but deliberately not built.** Two surfaces, and they are one
question rather than two.

*A list of every expense you have set up*, as rules rather than occurrences. It is the right
answer to reaching a bill that next charges in seven months, and it is a screen plus a
navigation model on top of an already-enlarged piece of work.

*Managing categories* — renaming, recolouring, deleting, and what happens to the expenses
still pointing at one you remove. Inline creation is what ships, but a category you can make
and never revise is a decision that hardens the moment it is typed, and designing the
creation control without knowing what revising looks like is how it gets designed wrong.

They belong in the same exploration because they are the same problem underneath: both are a
second surface, and Tilly currently has no way to reach one. Whatever navigation answers the
first answers the second, and a shell designed for one destination is the wrong shape.
`tilly-explore` designs both and keeps the prototypes; implementation waits.

*The cost of that split, stated so it is not discovered later:* an expense created with its
first occurrence far in the future and no past yet is unreachable until it charges. A typo in
a bill you have just set up for seven months' time cannot be corrected. Every other case has
a recent charge to tap.

**Out.** Variable and unknown amounts, and the estimate control that goes with them —
shelved, deliberately, and it is a change to the roadmap rather than a gap. The editor
requires an amount and offers no way to mark one as rough. Insights. Everything else the
roadmap defers, unchanged.

**Three roadmap rows move, and the roadmap should say so.** "Occurrence overrides" comes
forward into this work in full. "Categories" comes forward in full for design and in part for
implementation — the whole item is thought through here, and only inline creation is built.
And the editor row's own line *"Amount optional so variable bills fit"* stops being true: the
capability goes to a later version. Variable bills are worth thinking harder about than a
checkbox on an amount field — that is the reason for the deferral, not that they are
unimportant.

## Open questions

These gate exploration.

1. **What is genuinely required to save?** Removing variable amounts pushed the field count
   *up*, not down — amount is now mandatory where it was optional. Is a name required? Is
   there a version of this screen where one field is enough and the rest are defaults you can
   walk past?
2. **Where does the add control live**, given the return pill already occupies the bottom
   corner and the list reserves inset for it?
3. **What does tapping a timeline row open** — the occurrence, or the rule with the
   occurrence's scope on offer? The decision that the choice is presented does not say at
   what moment it appears.
4. **Does the scope choice come before or after the edit?** "Change this, then tell me what it
   applied to" and "tell me what you're changing, then change it" are both unmistakable at the
   moment of choosing. They are very different screens.
5. **How does a category get created without becoming a second screen** — and what does the
   timeline's reserved icon slot render for an expense with no category, now that categories
   exist but still ship empty?
6. **What does revising a category look like**, even though it is not being built? Renaming,
   recolouring, removing, and what becomes of the expenses still pointing at a category that
   is gone. The answer constrains the creation control that *is* being built — a category
   made of a name alone is a different control from one that also carries a colour and an
   icon.
7. **What navigation serves two second surfaces?** The expenses list and category management
   both need one, neither is being built, and designing a shell around a single destination
   is how it comes out the wrong shape.
8. **What does ending a bill ask for?** A date, or "from now"? Cancelling mid-cycle and
   cancelling at next renewal are different, and only one of them is a single tap.
9. **Confirm the reading of "no variable bills for now":** the editor requires an amount and
   has no estimate control, while `amount: Decimal?`, `isEstimate` and the timeline's `EST`
   rendering all stay exactly as they are — intact, tested, and unreachable from real input
   until variable bills return. Nothing is deleted on the strength of a deferral.

## Sources

- `docs/PROJECT.md` — tenets 1–4; v1 scope.
- `docs/ROADMAP.md` — the editor row, the overrides row, the categories row; v1 done-when.
- `docs/DECISIONS.md` — "Estimates are marked, not approximated" (2026-09-07), which hands
  the estimate question to this screen by name; "A moved occurrence leaves no trace at its
  original date" (2026-09-07), which hands it the scope question; "History begins at the
  oldest charge you have entered" (2026-09-08), for entered-forward and the seed;
  "Occurrences are computed, never stored", "Past charges are assumed, not confirmed",
  "Categories ship empty", "Recurrence is every N units from a fixed anchor" (all 2026-09-04);
  "The timeline row reserves a leading slot for a category icon" (2026-09-07). Supersession
  markers checked — all live.
- `docs/DESIGN.md` — copy rules, state grammar, "This occurrence vs. all future", empty states.
- `docs/INSPIRATION.md` — "The new-transaction screen asks for almost nothing"; "A future date
  looks different from a past one, at the point of entry"; "Everything is labelled, including
  the obvious"; "Categories you cannot create".
- `docs/briefs/timeline/brief.md` — for the shape of the previous brief.
- Code: `Tilly/Models/Expense.swift`, `OverrideRecord.swift`, `SampleData.swift`,
  `TillyStore.swift`; `Tilly/TillyApp.swift`; `Tilly/Timeline/TimelineView.swift`,
  `TimelineFloor.swift`, `TimelineEmptyState.swift`, `TimelineFormatting.swift`,
  `LatestButton.swift`; `Core/Sources/TillyCore/`.
- `git log --oneline -20`, and `git log --all` filtered for editor paths — no prior attempt.
