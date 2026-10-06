# Adding an expense, revisited

## Problem

Adding an expense works, but it has no flow. Jake used it on his iPhone and describes it this way:
after typing the amount, the next step isn't obvious. The name, maybe? Then the date, then the
category, then the repeat, in whatever order the eye happens to land. It feels demanding, and most
of all for someone new.

The screen does ask for little. Date and repeat come filled in as today and monthly, so only the
amount, the name and a category must be supplied. But nothing on the screen says so. The three
buttons under the name look equally unfinished whether they hold a default or wait for an answer,
so a person reads five questions where there are three. Nothing leads from one to the next: after
the amount, the keypad has no key that moves on, and the name is a faint line to find and tap. Its
return key says Done, and leaves you there.

The heaviest moment is the first expense. With no categories yet, the category button opens an
empty list whose only row is `New category`. That opens the emoji keyboard, then asks for a name,
then shows a colour. So adding a first bill means making a first category inside it, three
choices deep, before ✓ will light up. Someone who opened the app to write down one bill is asked to
design a filing system first.

Every later bill is lighter, but no smarter. The app knows the categories you have, which ones you
used last, and the name you just typed, and uses none of it. Choosing a category is always the same
full list behind a button, as if this were the first time. Adding is rare, since bills are set and
forgotten. That makes it matter more, not less: nobody gets practised at a flow they meet a few
times a year, so each time has to feel easy on its own.

## Which tenets are at stake

- **1:** a first entry that feels like setting up is a small obligation before any payoff.
- **2:** the amount is the screen, but once it's typed nothing says what matters next.
- **3:** the buttons are unlabelled, which is right, but a button showing a default and one
  waiting for an answer look alike, so the hierarchy stops explaining.
- **4:** this brief opens it on purpose. Jake has asked for the exploration to question what the
  first save needs, category included. If a direction wins that makes the category optional at
  entry, tenet 4's minimum gets rewritten, and "Every expense has a category, and a category is an emoji, a name and a colour" in `DECISIONS.md`
  with it.

## Why now

The editor shipped on 2026-09-23, and this is the first verdict from using it on a phone rather
than from drawings. The earlier rounds settled the look of each control one at a time. The path
through them was never designed as a path, and it only shows up in the hand. Categories, colours
and the lanes view have landed since, so the parts that entry has to feed are now fixed.

## What "better" looks like

1. After each step, the next one is obvious without reading anything.
2. A new person can add a first bill, with no categories yet, without it feeling like setup.
3. Values the app has already chosen (today, monthly) read as chosen, not as waiting.
4. A typical bill, amount, name and category with the defaults left alone, takes no more taps
   than today, and ideally fewer.
5. Whatever changes, the settled parts still hold: the amount is the screen, pickers open where the
   keypad was, and ✓ saves.
6. With categories already there, the app thinks ahead: the likely category is one tap or none,
   and a suggestion is easy to ignore and never wrong in a way that sticks.
7. It stays interruptible (TASTE 12). Guiding someone forward never traps them in a sequence they
   can't leave or jump around.

## Prior attempts

- **`docs/briefs/expense-editor/brief.md`** scoped the first build. Its open question 1 was this
  one: "Is there a version of this screen where one field is enough and the rest are defaults you
  can walk past?" It was answered with a single screen of required fields and defaults, and never
  revisited as a flow.
- **The 2026-09-15 prototype** (`docs/prototypes/expense-editor.html`) proposed one question at a
  time, a walkthrough. Jake set it aside for his own sketch of a single screen, with pickers in
  place of the keypad. That rejection is evidence to weigh, not a verdict on every guided flow: it
  lost to a drawing before either had been used on a phone.
- **Round 7, on device**, moved Save from a full-width bottom button to ✓ top right, because using
  the screen beat drawing it. The same may apply here.
- **The "view first" page** (`docs/prototypes/expense-editor-entry.html`) is about opening an
  existing charge and is out of scope, though it shares this sheet.
- No code reverts on the editor. Its history is the build plus fixes to how fast it answers a tap.

## Constraints

- **Same data.** Amount, name, category, date, repeat (interval, unit, and an end as a payment
  count). No new fields. What's required, and in what order and with what defaults it's asked, are
  open.
- **The engine and model don't change for a flow change.** A category that's optional at entry
  would be a schema change (`Expense.category` is set on every bill today) and would give the
  timeline row and the lanes view a case they don't have. Any direction that goes there has to
  say what those show.
- **Editing inherits.** Opening an existing charge keeps its behaviour: this charge or future
  charges, delete, and the keypad up on opening. It takes on whatever look the add flow lands on,
  so a direction that can't also hold a filled-in bill is a weaker direction.
- **The system emoji keyboard** is how a category gets its emoji (`DECISIONS.md`), and it covers
  the lower half of the sheet. The open 20pt lift of the amount while making a category is this
  flow's bug to settle or design out.
- **Stock SwiftUI behind `Tokens`** (TASTE 11). Where a direction needs custom motion or a custom
  keyboard, it names the cost.
