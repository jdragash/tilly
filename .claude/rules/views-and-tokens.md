---
paths:
  - "Tilly/**/*.swift"
---

# Views, tokens and models in the app target

## Tokens

- Views reference `Tokens`, never raw values (CLAUDE.md). That includes **dimensions**. A bare
  `.padding(8)` or `VStack(spacing: 8)` reads as incidental rather than as a value that escaped
  the seam, which is why it's the one that gets through.
- Need a value that doesn't exist? Add a token, with a comment if it's a tuning value.
  Introducing tokens on a screen is fine and expected. Proposing a type scale, palette or
  component system isn't; that pass is Jake's.
- `spacing: 0` is allowed. It's the absence of a gap, not a design value.
- The seam check must print nothing:

```
grep -REn '#[0-9A-Fa-f]{6}|Color\(red:|\.font\(\.(largeTitle|title|headline|subheadline|body|callout|footnote|caption)|\.font\(\.system|spacing: *[1-9]|\.padding\( *[0-9]|\.padding\([^)]*, *[0-9]|cornerRadius\( *[0-9]|\.frame\((width|height): *[0-9]' Tilly --include='*.swift' | grep -v 'DesignSystem/'
```

## Amounts

- Round to whole units **before** totalling (`NSDecimalRound`, `.plain`), so a total always
  equals the figures above it.
- VoiceOver speaks the currency in full from the device locale. Never hardcode a currency. Keep
  a non-euro test case.

## Accessibility

- An accessibility-size layout fills the width: `.frame(maxWidth: .infinity, alignment:
  .leading)`. Without it rows float centred and wide ones overflow both edges.
- Every interactive element gets a label, and a hint where the action isn't obvious. A gesture
  always has a `Button` equivalent, because a pull is invisible to VoiceOver and Switch Control.
- Hide invisible controls from the accessibility tree.

## Before calling a screen done

Light and dark. Dynamic Type at an accessibility size. The empty state. For timeline work:
upcoming and charged, skipped, a day with one charge and a day with several.

## SwiftData models

CloudKit-compatible from day one: every property optional or defaulted, no unique constraints,
relationships optional. Sync is off in v1.

## Size

A file past a few hundred lines is usually doing too much. Dime's 98KB `InsightsView.swift` is
the standing cautionary example.
