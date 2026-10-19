# The card's motion — implementation plan

**Brief:** docs/briefs/card-motion/brief.md
**Settled by:** `DESIGN.md`, "The hand is the category picker", "The card lands in the timeline",
"Opening a charge edits it"; `DECISIONS.md`, "Adding a bill is a card you complete, a hand of
categories dresses it, and it lands in the timeline" and "Views switch in place…" (the editor is
drawn by the app).
**Builds on:** branch `drawn-timeline` (`8724479`). Branch `card-motion` from it, not from `main`,
unless `drawn-timeline` has landed by then.
**Reference:** `docs/prototypes/combined.html`: `startCardFlip`, `openRow`, `returnRow`, `playCat`,
`dressCard`, `layoutHand`, `fanPose`, `closeSheet`. Its settled values are the first guesses below.

## Already decided — do not reopen

- The hand replaces the pockets entirely. `PocketGrid`, `PocketContents`, filing into a pocket and
  its tokens are deleted, not kept behind a flag.
- The editor stops being a system `.sheet`. It is `EditorSheet`, drawn by `TimelineView` in its own
  `ZStack`, above the levels and the bottom row. Settings and All bills stay system sheets.
- The flying card is drawn in one `CardFlightLayer` overlay in `TimelineView`, above the editor sheet.
  The card in the sheet and the row in the list hide while the flyer stands in for them.
- The card's back is `OccurrenceRow`, drawn at the card's size. It is not a second drawing of a row.
- A charged card never flips, landing or opening. An upcoming or skipped one always does.
- Every duration, bounce, hold and distance is a token; the debug panel tunes the live value.
  Sizes (the hand card's, the fan's arc) are tokens but not tuned.
- Card-polish's currency question stays out. Its four device fixes are step 9.
- Over the category view, the sheet drops with no card flight (the brief names only the calendar).

## Steps

Steps 1–3 and 8–9 are Sonnet's. Steps 4–7 are Opus's: each can be broken with the suite still green
(`CLAUDE.md`, model routing), and 5–7 touch the scroll-anchored list.

### Step 1 — Put the motion's values behind tunable tokens, with a debug panel

**Files:** `Tilly/DesignSystem/Tokens.swift` (modified), `Tilly/DesignSystem/MotionTuning.swift`
(new), `Tilly/Developer/MotionTuningSection.swift` (new), `Tilly/Developer/DeveloperSection.swift`
(modified), `Tilly/Settings/SettingsSheet.swift` (modified, only to place the section),
`TillyTests/MotionTuningTests.swift` (new).

