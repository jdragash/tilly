# Views: a category view beside the timeline — implementation plan

**Brief:** docs/briefs/views/brief.md
**Settled by:** `DESIGN.md` "The shell", "The month header", "The category view", "Pickers open where
the keypad was" (Category); `DECISIONS.md` "Views switch in place from a menu beside +", "Every
expense has a category, and a category is an emoji, a name and a colour", "The category view is
lanes across one month". Reference behaviour: `docs/prototypes/views-lanes.html` (defaults as
committed), where the docs are silent. Where they disagree, the docs win.

## Already decided — do not reopen

- Lanes, one month at a time. No spans, filters, compare, stacked months or merged layouts.
- Lane order is the user's, from Settings. Never by size or name.
- A category's colour is one of eight tokens, always set; a new one pre-picks the next unused.
- Colour shows in the lanes, the Settings list and the new-category row only. Timeline wells stay grey.
- The readout names the charges on the day under the finger and nothing else. No running total.
- Dragging starts on touch and snaps charge to charge.
- The view button and + are one glass pair; the view button opens a menu of views with a checkmark.
- The app opens on the view it was left on (`@AppStorage`), as Calendar does.
- Header: month name, figure beneath on its own line, in both views.
- + keeps its current 20pt gutter. Calendar measured 17.5pt; that difference is open, not this plan's.
- Accessibility text sizes in the lanes are not designed. The view must render without overlap;
  it need not look designed there.

## Model routing

Steps 2, 3, 4 and 5 prove themselves with tests: Sonnet. Steps 1, 6 and 7 are geometry, fitting
and gesture work a green suite can't judge: Opus (CLAUDE.md, "Implementation splits").

Dependencies: 1 stands alone and may land on `main` by itself. 2 before 3, 4 and 5. 5 before 6.
1 and 6 before 7.

## Steps

### Step 1 — The month header reads on two lines

**Files:** `Tilly/Timeline/MonthHeader.swift` (modified), `Tilly/DesignSystem/Tokens.swift` (modified)

**Interface:**
```swift
struct MonthHeader: View {
    init(section: MonthSection, today: Date, isPinned: Bool = false,
         figure: String? = nil,                       // replaces the section's figure when set (step 6's picked-out category)
         trailingClearance: CGFloat = Tokens.Space.headerTrailingClearance)
}
// Tokens
enum Size { static let groupSlot: CGFloat = 52 }      // Calendar's top group: 158pt for three icons
// headerTrailingClearance becomes: 2 * Size.groupSlot + gutter + gap   (the view button and +)
```

The standard branch becomes `VStack(alignment: .leading, spacing: 0) { nameText; totalText }`; the
accessibility branch keeps its `tight` spacing and vertical padding. `minHeight` stays
`Tokens.Size.headerRow`. Update the type's doc comment (the total no longer sits beside the name).

**Done when:** existing suites green, no test edits expected. Simulator screenshots, light and dark,
default and an accessibility size: the figure sits under the name; the header at default size is
still 60.0pt tall (measure it: a taller header moves every scroll anchor, see
`.claude/rules/swiftui-scrolling.md`); a pinned hand-off between two months looks as before; the
place restores after relaunch. **If the two lines exceed 60pt at the default size, stop and report.**

**Verify:** both commands in CLAUDE.md "Verification", then screenshots.

**Out of scope:** the glass pair (step 6). + still sits alone; the wider clearance is harmless until then.

### Step 2 — Categories carry a colour and an order

**Files:** `Tilly/Models/CategoryColour.swift` (new), `Tilly/Models/CategoryOrdering.swift` (new),
`Tilly/Models/ExpenseCategory.swift` (modified), `Tilly/DesignSystem/Tokens.swift` (modified),
`Tilly/TillyApp.swift` (modified), `Tilly/Developer/DeveloperScenario.swift` and
`Tilly/DesignSystem/PreviewData.swift` (modified: every seeded category gets a colour and order),
`TillyTests/CategoryOrderingTests.swift` (new)

