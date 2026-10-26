# Changing categories, on their own sheet — implementation plan

**Settled by:** `DESIGN.md` ("The shell"; "The picker is a grid of category cards"; "A category is
made and changed on its own sheet"); `DECISIONS.md` ("Every expense has a category…").
**Reference:** `docs/prototypes/category-editor.html`, with Tune on `search: bottom`, `findEdit: press`,
`cardInfo: cost`, `infoAt: below`. Every value below comes from it; a value not listed here is read
from the prototype's CSS, never guessed. Observations 2, 3 and 4.

## Already decided — do not reopen

- One sheet makes and changes a category. It slides over the bill editor or Settings; stacking is
  the system's (`.sheet` from a sheet). ✕ left; trash (changing only) and ✓ right.
- Card and colours are fixed at the top; only the symbols scroll. The name is typed on the card.
  No row of suggestions. Search is a capsule floating at the bottom.
- A new category starts on `tag`. While nothing is picked, a guess from the name replaces it and the
  picture carries a spark badge. Picking a symbol ends guessing for that sheet.
- Deleting a category deletes its bills, all their charges and overrides, after one alert.
- All bills stays read-only. Editing lives in Settings and in the bill editor's long-press.
- Settings cards show `€95/mo` under the name (`No bills` for none). Sort arranges once, with Undo.
- The prototype's `Made Home` / `Saved Home` / `Deleted Home` toasts are its own feedback and don't
  ship (tenet 1). The sort's Undo toast ships: it is the only way back from a sort.
- `NewCategoryRow` and the editor's `.newCategory` panel go. Settings' list rows, colour menu and
  inline `SymbolPicker` go.
- DialKit is a Debug-only dev tool (`CLAUDE.md`, code). Release reads `Tokens` and nothing else.

## Model routing

Steps 1–4 and 6 are Sonnet's. Steps 5 and 7 are Opus's: a fixed header over a scrolling grid with a
floating search, and drag-to-reorder in a grid, both stay green with the geometry broken.

## Steps

### Step 1 — Delete a category with its bills

**Files:** new `Tilly/Models/CategoryRemoval.swift`; new `TillyTests/CategoryRemovalTests.swift`.
`ExpenseCategory`'s relationship comment changes to say deletion goes through `CategoryRemoval`; the
rule stays `.nullify`, so a stray `context.delete(category)` still never takes bills silently.

```swift
enum CategoryRemoval {
    /// Bills (series, by `seriesKey`) filed under `category`, for the alert's count.
    static func billCount(of category: ExpenseCategory) -> Int
    /// Deletes every `Expense` filed under it (overrides cascade), then the category, then saves.
    static func delete(_ category: ExpenseCategory, context: ModelContext) throws
}
```

**Done when:** `deletesCategoryAndItsBills`, `deletesEveryRecordOfASeries`, `overridesGoWithTheirBill`,
`otherCategoriesBillsStay`, `billCountCountsSeriesNotRecords` pass.

### Step 2 — Figures for a category, and sorting once

**Files:** modified `Tilly/Models/CategoryOrdering.swift`; new `Tilly/Categories/CategoryFigures.swift`;
tests in `CategoryOrderingTests`, new `CategoryFiguresTests`.

- `CategoryFigures.figures(_ inputs: [BillInput], categories: [CategoryInfo], today:, calendar:) ->
  [UUID: (bills: Int, monthly: Decimal)]` from `AllBillsBuilder.bills(… period: .monthly)`: a
  category's running rows and its card total. A category with none is `(0, 0)`.
- `enum CategorySort: CaseIterable { case colour, name, monthlyCost, billCount }` with `title`
  (`Colour`, `Name`, `Monthly cost`, `Number of bills`) and `detail` (`rainbow`, `A to Z`,
  `most first`, `most first`).
- `CategoryOrdering.arrange(_ categories:, by: CategorySort, figures:) -> [UUID]` returns the previous
  order (ids) for Undo and rewrites `sortOrder` 0…n. Colour is rainbow: red, orange, yellow, green,
  teal, blue, purple, pink, uncoloured last. Name uses `localizedStandardCompare`. Ties fall back to
  name. `restore(_ categories:, order: [UUID])` puts an order back.

**Done when:** `colourSortsAsARainbow`, `nameSortsAToZ`, `costSortsMostFirst`, `countSortsMostFirst`,
`tiesFallBackToName`, `restorePutsTheOrderBack`, `figuresCountRunningBillsOnly`,
`figuresAreMonthlyShares` pass.

### Step 3 — Guess a symbol from the name

**Files:** new `Tilly/Categories/SymbolGuess.swift`, new `TillyTests/SymbolGuessTests.swift`.

```swift
enum SymbolGuess {
    static let fallback = "tag"
    /// A catalogue symbol for `name`, or nil. Keywords first, then word similarity.
    static func guess(for name: String) -> String?
    /// Up to `limit` symbols close to `query`, for a search with no matches.
    static func closest(to query: String, limit: Int) -> [String]
}
```

1. **Keywords:** each word of the name, folded as `SymbolCatalog.search` folds, matched whole against
   the catalogue's words, then against `brands`, a table in this file of the services people name
   categories after. Take the brand list from the prototype's `KEYWORDS` additions, mapped to this
   catalogue's names (`tv`, `music.note`, `icloud`, `gamecontroller`, `book`, `fork.knife`,
   `dumbbell`, `car`). First match in catalogue order wins.