**Interface:**
```swift
/// One tunable value: its key, label, default and range. The defaults are the prototype's.
struct MotionValue: Identifiable, Sendable {
    let id: String            // stable key, e.g. "flip"
    let label: String         // "Flip"
    let defaultValue: Double
    let range: ClosedRange<Double>
    let step: Double
}

/// The motion's values, live. Release builds read the defaults and nothing else.
@MainActor @Observable
final class MotionTuning {
    static let shared: MotionTuning
    static let values: [MotionValue]          // the catalogue below, in this order
    subscript(_ id: String) -> Double { get set } // debug: persisted in UserDefaults "motion.<id>"
    func reset()                              // every value back to its default, defaults removed
    var swiftSnippet: String { get }          // `static let flip: TimeInterval = 0.4` per changed value
}

extension Tokens.Motion {
    /// Read in `body`, so a change in the panel redraws what uses it.
    @MainActor enum Card {
        static var sheetExit: TimeInterval { get }     // 0.55, 0.2…1.2
        static var sheetContentsFade: TimeInterval { get } // 0.14, 0…0.4
        static var sheetRise: TimeInterval { get }     // 0.45, 0.2…1
        static var sheetRiseBounce: Double { get }     // 0.1, 0…0.5
        static var flip: TimeInterval { get }          // 0.4, 0.15…1
        static var flipHold: TimeInterval { get }      // 0.15, 0…0.6
        static var flipLift: Double { get }            // 0.06, 0…0.15
        static var drop: TimeInterval { get }          // 0.45, 0.2…1
        static var dropBounce: Double { get }          // 0.3, 0…0.6
        static var open: TimeInterval { get }          // 0.4, 0.2…1
        static var openBounce: Double { get }          // 0.3, 0…0.6
        static var landingRowOffset: CGFloat { get }   // 120, 0…300: a jumped-to row's top under the header
        static var press: TimeInterval { get }         // 0.14, 0.05…0.4
        static var pressLift: CGFloat { get }          // 18, 0…40
        static var pressScale: Double { get }          // 1.06, 1…1.2
        static var neighbourTilt: Double { get }       // 3, 0…10 (degrees)
        static var play: TimeInterval { get }          // 0.26, 0.1…0.8
        static var flood: TimeInterval { get }         // 0.38, 0.1…1
        static var stampScale: Double { get }          // 1.3, 1…1.6
        static var stampUnder: Double { get }          // 0.95, 0.8…1
        static var stampDown: TimeInterval { get }     // 0.14, 0.05…0.4
        static var stampSettle: TimeInterval { get }   // 0.1, 0.05…0.4
        static var dip: CGFloat { get }                // 2, 0…8
        static var deal: CGFloat { get }               // 200, 0…400
        static var dealStagger: TimeInterval { get }   // 0.022, 0…0.08
        static var dayDrop: CGFloat { get }            // 48, 0…120: the month and year's drop
        static var dayDropDuration: TimeInterval { get } // 0.45
        static var dayDropBounce: Double { get }       // 0.3
    }
}
```
Fixed (untuned) tokens added beside them: `Tokens.Size.handCard = CGSize(width: 84, height: 120)`,
`Tokens.Size.handPicture: CGFloat = 44`, `Tokens.Space.handStepMax: CGFloat = 48`,
`Tokens.Space.handStepMin: CGFloat = 24`, `Tokens.Space.handSideClearance: CGFloat = 64`,
`Tokens.Motion.handArc: Double = 8` (degrees per step), `Tokens.Motion.flipPerspective: CGFloat = 0.4`.
In release builds `subscript` returns the default and the setter does nothing (`#if DEBUG`).

`MotionTuningSection` is a `Section("Motion")` in `DeveloperSection`: a row per value (label, the
value to two places, a `Slider` over its range by its step), then `Reset motion` and `Copy changed
values`, which puts `swiftSnippet` on the pasteboard. Its footer: "Live, in this build only. Copy
what you like into Tokens.swift."

**Done when:** `MotionTuningTests`: `defaultsMatchCatalogue`, `setPersistsAcrossInstances`,
`resetRestoresDefaults`, `snippetListsOnlyChangedValues`, `snippetIsEmptyWhenNothingChanged`,
`everyValueIsInsideItsRange` all pass; the panel shows in Settings in a debug run.

**Verify:** `xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0' test`

**Out of scope:** using any of the new values; removing the pocket tokens (step 2).

### Step 2 — The hand replaces the pockets

**Files:** `Tilly/Editor/CategoryHand.swift` (new), `Tilly/Editor/HandFan.swift` (new),
`Tilly/Editor/ExpenseEditor.swift` (modified), `Tilly/Editor/PocketGrid.swift` (deleted),
`Tilly/Editor/PocketContents.swift` (deleted), `TillyTests/PocketContentsTests.swift` (deleted),
`TillyTests/HandFanTests.swift` (new), `Tilly/DesignSystem/Tokens.swift` (pocket tokens,
`lipFill`, `Motion.pick`, `file*`, `pocketBounce*`, `Shadow.pocket*`, `Radius.pocket*` deleted).

