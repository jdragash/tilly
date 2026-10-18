# The card's motion: the hand, the landing, opening a bill

The bill's card moves between the sheet and the timeline the way Jake settled it in the combined
prototype. The second of three pieces building that prototype: the look (`drawn-timeline`) is built,
All bills as folders follows. This one is everything that moves.

## Problem

The built editor still files the card into a pocket and closes, and a row opens its card by a plain
sheet rising. Neither is what Jake settled on 2026-10-18 in `docs/prototypes/combined.html`
(settled state read the same day):

- **Entry: the hand.** The categories are a fan of drawn cards under the card. Pressing one lifts
  it; letting go plays it: it flies onto the card's picture tile and shrinks into it, the colour
  floods out from the tile, the picture stamps, the card dips, one firm haptic. `New` is the last
  card in the hand.
- **Landing: Card leads, with a flip.** On ✓ the sheet drops away from under the card (soft: its
  contents fade first and it drops a little slower, 0.55s), the card turns over in place (0.4s) to
  its back, which is the bill as the stack will draw it, rests a beat (0.15s), then drops into its
  row (0.45s, bounce 0.3) as the rows below open a gap for it. The month's figure rolls to its new
  total. A bill landing off screen has the list jump, behind the sheet, to put its row in view first.
  A charged bill never flips: there is nothing to turn over to, so it goes straight down.
- **Opening a bill: Flip back.** Tapping a row lifts its card into the sheet's place as the sheet
  rises (0.4s, bounce 0.3). One still to come arrives as its dotted outline and turns over to the
  solid card; a charged one fills with its colour as it arrives and never flips. ✓ or ✕ sends it
  back to its row by the landing above.

Everything else in the prototype's sidebar lost and stays out.

## Which tenets are at stake

- **1, a system that helps:** the hand must not make picking a category slower than a pocket.
- **2, minimal for hierarchy:** the landing ends on the row, so the reader sees where the bill went
  without a toast saying so.
- **3, self-evident over labelled:** the flip says "this is what it becomes in the list". If it needs
  a caption, it failed.

From `TASTE.md`: leans on **2** (the row the card lands in opens without moving the rows under the
reader's eyes), **12** (every control answers the tap it gets, even mid-motion) and **4** (nothing
changes for a reason the reader can't see: the jump to an off-screen row happens behind the sheet,
before the card leaves). Jake's correction behind the beat (memory, 2026-10-18): each stage of a
motion has to read on its own, so turning over and dropping are two things, not one.

## Why now

The look is built, and the motion was settled in the same session. All bills as folders reuses the
card's flight, so it waits on this.

## What "better" looks like

1. On ✓ you can follow the card from the sheet into its row, and the turn and the drop each read.
2. Opening a row and closing it again ends with that row exactly where it was, at the point.
3. Playing a category from the hand takes no longer than tapping a pocket did: one press, one release.
4. A tap at any moment of a motion is answered at once (TASTE 12): ✓ mid-flip still saves, a tap on
   the list mid-landing finishes the landing.
5. Every duration, bounce, hold and offset is a token, and Jake can change them on the phone, live,
   from a debug panel, without a rebuild.
6. Reduce Motion fades instead, everywhere, as the prototype does.

## Prior attempts

- **`DECISIONS.md`, "Adding a bill is a card you complete, and the pockets pick its category":**
  rejected playing a category from a fanned hand (P2) because it was a second set of category cards
  beside the pockets the bill landed in. What is new: with Card leads the bill lands in the timeline,
  not a pocket, so the hand is the only set. Its "revisit when Tilly, Drawn arrives" has arrived.
- **`DECISIONS.md`, "Views switch in place…, and everything else is a sheet":** a system sheet is
  presented above the timeline in its own layer, so nothing can fly out of it into a row. The card's
  flight needs the editor and the timeline in one hierarchy (see Constraints).
- **`card-polish`** (branch, `811fdd6`..`8c757e0`, not merged): briefed the card's springs and press
  feedback from Jake's first use on device, with the tilly-video's values as the feel, and pockets
  under the card. The pockets, and filing into them, are gone with the hand. Its device fixes (the
  name field moving, backspace erasing the name, the amount's size and spacing, the date and repeat's
  44pt targets) are not motion; see open question 2.
