---
paths:
  - "Tilly/DesignSystem/Drawn/**"
  - "Tilly/Timeline/OccurrenceRow.swift"
  - "Tilly/Timeline/RowBadge.swift"
  - "Tilly/Timeline/TodayDivider.swift"
  - "Tilly/Editor/CategoryGrid.swift"
  - "Tilly/Editor/EditorCard.swift"
---

# The Drawn look, carried from a prototype

Learned matching `dashed-and-solid.html` 1:1, invisible to tests. The prototype's values live in
`Tokens` with comments; these are the traps behind them.

## Comparing

- **Crop the same element from the prototype and the Simulator at 3x, side by side**, before
  calling it done. Where a plan's numbers and the prototype disagree, build the prototype.
- **Render the prototype in the Simulator's Safari**, not desktop Chromium, which draws text
  heavier and misleads on weight. Served locally it needs a viewport meta prepended.
- **Measure an icon's ink, not its frame.** SF Symbols differ in width and carry padding: a game
  controller set as 17pt type ran 24pt across where the prototype's glyph spans 19. The round
  picture fits each symbol whole in a square (`resizable().scaledToFit()`), so none outgrows the rest.

## SVG filters, translated

- `feDisplacementMap` moves a point by `scale × (noise − 0.5)`: scale 5 is at most 2.5pt.
- `washF`'s grain mask keeps each pixel at `1.62 − 1.6 × noise`, about a point across and soft:
  `Grain.speckle` at one pixel per point, medium interpolation. At the screen's pixel it read
  as fine sand, not chalk.
- A roughened symbol at `sfR`'s 1.3 stays an even stroke; the rounded well's 1.8 bent the arcs.
- The prototype's drawn glyphs (the row badge's loop and arrow) are ours: draw them as `Shape`s
  from its paths (`BadgeGlyph`). SF Symbols' nearest read heavier and wider. Category pictures stay
  SF Symbols; the prototype's are stand-ins.

## Building

- **A `Shape` that reads `Tokens.Size` won't build**: main-actor isolation crosses into `Shape`.
  Pass the sizes in (`Squiggle`), or read `nonisolated` `Tokens.Drawn`.
- Shadows the prototype draws with `html:not(.dark)` are light-mode only: clear them in dark.
