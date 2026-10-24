# A quieter timeline, and a picker you can read

The timeline stops being a stack of full-colour cards and becomes Dashed and solid: a bill still to
come is a dashed outline, a charged one a solid paper card, both echoing the category cards. The
fanned hand gives way to a category picker whose names and symbols read at a glance. The flips and
the landing go. Designed in a new prototype first, then built on a branch from `tuning`.

## Problem

Jake used the `tuning` build on his phone (an iPhone 13 Pro) on 2026-10-21 and found three things:

- **The Wallet stack invites action.** A list of full-colour cards reads as things to tap, and a bill
  is rarely edited after it's made. The timeline is read far more than it is touched.
- **The hand can't be read.** At the phone's real size, with real categories, the fan hid every name
  and most of the symbols. It looked fine in a browser at desktop size; on the phone it failed.
- **Too much motion.** The flip into the editor, the turn and the drop on ✓ and the card's flight make
  the app feel slow. Performance is better after the tune-up, so this is about feel, not frames.

Dashed and solid already exists as a losing option in `docs/prototypes/combined.html`. Jake wants it
back as an upgrade, because a dashed row reads as "not yet" and a solid one as "done", and a row
drawn like a category card ties the timeline to the picker.

## Which tenets are at stake

- **2, minimal for hierarchy's sake.** The amount must be the first read on a row again, not the
  colour. Past and future must read apart in under a second.
- **3, self-evident over labelled.** Dashed against solid carries "to come" against "charged" with no
  word. If a row needs a legend, it failed.
- **1, a system that helps.** Picking a category must be one tap on a name you can read.

From `TASTE.md`: leans on **8** (a row is content, so it shouldn't look like a control) and **5**
(spend the colour where it distinguishes: the category, not the whole card). Strains **14** a little:
a flat list shows less shape than a stack.

## Why now

Jake tested the full card build on the phone and is pivoting before folders and the rest are built on
top of it. Every later piece (All bills as folders, the calendar's redesign) reuses the row and the
picker, so they should be right first.

## What "better" looks like

1. On the phone, without reading a word, you can tell which rows are charged and which are to come.
2. A row reads as something to read, not something to tap, in light and in dark.
3. The row and the category picker are clearly one family: the same card, picture and colour.
4. Every category's name and symbol is readable in the picker at the phone's size, with a real
   number of categories (a dozen or more), and picking one is one tap.
5. Adding and opening a bill feels instant. Any motion that's left is short and doesn't hold you up.
6. Drawn at the iPhone 13 Pro's real size (390 × 844pt) before anything is built.

## Prior attempts

- **`combined.html`, Rows:** Today, Card chip, Dashed and solid and Wallet stack. Wallet stack won on
  2026-10-18 and was built (`drawn-timeline`, `8724479`). Dashed and solid was then paper rows, a
  dashed border for to come, a solid raised card for charged, and a colour bar at the left edge.
- **`DECISIONS.md`, "Adding a bill is a card you complete, a hand of categories dresses it, and it
  lands in the timeline":** this reopens it. The hand, the flip and the landing are what's dropped;
  the card you complete and the input in the keypad's place stay. New since: the phone test.
- **Pockets** (built in v0.6.0, `51d326a`): a grid of category pockets with their bills peeking out,
  rejected once the bill landed in the timeline. Jake's "folders" is this idea returning as a picker.
- **`card-motion` and `tuning`** (branches, not merged): the hand, the flips and the landing, then
  the device tune-up and the speed fixes. They stay unmerged as reference. The new build branches
  from `tuning` to keep the paper look, the symbols, the symbol picker and the speed fixes.
- **The prototype lied before:** the fan was judged at desktop size. This round is drawn at the
  phone's size and opened on the phone.

## Constraints

- **Keep:** the Drawn look as corrected on `tuning` (paper, grain, washes, roughened symbols), a
  category's picture as a symbol, the symbol picker for a new category, the editor's card with its
  parts filled in place.
- **Drop:** the Wallet stack, the hand, the flips, the card's flight and landing.
- **Rows stay 64pt** (`Tokens.Size.stackRow`) unless the prototype shows a reason to change it.
- **The editor's sheet:** the app draws its own sheet so the card could fly. Without the flight, the
  system sheet may come back. That is the plan's call, once the motion is settled.
- **Real data:** Jake's own categories, typed into the prototype, never committed (the repo is
  public). The prototype ships with a made-up set.
- **Motion is tuned on the phone**, not in the prototype (Jake, 2026-10-18).

## We'll know it worked when

Jake opens the prototype on his phone with his own categories, picks a row and a picker without
reaching for a legend, and the built version scrolls and opens as fast as Settings does. Checked by
screenshots on the phone, in light, dark and an accessibility size.

## In and out

**In:** the timeline's row, charged and to come, in light and dark; the category picker in the
editor; what motion is left when adding, opening and closing a bill.

**Out:** All bills as folders; the calendar's month and year and the category view, which keep
their current look; the symbols' own fixes (off-centre shapes), which are their own piece; variable
bills.

## Open questions

1. **Which row?** The prototype draws three: the reference Dashed and solid, a row drawn as a
   category card, and a row whose colour lives only in its picture tile.
2. **Which picker?** A grid of category cards, folders with their bills peeking out, or a plain list.
3. **What's left of the motion?** The default: a stock sheet, the card's colour changes in a quick
   fade when a category is picked, and a saved row appears in place. No flips.
4. **What are Jake's categories?** He types them into the prototype; how many decides the grid's size.

## Sources

- Jake's on-device feedback, 2026-10-21, and the card-motion thread.
- `docs/PROJECT.md` (tenets 1, 2, 3); `docs/TASTE.md` (5, 8, 14); `docs/DESIGN.md` (state grammar,
  the timeline, the editor); `docs/DECISIONS.md` (the editor entry above).
- `docs/prototypes/combined.html` (`lk-paper`, the hand, `catPic`, `washSrc`, `outlineSrc`).
- `docs/briefs/drawn-timeline/brief.md`, `docs/briefs/card-motion/brief.md`.
- `Tilly/DesignSystem/Tokens.swift` on `tuning` (`Drawn`, `CategoryColour`, `Size.stackRow`).
- `git log`: `8724479` (the Wallet stack), `629d706` (the landing), `8088222` (the speed fixes).
