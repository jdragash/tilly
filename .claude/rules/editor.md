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

- **`EditorSheet` matches the system sheet it replaced:** the card measured 132.00 global in both,
  under every panel. At an accessibility size, making a category scrolls it up (117.00 → 115.67 now).
- **A frame read inside the moving sheet includes its travel, every frame.** The sheet's slot
  shrinks by the keyboard (812 → 484pt): measure the drop from its ground, which ignores it, or a
  closing sheet stops halfway.
- **The sheet's drag is simultaneous, so it moves from anywhere**, refused if it starts sideways or
  upward, on a wheel, or on a scroll view away from its top (`editorDragExcluded`). The key or card
  it starts on stays under the finger, so its button fires on the lift: `allowsHitTesting(false)`
  mid-drag didn't cancel it, so actions check `EditorSheetTouch.allowsTap`. A drag down arrives as
  `request` going nil with no `EditorClose`; every close refreshes from `onChange(of: editor)`.
- **The category grid takes everything under the card**, sized from the card's measured height.
  Letting it grow with `layoutPriority` squashed the card instead.
- **A shape's fill eats the taps of a button in its `.background`.** The card's background button
  is an overlay over the fill and under the parts.

## Pickers and menus

- **The header's buttons are its own glass circles, not a toolbar.** `.plain` dims a disabled
  label; the system's ✓ stays white on grey, so ✓ uses a `ButtonStyle` returning its label.
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
- A `TextField` ignores `minimumScaleFactor`: to shrink a typed name as a `Text` would, measure
  it with `UIFont` and set the size yourself.