**Interface:**
```swift
/// Identity only. What each one looks like lives in `Tokens.CategoryColour`.
enum CategoryColour: String, CaseIterable, Sendable {
    case blue, orange, aqua, yellow, magenta, green, violet, red   // this order is the pre-pick order
    var name: String   // "Blue", "Orange", "Aqua", "Yellow", "Pink", "Green", "Violet", "Red"
}

@Model final class ExpenseCategory {
    // existing properties unchanged, plus:
    var colourRaw: String = ""      // "" until backfilled; CloudKit-compatible default
    var sortOrder: Int = 0
    var colour: CategoryColour? { get set }   // nil when colourRaw doesn't name a case
    init(id: UUID = UUID(), name: String, emoji: String, colour: CategoryColour? = nil,
         sortOrder: Int = 0, createdAt: Date = Date())
}

enum CategoryOrdering {
    /// The first colour in `CategoryColour.allCases` order not in `used`; once all eight are
    /// used, the least-used, ties to the earlier case.
    static func nextColour(after used: [CategoryColour]) -> CategoryColour
    /// One past the largest; 0 when there are none.
    static func nextSortOrder(after existing: [Int]) -> Int
    /// Renumbers `sortOrder` 0..<n by (sortOrder, createdAt, name), which orders a freshly migrated
    /// store (all 0) by creation; then gives each category without a colour `nextColour(after:)`
    /// the colours already held, in that order. Idempotent.
    static func backfill(_ categories: [ExpenseCategory])
    /// Applies a List move and renumbers 0..<n.
    static func move(_ categories: [ExpenseCategory], from source: IndexSet, to destination: Int)
}

extension Tokens {
    enum CategoryColour { static func color(_ colour: Tilly.CategoryColour) -> Color }
}
```

Token values, light / dark (checked by the dataviz validator in both modes, 2026-09-24):
blue `#2a78d6`/`#3987e5`, orange `#eb6834`/`#d95926`, aqua `#1baf7a`/`#199e70`, yellow
`#eda100`/`#c98500`, magenta `#e87ba4`/`#d55181`, green `#008300`/`#008300`, violet
`#4a3aa7`/`#9085e9`, red `#e34948`/`#e66767`. Build each as a dynamic `UIColor` in `DesignSystem/`.

`TillyApp` runs `CategoryOrdering.backfill` over all categories once at launch and saves, on the
store in use (in DEBUG, whenever `DeveloperSession` switches store too).

**Done when:** these pass, in `CategoryOrderingTests`:
`nextColourWithNoneUsedIsBlue`, `nextColourSkipsUsedOnesInOrder`,
`nextColourWhenAllEightUsedPicksLeastUsedEarliestFirst`, `nextSortOrderOfNoneIsZero`,
`nextSortOrderIsOnePastTheLargest`, `backfillOrdersAMigratedStoreByCreation`,
`backfillBreaksCreationTiesByName`, `backfillRenumbersDuplicatesContiguously`,
`backfillColoursInOrderAroundOnesAlreadyTaken`, `backfillReadsAnUnknownColourAsUnset`,
`backfillIsIdempotent`, `moveRenumbersContiguously`; and in `ModelLayerTests`,
`categoryDefaultsToNoColourAndOrderZero`. Existing suites green. The seam check prints nothing.

**Verify:** CLAUDE.md "Verification"; the seam check in `.claude/rules/views-and-tokens.md`.

**Out of scope:** every view. No colour drawn anywhere yet.

### Step 3 — Settings orders categories and changes their colour

**Files:** `Tilly/Settings/SettingsSheet.swift` (modified), `Tilly/Editor/CategoryPicker.swift`
(modified: `@Query(sort: \ExpenseCategory.sortOrder)`), `Tilly/DesignSystem/Tokens.swift` (modified)

**Interface:**
```swift
// SettingsSheet: @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
// Each row: emoji, name, then a colour swatch that is a Menu holding
//   Picker("Colour", selection:) { ForEach(CategoryColour.allCases) { Label(name, swatch) } }
// ForEach(...).onMove { CategoryOrdering.move(categories, from: $0, to: $1); save }
enum Size { static let colourSwatch: CGFloat = 22 }
```

Footer: `New categories are made while adding an expense.` unchanged. Reordering is by the stock
`List` drag. VoiceOver: the swatch reads "Colour, Blue" and is adjustable through the menu.

**Done when:** in the Simulator (typical-year scenario), a category dragged to a new place stays
there after relaunch and the editor's category list shows the same order; a colour picked from the
menu shows at once and survives relaunch; screenshots light, dark, accessibility size.
**If `.onMove` won't reorder by long-press outside edit mode on iOS 26, stop and report** rather
than adding an Edit button.

**Verify:** CLAUDE.md "Verification", then the Simulator checks.

**Out of scope:** renaming, changing an emoji, deleting categories.

### Step 4 — A new category takes a colour

**Files:** `Tilly/Editor/NewCategoryRow.swift` (modified), `Tilly/Editor/ExpenseEditor.swift`
(modified: `create` unchanged apart from what it receives), `Tilly/DesignSystem/Tokens.swift`

