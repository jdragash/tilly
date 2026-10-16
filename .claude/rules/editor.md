---
paths:
  - "Tilly/Editor/**"
---

# The expense editor: keypad, pickers and fields

Learned in the Simulator, invisible to tests. General keyboard and safe-area lessons are in
`swiftui-controls.md`.

## Holding the amount still

- For the keyboard to cover content rather than push it, keep what it covers in the layout
  (hidden with `opacity`, not removed), or what's above re-centres.
- A focused `TextField` is taller than an unfocused one (24.0 → 25.67pt): a scaled `minHeight`
  keeps what's around it still.
- **While a category is made, the amount and name hold their resting inset**, drawn with
  `.offset` so their space can't depend on where they're drawn, and rise only by the shortfall:
  0pt under the name keyboard, 20pt under the emoji keyboard, which is taller. That 20pt breaks
  "never moves" and is open (`ROADMAP.md`).

## Pickers and menus

- A wheel `Picker`'s natural width is unbounded: `fixedSize` on one widens the whole layout. Give
  narrow wheels explicit widths.
- A `confirmationDialog`'s button ran only once its closing transition finished, 1.1s after it
  had visibly gone (measured), and couldn't be dismissed mid-open. A `Menu` acts on the tap
  itself; style it `.buttonBorderShape(.circle)` with `sharedBackgroundVisibility(.hidden)` on
  its toolbar item, or the toolbar draws a second glass circle around it.

## Focus and UIKit fields

- SwiftUI drops a `TextField`'s focus after `onSubmit`: refocus in `Task { @MainActor in }`.
- A `UIViewRepresentable` acts on a *change* of its focus binding, tracked as the last value it
  saw, never on its state, and its delegate writes the binding asynchronously:
  `resignFirstResponder()` in `updateUIView` fires `didEndEditing` mid-update.
- A `UITextField` subclass whose `textInputMode` returns the active mode with
  `primaryLanguage == "emoji"` opens straight on the system emoji keyboard.
