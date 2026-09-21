---
paths:
  - "Tilly/Timeline/**"
---

# SwiftUI scrolling: pinned, anchored lists

Every item was learned on device and is invisible to tests. Work here proves itself by
measurement, so Opus builds it.

## Traps

- **Never attach a geometry modifier to a `Section` inside a pinned `LazyVStack`.**
  `.onGeometryChange` on the `Section` silently stops `pinnedViews: [.sectionHeaders]` from
  pinning. `.id(_:)` there is safe. Measure the header, on the header.
- **Pinning changes what `scrollTo(_:anchor:)` resolves an id to.** With pinning working, it
  resolves to the pinned header alone. Break pinning and it resolves to the whole section. Any
  anchor arithmetic uses the *header's* height. After any change to pinning, re-check the
  anchor, and vice versa. They're one mechanism.
- **A pinned header reports `minY == 0` however deep into its section you are.** It can tell
  you which month you're in, never where in it. Measure the section's content for depth.
- **`scrollTo(_:anchor:)` aligns within the container, minus its content margins**, and doesn't
  extrapolate outside the unit square. With `contentMargins(.bottom, …)` the divisor is the
  container's height, not the viewport's. Dividing by the viewport landed every restore at
  0.907× the distance asked for. A negative offset asked for as −155.6 delivered +139.

## APIs that don't behave here

- **Use `ScrollViewReader`, not `ScrollPosition`.** `.scrollPosition(_:)` produced no scroll at
  all in this view. Defer the call one run-loop turn (`DispatchQueue.main.async`), because the
  proxy isn't set when sections first populate. Mark a restore done only once a scroll was
  actually issued.
- **Point-based scrolling blanked the list.** `scrollTo(y:)` after an id-based scroll rendered
  it empty, with the app still alive. `contentOffset.y` reads −62.0 at the top. Calibrate the
  two coordinate spaces from a settled position before trying again.
- **An animated `scrollTo` has no reliable completion.** It's a `UIScrollView` underneath, and
  the completion ran before the list moved. Work that must follow a scroll waits for the scroll
  phase to settle.
- **`LazyVStack` stops laying out distant headers**, so their cached geometry freezes. Distance
  from an arbitrary point comes from the `ScrollView`'s own offset. Caches that only pick among
  nearby months stay safe while scrolling travels through the viewport. A scroll that teleports
  breaks them.

## Anchoring

- When content is inserted or removed, anchor on the month under the **middle** of the
  viewport. The top-most visible item is the control about to be tapped, so preserving it
  pushes the reader's month off screen. Total content height fails when one change adds at one
  end and removes at the other.
- Compute offsets from a live frame; rounding drifted half a point per gesture.
- Content that opens above the viewport is instantly "not visible". A close trigger needs a
  latch: the reader must have travelled into it first. Suppress closing during a programmatic
  scroll.
- `restingContentOffset` is built from two callbacks that are sampled at different moments
  during animation, and was measured 702pt and 493pt wrong. Set it outright at the end of a
  return. **Known and unfixed:** it can still drift.

**Diagnosing:** a correcting second pass that converges is how a missing term hides. A constant
ratio error usually means two heights are confused. Find the term before adding machinery.