2. **Similarity:** `NLEmbedding.wordEmbedding(for: .english)`, loaded once. For each word of the name,
   the catalogue word with the smallest `distance` under `Tokens.Guess.maxDistance` (start at 0.85;
   Jake tunes it). nil when the embedding isn't available.

**Done when:** `netflixIsTV`, `electricityIsBolt`, `rentIsHouse`, `emptyIsNil`, `gibberishIsNil`,
`caseAndAccentsFold` pass, and `rugbyIsSport` passes or is skipped with `.enabled(if:)` when the
embedding can't load.

### Step 4 — Tokens, and DialKit for live tuning

**Files:** modified `Tokens.swift`; new `Tilly/DesignSystem/CategoryLayout.swift`; new
`Tilly/Developer/CategoryDials.swift`; modified `TillyApp.swift`, `project.pbxproj` (the package).

- New tokens, from the prototype: sheet card 150 × 184, radius 14, strip 5, picture 64 at 28 from the
  top; name on the card inset 10, 24 from the bottom, 40 tall, `.rounded` bold 20 scaling to 12, a
  2pt dashed outline radius 10 at 0.7 while empty; card 6 below the header, 22 above the colours,
  light shadow 0.12 black, radius 5, y 2. Spark badge 17 round, `paperCard` with a hairline ring, a
  `sparkle` at 12 in `ink2`, offset 6 right and 4 up. Swatches spread across the width: 28 targets,
  22 dots, the ring 2pt at 3 outside; 10 above, 4 below. Gutter 22. Symbols six across, 10 apart, a
  ring 2.5pt at 3 outside, radius 14; section titles 12 semibold, uppercase, tracking 0.6, 16 above
  and 8 below (4 above the first); a 0.5 hairline above the scroll. Search capsule 48 tall, 16 from
  the sides, 6 above the bottom safe area, `paperCard` at 0.92, edge 0.5, shadow 0.1, radius 18,
  y 4; the scroll keeps 80 clear under it. Settings card 112 tall with its figure, the name 27 from
  the bottom; the figure `.caption2` medium, `ink2`, 11 from the bottom, 4 in from the sides.
  Settings' `Categories` tile 32, radius 8, `#5A6CE8`, white `square.grid.2x2`.
- `CategoryLayout: Codable, Equatable` holds the numbers above as stored properties whose defaults
  are the tokens. Views read `@Environment(\.categoryLayout)`, which is `CategoryLayout()` unless set.
- Debug only: add `https://github.com/mikelikesdesign/dialkit-macos`, products `DialkitmacOS` and
  `DialkitmacOSAgent` on the app target. Every import sits in `#if DEBUG`. `TillyApp.init` starts
  `DialKitAgent.shared.start(appName: "Tilly")`. `CategoryDials` owns a `DialPanelState` with a fixed
  UUID, `name: "Categories"`, a slider per value, and sets `\.categoryLayout` on the root from
  `dial.values`. Previews of the sheet and the Settings grid start the agent in `.task`.

**Done when:** a Release build doesn't reference DialKit symbols (`nm` on the binary), the suite is
green, and in the Simulator a slider in the inspector moves the sheet's card live.

### Step 5 — The category sheet (Opus)