**Interface:**
```swift
/// Where each card of the fan sits: on an arc, `handArc` degrees per step, the step tightening from
/// `handStepMax` to fit `width`, never below `handStepMin`; past that the fan is wider than `width`
/// and scrolls. Pure, so it's tested without views.
struct HandFan: Equatable {
    struct Pose: Equatable { var offset: CGSize; var angle: Double } // degrees
    let count: Int
    let width: CGFloat
    var step: CGFloat { get }
    var contentWidth: CGFloat { get }   // == width unless the fan scrolls
    var scrolls: Bool { get }
    func pose(at index: Int) -> Pose    // the prototype's fanPose, offsets from the hand's centre
}

struct CategoryHand: View {
    let categories: [ExpenseCategory]   // Settings order
    let selection: UUID?
    let newBreathes: Bool
    /// The tile's frame in the editor's coordinate space, for a played card to fly to.
    let tileFrame: CGRect
    let onPlay: (UUID) -> Void          // called when the flying card reaches the tile
    let onNew: () -> Void
}
```
A hand card: `Wash` in the category's colour, `Radius.card`-scaled corners, `CategoryPictureView`
at `handPicture` on card, the name in `Tokens.Text.caption` on card. `New`: a `DottedOutline`, a
`plus` and `New`. Pressing lifts the card by `pressLift`, scales `pressScale`, tilts each neighbour
`neighbourTilt` away, over `press`; `.sensoryFeedback(.selection)`. Letting go on the same card
plays it: a copy flies from its frame to `tileFrame` over `play` (shrinking to the tile's height,
turning to 0°, to 0.75 opacity), the played card leaves the fan, and `onPlay` fires on arrival.
Letting go elsewhere settles the fan. Playing the selected category does nothing. On appear the
cards deal up from `deal` below, `dealStagger` apart. Reduce Motion: no deal and no flight;
`onPlay` fires on release.

`ExpenseEditor`'s `.category` panel shows `CategoryHand`; `pick(_:)` sets `draft.categoryID` with
no animation of its own (step 3 animates the card). `create(_:)` plays the new category. ✓ on a
new bill dismisses as today until step 6 (`file(into:)` goes; `dismiss()` stands in).

**Done when:** `HandFanTests`: `oneCardSitsCentredUpright`, `stepIsMaxWhenItFits`,
`stepTightensToFitWidth`, `stepStopsAtMinAndScrolls`, `posesAreSymmetric`, `anglesGrowByArcPerStep`.
Existing tests that referenced pockets are deleted with them; no other test changes. In the
Simulator: playing a card dresses the card, at 2, 8 and 20 categories, light and dark.

**Verify:** both suites (`CLAUDE.md`, Verification).

**Out of scope:** the flood and stamp (step 3); the landing (step 6).

### Step 3 — Playing a card floods the editor's card and stamps its picture

**Files:** `Tilly/Editor/EditorCard.swift` (modified), `Tilly/Editor/ExpenseEditor.swift` (modified).

**Interface:**
```swift
/// The colour arriving on the card: the new wash revealed by a circle growing from the tile.
struct CardFlood: Equatable {
    let previous: CategoryColour?   // nil = the grey card
    var progress: CGFloat           // 0 … 1, animated over Motion.Card.flood
}

// EditorCard gains:
var flood: CardFlood? = nil
var stamp: CGFloat = 1      // the tile's picture scale
var dip: CGFloat = 0        // the card's y offset
```
The circle's centre is the tile's centre and its final radius reaches the card's furthest corner.
On `onPlay` the editor runs: `flood` 0→1 over `flood`, `stamp` to `stampScale` at once, then to
`stampUnder` over `stampDown`, then to 1 over `stampSettle`; `dip` to `dip` and back over 0.07s and
0.13s; `.sensoryFeedback(.impact(weight: .medium))`. Reduce Motion: the colour crossfades over
`flood`, no stamp or dip.

**Done when:** in the Simulator the flood starts at the tile and the picture stamps, from grey and
from another colour; the suites stay green.

**Verify:** both suites.

**Out of scope:** the hand itself; the sheet.

### Step 4 — The editor is a sheet the app draws (Opus)

