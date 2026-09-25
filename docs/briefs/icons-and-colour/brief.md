# Icons and colour

How Tilly draws a category's picture and its colour, and through them, what the app feels like.

## Problem

Tilly is meant to feel hand-drawn: handwriting, paper, rough lines, imperfections. Today only the
app icon does. Everything a person looks at inside the app is stock: the category is a system emoji
(Apple's glossy, lit, three-dimensional artwork), sitting in a grey well on the timeline and a flat
fill in the lanes and Settings. The icon is the biggest single lever on that feeling, because every
timeline row, every lane and every row of the category picker leads with one. Colour is part of the
same question: the eight tokens are flat fills, tuned for telling dots apart, with no material to them.

Two pieces of the current app are explicitly waiting on this work:

- The timeline's icon wells are grey (`DESIGN.md`, "The category view": "the timeline's wells stay
  grey for now").
- `DECISIONS.md`, "Every expense has a category…", says to revisit "when icons are explored as an
  alternative to emoji; the pairing with a colour stays."

This is a direction for the app's character, not a component choice.

## Which tenets are at stake

- **4, never prescriptive.** The constraint most likely to kill a direction. The user makes every
  category and chooses its picture; a starter set and a curated emoji grid were both rejected as
  weaker than the keyboard's search. Any direction that limits what a person can pick to what Tilly
  has drawn has to answer "what about the category I thought of that you didn't?"
- **2, minimal for hierarchy's sake.** The icon is context, the amount is the point. A richer
  picture must not outshout the figure beside it. An upcoming row's icon sits back at secondary
  weight; whatever draws the icon has to be able to sit back too.
- **5, free forever.** Rules out any icon set or service that is paid per user, and any generation
  that costs money per category.
- **1, a system that helps.** A direction that makes making a category into an art project (draw it,
  wait for it, pick from four candidates) adds work to the one required step that already has most.

Principles leaned on or strained, from `TASTE.md`:

- **11, stock platform first, behind a seam.** A hand-drawn look strains this *on purpose*. Where it
  strains, and what that costs, is part of every direction's write-up.
- **8, different kinds of thing never share a look.** Drawn things are content; glass is controls.
  A hand-drawn look belongs to content (icons, dots, rules) and should not reach the glass buttons.
- **5, a mark that looks the same everywhere says nothing.** Roughness applied uniformly becomes
  texture, not meaning. Imperfection should vary, not be one filter over everything.
- **1, the app never claims what it doesn't know.** Relevant to AI-generated pictures: a picture
  the user didn't choose is Tilly's guess about what "Home" looks like.

## Why now

The lanes shipped with colour and the timeline still has grey wells. Before the timeline gains colour
(or the wells change at all), the look of an icon and its colour should be settled together, or the
wells get filled twice. The app icon is also hand-drawn "for now" and is the only artefact of the
intended character so far.

## What "better" looks like

1. A person can make a category for anything they can think of, in about the time the emoji keyboard
   takes now, without leaving the editor.
2. The icon reads at every size it appears: 15-30pt in a lane that has shrunk to 30pt, 40pt in the
   timeline's well (44pt at accessibility sizes), the picker row, and, as a family, the app icon.
3. An upcoming row's icon can sit back and a charged row's come forward, as the state grammar needs.
4. Light and dark both look intended, not inverted: ink on paper in the light, something honest in the dark.
5. The eight colours stay separable in both modes and for colour-blind readers, checked the same way
   they are now (the dataviz validator, 2026-09-24), after any paper-and-ink treatment is applied.
6. It is buildable and maintainable by one person, with licences that fit GPL-3.0 plus the App Store exception.

## Prior attempts

- **Categories as emoji from the system keyboard**, decided 2026-09-19. Rejected then: a starter set,
  a custom emoji grid, an optional category.
- **Colour taken from the emoji**, rejected 2026-09-24: 🏠 and 🚗 land on orange and red, ΔE 7.1,
  too close as dots. Relevant to any direction that derives colour rather than asking for it.
- **Colour assigned by Tilly in creation order**, proposed and overruled 2026-09-24: a colour the
  user didn't pick means nothing to them. Colour is required and chosen.
- **An emoji-list sheet instead of the keyboard** was floated during views work and parked, not
  rejected, because the emoji keyboard's height pushes the editor's amount up 20pt. Any direction
  that changes how a picture is picked can revisit it, but "nothing stacks a second sheet over the
  editor" holds.
- **The app icon** (`b3ba8b6`, "tilly gets a hand-drawn icon, for now"): a lowercase "tilly" in a
  thick, slightly ragged felt-tip, on warm off-white paper with a faint grain, a swash underline from
  the y. It is the only reference for Tilly's hand that exists.
- `git log` shows no earlier icon or colour exploration beyond the eight-colour tokens (`ce50e5b`,
  `4b5af86`).

## Constraints

**Data.** A category stores `emoji: String`, `colourRaw: String`, `name`, `sortOrder`. SwiftData,
CloudKit-shaped: any new field is optional or defaulted, and a stored drawing would be `Data`.
Anything keyed on the emoji string keeps existing categories working with no migration.

**Sizes today** (`Tokens`): row well 40pt, radius 10 (44 and 12 at accessibility sizes), emoji
`.title2`; lane emoji follows lane height, 30-60pt, in a 40pt column; new-category slot 48pt; swatch 22pt.

**Seam.** Views reference `Tokens`, never raw values. A drawn icon means a view that renders "the
category's picture" behind one component, so every direction is swappable later. Rendering belongs
in the app target; `Core/` never sees it.

**Licences.** Checked 2026-09-25 against GPL-3.0 with the App Store exception. The exception is a
permission from Tilly's own copyright holders; it cannot cover anyone else's assets, so a bundled
set has to permit App Store distribution under its own terms.

| Source | Licence | Fits? |
|---|---|---|
| SF Symbols | Apple's, UI on Apple platforms only; not in app icons or logos | At runtime, yes. Exported or redrawn symbol paths in a public GPL repo, no: they aren't Tilly's to relicense |
| Phosphor, Lucide, Tabler, Iconoir | MIT / ISC | Yes |
| Doodle Icons (Khushmeen Sidhu), ~400 hand-drawn | CC0 | Yes, cleanest hand-drawn option found |
| Streamline Freehand and similar premium hand-drawn sets | Commercial, no redistribution | No: the source is public |
| Microsoft Fluent Emoji (flat, colour, 3D, high-contrast) | MIT | Yes |
| Noto Emoji monochrome variable font | OFL 1.1 (font), Apache 2.0 (images) | Yes |
| OpenMoji (colour and black line art) | CC BY-SA 4.0 | Risky: the licence forbids adding technical measures (App Store DRM), the same conflict the exception exists to solve, and we can't grant it for them |
| Twemoji graphics | CC BY 4.0 | Same DRM clause; used widely in apps, but not provably clean |
| Handwriting fonts (Caveat, Patrick Hand, Kalam…) | OFL 1.1 | Yes |
| On-device generation (Image Playground `ImageCreator`) | Apple's; output is the user's | Yes, but Apple Intelligence devices only |

These are licence readings, not legal advice; the risky rows would need a proper check before shipping.

**Platform.** iOS 26, SwiftUI. Rough strokes can be drawn at runtime (`Canvas`, `Path` with
seeded noise) or in Metal via `.distortionEffect`/`.layerEffect`, which works on any view, SF
Symbols and emoji included. PencilKit gives finger drawing stored as `PKDrawing` data. Genmoji
arrive as `NSAdaptiveImageGlyph`, not as a `String`, so the current emoji field can't hold one.

**Scope.** Jake owns the full design system pass. This work settles icons and colour only; it
doesn't propose a type scale, spacing or components, and the glass controls stay stock.

## We'll know it worked when

Not measurable in numbers. It worked when Jake opens the app on his phone and the timeline reads as
one hand, the same one that drew the app icon, and making a new category still takes seconds and
never makes him settle for a picture that isn't what he meant. Secondary checks: the validator passes
on the treated colours; every size from 15pt to the app icon is screenshotted in light, dark and
an accessibility size.

## In and out

**In:** what a category's picture is and how it's drawn; how a new one is made; how the colour is
rendered (fill, wash, pencil, marker, ink); the timeline's well; the lane's leading icon; the
category picker and new-category row; Settings' category list; motion on the icon itself (draw-on,
boil, a wobble on tap); how the icon family relates to the app icon.