- **Suggestions are conceptual here.** Where one comes from (recency, matching a name against past
  bills, or Apple's on-device Foundation Models) is for a later discussion. Exploration designs how a
  suggestion looks, is accepted and is ignored, and how the screen behaves when there's no
  suggestion. Whatever supplies them has to be on-device and free (tenet 5), and has to cope with
  devices that can't run a model.
- **Accessibility sizes** have to hold. Today's three buttons stack there.

## We'll know it worked when

This can't be measured, so it isn't dressed up as a number. The test is Jake's phone: he adds a
bill from an empty app, then a second and a third, and at no point hesitates over what comes next.
A secondary check is tap counts for a first bill and for a typical later one, written down for
each direction so they can be compared.

## In and out

**In.** Adding an expense, from + to ✓: order, defaults, guidance, how each step hands on to the
next, and making a category during entry. Whether the category is required at the first save.
Entry with categories already there: recent categories offered in place (a row of chips, say), and a
category suggested from the name.
Directions compared in a working prototype, since the complaint is about feel.

**Out.** Choosing and building a suggestion engine, Foundation Models included. New data or fields. Variable bills and the "view first" page (v1.1). Editing's scope
choice and delete. Settings and managing categories. The category view. Undo.

## Open questions

These gate exploration.

1. **Is the first category a step in the first bill, or something that follows it?** The biggest
   lever, and it's the one tenet 4 currently answers.
2. **Should the screen lead from one step to the next, or lay everything out and make the defaults
   read as done?** A walkthrough lost once, on paper.
3. **What does the keypad hand on to?** Something has to happen after the amount, whether that's
   a return key, the name taking focus, or a next step appearing.
4. **Does a second bill get the same path as the first?** A person with ten categories and a
   person with none may want different screens.
5. **How far does thinking ahead go?** Recent categories are shown, and the likely category from
   the name is suggested. Does it go as far as filling it in? The same question could apply to
   amount and repeat for a name seen before. A suggestion that fills a field has to look filled
   by the app, and be as easy to change as one you chose.
6. **Jake's own ideas.** He has some and they aren't concrete yet. Exploration should draw them out
   early rather than present a finished set.

## Sources

- `docs/PROJECT.md`, tenets 1–4. `docs/TASTE.md` 2, 9, 11, 12.
- `docs/DESIGN.md`, "The editor" and "Empty states".
- `docs/DECISIONS.md`: "Every expense has a category, and a category is an emoji, a name and a colour", "Editing a charge is
  Calendar's".
- `docs/ROADMAP.md`: the editor row, with the open 20pt lift; v1.1's "Viewing a charge before
  editing it".
- `docs/INSPIRATION.md`: "The new-transaction screen asks for almost nothing".
- `docs/briefs/expense-editor/brief.md`.
- Code: `Tilly/Editor/ExpenseEditor.swift`, `ExpenseDraft.swift` (defaults today and monthly),
  `CategoryPicker.swift`, `NewCategoryRow.swift`, `EditorButtonRow.swift`.
- `git log` on `Tilly/Editor/` from `60da59a` to `4b5af86`: no reverts.

## Updates

### 2026-10-04 · From a form to a card you complete

Two canvas rounds (https://claude.ai/artifact/A8CUNvsPrYMjek5S2a64Rm) and a working prototype
(`docs/prototypes/edit-revisit.html`) tried to make the form lead better: one screen that leads,
one step at a time, name first, the bill as a sentence, and one button that never moves. What
held up: a single primary action that stays in one place, a real date rather than "today", and
guessing the category from the name. What didn't: every version still reads as filling out a
form. Steppers feel constricted, and a next action that moves leaves no clear thing to press.

The exploration now turns to **the card as input**. Adding a bill greets you with a card. The
amount starts at 0, and the other fields are drawn as incomplete (dotted outlines, say), so the
card itself shows what's left and invites you to finish it. Its information hierarchy comes
first. Its look comes later, with the design pass.

Two follow-ons, each explored after the card settles:

- **Filing as a gesture.** Instead of picking a category from a list, the finished card is
  dragged into one of a set of folders or pockets, where filed cards stack visibly.
- **Landing in the list.** Adding plays an animation of the bill arriving in the timeline: a
  slam like iMessage's, or a slide that ripples the rows around it. It never holds up the next
  tap (TASTE 12).

New open questions:

1. What does the card show empty, half done and complete, and what leads?
2. Does the category stay a field on the card, or become only the act of filing it?
3. How does the folder gesture work for a first bill, with no folders yet?

### 2026-10-06 · The ending, and what you see is what you get

Canvas rounds 3 to 7 and a working prototype (`docs/prototypes/edit-revisit-card.html`) took the card
wide: playful cards, physical behaviours, a hand of category cards, and filing the card into category
pockets. What held up:

- The card is the input. Dashed means a part still needs you. A small pencil means it's filled in and
  yours to change.
- Choosing the category is the most important act, because it decides where the bill goes, so it can't
  look like one more field. When filing into a pocket was also the save, nothing said it was final.
- What you see is what you get wins. The card shows its category, colour included, before ✓ saves, and
  filing into the pocket afterwards is feedback rather than input. Of the three endings tried, the one
  where you play a category onto the card and ✓ files it (P2) is the strongest. Picking a pocket to
  preview it (P3) is close behind. Filing as the save itself (P1) is still on the table.
- Pockets that hold the bills already filed in them are a strong concept.

The next revision mixes and matches rather than adding fixed variants: the card's layout and the size of
each part, ways to show the date and repeat, how the card is presented, how pockets show what they
hold, how categories are offered for picking, and how all of that holds with 1 category or 20.
