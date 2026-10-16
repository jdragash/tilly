# Adding a bill as a card you complete — implementation plan

**Brief:** docs/briefs/edit-revisit/brief.md (the 2026-10-16 update)
**Settled by:** `DESIGN.md` "The editor": "The card is the input", "Amount, name and category are
required", "Tapping a part opens its input in the keypad's place", "The pockets are the category
picker", and the unchanged "Opening a charge edits it", "This charge, or future charges",
"Deleting asks which". `DECISIONS.md`: "Adding a bill is a card you complete, and the pockets pick
its category", "Every expense has a category…", "Editing a charge is Calendar's…", "Deleting asks
Calendar's question…", "Stock SwiftUI in v1, behind a token layer".
**Reference:** `docs/prototypes/edit-revisit-card.html` with P3, the Start top left preset, sizes L,
L, L, S, the Wallet card, Emoji, Two lines, Bills peeking, Grid, White sheet, Float off, iOS default.

## Already decided — do not reopen

- P3: the pockets are the picker. No hand, no spread, no stamp, no drag-to-try.
- The iOS look. Nothing from Tilly, Drawn: no wash, grain, boil, rounded type or drawn glyphs.
- No category guessing, no sparkle, no faint card. A category is only ever chosen by a tap.
- Pockets follow the Settings order (`sortOrder`), `New` last. Never recency.
- Pockets stay in the keypad's place and scroll there. Pockets under the card is a later phase.
- The model, the engine, `BillEditor` and `EditSession` don't change. The scope menu, trash and
  their copy carry over exactly.
- New categories keep `NewCategoryRow` as it is, swatches included.
- Editing opens with the keypad up, not the pockets.

## Steps

Steps 2, 3, 5 and 6 prove themselves only on screen: Opus builds them (`CLAUDE.md`, model
routing). Steps 1 and 4 are logic: Sonnet.

### Step 1 — Know which part of the card is missing, and which comes next

**Files:** `Tilly/Editor/CardProgress.swift` (new), `TillyTests/CardProgressTests.swift` (new)

**Interface:**
```swift
/// The parts of the card, in the order the accessibility layout stacks them.
enum CardPart: CaseIterable, Equatable, Sendable {
    case amount, name, date, `repeat`, category
}

/// What the card still needs. Pure: built from the draft and two facts the view knows.
struct CardProgress: Equatable, Sendable {
    init(draft: ExpenseDraft, categoryExists: Bool, isMakingCategory: Bool)

    /// Amount: `draft.amount == nil`, except an edit at €0 (`baseline != nil && isZero`), which is
    /// filled. Name: trimmed empty. Category: `!categoryExists`. Date and repeat: never.
    func isMissing(_ part: CardPart) -> Bool

    /// The first missing part after `part` in the order amount, name, category, wrapping round;
    /// `nil` when nothing is missing. Skips the category while one is being made.
    func next(after part: CardPart?) -> CardPart?

    /// The part that breathes: the first missing of amount, name, category, but never the one
    /// focused, never while the amount is missing, and never the category while one is made.
    func breathing(focused: CardPart?) -> CardPart?
}
```

**Done when:** `CardProgressTests` covers, by name:
`emptyDraftMissesAmountNameCategory`, `dateAndRepeatAreNeverMissing`,
`editAtZeroCountsTheAmountAsFilled`, `newBillAtZeroIsMissingTheAmount`,
`whitespaceNameIsMissing`, `nextAfterAmountIsName`, `nextAfterNameIsCategory`,
`nextWrapsToAmount`, `nextIsNilWhenComplete`, `nextSkipsCategoryWhileMaking`,
`nothingBreathesWithoutAnAmount`, `nameBreathesAfterTheAmount`, `focusedPartDoesNotBreathe`,
`categoryBreathesLast`, `categoryDoesNotBreatheWhileMaking`. Both suites green.

**Verify:** the two commands in `CLAUDE.md`.

**Out of scope:** any view.

### Step 2 — Draw the card

Depends on step 1.

**Files:** `Tilly/Editor/EditorCard.swift` (new), `Tilly/DesignSystem/Tokens.swift` (modified)

**Interface:**
```swift
/// The Wallet card, live: every part is a button that reports itself, and the name is the
/// text field itself. See "The card is the input" in `docs/DESIGN.md`.
struct EditorCard: View {
    let draft: ExpenseDraft
    @Binding var name: String
    var nameFocus: FocusState<Bool>.Binding
    let category: ExpenseCategory?          // the one the card wears; nil = grey
    let progress: CardProgress
    let focused: CardPart?
    let today: Date
    let onTap: (CardPart?) -> Void          // nil = the card's background
    let onNameSubmit: () -> Void
}
```

