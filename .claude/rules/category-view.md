---
paths:
  - "Tilly/Categories/**"
  - "Tilly/Shell/**"
  - "Tilly/Settings/**"
  - "Tilly/Editor/NewCategoryRow.swift"
  - "Tilly/Editor/ExpenseEditor.swift"
  - "Tilly/Timeline/MonthHeader.swift"
---

# The category view, the shell and categories

Learned in the Simulator (iPhone 17, iOS 27), invisible to tests.

## The header row

- **Name over figure fits the 60pt row** at the default size, 60.00pt measured; a taller header
  moves every scroll anchor. The accessibility size keeps its own branch (104.33pt). The standard
  branch needs `.frame(maxWidth: .infinity, alignment: .leading)`, or the pinned ground stops
  short of full width.
- **Beside the arrows and the glass pair the header keeps 134pt** (402 − 20 − 248). A `fixedSize`
  figure wider than that widened the whole screen past both edges. Each line holds to one,
  shrinking to 0.8, then truncating a category's name, never its total.

## Layers and gestures

- **An overlay inside the category view draws beneath the shell's glass controls**, which are a
  later overlay on the shell. The readout rides `CategoryReadoutKey` up to the shell and is drawn
  by `overlayPreferenceValue` after them. The same key tells the shell's controls to step aside.
- **Glass on glass reads as a pile.** While dragging, the header's name, figure and controls fade
  out and the readout takes their row. The bottom row stays: hiding it felt wrong on a phone.
- **A `DragGesture(minimumDistance: 0)` inside a scrolling `ScrollView` still lets a vertical
  swipe scroll**, and a sideways drag still reads. When the scroll view takes the touch,
  `onEnded` never runs; `@GestureState` resets regardless, so clear the line from its change.
- **Don't start a touch's clock from `onChange` of gesture state.** It lands a view update after
  `onEnded` cleared it, and the next tap read as a hold. Set it in the first `onChanged`; clear it
  in `onEnded` and on the state reset.

## Settings and the editor

- **A `List`'s `.onMove` reorders by long-press drag outside edit mode.** No Edit button.
- **A `Menu` draws an SF Symbol in one ink, whatever its `foregroundStyle`.** A colour swatch in a
  menu needs the colour in the image: `Tokens.CategoryColour.menuSwatch`, `.alwaysOriginal`.
- **A 44pt minimum height on a list row's trailing control makes the row taller** (52 → 74pt).
  Give it the minimum width only; the row already clears 44pt.
- **While a category is made, the amount and name hold their resting inset**, drawn with
  `.offset` so their space can't depend on where they're drawn, and rise only by the shortfall:
  0pt under the name keyboard, 20pt under the emoji keyboard, which is taller. That 20pt breaks
  "never moves" and is open (`ROADMAP.md`).

## Formatting

- **`DateFormatter.doesRelativeDateFormatting` measures from the real clock**, not an injected
  `today`. Feed the day count to `RelativeDateTimeFormatter` (`.named`, `.beginningOfSentence`).
- A quiet category's next date is its first charge after the month shown; one whose only charge
  this month is skipped is quiet; the lane without a category is "No category".