**Files:** new `Tilly/Categories/CategorySheet.swift`, `CategoryCardFace.swift`; new
`Tilly/DesignSystem/SheetHeader.swift`, extracted from `ExpenseEditor`'s header row so both sheets
share the glass circles; modified `SymbolPicker.swift` (becomes the sheet's grid: sections, six
across, the bottom search, `No exact match. Closest` from `SymbolGuess.closest(limit: 6)`).

```swift
struct CategorySheet: View {
    enum Subject { case new(existing: [ExpenseCategory]), change(ExpenseCategory) }
    let subject: Subject
    let onSave: (ExpenseCategory) -> Void     // the made or changed category
    let onDelete: () -> Void                  // after the delete, for the host to tidy up
}
```

- Title `New Category` or `Edit Category`, 17 semibold. ✓ is enabled when the trimmed name isn't
  empty and something changed. Return in the name saves when ✓ would, else dismisses the keyboard.
  A new category's name is focused once the sheet is up.
- `CategoryCardFace` draws the sheet's card and the grid's card from one view at two sizes, so the
  Settings and picker cards stay the same drawing (`CategoryGrid.card` moves into it).
- The name fits the card: one line, shrinking from 20 to 12 before it truncates.
- Tapping the card's picture scrolls the symbols to the top.
- Trash shows the stock alert: title `Delete “Home”?`; message `Its bill goes too, past and future.
  This can’t be undone.`, `Its 3 bills go too…`, or `No bills use it.`; buttons `Delete Category
  and Bill(s)` or `Delete Category`, destructive, and `Cancel`.
- Writes go through `modelContext` with `try? save()`; a new category takes
  `CategoryOrdering.nextSortOrder` and `nextColour`.

**Done when:** previews for new, guessed, picked, changing and searching match the prototype in
light and dark, compared as crops at the same scale, and at an accessibility size the symbols scroll
under a fixed card without clipping it. List each remaining difference before calling it done.

### Step 6 — The bill editor opens the sheet

**Files:** modified `ExpenseEditor.swift`, `CategoryGrid.swift`, `CardProgress.swift`; deleted
`NewCategoryRow.swift`; tests in `EditSessionTests`/`BillEditorTests` that reference `.newCategory`.

- `New` presents `CategorySheet(.new)`; saving applies it to the bill. The `.newCategory` panel and
  `isMakingCategory` go.
- Each grid card gets `.contextMenu { Edit (pencil), Delete (trash, destructive) }`. Edit presents
  `CategorySheet(.change)`. Delete shows the same alert, from a shared `CategoryDeleteAlert` modifier.
- Deleting the bill's own category clears its selection. If the open charge's bill was deleted, the
  editor closes.

**Done when:** the suite is green and in the Simulator: make a category from `New`, hold a card to
edit it, delete one with bills and see its rows leave the timeline.

### Step 7 — Settings opens Categories as a grid (Opus)

**Files:** modified `SettingsSheet.swift`; new `Tilly/Settings/CategoriesPage.swift`,
`Tilly/Settings/SortUndo.swift`.

- Root: one inset group, the `Categories` row (tile, name, count in `ink2`, chevron) pushing
  `CategoriesPage`; footer `More settings join this list as they arrive.` The developer section stays.
- `CategoriesPage`: title `Categories`, the grid four across with `CategoryCardFace` at 112 and its
  `€95/mo` figure, `New` last; footer `Tap a category to change or delete it. Hold and drag to
  reorder.` Tap presents `CategorySheet(.change)`, `New` presents `.new`.
- Reorder by drag in the grid, writing `sortOrder` on drop. Read `.claude/rules/swiftui-scrolling.md`
  first; the grid must not jump while a card is held.
- Sort: a toolbar `Menu` (`arrow.up.arrow.down`), section title `Arrange once, then drag as you
  like`, the four sorts with their detail. Choosing one calls `arrange` and shows a capsule at the
  bottom, `Sorted by colour · Undo`, for 4 seconds; Undo calls `restore`.

**Done when:** in the Simulator, light and dark and at an accessibility size: open Categories, sort
by each key and undo, drag a card to a new place and see the picker's order follow.

## Landing

Move observations 2, 3 and 4 to Done, screenshot the sheet and Settings next to the prototype, and
ask Jake once before merging to `main`.
