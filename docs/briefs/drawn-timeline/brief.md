# Tilly, Drawn, on the timeline

The app takes on the Drawn look Jake settled in the combined prototype, and the timeline becomes a
Wallet stack of the bills' own cards. The first of three pieces that build that prototype: this one
is the look, standing still. The motion (the hand, the card landing, opening a bill) and All bills
as folders follow as their own briefs.

## Problem

Everything inside the app is stock while the app icon, every prototype since September and the
settled direction are drawn. The timeline's wells are still grey, waiting on the icons work
(`DESIGN.md`, the category view), and colour reaches the timeline nowhere. Jake settled on
2026-10-18, in `docs/prototypes/combined.html`:

- **Skin: Drawn.** Paper with a grain, colour laid down as a wash with a rough, blooming edge,
  rounded type, no handwriting, the category drawn. The glass controls stay stock.
- **The category, drawn as I:** a symbol, roughened as it draws, boiling (three drawings swapped).
- **Timeline look: Wallet stack.** Each row is its bill's card, overlapping the one above. A
  charged bill is its card, solid, in the category's colour. One still to come is a dotted outline
  in its colour on the paper, its words set back. A card tucked under the next shows only its top
  corners rounded; the last in a month is whole.
- **Cards: colour** (not cream). **Sheet: white** (not glass).

## Which tenets are at stake

- **2, minimal for hierarchy's sake.** Full-colour cards are loud. The amount must still be the
  first read on a row, and charged versus to come must read in under a second.
- **3, self-evident over labelled.** Solid against dotted carries charged against to come with no
  word for it. If it needs a legend, it failed.
- **4, never prescriptive.** Settles what a category's picture is (open question 1). Today it is any
  emoji from the system keyboard.

From `TASTE.md`: leans on **8** (drawn things are content, glass is controls, so the glass stays
stock) and **5** (the wash and the dotted line each mean something, charged and to come, rather
than being one texture over everything). Strains **11** on purpose: this is the platform's look
replaced, not tuned.

## Why now

Jake chose to build the prototype as the app's direction, look included, rather than leave the look
for a later pass. The look goes first because the motion and All bills are drawn in it: building
them on stock would mean building them twice.

## What "better" looks like

1. The timeline reads as a stack of the bills' own cards, and a glance tells charged from to come.
2. Every category has a drawn picture, and making a category still takes seconds (open question 1).
3. Light and dark both look intended: ink on paper, and paper gone dark, never the light inverted.
4. Scrolling a year of rows is as smooth as today: the washes and grain cost nothing a person can see.
5. Every value of the look (grain, wash, edge, dot pitch, tuck, radii) is a token, so tuning it on
   the phone is a one-file change.
6. Reduce Motion stills the boil; Increase Contrast and accessibility sizes still read.

## Prior attempts

- **Icons and colour** (`docs/briefs/icons-and-colour/brief.md`, Sep 25 to Oct 1): three drawn
  directions (I, L, G) prototyped in `icons-and-type.html` and `icons-in-app.html`. Nothing was
  chosen then. This brief answers its open questions 4 (colour moves onto the timeline, as the
  card itself) and 5 (dark is paper gone dark), and settles I.
- **The reference look** is the Drawn look in `docs/prototypes/edit-revisit-card.html`, not
  `icons-and-type.html`'s handwriting (Jake, 2026-10-17).
- **Timeline looks** in `combined.html`: Card chip (colour in the well only) and Dashed and solid
  lost to Wallet stack. Jake changed the stack to a subdued dotted future and square tucked corners
  because rounded ones stopped it reading as a stack.
- **`DECISIONS.md`, "Stock SwiftUI in v1, behind a token layer":** said the design pass waits for
  v2. It arrives now, on the same seam: every value through `Tokens`.
- **`card-polish`** (branch, briefed and prototyped, nothing built): springs for the card's own
  motion. It belongs to the motion piece, not this one.

## Constraints

- **The prototype lies** about rendering: its roughening is an SVG filter, its wash a turbulence
  filter, its rounded type Nunito. In the app the roughening is a Metal `.layerEffect` or
  `.distortionEffect` on an SF Symbol at runtime, the wash a `Canvas` or shader with seeded noise,
  the type SF Pro Rounded (`.fontDesign(.rounded)`).
- **Licence:** SF Symbols may be drawn at runtime, never exported or redrawn as paths in the repo
  (`icons-and-colour/brief.md`). The prototype's glyphs are stand-ins drawn in their manner.
- **A category is an emoji today** (`ExpenseCategory.emoji`). A symbol needs a new optional,
  defaulted field to stay CloudKit-shaped.
- **A Wallet stack is a scroll-anchored list:** overlapping rows under a pinned month header, and a
  place that survives a relaunch. `.claude/rules/swiftui-scrolling.md` applies, and the steps that
  touch it are Opus's (`CLAUDE.md`, model routing).
- **Amounts stay whole** (`DESIGN.md`, Amounts): the prototype's cents are its own.
- **Every surface** the person can reach should be Drawn when this lands, or the app reads as two
  apps. The calendar's month and year and the category view take the ground, the type and the
  colours; their own redesign is not this work.

## We'll know it worked when

Not measurable in numbers. It worked when Jake scrolls the timeline on his phone and it reads as the
prototype, in both modes, without a stutter, and he can tell what's charged without reading a word.
Checked by screenshots in light, dark and an accessibility size, and Instruments' hitches on a scroll
through a year.

## In and out

**In:** the paper ground, grain and rounded type through `Tokens`; the wash and the dotted outline as
components; the category's drawn picture with its boil; the timeline's rows as a Wallet stack; the
month header on paper; the editor card's face washed, standing still; the calendar and category view
taking the ground, type and colours.

**Out:** all motion between surfaces (the hand, landing, opening a bill), which is the next piece;
All bills as folders, the piece after; the glass controls; handwriting; cream cards and the glass
sheet, which lost.

## Open questions

1. **What is a category's picture?** I is a symbol, but a category holds an emoji. Picking a symbol
   in a searchable picker is the honest version of I, and costs the emoji keyboard's search, which
   was kept over a curated grid in September. Matching an emoji to a symbol keeps the keyboard, but
   any emoji without a match shows mixed rows. This gates the build.
2. **Does the boil run always?** The prototype boils every picture all the time. In a list read every
   day it may tire. The default to build is to boil while the picture is on the editor's card and on
   touch, and to hold still in the list, unless Jake wants it always on.
3. **What does a row tucked under the next hide?** Its bottom 12 points. A bill with a long name or an
   end date must still read in the visible part at every text size.

## Sources

- `CLAUDE.md`; `docs/PROJECT.md` (tenets 2, 3, 4); `docs/TASTE.md` (5, 8, 11); `docs/DESIGN.md`
  (state grammar, the timeline, Amounts, the editor); `docs/DECISIONS.md` ("Stock SwiftUI in v1",
  "Every expense has a category", "Every charge is its own row"); `docs/ROADMAP.md` (v2 design pass,
  v1.1 calendar in the card's language).
- `docs/briefs/icons-and-colour/brief.md`; `docs/prototypes/edit-revisit-card.html`,
  `icons-in-app.html`; `docs/prototypes/combined.html` and its settled state (read 2026-10-18).
- `Tilly/Models/ExpenseCategory.swift`, `Tilly/DesignSystem/Tokens.swift`, `Tilly/Timeline/`.
- `git log`: `4030eae` (v0.6.0, the card editor), `origin/card-polish` (`811fdd6`..`8c757e0`).