**Interface:**
```swift
struct NewCategoryRow: View {
    let existing: [ExpenseCategory]          // for the pre-pick and the next sortOrder
    let onCreate: (ExpenseCategory) -> Void  // built with colour and sortOrder set
    let onCancel: () -> Void
}
```

Under the emoji-and-name row, a row of the eight swatches (`Size.colourSwatch`, `Space.tight`
apart), the pre-picked one (`nextColour(after:)` of `existing`) ringed. Once an emoji is chosen the
slot's circle fills with the chosen colour instead of `iconWell`. Swatches are buttons labelled
with the colour's name, the chosen one carrying `.isSelected`. Choosing a swatch keeps focus where
it was.

**Done when:** Simulator screenshots show the row above the emoji keyboard and above the name's
keyboard, light and dark; **the amount and name don't move** when the panel opens (measure, as
DESIGN.md requires); a created category lands last in Settings with the colour shown.
**If the swatch row doesn't fit above the keyboard without moving the amount, stop and report.**

**Verify:** CLAUDE.md "Verification", then the Simulator checks.

**Out of scope:** the category picker list's own rows (no colour there yet).

### Step 5 — A month of categories, as data

**Files:** `Tilly/Categories/CategoryMonth.swift` (new: the types), `Tilly/Categories/CategoryMonthBuilder.swift`
(new), `Tilly/Categories/CategoryFormatting.swift` (new), `Tilly/Models/Expense+Timeline.swift`
(modified), `TillyTests/CategoryMonthBuilderTests.swift`, `TillyTests/CategoryFormattingTests.swift` (new)

**Interface:**
```swift
struct CategoryInfo: Equatable, Sendable { let id: UUID; let emoji: String; let name: String; let colour: CategoryColour? }

struct LaneDot: Identifiable, Equatable, Sendable {
    let entry: TimelineEntry          // date, amount, state, name, expenseID, scheduledDate
    var id: String { entry.id }
    var day: Int                      // day of month of entry.date
}
struct CategoryLane: Identifiable, Equatable, Sendable {
    let category: CategoryInfo?       // nil: charges saved before categories existed
    let dots: [LaneDot]               // by day ascending, a day's by amount descending
    let total: Decimal                // == sum of its dots' amounts, skipped excluded
    var id: String { category?.id.uuidString ?? "uncategorised" }
}
struct QuietCategory: Equatable, Sendable { let category: CategoryInfo; let next: Date? }
struct NextCharge: Identifiable, Equatable, Sendable { let entry: TimelineEntry; let category: CategoryInfo?; var id: String { entry.id } }

struct CategoryMonth: Equatable, Sendable {
    let section: MonthSection         // from TimelineBuilder.month; the header reads it
    let lanes: [CategoryLane]         // categories with a charge this month, in Settings order; uncategorised last
    let quiet: [QuietCategory]        // categories with bills but none this month, in Settings order
    let next: [NextCharge]            // current month only: 3 soonest after today, at most one per category
    let dotScale: Decimal             // largest amount of any bill's rule or override, ever: the same for every month
}

enum CategoryMonthBuilder {
    /// `categories` in Settings order. `categoryOf` maps an expense's snapshot id to its category.
    static func month(_ month: MonthKey, expenses: [TimelineExpense], categoryOf: [UUID: UUID],
                      categories: [CategoryInfo], today: Date, calendar: Calendar, isCurrent: Bool) -> CategoryMonth
    /// How far ahead `next` and `QuietCategory.next` look.
    static let lookAheadMonths = 13
}

extension Expense { static func categoryMap(_ expenses: [Expense]) -> [UUID: UUID] }

enum CategoryFormatting {
    static func relativeDay(_ date: Date, today: Date, calendar: Calendar, locale: Locale) -> String   // "Tomorrow", "Saturday" (2–6 days), "Oct 15"
    static func quietLine(_ quiet: [QuietCategory], month: String, calendar: Calendar, locale: Locale) -> String?   // "Nothing in September: 📗 next Nov 3 · ✈️ next Jan 12"; nil when empty; a category with no next shows its emoji alone
    static func focusFigure(_ lane: CategoryLane, locale: Locale) -> String            // "🏠 Home −€1,259"
    static func laneLabel(_ lane: CategoryLane, locale: Locale) -> String              // VoiceOver: "Home, −€1,259, 3 charges"
    static func readoutDate(_ date: Date, calendar: Calendar, locale: Locale) -> String // "Sat 12 Sep"
}
```

Built on `TimelineBuilder.month`, so rounding, state and the effective date are the timeline's own.

