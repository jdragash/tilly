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
  the whole section once pinning breaks. Anchor arithmetic uses the *header's* height.
- **A pinned header reports `minY == 0` however deep into its section you are.** Measure the
  section's content for depth, never the header.
- **`scrollTo(_:anchor:)` aligns within the container, minus its content margins**, and doesn't
  extrapolate outside the unit square: asked for −155.6 it delivered +139. `containerSize.height`
  already excludes the bottom margin (660 = 718 − 58).
- **The reader sits at the bottom of the list, so the list's height is paid at launch.** 1,200
  months ahead cost 380ms and flashed 2126 on screen; rows built only when drawn,
  `.defaultScrollAnchor(.bottom)` and `List` were no better. Five years builds in 22ms.
- **Anything above the months that reads live data moves the list before the anchor is read.**
  Change it with the window, or the anchor holds the already-moved place (60pt, measured).

## APIs that don't behave here

- **Use `ScrollViewReader`, not `ScrollPosition`,** which produced no scroll at all. Defer the
  call one turn (`DispatchQueue.main.async`): the proxy isn't set when sections first populate.
- **A lazy list resolves only ids it has laid out.** Asked for a row in a month it hadn't built,
  it didn't move. Scroll to the month, then to the row a turn later, both unanimated. A zero-high
  marker as the target needs no row height (landed 59.86 under a 60pt header). Two *animated*
  scrolls a turn apart fight: the second landed at 0.0 or nowhere.
- **A scroll issued while the list glides is dropped.** Rebuilding the months mid-glide lost the
  anchor, and once the list had shrunk under the glide it ran off the end, blank. Halting scrolling
  for a turn (`scrollDisabled`) stops it in the Simulator; on an iOS 27 iPhone even that hasn't
  stopped the glide. Unsolved: see the month button. Test on device, logs via `devicectl --console`.
- **An animated `scrollTo` has no reliable completion.** Work that must follow it waits out its
  own duration. An anchoring scroll lands a turn after new content: a few frames at raw offset.
- **`scrollTo(y:)` after an id-based scroll blanked the list.** Avoid point-based scrolling.
- **`LazyVStack` stops laying out distant headers**, freezing their cached geometry, and a header
  it stops drawing keeps its last offset: after a jump the month under the middle read June from
  a stale entry. Clear it in `onDisappear`; take distance from the `ScrollView`'s own offset.

## Anchoring and measuring

- Anchor on the month under the **middle** of the list, from a live frame; rounding drifted
  half a point per gesture. Too little above or below to place it settles it as near as the
  content allows: that is the content, not the anchoring.
- **Two geometry callbacks are sampled at different moments.** `restingContentOffset` built from
  two was 702pt wrong mid-animation. Set values outright at a known rest, derive what you can
  (the list's height is the viewport less the fixed top row), or measure in a coordinate space on
  the `LazyVStack`, which scrolling doesn't move.
- Suppress saving a place during the app's own scroll, then save once it settles.

**Measuring:** `NSLog`s of frames (`simulator.md`) beat pixels; fling with `touch_path` at 8ms.
**Diagnosing:** a correcting second pass that converges is how a missing term hides, and a constant
ratio error means two heights are confused. Find the term before adding machinery.
