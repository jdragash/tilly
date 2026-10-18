# Tilly, Drawn, on the timeline — implementation plan

**Brief:** docs/briefs/drawn-timeline/brief.md
**Settled by:** `DESIGN.md` (state grammar, the look, the timeline, the editor, the pockets);
`DECISIONS.md` ("Tilly is Drawn, on the token layer…", "Every expense has a category, and a category
is a symbol…", "The timeline is a Wallet stack…"). Reference: `docs/prototypes/combined.html` with
its Look topic on Drawn · I · Wallet stack · Colour · White, and `docs/prototypes/edit-revisit-card.html`.

## Already decided — do not reopen

- Drawn, I (symbols), Wallet stack, colour cards, an opaque sheet. Not cream, not glass, not handwriting.
- A category's picture is a symbol from Tilly's own searchable set. A category made before symbols
  shows its emoji until one is picked; nothing migrates it.
- The boil runs only on the editor's card, and not under Reduce Motion. Everywhere else the picture
  holds still.
- The glass controls stay stock. Sheets are paper too.
- The calendar and the category view take the ground, the type, the colours and the picture; their
  layouts don't change.
- Amounts stay whole; the prototype's cents are its own.
- No motion between surfaces in this plan (the hand, landing, opening a bill): that is the next brief.
- Prototype values below are starting points and live as tokens. Jake tunes them on the phone.

## Model routing

Steps 1 to 6 are Sonnet's. Step 7 is Opus's: a green suite stays green with a broken stack
(`CLAUDE.md`, model routing; `.claude/rules/swiftui-scrolling.md`).

## Steps

### Step 1 — Give a category a symbol, and carry its picture and colour to every surface

Order: first. Every later step reads `CategoryPicture`.

**Files:**
- modified `Tilly/Models/ExpenseCategory.swift` — `var symbol: String = ""` (an SF Symbol name; "" =
  none). Defaulted, so the store is CloudKit-shaped and needs no migration. `init` gains
  `symbol: String = ""`.
- new `Tilly/Models/CategoryPicture.swift`
- modified, `emoji: String?` → `picture: CategoryPicture` (and `emoji: String` → `picture`):
  `TimelineExpense`, `TimelineEntry` (`Timeline/TimelineModels.swift`), `TimelineBuilder`,
  `Expense+Timeline.swift`, `CategoryInfo` (`Categories/CategoryMonth.swift`), `PocketContent`,
  `CategoryReadout`/`CategoryView` (`emojis` → `pictures: [String: CategoryPicture]`),
  `AllBillsSheet`, `BillRowView` (`emoji` → `picture`), `DeveloperScenario`, `PreviewData`.
- `TimelineExpense` and `TimelineEntry` also gain `colour: CategoryColour?` (the category's).
- modified `Tilly/Categories/CategoryFormatting.swift`: `quietLine`, `focusFigure`, `focusLabel` stop
  interpolating the emoji. Views put the picture in front with `picture.inline` (below).
- modified `AllBillsSheet` lines that build `"\(category.emoji) \(category.name)"`: name only, picture
  in front in the view.
- modified tests: `TimelineBuilderTests`, `CalendarMonthBuilderTests`, `YearBuilderTests`,
  `CategoryMonthBuilderTests`, `CategoryFormattingTests`, `AllBillsBuilderTests`,
  `PocketContentsTests`, `ModelLayerTests`, `EditSessionTests`, `BillEditorTests`,
  `ExpenseDraftTests`, `CategoryOrderingTests`, `CalendarFormattingTests`,
  `TimelineFormattingTests`: only where they construct or assert an emoji field. The formatting
  tests' expected strings lose their emoji; that is this step's change, and no other assertion moves.

**Interface:**
```swift
/// What draws a category: its symbol, or the emoji it was made with before symbols, or nothing
/// for data saved before categories existed.
enum CategoryPicture: Equatable, Hashable, Sendable {
    case symbol(String)
    case emoji(String)
    case none

    init(symbol: String, emoji: String)          // symbol wins when non-empty, then emoji, else .none
    init(_ category: ExpenseCategory?)

    /// For a line of text: the symbol as `Image(systemName:)`, plain, or the emoji. Empty for `.none`.
    var inline: Text { get }
}
```

**Done when:** the app builds, the whole suite passes, and these new tests pass in
`TillyTests/CategoryPictureTests.swift`: `symbolWinsOverEmoji`, `emojiWhenNoSymbol`,
`noneWhenBothEmpty`, `nilCategoryIsNone`, `whitespaceSymbolIsNone`. `TimelineBuilderTests` gains
`entryCarriesCategoryColour` and `entryCarriesSymbolPicture`.

**Verify:** `xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0' test`
and the seam check in `.claude/rules/views-and-tokens.md`.

**Out of scope:** how a picture is drawn (step 3); picking a symbol (steps 4 and 5). Views keep showing
the emoji through a temporary `Text` of `picture.inline` until step 3.

### Step 2 — Lay the paper, the grain and the rounded type, and make the drawn shapes

Depends on nothing but step 1's build.

**Files:**
- modified `Tilly/DesignSystem/Tokens.swift`: new `enum Drawn` (values below); `Surface.base` and
  `Surface.pinned` become `Drawn.paper`; new `Text.design: Font.Design = .rounded`.
- new `Tilly/DesignSystem/Drawn/Grain.swift`, `RoughRoundedRectangle.swift`, `Wash.swift`,
  `DottedOutline.swift`, `Drawn.metal`.
- modified `Tilly/TillyApp.swift`: `.fontDesign(Tokens.Text.design)` and `.drawnGround()` on the
  root in both branches. Each sheet's root (`ExpenseEditor`, `AllBillsSheet`, `SettingsSheet`) gets
  `.drawnGround()` too, and `.fontDesign` if a screenshot shows a sheet not inheriting it.

**Values** (from the prototype's `DT`, as `Tokens.Drawn` statics with a comment saying so):
```
paper            light #EFEEEA  dark #1D1C1A
paperCard        light #F7F6F2  dark #2B2A27
ink              light #1C1B19  dark #F2F1EE
ink2             light #8A8883  dark #8D8B86
grainTile        160 (pt square), grainAlpha 9/255 on a random half of its pixels, black or white
edgeWobble       5      (pt, the edge's displacement)
edgeFrequency    0.012  (per pt)
edgeStep         3      (pt between sampled points on the edge)
roughAmplitude   0.6    (pt, the second, finer wobble)
bloom            0.22   (how far the fill's alpha varies)
bloomFrequency   0.006
cardFill         0.9    (fill opacity)   cardEdge 1 (edge opacity)   edgeWidth 3
washFill         0.72   washEdge 0.85   washWell 0.24
dotWidth 2, dotDash [0.1, 5], round caps, dotOpacity 0.9
```

**Interface:**
```swift
enum Grain {
    /// One tile, made once from a fixed seed, so every launch draws the same paper.
    static let tile: UIImage
}
extension View {
    /// The paper, with the grain tiled over it, ignoring safe areas.
    func drawnGround() -> some View
}

/// A rounded rectangle whose edge wobbles by seeded noise: the same seed draws the same edge, so
/// a row redrawn while scrolling doesn't shimmer.
struct RoughRoundedRectangle: Shape {
    var cornerRadii: RectangleCornerRadii
    var seed: UInt64
    var wobble: CGFloat = Tokens.Drawn.edgeWobble
    func path(in rect: CGRect) -> Path
}

/// A colour laid down as a wash: paper first, so it hides what's beneath, then the colour at
/// `cardFill` with its edge at `cardEdge`, its alpha varied by `bloom`.
struct Wash: View {
    let colour: Color
    let cornerRadii: RectangleCornerRadii
    let seed: UInt64
}

/// What's still to come: paper inside a dotted line in the colour.
struct DottedOutline: View {
    let colour: Color
    let cornerRadii: RectangleCornerRadii
    let seed: UInt64
}
```
`Drawn.metal` holds `[[stitchable]] half4 bloom(float2 position, half4 color, float frequency, float strength, float seed)`
and `[[stitchable]] float2 roughen(float2 position, float frequency, float amount, float seed)`
(value noise, seeded). Used through `ShaderLibrary.default`.

**Done when:** these pass in `TillyTests/RoughRoundedRectangleTests.swift`: `sameSeedSamePath`,
`differentSeedDifferentPath`, `staysWithinWobbleOfRect` (every point within `wobble +
roughAmplitude` of the plain rounded rect), `squareCornersStaySquare` (a 0 radius corner's point
within the wobble of the rect's corner), `tinyRectStillCloses`. Screenshots of the timeline, the
editor and Settings in light and dark show paper with a grain and rounded type, the glass stock.

**Verify:** the test command above; screenshots per `.claude/rules/simulator.md`.

**Out of scope:** the rows (step 7), the card's face (step 6), the picture (step 3).

### Step 3 — Draw each category's picture

Depends on steps 1 and 2.

**Files:**
- new `Tilly/DesignSystem/Drawn/CategoryPictureView.swift`
- modified, `Text(emoji)` and friends → `CategoryPictureView`: `OccurrenceRow` (the well),
  `CalendarDayCell` (one, or two overlapped), `LanesView` and `CategoryView` (a lane's lead and the
  `Next` rows), `CategoryReadout`, `BillCardView`, `PocketGrid` (the lip), `EditorCard` (the tile),
  `SettingsSheet` (the row). Lines of text (`quietLine`, `focusLabel`, All bills' title) use
  `picture.inline`.
- `Tokens.Size`/`Tokens.Text`: a picture size per place, from the font sizes they replace.

**Interface:**
```swift
/// A category's picture as Tilly draws it. A symbol is roughened (`roughen`), in its colour on a
/// faint wash, or white on a faint white wash where it sits on its own solid card. An emoji is
/// drawn as itself. `.none` draws nothing.
struct CategoryPictureView: View {
    let picture: CategoryPicture
    let colour: CategoryColour?
    let size: CGFloat
    var onCard: Bool = false
    /// Three drawings swapped every `Tokens.Motion.boilStep`; ignored under Reduce Motion.
    var boils: Bool = false
}
```
Tokens: `Motion.boilStep = 0.125`, `Drawn.roughFrequency = 0.32`, `Drawn.roughAmount = 1.3`,
`Drawn.boilSeeds: [Float] = [1, 2, 3]`, `Drawn.wellWash = washWell` (0.24), `Drawn.onCardWash = 0.35`.
The roughening is the shader on `Image(systemName:)` at `size`, with
`.distortionEffect(…, maxSampleOffset: CGSize(width: roughAmount, height: roughAmount))`.

**Done when:** the suite passes; screenshots in light, dark and an accessibility size show a
symbol category and an emoji category side by side on the timeline, the calendar's month, a lane,
All bills, the pockets, Settings and the card. `#Preview` covers every case of `CategoryPicture`
with and without `onCard`, and with `boils`.

**Verify:** the test command; the seam check; screenshots.

**Out of scope:** the timeline's cards (step 7); the editor's face (step 6).

### Step 4 — Write Tilly's symbol set and its search

Independent of steps 2 and 3; needs step 1.

**Files:** new `Tilly/Categories/SymbolCatalog.swift`; new `TillyTests/SymbolCatalogTests.swift`.

**Interface:**
```swift
struct SymbolEntry: Identifiable, Hashable, Sendable {
    let name: String                // an SF Symbol name
    let words: [String]             // lowercase search words, the plain English for it
    var id: String { name }
}
struct SymbolSection: Identifiable, Sendable {
    let title: String
    let entries: [SymbolEntry]
    var id: String { title }
}
enum SymbolCatalog {
    static let sections: [SymbolSection]
    /// Every entry whose name components or words start with each word of `query`, ignoring case
    /// and diacritics, in catalogue order. Empty or blank `query` returns every entry.
    static func search(_ query: String) -> [SymbolEntry]
}
```
Sections, in this order: Home, Utilities, Transport, Phone & internet, Subscriptions & media, Health,
Insurance & money, Learning & work, Family & pets, Shopping, Travel, Giving, Other. Between 250
and 400 symbols in all, outline (not `.fill`) variants, each available on iOS 27. No symbol twice.

**Done when:** `everyNameResolves` (`UIImage(systemName:)` is non-nil for every entry),
`noDuplicateNames`, `countWithinBounds`, `blankQueryReturnsAll`, `searchIsCaseAndDiacriticInsensitive`
("CAFÉ" finds the cup), `searchMatchesNameComponents` ("car" finds `car`), `searchMatchesWords`
("rent" finds the house), `everyWordMustMatch` ("water bill" narrows), `unknownQueryIsEmpty`.

**Verify:** the test command.

**Out of scope:** any UI.

### Step 5 — Pick a symbol when making a category, and change it in Settings

Depends on steps 3 and 4.

**Files:**
- new `Tilly/Categories/SymbolPicker.swift`
- modified `Tilly/Editor/NewCategoryRow.swift`: the emoji slot becomes a picture slot; the panel under
  the slot, name and colours is the `SymbolPicker` while the name isn't being typed. Picking a symbol
  fills the slot and moves focus to the name. Return makes the category, needing both, as now. The
  category is made with `symbol:` and `emoji: ""`.
- deleted `Tilly/Editor/EmojiTextField.swift` and `EmojiInput` in `ExpenseDraft.swift`, with
  their tests in `ExpenseDraftTests` (this step exists to remove them).
- modified `Tilly/Settings/SettingsSheet.swift`: tapping a row's picture shows the `SymbolPicker`
  inline under that row; picking sets `symbol` and saves. One row open at a time.
- modified `PocketGrid`'s `New` hint: "Picks a symbol to make one".

**Interface:**
```swift
/// Tilly's symbols in the keypad's place: a search field over a grid, in sections, each symbol
/// drawn as the category will draw it, in `colour`.
struct SymbolPicker: View {
    let colour: CategoryColour?
    let selection: String?
    let onPick: (String) -> Void
}
```
Grid: `Tokens.Size.symbolCell` (44), adaptive columns, `Tokens.Space.tight` between. A picked
symbol has `Tokens.Stroke.pocketRing` round it in `Ink.accent`. Each cell's accessibility label is
its first word, capitalised.

**Done when:** the suite passes; a new category is made from the editor with a symbol in the
Simulator, shown in the pockets, on the card and in Settings; an emoji category is changed to a
symbol in Settings and its rows change with it. Screenshots in light, dark, and an accessibility
size. VoiceOver reads a symbol cell and the slot.

**Verify:** the test command; screenshots; VoiceOver in the Simulator's Accessibility Inspector.

**Out of scope:** renaming or deleting categories in Settings; the hand (next brief).

### Step 6 — Wash the editor's card

Depends on steps 2 and 3.

**Files:** modified `Tilly/Editor/EditorCard.swift`: `fill` draws a `Wash` in the category's colour,
or `Chart.uncoloured` before it has one, with `RectangleCornerRadii` of `Radius.card` all round
and a fixed seed per category id; the card's `.shadow` keeps its tokens. The tile's picture is
`CategoryPictureView(…, onCard: true, boils: true)`. `Tokens.CategoryColour.cardFill` is deleted.

**Done when:** the suite passes; screenshots of the editor grey, coloured and with each of two
categories crossfading, light and dark, an accessibility size; Reduce Motion stills the boil.

**Verify:** the test command; screenshots; Reduce Motion per `simulator.md`.

**Out of scope:** any motion of the card (next brief); the pockets' look beyond their picture.

### Step 7 — Make the timeline a Wallet stack (Opus)

Depends on steps 2, 3 and 6.

**Files:**
- modified `Tilly/Timeline/OccurrenceRow.swift`: the row draws its card behind itself.
- modified `Tilly/Timeline/MonthSectionView.swift`: passes each row whether it is the month's last.
- modified `Tokens.swift`: `Size.stackRow` 64 (the row's height, from the prototype, up from
  `Size.row` 52 for the timeline only), `Space.stackTuck` 12, `Space.stackInset` 12 (each side),
  `Space.stackTop` 11, `Space.stackLeading` 14, `Radius.stackCard` 14, `Size.stackPicture` 36,
  `Space.stackMonthBottom` 14 (under a month's last card), `Shadow.stackColour` black 16%,
  `Shadow.stackRadius` 1.25, `Shadow.stackY` −1, `Ink.onStackSoft` white 82%.

**Interface:**
```swift
struct OccurrenceRow: View {
    let entry: TimelineEntry
    var isMarked = false
    /// The month's last card is whole; every other one is tucked under the next.
    var isLast = false
}
```
The card sits behind the row, `stackInset` in from each side, from the row's top to `stackTuck`
below its bottom, so the next row's card covers it. Corners: `stackCard` at the top, 0 at the bottom
unless `isLast`. Charged: a `Wash` in `colour` (uncoloured `Chart.uncoloured`), name and amount
`Ink.onCard`, date `Ink.onStackSoft`, picture `onCard: true`, the shadow above. Upcoming: a
`DottedOutline` in the colour, ink as the state grammar's. Skipped: a `DottedOutline` in
`Ink.tertiary`, struck through as now. Content aligns to the card's top: `stackTop`, `stackLeading`.
Seeds come from `entry.id`, so a row draws the same edge every time. Accessibility sizes keep the
same card, grown with the row. `isMarked` tints the card's content, not the row.

**Done when:**
- The suite passes, and nothing in `TimelineView`'s anchoring changes: the row height comes from
  the row, and `scrollMarker`'s zero-high targets still land at a row's top.
- Screenshots of a month with a long name, a day with two charges and a day with one, a skipped
  charge, upcoming and charged, an ended bill's date line, the empty state and a month with nothing
  charged yet; light, dark, an accessibility size.
- The place survives a relaunch, to the month (`TimelinePlaceTests`, plus a manual relaunch).
- A calendar tap lands on its day's first card, top aligned, in the Simulator and on the phone.
- Scrolling a year on the phone shows no hitch in Instruments' Animation Hitches.

**Verify:** the test command; screenshots; `xcrun xctrace record --template 'Animation Hitches'` on
the device while flinging through a year.

**Out of scope:** opening a row (the next brief's flip), the month header's layout.

## Lessons

- **Metal needs the Metal Toolchain**, a separate 840MB Xcode component: `xcodebuild -downloadComponent
  MetalToolchain`. Without it any `.metal` file fails the build.
- **Module-default main-actor isolation reaches `Shape`.** A `Shape` that reads `Tokens` can't conform
  (the conformance "crosses into main actor-isolated code"). `Tokens.Drawn` is `nonisolated`, and the
  shapes and `CategoryPicture` (read from `Expense+Timeline`) are `nonisolated` too.
- **A screen's own `.background(Surface.base)` hides the root's grain.** Screens use `.drawnPaper()`
  and a sheet's root `.drawnGround()` (which also sets `presentationBackground`); `Surface.base` is
  paper without grain, for fills that sit on something.
- **The app has its own `TimelineView`**, which shadows SwiftUI's: write `SwiftUI.TimelineView` for the
  boil's clock.
- **`CategoryPictureView.size` is the square of the picture**, wash included: the symbol fills 0.58
  of it, an emoji 0.7. An emoji gets no wash, so an emoji category's row has no well; a symbol's
  roughening (`roughen`, frequency 0.32, amount 1.3) reads clearly from 22pt up.
- **Pictures don't scale with Dynamic Type**; each place has a size token, and the accessibility row
  takes `iconAccessible`. Text lines (quiet line, picked lane's label, chips) keep `picture.inline`,
  where a symbol draws as a plain glyph.

- **The catalogue is 332 symbols once the invalid ones were struck** (`ladder`, `fence`, `recycle`,
  `piggybank`, `gift.card`, `passport` don't exist on iOS 27; `everyNameResolves` catches this).
- **The symbols take the keypad's place under the row** at `Size.symbolPicker` (340); the name's
  keyboard replaces them while a name is typed (`nameFocused`), so there's no second keyboard on screen.
  VoiceOver was not driven in the Simulator; labels and values are set but unheard.

## If a step is wrong

These specs were written before the code existed. If a step turns out to be
ambiguous, impossible, or wrong, **stop and say so** — don't improvise a fix and
don't silently widen the scope. A wrong spec caught in one message costs far less
than a wrong spec followed to completion.