**Done when:** these pass. `CategoryMonthBuilderTests`: `lanesFollowSettingsOrderNotSize`,
`laneTotalEqualsItsDots`, `laneTotalsSumToTheMonthTotal`, `aCategoryWithNothingThisMonthIsQuietWithItsNextDate`
(a quarterly bill), `aQuietCategoryWithNoFutureChargeHasNoNext` (an ended bill),
`aCategoryWithNoBillsAtAllIsLeftOut`, `uncategorisedChargesFormTheLastLane`,
`skippedChargesAreNeitherDotsNorTotalled`, `aZeroChargeIsADotAndAddsNothing`,
`twoChargesOnOneDayAreTwoDotsLargestFirst`, `aMovedChargeSitsOnItsNewDay`,
`dotScaleIsTheLargestAmountEverNotThisMonths`, `nextIsTheThreeSoonestAtMostOnePerCategory`,
`nextStartsTomorrowNotToday`, `nextReachesAYearlyBillElevenMonthsOut`, `nextIsEmptyForOtherMonths`.
`CategoryFormattingTests`: `relativeDayTomorrow`, `relativeDayNamesTheWeekdayWithinSixDays`,
`relativeDayFallsBackToMonthAndDay`, `quietLineJoinsCategoriesWithTheirNext`,
`quietLineShowsAnEmojiAloneWithNoNext`, `quietLineIsNilWhenNothingIsQuiet`,
`focusFigureReadsEmojiNameAndTotal`, `laneLabelCountsCharges`, one non-euro locale case.

**Verify:** CLAUDE.md "Verification".

**Out of scope:** any view.

### Step 6 — The category view, drawn, behind the view menu

**Files:** `Tilly/Shell/ViewMode.swift` (new), `Tilly/Shell/HeaderControls.swift` (new: the glass
pair), `Tilly/Categories/CategoryView.swift` (new: the screen), `Tilly/Categories/LanesView.swift`
(new: axis, today line, lanes, dots, totals), `Tilly/Categories/MonthArrows.swift` (new),
`Tilly/Timeline/TimelineView.swift` (modified), `Tilly/Developer/DeveloperScenario.swift` (modified:
`.manyCategories`, fourteen categories), `Tilly/DesignSystem/Tokens.swift` (modified),
`TillyTests/ViewModeTests.swift` (new)

**Interface:**
```swift
enum ViewMode: String, CaseIterable, Identifiable, Sendable {
    case timeline, categories                                   // raw values are stored; never rename
    var title: String        // "Timeline", "Categories"
    var systemImage: String  // "list.bullet", "chart.dots.scatter"
}

/// The view button (a Menu with an inline Picker over ViewMode) and +, in one glass capsule,
/// 2 × Size.groupSlot wide, Size.floatingButton tall.
struct HeaderControls: View { @Binding var mode: ViewMode; let onAdd: () -> Void }

struct MonthArrows: View { let canGoBack: Bool; let canGoForward: Bool; let step: (Int) -> Void }

struct CategoryView: View {
    @Binding var month: MonthKey
    let window: TimelineWindow          // floor and ceiling bound the arrows
    let expenses: [Expense]
    let today: Date
    let bottomClearance: CGFloat
    let onOpen: (TimelineEntry) -> Void
    // @Query(sort: \ExpenseCategory.sortOrder) inside; picked-out category is @State, cleared on month change
}
```

`TimelineView`: `@AppStorage("viewMode") var mode: ViewMode = .timeline` and
`@State var categoryMonth: MonthKey`. The timeline stays mounted under the category view, hidden
(`opacity 0`, no hit testing, hidden from accessibility), so its place survives a switch. The pair
replaces the lone + overlay in both views. The month button sets `categoryMonth` to the current month
in the category view and scrolls back as now in the timeline. With no expenses, both views show the
empty state. `openEntry` serves both.

`MonthArrows` sits left of the pair, `Space.groupGap` (8pt, drawn, not measured) apart; each arrow
a `Size.groupSlot` slot in one glass capsule. Disabled at the window's floor and ceiling. VoiceOver:
"Previous month" / "Next month".

Lanes, per DESIGN.md "The category view", with these values as tokens (from the prototype):
lane height `clamp(floor(available / lanes), 30, 60)` where `available` is what the screen has
between the axis and the quiet line, `Next` and the bottom clearance, measured; past 30pt the page
scrolls (`.scrollDisabled` while it fits). Dot diameter
`7 + (maxD − 7) · √(amount / dotScale)`, `maxD = min(0.78 · laneHeight, 36)`; €0 and a missing amount
draw an 8pt dashed ring. Charged: filled; upcoming: 2pt ring on `Surface.base`; every dot a 2pt
`Surface.base` halo. Two dots on one day offset 5pt. Emoji column 40pt, emoji size
`clamp(0.46 · laneHeight, 15, 26)` (a `Tokens.Text` function, like `editorAmount`). Totals column
right-aligned in the last 70pt. Axis 18pt: days 1, 8, 15, 22 and the last, dropping any within 2 days
of today, today's day bold. Today: a 1.5pt line at 75% opacity. Hairlines between lanes, not after the last.
A picked-out category fades the other lanes to 22% and sets the header's `figure` to
`CategoryFormatting.focusFigure`. Tapping a dot calls `onOpen`. Dots are buttons for VoiceOver
(`TimelineFormatting.accessibilityLabel(for: entry…)`); each lane's emoji is a button labelled
`laneLabel` with the hint "Picks out this category".