**Out:** type scale, spacing, component system (Jake's pass); renaming, re-emoji-ing and deleting
categories in Settings (not designed yet, though a chosen direction must leave room for "change the
picture"); the glass controls; paper texture on the page ground beyond what's needed to judge an
icon on it; a new app icon.

## Open questions

These gate narrowing, not exploring. The canvas should show enough to answer them.

1. **How literal is "hand-drawn"?** Rough and imperfect but clearly designed (a drawn set), or
   genuinely made by a hand, the user's (drawing their own)? The two lead to different apps.
2. **Does the emoji keyboard's search survive?** Most hand-drawn directions keep it as the way to
   *choose* and change only how the choice is *drawn*. Is that the right split, or is choosing from
   Tilly's own set acceptable if the set is big enough?
3. **What happens to an emoji Tilly has no drawing for?** Fall back to the system emoji, a letter, a
   handwritten name? A mixed row is the likeliest failure of any mapped set.
4. **Does colour move onto the timeline** once the look is settled, as the wells' fill, the icon's
   ink, or not at all?
5. **Dark mode:** chalk on a blackboard, ink on dark paper, or the light look inverted?
6. **Motion:** is a line boil charming or tiring in a list you read every day? Should it run always,
   on appear, or only on touch?

## Sources

- `CLAUDE.md`, `docs/PROJECT.md` (tenets 1, 2, 4, 5), `docs/TASTE.md` (1, 5, 8, 11),
  `docs/DESIGN.md` ("The row", "The category view", "Pickers open where the keypad was"),
  `docs/DECISIONS.md` ("Every expense has a category…", "Stock SwiftUI in v1, behind a token layer",
  "Tilly is GPL-3.0…"), `docs/ROADMAP.md` (v2 design system pass), `docs/INSPIRATION.md`.
- `Tilly/DesignSystem/Tokens.swift` (sizes, `CategoryColour`), `Tilly/Models/ExpenseCategory.swift`,
  `Tilly/Timeline/OccurrenceRow.swift`, the app icon.
- Commits `b3ba8b6`, `ce50e5b`, `4b5af86`.
- Licences, read 2026-09-25: Fluent Emoji `LICENSE` (MIT); khushmeen.com/icons.html (Doodle Icons,
  CC0); openmoji.org/faq (CC BY-SA 4.0); github.com/googlefonts/noto-emoji (OFL 1.1, Apache 2.0);
  Apple SF Symbols licence terms as reported on developer forums; Apple `ImageCreator` documentation.
