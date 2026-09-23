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
- **Anything above the months that reads live data moves the list before the anchor is read.**
  Change it with the window, or the anchor holds the already-moved place (60pt, measured).

## APIs that don't behave here

- **Use `ScrollViewReader`, not `ScrollPosition`,** which produced no scroll at all. Defer the
  call one turn (`DispatchQueue.main.async`): the proxy isn't set when sections first populate.
- **Two `scrollTo` calls a turn apart fight:** the second landed at 0.0 or nowhere. One per intent.
- **On an iOS 27 iPhone, a `scrollTo` issued while a fling decelerates is dropped,** and
  `.scrollDisabled(true)`, for a turn or held 0.25s, doesn't stop the glide. The Simulator
  hides this. Unsolved: see the month button. Test it on device, logs via `devicectl --console`.
- **An animated `scrollTo` has no reliable completion.** Work that must follow it waits out its
  own duration. An anchoring scroll lands a turn after new content: a few frames at raw offset.
- **`scrollTo(y:)` after an id-based scroll blanked the list.** Avoid point-based scrolling.
- **`LazyVStack` stops laying out distant headers**, freezing their cached geometry. Distance
  comes from the `ScrollView`'s own offset.

## Anchoring and measuring

- Anchor on the month under the **middle** of the viewport, from a live frame; rounding drifted
  half a point per gesture. Too little above to fill the space asked for settles on this month.
- **Two geometry callbacks are sampled at different moments.** `restingContentOffset` built from
  two was 702pt wrong mid-animation, and a spacer measured in the scroll view's space flickered
  548 → 0.3 → 548 across one scroll. Set values outright at a known rest, or measure in a
  coordinate space on the `LazyVStack`, which scrolling doesn't move; recompute on other inputs.
- Suppress saving a place during the app's own scroll, then save once it settles: a fling cut
  short never settles to save.

**Measuring:** temporary `print`s of frames, read through `simctl launch --console-pty`, beat
pixels; `simctl io booted screenshot` while it runs. Fling with `touch_path` at 8ms; `swipe`
carries no momentum. Tool taps land ~1s late, too late to interrupt a fling.

**Diagnosing:** a correcting second pass that converges is how a missing term hides. A constant
ratio error means two heights are confused. Find the term before adding machinery.