**Done when:** `ViewModeTests`: `rawValuesAreStable`, `defaultIsTimeline`. Existing suites green.
Simulator screenshots, light and dark, typical-year and many-categories scenarios: the menu open with
its checkmark; the category view on the current month and on a month ahead; the arrows dimmed at
each end; a picked-out category; an accessibility text size with nothing overlapping. Switching
views and back leaves the timeline exactly where it was (screenshot both). The month button returns
from a month ahead. A tapped dot opens that charge in the editor. The app relaunches into the view
it was left on.

**Verify:** CLAUDE.md "Verification", the seam check, then the Simulator checks.

**Out of scope:** dragging and the readout (step 7). Timeline wells stay grey.

### Step 7 — Dragging reads charges

**Files:** `Tilly/Categories/LaneScrubbing.swift` (new), `Tilly/Categories/CategoryReadout.swift`
(new), `Tilly/Categories/LanesView.swift` (modified), `TillyTests/LaneScrubbingTests.swift` (new)

**Interface:**
```swift
enum LaneScrubbing {
    /// The charge day nearest the finger's day; ties to the earlier. nil when there are none.
    static func snappedDay(at x: CGFloat, plot: ClosedRange<CGFloat>, daysInMonth: Int, chargeDays: [Int]) -> Int?
    /// Under this much travel and this long, a touch is a tap.
    static let tapSlop: CGFloat = 6
    static let tapDuration: TimeInterval = 0.4
}

/// Floats above the lanes, centred on the line, clamped to the gutters: the day, then each of
/// that day's charges as emoji, name and amount, still-to-come ones secondary. Glass: it floats.
struct CategoryReadout: View { let date: Date; let charges: [TimelineEntry]; let emojiOf: (TimelineEntry) -> String? }
```

A `DragGesture(minimumDistance: 0)` over the plot. While it moves: a 2pt line at the snapped day
across all lanes, that day's dots scaled 1.18, the rest at 28%, the readout above the plot's top edge
(10pt clear), and `.sensoryFeedback(.selection, trigger:)` on each new day. A picked-out category
limits `chargeDays` to its own. On release under `tapSlop` and `tapDuration`, the nearest dot within
22pt opens; otherwise the readout goes. Taps on the emoji column never start a drag.

**Done when:** `LaneScrubbingTests`: `snapsToTheNearestChargeDay`, `aTieGoesToTheEarlierDay`,
`beforeThePlotSnapsToTheFirstCharge`, `pastThePlotSnapsToTheLast`, `noChargesSnapsNowhere`,
`oneChargeAlwaysSnapsToIt`. On the Simulator, a `touch_path` drag held mid-way screenshots the line,
the readout and the faded dots, light and dark; a quick tap on a dot opens its charge; a drag that
starts on a dot doesn't open it. Jake feels the ticks and the response on his phone.

**Verify:** CLAUDE.md "Verification", then the Simulator checks.

**Out of scope:** anything VoiceOver can't already reach through the dots from step 6.

## Lessons

- **Step 1: two lines fit the 60pt row.** Name over figure measured 60.00pt at the default size on
  the iPhone 17 simulator (iOS 27), every header, before and after a relaunch; `accessibility-large`
  stays on its own branch at 104.33pt. The standard branch needs `.frame(maxWidth: .infinity,
  alignment: .leading)` once the `HStack`'s `Spacer` goes, or the pinned ground stops short of full width.
- **`simctl launch --console-pty` hung here with no output** (from the agent's shell, with and
  without `script`), and `--stdout=` to the scratchpad wrote nothing. A temporary `NSLog` read back
  with `simctl spawn booted log show --last 1m --predicate 'eventMessage CONTAINS "…"'` worked.

## If a step is wrong

These specs were written before the code existed. If a step turns out to be
ambiguous, impossible, or wrong, **stop and say so** — don't improvise a fix and
don't silently widen the scope. A wrong spec caught in one message costs far less
than a wrong spec followed to completion.