**Files:** `Tilly/Editor/EditorSheet.swift` (new), `Tilly/Timeline/TimelineView.swift` (modified),
`Tilly/Editor/ExpenseEditor.swift` (modified), `.claude/rules/editor.md` (lessons only).

**Interface:**
```swift
/// What the editor is open for.
enum EditorRequest: Identifiable, Equatable {
    case add
    case edit(EditSession)
    var id: String { get }
}

/// The editor's sheet, drawn by the timeline: a scrim, then the sheet rising from the bottom with
/// the system sheet's corner radius and grabber, dragged down to close.
struct EditorSheet<Content: View>: View {
    @Binding var request: EditorRequest?
    /// Where the editor's card rests when the sheet is up, in `CardFlightLayer.space`, with the
    /// sheet's own travel taken out: a flight can aim at it before the sheet has arrived.
    let onCardRest: (CGRect) -> Void
    @ViewBuilder let content: (EditorRequest) -> Content
}

// ExpenseEditor gains, replacing @Environment(\.dismiss):
let onClose: (EditorClose) -> Void
enum EditorClose: Equatable {
    case cancelled                              // ✕ or a drag down
    case saved(expenseID: UUID, date: Date)     // the charge to land on: the saved bill's charge at `date`
    case deleted
}
```
The sheet rises over `sheetRise` with `sheetRiseBounce`. Closing without a landing (cancel, delete,
over the category view): the sheet drops over `sheetExit` with its contents first fading over
`sheetContentsFade` (the prototype's soft exit). Reduce Motion fades it. The scrim is the system's
dimming (`Tokens.Surface.scrim`, new, 16% black) and taps on it do nothing, as a sheet's do.
`TimelineView` replaces both editor `.sheet`s with one `@State var editor: EditorRequest?` and
runs `refreshWindow()` on every close, as `onDismiss` did. The editor's sheet sits under the
pinned glass controls in z-order only while closed.

**Done when:** every check in `.claude/rules/editor.md`, "Holding the card still", still holds,
measured at the card's top edge under the keypad, the name keyboard, the calendar, the wheel, the
hand and making a category, at a standard and an accessibility size; dragging down closes and a
short drag springs back; the scope and trash menus still open from ✓ and trash. Suites green.

**Verify:** both suites; the Simulator measurements logged per `simulator.md`.

**Out of scope:** any card flight (steps 6–7).

### Step 5 — The timeline can hold a row open, closed or hidden, and jump to it (Opus)

**Files:** `Tilly/Timeline/TimelineView.swift`, `Tilly/Timeline/MonthSectionView.swift`,
`Tilly/Timeline/OccurrenceRow.swift`, `Tilly/Timeline/RowFrames.swift` (new),
`TillyTests/TimelineLandingTests.swift` (new).

**Interface:**
```swift
/// What the list is doing with one row while a card stands in for it.
struct RowHold: Equatable {
    let entryID: String
    var height: CGFloat     // 0 … 1 of the row's own height; 1 while a row is open in the sheet
    var showsCard: Bool     // false while the flyer is its card
}

/// The rows on screen, by entry id, in `CardFlightLayer.space`. Rows report on appear and change,
/// and drop out on disappear.
@MainActor @Observable final class RowFrames {
    private(set) var frames: [String: CGRect]
    func report(_ id: String, frame: CGRect?)
}

enum TimelineLanding {
    /// The entry a save lands on: the bill's charge on `date` (its effective date), from the built
    /// sections. Nil when that charge isn't in the window, or Extras hides it.
    static func target(expenseID: UUID, date: Date, in sections: [MonthKey: MonthSection]) -> TimelineEntry?
    /// Whether a row's frame is fully inside the list, under the pinned header.
    static func isInView(_ frame: CGRect, listTop: CGFloat, headerHeight: CGFloat, listBottom: CGFloat) -> Bool
}

// TimelineView gains:
@State private var hold: RowHold?
private let rowFrames = RowFrames()
/// Puts the held row's top `landingRowOffset` under its month's pinned header, unanimated: the
/// month first, then the day's marker a turn later, as `openDay` does.
private func jump(to entry: TimelineEntry)
```
`OccurrenceRow` gains `var heightFraction: CGFloat = 1` (the row's frame and card clip to it) and
`var showsCard = true`. A held row's months are rebuilt by `refreshWindow()` as any others are: with
the window unchanged the list keeps what's on screen still by itself, so a monthly bill's new
charges in the months above move nothing (TASTE 2). No extra anchoring.

**Done when:** `TimelineLandingTests`: `targetIsTheChargeOnItsDate`, `targetFollowsAMovedCharge`,
`targetIsNilOutsideWindow`, `targetIsNilWhenExtrasHidesIt`, `inViewNeedsWholeRowUnderHeader`,
`inViewFalseWhenUnderBottomRow`. In the Simulator, logged: with a row held at 0, a debug-menu
`jump` lands its top `landingRowOffset` ± 0.5pt under the header from the current month and from
two years away; adding a monthly bill moves the month under the middle by less than 0.5pt.

**Verify:** both suites; the logs.

**Out of scope:** drawing a flyer (step 6). The debug-menu jump is removed in step 6.

### Step 6 — On ✓ the card turns over and drops into its row (Opus)

**Files:** `Tilly/Editor/CardFlightLayer.swift` (new), `Tilly/Editor/CardFlip.swift` (new),
`Tilly/Timeline/TimelineView.swift`, `Tilly/Timeline/OccurrenceRow.swift`,
`Tilly/Timeline/MonthHeader.swift` (the figure's roll), `Tilly/Editor/ExpenseEditor.swift`.

**Interface:**
```swift
/// A flight in progress. The layer draws `front` until the turn passes 90°, then `back`.
struct CardFlight: Equatable {
    enum Kind: Equatable { case landing(flips: Bool), opening(flips: Bool) }
    let kind: Kind
    let entry: TimelineEntry          // the back is this row
    let isLast: Bool                  // the back's corners, as in its month
    let cardFrame: CGRect             // the editor's card, in `space`
    var rowFrame: CGRect              // the row at its full height, in `space`
    var turn: Double                  // 0 … 1: 0 the front up, 1 the back up
    var travel: CGFloat               // 0 … 1: 0 at the card, 1 at the row
}

struct CardFlightLayer: View {
    static let space = "cardFlight"   // named coordinate space on TimelineView's root
    @Binding var flight: CardFlight?
    let front: () -> EditorCard       // the live card, nothing focused, not hit-testable
    let onTapDuringFlight: () -> Void // finishes the flight at once (TASTE 12)
}

/// The turn: rotation about y in `flipPerspective`, the face swapped at 90°, lifted by
/// `1 + flipLift × sin(π × turn)`. One view either way, so it animates (`editor.md`).
struct CardFlip: ViewModifier, Animatable { var turn: Double }

// OccurrenceRow gains `var morph: CGFloat = 1`: at 0 the card fills the frame with `Radius.card` on
// every corner and no `stackInset`; at 1 it is the row. The content keeps the row's layout.
```
The sequence on `EditorClose.saved`, for a row in the days: `hold` the target at height 0, card
hidden; `jump(to:)` if `isInView` is false, behind the sheet; the sheet's soft exit starts. A
flipping landing turns over `flip` (`.sensoryFeedback(.selection)` at 90°), waits `flipHold`,
then travels with a `.spring(duration: drop, bounce: dropBounce)` while `hold.height` follows
`travel` on the same spring and `morph` follows `travel`. A charged landing skips the turn: it
travels at once, crossfading the card into the back over the first 0.65 of `travel`. On arrival:
`hold` clears, the flyer goes, `.sensoryFeedback(.impact(weight: .light))`, and the month's figure
rolls (`.contentTransition(.numericText())`). With no target (outside the window, hidden by
Extras) the sheet closes as a cancel does. Reduce Motion: the sheet fades and the row fades in.

**Done when:** in the Simulator, recorded at 60fps and stepped frame by frame: the turn, the beat
and the drop each read; the flyer's last frame and the row's first match within 0.5pt; the rows
below open on the drop's spring and those above don't move; a row two years away is jumped to
before the card leaves; a tap mid-flight finishes it. Charged and upcoming, light and dark, an
accessibility size. On the device: Instruments' Animation Hitches over five landings, none
reported. Suites green.

**Verify:** both suites; the recording; `xcrun xctrace record --template 'Animation Hitches'`.

**Out of scope:** opening a row (step 7); the calendar's month and year (step 8).

### Step 7 — Opening a row flips its card back into the sheet (Opus)

**Files:** `Tilly/Timeline/TimelineView.swift`, `Tilly/Editor/CardFlightLayer.swift`,
`Tilly/Editor/EditorSheet.swift`.

**Interface:** no new types. `openEntry(_:)` sets `editor = .edit(session)`, `hold` the row at
height 1 with its card hidden, and starts `CardFlight(kind: .opening(flips: entry.state != .charged))`
at `travel` 1, `turn` 1, travelling to 0 with `.spring(duration: open, bounce: openBounce)` as the
sheet rises, then, if it flips, turning to 0 over `flip` once `travel` passes 0.985. A charged
opening fades the front in over `travel` 0.45 → 0.05 instead. Arrival removes the flyer and shows
the sheet's card; until then the sheet's card is hidden and a tap finishes the opening.
`.sensoryFeedback(.impact(weight: .light))` on the tap. ✕ and an unchanged close land the card back
as step 6 does with the row already open (`hold.height` stays 1); a save that moved the charge lands
on its new row and releases the old one.

**Done when:** in the Simulator, recorded: an opened and closed row ends within 0.5pt of where it
was; upcoming flips both ways, charged never; a moved charge lands at its new date. Suites green.

**Verify:** both suites; the recording.

**Out of scope:** the category view's rows, which open the sheet without a flight.

### Step 8 — Over the calendar's month or year, the charge drops into its day

**Files:** `Tilly/Calendar/CalendarMonthView.swift`, `Tilly/Calendar/CalendarDayCell.swift`,
`Tilly/Calendar/YearView.swift`, `Tilly/Calendar/YearMonthCell.swift`, `Tilly/Timeline/TimelineView.swift`.

**Interface:** `CalendarDayCell` and `YearMarkView` gain `var arrives = false`: when set on appear
or change, the picture (the year's mark) starts `dayDrop` above at 0 opacity and drops with
`.spring(duration: dayDropDuration, bounce: dayDropBounce)`, fading in over 0.15s, with
`.sensoryFeedback(.impact(weight: .light))` at 40% of the drop and the day's total rolling then.
`TimelineView` passes the saved charge's day as arriving after the sheet's exit begins.

**Done when:** in the Simulator, a bill saved over the month drops into its day and one saved over
the year drops its mark; Reduce Motion fades. Suites green.

**Verify:** both suites.

**Out of scope:** the category view.

### Step 9 — Card-polish's device fixes

**Files:** `Tilly/Editor/EditorCard.swift`, and whatever each cause turns out to be in.

Each from `card-polish/brief.md`, reproduced first; one that no longer reproduces on this branch is
reported as such and skipped.
1. The name field moves when tapped or typed in: nothing around it or its text moves (measured).
2. Backspace in the name erases the whole name and selects it: backspace removes one character.
   If the cause isn't found, stop and report rather than working around it.
3. The amount (`Tokens.Text.cardAmount(size:)`) takes the prototype's −0.026em tracking, as
   `Tokens.Text.cardAmountTracking` (new, a fraction of the size); `85.55` renders at full size.
4. The date and repeat hit areas measure at least 44pt tall, with the type unchanged.

**Done when:** each fix measured in the Simulator; `ExpenseDraftTests` gains
`backspaceRemovesOneCharacterFromName` if the cause is in the draft. Suites green.

**Verify:** both suites.

**Out of scope:** currency placement.

## Lessons

- **The prototype's fan only works while the cards fit.** Its arc keeps turning 8° a step, so past about
  eleven cards a hand that scrolls would curl into a circle (20 categories: ±80°). `HandFan` stops the
  curve at `Motion.handArcMax` (40°) and runs the rest straight at the same height and angle. A tuning value.
- **The category the bill is in is on the card, so it isn't in the fan** (the prototype hides the
  played card too). The hand is sorted by `sortOrder`; the editor's `@Query` is sorted by name.
- **The hand draws its own flyer** in an overlay on its scroll view (`scrollClipDisabled`), so it can
  leave the hand and reach the tile; the hand sits at `zIndex(1)` over the card for that. The tile
  reports its frame in `.global`, and the hand converts with its own.
- **A `ButtonStyle`'s `isPressed` drives the lift and the neighbours' tilt**; `onGeometryChange` after
  `.offset` reports the card's place without its rotation or scale.
- **The system sheet it replaced, measured (iPhone 17, iOS 27, 3x):** top at the safe area's top
  (62pt), full width, circular 38pt top corners, 44pt glass buttons 16pt in from the sides and top,
  trash 12pt before ✓, the card 70pt under the sheet's top (132.00 global). `EditorSheet` lands the
  card at 132.00 too, at a standard and an accessibility size.
- **`CardFlightLayer.space` starts at the safe area's top,** not the screen's: the timeline's root
  respects it. The card rests at y 70 in it. Rows reported in step 5 share the space, so it cancels.
- **A frame read inside a moving view includes the move, every frame:** `onGeometryChange` logged
  the card 910 → 132 through the rise. The card's rest is its frame in the sheet's own space
  (`EditorSheetSpace`, which moves with it) plus the origin of an unmoved slot. It held at 70.0
  through the rise, a drag and the spring back.
- **The sheet's slot shrinks by the keyboard (812 → 484pt):** an off-screen distance read from it
  stopped a closing sheet halfway. The ground's own height, which ignores the keyboard, is used.
- **The timeline's root shrinks under the keyboard despite `.ignoresSafeArea(.keyboard)`:** 778 → 484
  under the name keyboard, with the old system sheet too (measured on `51c7db6`). Hidden behind the
  sheet; step 5 should know `listHeight` changes while a keyboard is up. The sheet sits in an
  `.overlay` after that modifier and still gets the keyboard's inset.
- **Making a category at an accessibility size moves the card** as the field scrolls into view:
  132 → 117.00 in the system sheet, → 115.67 in the drawn one. Not new; the 1.33pt is the old nav
  bar's content inset.
- **A drag starting on a key or a hand card belongs to that control** (the sheet's `.gesture` loses
  to theirs); from the grabber, the buttons' row, the card or bare ground it moves the sheet.
- **A drag down arrives as `request` going nil with no `EditorClose`:** the timeline reads it as a
  cancel. Every close, a drag included, refreshes from `onChange(of: editor)`.
- **A jump aims at the row's own id, not its day's marker:** the held row is often not its day's
  first (the debug jump held a second charge on the 8th). Each row's button carries
  `OccurrenceRow.rowScrollID`; held at 0 it is zero high, so `f = top / (room − h)` with `h` 0
  lands it: 119.88, 120.05 and 120.00 under the header (current month, two years back, and back).
- **Re-anchoring to a pinned header moves the list; a held row needs no anchor of its own.** The
  plan first rebuilt a held row's months with `anchorAndSettle(monthUnderMiddle())`. A jump leaves
  the row's month pinned with rows hidden under its header, which reads 0, so re-anchoring to 0
  scrolled the month's top into view: adding a monthly bill moved the rows 136pt (current month)
  and 72pt (two years back). Plain `refreshWindow()` held them at 0.000 in both, held or not.
- **A held row's full frame comes from inside its cut:** `RowHeightLayout` lays the row out whole, so a
  geometry read on its content is the row at full height however little shows. `RowFrames.fullFrames`
  holds it for held rows only; `frames` stays the cut height `jump` needs.
- **Closing a row that was there shortens the list, and at its end the list is pulled back:** holding
  an edited Rent at 0 dropped every row above it 156pt. `holdSlack` keeps the row's old height at the
  list's end and gives it back on the same spring. A `.frame(height:)` there didn't work: the scroll
  view reads its length from layout, and the frame jumped to its end value while only its drawing
  animated. `SlackLayout` animates in layout, as `RowHeightLayout` does. Measured after: the list's
  offset never changed, the held row's top held to 0.000, rows above reported no change.
- **A restored place can rest past the list's end** (typicalYear, April: 92pt past it). Any change of
  the list's length then snaps it back, a landing's last rounding pixel included. Not new, and not
  fixed here; a place the reader scrolls to never rests there.
- **The drop's spring settles long after it reads as arrived** (0.45s, bounce 0.3): `.logicallyComplete`
  fired at 0.57s, `.removed` at 1.0s. The haptic and the figure's roll take the first; the flyer gives
  way to the row on the second, when its last frame is the row's to 0.001pt. Two `withAnimation`s with
  one spring in one update stay in step.
- **The flyer animates `travel` as an `Animatable` view and the turn in `CardFlip` inside it,** so neither
  is interpolated twice. The front is a snapshot of the editor's card handed up by `onFace` as a save
  closes it; the sheet's card hides through `\.editorCardHidden` until the next open.
- **With its card gone and contents faded, the dropping sheet is paper on paper:** only its top edge and
  the scrim read, and in recordings it looks gone at once. Worth Jake's eye on the phone.
- **`@Query` is current inside the editor's close:** a new bill and an edit both found their target at
  once, so the landing needs no extra turn.
- **An opening can't wait for the sheet's card to report its rest:** it came 156–297ms after the tap,
  the flyer standing still on its row. It sets off for where the card last rested (`lastCardRest`)
  and corrects its aim if the report differs; only the first open after launch waits.
- **"Once `travel` passes 0.985" means 0.985 of the way, not the value:** travel runs 1 → 0, so it
  passes 0.985 at once. An animated value can't be watched either; the turn is timed from
  `Spring.value` (0.204s into a 0.4s, 0.3-bounce spring).
- **A moved charge keeps its id** (keyed on the rule's date), so "in place" is the same id on the same
  day. Its old place closes at once as the new one opens on the drop's spring: the rows between jump
  one row behind the dropping sheet. `openedRowHeight` goes to `holdSlack`. Worth Jake's eye.
- **A row already open has no height to animate,** so a completion on `hold.height` fired at once.
  The drop runs both completions off one `Transaction` (`addAnimationCompletion`) on `travel`.
- **A restored place past the list's end** (typicalYear, April, above) snapped 92pt as a row opened,
  and the card landed back in the moved row. Scrolled to by hand, every round trip ended at 0.000pt.
- **A tap mid-opening is spent finishing it** (TASTE 12): a date tapped 0.4s in did nothing else. Once,
  while recording, the turn's timer fired 0.62s late, not 0.20s. Both for the device check.
- **`RowFrames` is `@State`, not a `let`:** a `let` on a view struct is rebuilt with every redraw
  of the parent, and would start empty.

- **A day's arrival hides its picture from the save, not from the drop**: the data refreshes as the sheet
  closes, so a day that only just gained a charge would show it early. `DayArrival` starts hidden while
  `arrives` is set, waits `sheetExit × dayArrivalAfter`, then drops; the day's total is held at its old
  figure until the tap at 40% of the drop. Saved into another month than the one shown, nothing arrives.

## If a step is wrong

These specs were written before the code existed. If a step turns out to be
ambiguous, impossible, or wrong, **stop and say so** — don't improvise a fix and
don't silently widen the scope. A wrong spec caught in one message costs far less
than a wrong spec followed to completion.