New tokens, values from the prototype, each with a comment naming where it came from:
`Size.cardAspect` 1.586, `Radius.card` 20, `Space.cardHorizontal` 18, `Space.cardVertical` 16,
`Space.editorCardInset` 22 (from the sheet's sides), `Size.cardCategoryTile` 46,
`Radius.cardCategoryTile` 46 × 0.28, `Text.cardAmount(size:)` with a base of 60,
`Text.cardName` `.title2.weight(.semibold)`, `Text.cardWhen` `.footnote.weight(.semibold)`,
`Text.cardEmoji` `.title`, `Stroke.cardDash` 2pt dashed, `Ink.onCard` white,
`Ink.onCardSoft` white 58%, `Ink.onCardDash` white 75%, `Motion.breathe` 1.8s ease-in-out to 55%
opacity, and `Tokens.CategoryColour.cardFill(_:)` (`CategoryColour?` → `LinearGradient`, 135°,
the colour mixed 72% toward white, the colour, then 76% toward black; nil uses `Chart.uncoloured`
the same way).

Layout per "The card is the input": amount top left with `minimumScaleFactor`
`Scale.editorAmountMin`; date and repeat top right as two trailing lines, each a button, with the
clock glyph (`calendar.badge.clock`) for a future date and the one-way arrow for an ended repeat,
as `EditorButtonRow` does today; name bottom left; the emoji tile bottom right. The pencil is
`pencil` at `Text.cardWhen`'s size after the date, the repeat, and as a small badge on a chosen
category's tile. At accessibility sizes, drop the aspect ratio and stack the parts, full width,
in `CardPart.allCases` order.

**Done when:** `#Preview`s show an empty card, a half-filled card (amount, no name), a complete
card in a colour, a future date with a counted repeat, dark mode, and `.accessibility3`.
Screenshots of each in the Simulator are checked against the prototype at the chosen settings.
The seam check in `.claude/rules/views-and-tokens.md` prints nothing.

**Verify:** the `xcodebuild … test` command in `CLAUDE.md`, then the seam check.

**Out of scope:** `ExpenseEditor`. The card isn't on screen in the app yet.

### Step 3 — Put the card in the sheet

Depends on step 2.

**Files:** `Tilly/Editor/ExpenseEditor.swift` (modified), `Tilly/Editor/EditorButtonRow.swift`
(deleted; `EditorPanel` moves into `ExpenseEditor.swift`)

**Interface:**
```swift
enum EditorPanel: Equatable { case keypad, date, `repeat`, category, newCategory }
```
`ExpenseEditor`'s public `init` doesn't change.

The sheet is `EditorCard` at the top, inset `Space.editorCardInset`, then the panel at
`Size.editorPanel`, bottom-aligned; nothing between them moves when the panel changes. `onTap`
maps amount → `.keypad`, name → focus the field, date → `.date`, repeat → `.repeat`, category
and background → `.category`. The category panel is still `CategoryPicker` in this step. The
name's submit label is `.next` when `progress.next(after: .name)` isn't nil and `.done`
otherwise; submitting moves to that part's panel, or drops focus. Remove `heldOffset`,
`restingAmountInset` and their measurements if the card stays put above `NewCategoryRow` without
them; if it doesn't, stop and report the measurement.

**Done when:** in the Simulator, adding a bill from an empty store and a second one with
categories both save; the card doesn't move between keypad, keyboard, calendar, wheel, category
list and emoji keyboard (screenshots compared at the card's top edge); editing a charge, the scope
menu and both delete paths behave as before; light, dark and `.accessibility3` screenshotted. All
existing tests green.

**Verify:** both `CLAUDE.md` commands; `xcodebuild -scheme Tilly -configuration Release build`.

**Out of scope:** pockets, filing, any change to saving.

### Step 4 — Work out what each pocket holds

**Files:** `Tilly/Editor/PocketContents.swift` (new), `TillyTests/PocketContentsTests.swift`
(new)

**Interface:**
```swift
struct PocketContent: Identifiable, Equatable {
    let id: UUID                 // the category's
    let emoji: String
    let name: String
    let colour: CategoryColour?
    let peeking: [String]        // up to three bill names, the one in front last
}

enum PocketContents {
    static let maxPeeking = 3

    /// One per category, in `sortOrder`. A bill is a series (`seriesKey`), read from its record
    /// with the latest anchor, and counts while that record has no `endDate` or ends on or after
    /// `today`. The latest anchor goes in front. `excluding` drops the series being edited.
    static func make(
        categories: [ExpenseCategory],
        expenses: [Expense],
        excluding seriesKey: UUID?,
        today: Date,
        calendar: Calendar
    ) -> [PocketContent]
}
```

**Done when:** `PocketContentsTests` covers, by name: `noCategoriesNoPockets`,
`pocketsFollowSortOrder`, `emptyCategoryPeeksNothing`, `atMostThreePeek`,
`latestAnchorIsInFront`, `endedBillsDontPeek`, `billEndingTodayStillPeeks`,
`splitSeriesPeeksOnceUnderItsLatestName`, `editedSeriesIsExcluded`,
`billWithoutCategoryIsIgnored`. Both suites green.

**Verify:** the two commands in `CLAUDE.md`.

**Out of scope:** any view.

### Step 5 — Pick a category by tapping its pocket

Depends on steps 3 and 4.

**Files:** `Tilly/Editor/PocketGrid.swift` (new), `Tilly/Editor/ExpenseEditor.swift` (modified),
`Tilly/Editor/CategoryPicker.swift` (deleted), `Tilly/DesignSystem/Tokens.swift` (modified)

**Interface:**
```swift
/// The pockets, three across in the keypad's place, `New` last. See "The pockets are the
/// category picker" in `docs/DESIGN.md`.
struct PocketGrid: View {
    let pockets: [PocketContent]
    let selection: UUID?
    let draftName: String          // on the card standing in the chosen pocket
    let newBreathes: Bool          // first bill, amount and name in
    let filing: UUID?              // step 6; nil here
    let onPick: (UUID) -> Void
    let onNew: () -> Void
}
```

New tokens: `Size.pocketWidth` 108, `Size.pocketHeight` 86, `Size.pocketLip` 46,
`Space.pocketRow` 22, `Space.pocketColumn` 14, `Space.pocketPeekStep` 11, `Radius.pocket` 12,
`Radius.pocketPeek` 6, `Opacity.pocketBack` 0.35, `Size.pocketLift` 6, `Motion.pick` 0.3s.
Pocket text uses `Text.caption`-scale fonts through new `Text.pocketName` and `Text.pocketPeek`.

The `.category` panel becomes `PocketGrid` in a `ScrollView`; `onNew` opens `.newCategory`, whose
row now sits where the pockets were. Picking sets `draft.categoryID` with `Motion.pick`: the card's
fill crossfades and its emoji drops in (scale 1.35 and 6pt up to rest). A category made with `New`
selects itself and the panel returns to the pockets. At accessibility sizes the grid is two
across, and each pocket is a `Button` with the category's name as its label and its peeking bills
as its value.

**Done when:** in the Simulator, with 0, 1, 7 and 20 categories (use developer scenarios, adding
one if needed): first bill makes a category through `New`, which breathes; picking crossfades;
20 scroll in the panel; light, dark and `.accessibility3` screenshotted. Both suites green; seam
check clean.

**Verify:** both `CLAUDE.md` commands; the seam check.

**Out of scope:** filing after ✓.

### Step 6 — File the card into its pocket on ✓

Depends on step 5.

**Files:** `Tilly/Editor/ExpenseEditor.swift` (modified), `Tilly/Editor/PocketGrid.swift`
(modified), `Tilly/DesignSystem/Tokens.swift` (modified)

**Interface:**
```swift
// in ExpenseEditor
@State private var filing: UUID?          // the category being filed into
private func file(into categoryID: UUID)  // replaces `dismiss()` after a successful save or edit
```

New tokens: `Motion.file` 0.24s with the curve `(.3, .6, .35, 1)`, `Motion.fileHold` 0.7s,
`Motion.pocketBounce` (scale 1.06, 0.98, 1 over 0.28s), `Motion.fileFade` 0.16s.

Saving writes first, exactly as now; only on success does `file(into:)` run. It shows the pockets
(non-interactive), scrolls the target into view, shrinks the card into the target with a
`matchedGeometryEffect` keyed on the category, bounces the pocket, then dismisses after
`Motion.fileHold`. With Reduce Motion the card fades over `Motion.fileFade`. Delete paths still
dismiss directly. Any tap during filing dismisses at once (TASTE 12).

**Done when:** in the Simulator, adding, saving "this charge only", "future charges", and a whole
bill each file into the right pocket; a tap mid-flight closes the sheet; Reduce Motion fades;
screenshots held mid-flight per `.claude/rules/simulator.md`. Both suites green.

**Verify:** both `CLAUDE.md` commands; Release build.

**Out of scope:** the timeline's reaction to the new row.

## Lessons

- **The prototype's `color-mix(in srgb, c 72%, white)` is 72% of the colour**, so the card's light
  end is the colour mixed 28% toward white, and its dark end 24% toward black. `Color.mix(with:by:in:
  .device)` does it without resolving traits by hand.
- **A view not yet in the app can still be screenshotted in the Simulator**: a temporary file
  that `TillyApp`'s debug branch shows instead of the timeline, with states picked by
  `SIMCTL_CHILD_<NAME>` launch variables, deleted before committing.

## If a step is wrong

These specs were written before the code existed. If a step turns out to be
ambiguous, impossible, or wrong, **stop and say so** — don't improvise a fix and
don't silently widen the scope. A wrong spec caught in one message costs far less
than a wrong spec followed to completion.
