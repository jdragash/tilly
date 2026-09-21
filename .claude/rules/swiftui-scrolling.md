---
paths:
  - "Tilly/Timeline/**"
---

# SwiftUI scrolling: pinned, anchored lists

Every item was learned on device and is invisible to tests. Work here proves itself by
measurement, so Opus builds it.

## Traps

- **Never attach a geometry modifier to a `Section` inside a pinned `LazyVStack`.** It silently
  stops `pinnedViews: [.sectionHeaders]` from pinning. `.id(_:)` there is safe.
- **Pinning changes what `scrollTo(_:anchor:)` resolves an id to:** the pinned header alone, or
  the whole section once pinning breaks. Anchor arithmetic uses the *header's* height. Re-check
  one whenever the other changes.
- **A pinned header reports `minY == 0` however deep into its section you are.** Measure the
  section's content for depth, never the header.
- **`scrollTo(_:anchor:)` aligns within the container, minus its content margins**, and doesn't
  extrapolate outside the unit square. Dividing by the viewport landed every restore at 0.907×;
  a negative offset asked for as −155.6 delivered +139.
- **The reader sits at the bottom of the list, so the list's height is paid at launch.** Scrolling
  to this month lays out every month above it first: 1,200 months ahead cost 380ms and flashed
  2126 on screen. Rows built only when drawn, `.defaultScrollAnchor(.bottom)` and `List` were all
  no better. Keep what's above the reader small; five years ahead builds in 22ms.

## APIs that don't behave here

- **Use `ScrollViewReader`, not `ScrollPosition`,** which produced no scroll at all. Defer the
  call one turn (`DispatchQueue.main.async`): the proxy isn't set when sections first populate.
- **Two `scrollTo` calls a turn apart fight.** The first is still settling, and the second landed
  at 0.0 or nowhere. One scroll per intent.
- **An animated `scrollTo` loses to a fling still decelerating,** about one time in three: the
  phase never becomes `animating`. `.scrollDisabled(true)` for one turn stops the momentum where
  it is, with no jump; issue the scroll a turn later.
- **An animated `scrollTo` has no reliable completion.** Work that must follow it waits out its
  own duration; the completion ran before the list moved.
- **`scrollTo(y:)` after an id-based scroll blanked the list.** Avoid point-based scrolling.
- **`LazyVStack` stops laying out distant headers**, freezing their cached geometry. Distance
  comes from the `ScrollView`'s own offset.

## Anchoring and measuring

- When content is inserted or removed, anchor on the month under the **middle** of the viewport,
  from a live frame; rounding drifted half a point per gesture.
- **Two geometry callbacks are sampled at different moments.** `restingContentOffset` built from
  two was 702pt wrong mid-animation, and a spacer measured in the scroll view's space flickered
  548 → 0.3 → 548 across one scroll. Set values outright at a known rest, or measure in a
  coordinate space on the `LazyVStack`, which scrolling doesn't move; its callbacks then fire
  once, so recompute on the other inputs as well.
- Suppress saving a place during the app's own scroll, then save once it settles: a fling cut
  short never settles to save.

**Measuring:** temporary `print`s of frames, read through `simctl launch --console-pty`, beat
pixels. While it runs, the simulator tool's screenshot fails: use `xcrun simctl io booted
screenshot`. Fling with `touch_path` at 8ms samples; `swipe` carries no momentum.

**Diagnosing:** a correcting second pass that converges is how a missing term hides. A constant
ratio error usually means two heights are confused. Find the term before adding machinery.
