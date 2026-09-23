---
paths:
  - "Tilly/**/*.swift"
---

# SwiftUI controls, keyboards and focus

Learned in the simulator, invisible to tests.

## Matching the system

- Measure Apple's apps, don't guess: screenshot in the simulator and walk pixel columns out from
  inside a glass shape to where its shadow starts, through its flat middle, not its rounded ends
  or label. Compare text weight by stem width in the ascender band, clear of content under glass.
- The `.glass` button style pads its label (44pt measured 58pt). For an exact size, use
  `glassEffect(.regular.interactive(), in:)` on a plain button.
- `.borderedProminent` tinted `Ink.primary` is white in dark mode with a white label. Give the
  label the opposite ground (`Tokens.Surface.base`).
- A wheel `Picker`'s natural width is unbounded: `fixedSize` on one widens the whole layout. Give
  narrow wheels explicit widths.
- A `confirmationDialog`'s button ran only once its closing transition finished, 1.1s after it
  had visibly gone (measured), and couldn't be dismissed mid-open. A `Menu` acts on the tap
  itself; style it `.buttonBorderShape(.circle)` with `sharedBackgroundVisibility(.hidden)` on
  its toolbar item, or the toolbar draws a second glass circle around it.
- A `.plain` `Button` hit-tests its label's shape, not the button's: put `.contentShape(Rectangle())`
  on the label, or the gap between a row's parts (a name and its trailing amount) stays dead.

## Keyboards and safe areas

- A sheet's keyboard shrinks the screen behind it too. Ignore the keyboard on the presenting
  screen's root: on a child it does nothing, because the child follows its container's bottom.
- To place something from the screen's edge, let it fill first:
  `.frame(maxHeight: .infinity, alignment: .bottom)` before `.ignoresSafeArea(...)`. A view only
  as tall as its content never reaches the edge it's told to ignore.
- For the keyboard to cover content rather than push it, keep what it covers in the layout
  (hidden with `opacity`, not removed), or what's above re-centres.
- A focused `TextField` is taller than an unfocused one (24.0 → 25.67pt): a scaled `minHeight`
  keeps what's around it still.
- To fill a `ScrollView`'s visible height, use `onScrollGeometryChange { $0.containerSize.height }`,
  which is net of insets. `visibleRect` overshoots; subtracting `contentInsets` undershoots.

## Focus and UIKit fields

- SwiftUI drops a `TextField`'s focus after `onSubmit`: refocus in `Task { @MainActor in }`.
- A `UIViewRepresentable` acts on a *change* of its focus binding, tracked as the last value it
  saw, never on its state, and its delegate writes the binding asynchronously:
  `resignFirstResponder()` in `updateUIView` fires `didEndEditing` mid-update.
- A `UITextField` subclass whose `textInputMode` returns the active mode with
  `primaryLanguage == "emoji"` opens straight on the system emoji keyboard.

## Stores and builds

- Never release a `ModelContainer` while a view may still show its models: a sheet re-rendering
  for a frame after a store switch crashed ("This model instance was destroyed"). Keep the
  outgoing container until the next switch.
- `#Preview` blocks survive into Release. One that uses a `#if DEBUG` type sits inside
  `#if DEBUG` too. Check with `xcodebuild -scheme Tilly -configuration Release build`.
- `@Query`'s array compares by model identity, not its fields, and a relationship-only write
  (an override insert, a field edit on an existing model) doesn't reliably notify either. Don't
  lean on `.onChange(of:)` alone: give the writing sheet its own `onDismiss` refresh.