- **The filing built in v0.6.0** (`c2bb596`) files the card "as one picture, by a measured scale and
  offset, not `matchedGeometryEffect`", because matching frames re-lays the card out at the target's
  size (`.claude/rules/editor.md`). The same holds for the card shrinking into a row.
- **Timing in the app, not the prototype:** Jake chose to tune timing and transitions on the phone
  (2026-10-18). The prototype's values are the first guess, not the answer.

## Constraints

- **The sheet.** The editor is a `.sheet` today. The flight needs a sheet the app draws itself, in
  the same hierarchy as the timeline, or an overlay layer above both that the card is handed to.
  Either way the sheet keeps its detents, its drag to dismiss and the keyboard rules in
  `.claude/rules/editor.md` and `swiftui-controls.md`. This reopens the "everything else is a sheet"
  decision for the editor only; All bills and Settings stay system sheets.
- **The landing is scroll-anchored.** The row's gap opens beneath a pinned month header, the list may
  jump to an off-screen row, and the reader's place must hold to the point (TASTE 2,
  `.claude/rules/swiftui-scrolling.md`). Those steps are Opus's (`CLAUDE.md`, model routing).
- **The prototype lies:** its flip is CSS `rotateY` with `backface-visibility`; its springs are its
  own, not SwiftUI's; its hand is DOM cards. In the app the turn is `rotation3DEffect` with the face
  swapped at 90°, springs are `.spring(duration:bounce:)`, and the hand is drawn with the step 3
  `CategoryPictureView`.
- **The card in the sheet is the editor card**; its back is the timeline row's own view, drawn at
  the card's size, so the stack's look is reused rather than redrawn.
- **The month and year:** if the calendar's month or year is showing, the sheet closes and the
  charge drops into its day (from 48pt, 0.45s, bounce 0.3) as the prototype does, with no card flight.
- **Debug only:** the tuning panel is `#if DEBUG`, in Settings' Developer section, and edits the
  tokens' live values in memory. Copying a tuned value into `Tokens.swift` is a commit.

## We'll know it worked when

Jake adds a bill, opens one and closes it on his phone and doesn't reach for the prototype to say
what's wrong, and the values he tunes are each one token. Checked: a row opened and closed lands
within 0.5pt of where it was (measured in the Simulator), and Instruments shows no hitch over the
landing on device.

## In and out

**In:** the hand as the category picker, with `New` in it; playing a card onto the tile; Card leads
landing with its flip, hold and soft sheet exit; opening a bill by Flip back and closing it again;
the jump to an off-screen row; the figure's roll; the month and year's drop; haptics at the press,
the play, the turn and the landing; timing tokens and the debug panel; Reduce Motion.

**Out:** All bills as folders (the next brief); pockets, which go; the losing landings (fall, slam,
slide, slip, zoom, carry, highlight), the glow and the ripple; card-polish's currency question.

## Open questions

1. **How many categories does the hand hold before it crowds?** The fan tightens to fit the width.
   Default to build: it tightens down to 24pt between cards, then scrolls sideways. Ask once Jake
   has more than a dozen categories.
2. **Do card-polish's device fixes ride along?** The name field moving, backspace erasing the name,
   the amount's size and spacing, and the date and repeat targets touch the same card. Default: yes,
   as one step at the end of the plan, since nothing else schedules them.
3. **Can a landing be cut short?** Default: a tap on the list or + finishes it at once, as filing
   did, and ✓ pressed twice is ignored.

## Sources

- `docs/prototypes/combined.html` and its settled state (artifact db `flow/state`, read 2026-10-18);
  the prototype's `startCardFlip`, `openRow`, `returnRow`, `playCat`, `dressCard` and `closeSheet`.
- `docs/PROJECT.md` (tenets 1, 2, 3); `docs/TASTE.md` (2, 4, 12); `docs/DECISIONS.md` ("Adding a
  bill is a card you complete…", "Views switch in place…"); `docs/DESIGN.md` (the editor, the
  pockets); `docs/ROADMAP.md` (pockets under the card, which this replaces).
- `docs/briefs/drawn-timeline/brief.md`; `origin/card-polish:docs/briefs/card-polish/brief.md`.
- `.claude/rules/editor.md`; `Tilly/DesignSystem/Tokens.swift` (`Motion`);
  `Tilly/Developer/DeveloperSection.swift`.
- `git log`: `c2bb596` (filing into a pocket), `origin/drawn-timeline` `cb9620a`..`8724479`.
