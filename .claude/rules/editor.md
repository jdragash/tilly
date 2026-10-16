---
paths:
  - "Tilly/Editor/**"
---

# The expense editor: card, keypad, pickers and fields

Learned in the Simulator, invisible to tests. General keyboard and safe-area lessons are in
`swiftui-controls.md`.

## Holding the card still

- For the keyboard to cover content rather than push it, keep what it covers in the layout
  (hidden with `opacity`, not removed), or what's above re-centres.
- **The card holds the top and the panel the bottom, with a `Spacer` between.** Where the
  keyboard pushes the sheet up (making a category), the space gives way and the card stays put
  with nothing measured. Its top edge measured the same under the keypad, the name keyboard,
  the calendar, the wheel, the category list and the emoji keyboard.

- **A shape's fill eats the taps of a button in its `.background`.** The card's background button
  is an overlay over the fill and under the parts.
- **Three 108pt pockets and two 14pt gaps are 352pt, which fits only inside the 20pt gutter.** Any
  side padding of the grid's own widens the whole sheet, card included.

## Filing the card

- **The card files as one picture, by a measured scale and offset, not `matchedGeometryEffect`.**
  Matching frames re-lays the card out at pocket size, so its type stays full size and clips. The
  target pocket reports where the card lands through `FilingTargetKey`.
- **A modifier that returns different views for "flying" and "resting" doesn't animate**; it swaps
  views. Keep one view and vary its values.

## Pickers and menus

- A wheel `Picker`'s natural width is unbounded: `fixedSize` on one widens the whole layout. Give
  narrow wheels explicit widths.
- A `confirmationDialog`'s button ran only once its closing transition finished, 1.1s after it
  had visibly gone (measured), and couldn't be dismissed mid-open. A `Menu` acts on the tap
  itself; style it `.buttonBorderShape(.circle)` with `sharedBackgroundVisibility(.hidden)` on
  its toolbar item, or the toolbar draws a second glass circle around it.

## Focus and UIKit fields

- **iOS 27 draws `.next` as a chevron and `.done` as a ✓ on the Return key.** The name's label
  reads the next part besides the name; `CardProgress.next(after:)` wraps round to the part it
  started from.
- SwiftUI drops a `TextField`'s focus after `onSubmit`: refocus in `Task { @MainActor in }`.
- A `UIViewRepresentable` acts on a *change* of its focus binding, tracked as the last value it
  saw, never on its state, and its delegate writes the binding asynchronously:
  `resignFirstResponder()` in `updateUIView` fires `didEndEditing` mid-update.
- A `UITextField` subclass whose `textInputMode` returns the active mode with
  `primaryLanguage == "emoji"` opens straight on the system emoji keyboard.
