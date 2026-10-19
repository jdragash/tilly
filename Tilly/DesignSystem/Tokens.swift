import SwiftUI
import UIKit

enum Tokens {
    enum Text {
        /// The face the whole app is set in: SF Pro Rounded, through `.fontDesign` at the root.
        static let design: Font.Design = .rounded
        static let monthName: Font = .title3.weight(.semibold)
        static let monthTotal: Font = .subheadline
        /// Calendar's Today: 17pt medium. Measured at 3x, Today's label has a 12.0pt cap height
        /// and 5px vertical stems; this measured 5px too, where `.headline` (semibold) measured 6px.
        static let monthButton: Font = .body.weight(.medium)
        static let floatingSymbol: Font = .body.weight(.medium)
        static let name: Font = .body
        static let amount: Font = .body
        static let caption: Font = .footnote
        static let body: Font = .body
        static let emptyTitle: Font = .title2.weight(.semibold)
        static let rowEmoji: Font = .title2
        static let keypadKey: Font = .title
        /// The dashed circle of a lane with no category follows the lane's height, which already
        /// answers to the screen, so it doesn't scale with Dynamic Type too. From the prototype.
        static func laneEmoji(laneHeight: CGFloat) -> Font {
            .system(size: min(26, max(15, (0.46 * laneHeight).rounded())))
        }
        static let laneTotal: Font = .subheadline
        static let axisDay: Font = .caption2
        static let axisToday: Font = .caption2.weight(.semibold)
        static let quietLine: Font = .footnote
        static let nextHeading: Font = .footnote.weight(.semibold)
        static let nextRow: Font = .subheadline
        static let readoutDate: Font = .footnote.weight(.semibold)
        static let readoutRow: Font = .footnote
        /// The calendar's month title, over its figure.
        static let calendarTitle: Font = .title.weight(.bold)
        static let weekday: Font = .caption2.weight(.semibold)
        static let dayNumber: Font = .footnote
        static let dayNumberToday: Font = .footnote.weight(.semibold)
        /// The "+N" after a day's two pictures.
        static let dayMore: Font = .caption2.weight(.bold)
        static let dayTotal: Font = .caption2.weight(.semibold)
        /// The level's name in a back button, as Calendar's top left reads.
        static let backButton: Font = .body
        /// The year's month cells: the month's short name, its total beside it, and the key.
        static let yearMonthName: Font = .footnote.weight(.semibold)
        static let yearMonthLabel: Font = .caption
        static let yearMonthLabelHeavy: Font = .caption.weight(.semibold)
        static let yearKey: Font = .footnote
        /// All bills: the chips, a card's header, and its rows.
        static let billsChip: Font = .subheadline
        static let billCardName: Font = .body.weight(.semibold)
        static let billCardTotal: Font = .title3.weight(.semibold)
        static let billName: Font = .subheadline
        static let billNote: Font = .footnote
        static let billFigure: Font = .subheadline
        static let endedToggle: Font = .subheadline
        /// The editor's card, at the prototype's sizes L, L, L, S. The amount scales
        /// `Size.cardAmount` with `@ScaledMetric`, as the editor's amount does.
        static func cardAmount(size: CGFloat) -> Font { .system(size: size, weight: .bold) }
        static let cardName: Font = .title2.weight(.semibold)
        static let cardWhen: Font = .footnote.weight(.semibold)
        /// The pencil badge on a chosen category's tile: a fixed 10pt glyph in a fixed 16pt
        /// circle, from the prototype.
        static let cardBadge: Font = .system(size: 10, weight: .semibold)
        /// A pocket's emoji and name on its lip, and the bills peeking out of it; from the
        /// prototype's 13pt and 11pt.
        static let pocketName: Font = .footnote.weight(.semibold)
        static let pocketPeek: Font = .caption2.weight(.semibold)
    }

    enum Stroke {
        /// The empty emoji slot's dashed outline.
        static let emojiSlot = StrokeStyle(lineWidth: 1.5, dash: [4, 3])
        /// The ring round the chosen colour swatch.
        static let swatchRing: CGFloat = 2
        /// A €0 or amountless dot in the lanes.
        static let zeroDot = StrokeStyle(lineWidth: 1.5, dash: [2, 2])
        /// A still-to-come dot's ring.
        static let upcomingDot: CGFloat = 2
        /// The year's ring for a bill that starts, changes or ends; a €0 one reuses `zeroDot`.
        static let yearRing: CGFloat = 1.5
        /// What the editor's card still needs: the name's field and the category's tile. 2pt from
        /// the prototype; the dash and gap are a guess at a browser's dashed border.
        static let cardDash = StrokeStyle(lineWidth: 2, dash: [5, 4])
        /// Round the part of the card whose input is open; from the prototype.
        static let cardFocus: CGFloat = 2
        /// Round the chosen pocket; the dashed outline of `New`. From the prototype.
        static let pocketRing: CGFloat = 2.5
        static let pocketNew = StrokeStyle(lineWidth: 2, dash: [5, 4])
    }

    /// How far text may shrink to fit a line before it truncates.
    enum Scale {
        /// The card's amount, before it truncates.
        static let editorAmountMin: CGFloat = 0.3
        /// A month header's name and a picked-out category's name, before they truncate.
        static let headerMin: CGFloat = 0.8
        /// A lane's total, before it would run out of its column.
        static let laneTotalMin: CGFloat = 0.5
        /// A day's total, before it would run out of its column.
        static let dayTotalMin: CGFloat = 0.6
        /// The dots on the day under a dragging finger; from the prototype.
        static let dotOnLine: CGFloat = 1.18
        /// A zoom with nothing tapped to grow from, about the middle: the closer level grows from
        /// this, and the further one from its inverse. From the prototype.
        static let zoomIn: CGFloat = 0.93
        /// A zoom about a tapped cell starts the closer level at that cell's size, but no smaller
        /// than this, and the further level no larger than `zoomMax`. Tuning values.
        static let zoomMin: CGFloat = 0.2
        static let zoomMax: CGFloat = 3
        /// The card's emoji drops into its tile from this size.
        static let emojiDrop: CGFloat = 1.35
    }

    enum Opacity {
        /// How far an upcoming or skipped row's icon well sits back; from the prototype.
        static let upcomingIcon: Double = 0.55
        /// The category view's today line; from the prototype.
        static let todayLine: Double = 0.75
        /// The lanes not picked out while one category is; from the prototype.
        static let unpickedLane: Double = 0.22
        /// A month arrow at the end of what can be paged to; from the prototype.
        static let disabledArrow: Double = 0.3
        /// While dragging across the lanes: the dots off the line, and the today line, which would
        /// otherwise read as a second line. From the prototype.
        static let offLineDot: Double = 0.28
        static let todayLineWhileDragging: Double = 0.2
        /// A pocket's back, its colour at this strength; its lip, nearly solid. From the prototype.
        static let pocketBack: Double = 0.35
        static let pocketLip: Double = 0.95
    }

    enum Ink {
        static let primary: Color = .primary
        static let secondary: Color = .secondary
        static let tertiary: Color = Color(.tertiaryLabel)
        static let quaternary: Color = Color(.quaternaryLabel)
        static let accent: Color = .accentColor
        /// The editor's trash button, and its confirmation dialog's destructive buttons.
        static let destructive: Color = .red
        /// Today's circle on the calendar, as Calendar draws it, and the number inside it.
        static let today: Color = Color(.systemRed)
        static let onToday: Color = .white
        /// Type on the editor's card, which is always a colour, or grey before it has one. From the
        /// prototype: white, a soft white for what's still faint, and the dashes between.
        static let onCard: Color = .white
        static let onCardSoft: Color = .white.opacity(0.58)
        static let onCardDash: Color = .white.opacity(0.75)
        /// A charged card's date in the timeline's stack, a touch softer than its name; from the
        /// prototype.
        static let onStackSoft: Color = .white.opacity(0.82)
        /// A peeking bill's name on its white slip, in both modes; from the prototype.
        static let onPocketPeek: Color = Color(white: 0.23)
    }

    enum Surface {
        static let base: Color = Drawn.paper
        static let iconWell: Color = Color(.quaternarySystemFill)
        static let rule: Color = Color(.separator)
        /// The pinned month header's ground. Opaque, and deliberately the same paper as
        /// the page: a pinned header hides what passes beneath it rather than tinting it.
        /// Because it matches `base`, the header can carry it at rest too — see the note in
        /// `MonthHeader`. Liquid Glass is for things that float *over* content, which the
        /// floating buttons are and a full-bleed sticky header is not.
        static let pinned: Color = Drawn.paper
        static let editorButtonActive: Color = Color(.tertiarySystemFill)
        /// Behind a picked-out lane's emoji.
        static let pickedLane: Color = Color(.secondarySystemFill)
        /// An All bills card: the prototype's 8% grey in light and 18% in dark, which is what the
        /// system's quaternary fill is.
        static let card: Color = Color(.quaternarySystemFill)
        /// A chip that isn't picked: the prototype's 14% and 32%, which the secondary fill is.
        static let chip: Color = Color(.secondarySystemFill)
        /// The pencil badge's ground: white in light, the prototype's #2C2C2E in dark.
        static let cardBadge: Color = Color(.tertiarySystemBackground)
        /// A peeking bill's slip: white in both modes, as the prototype draws paper.
        static let pocketPeek: Color = .white
    }

    enum Chart {
        /// A dot for a category without a colour, or charges with no category.
        static let uncoloured: Color = Color(.systemGray)
        /// The hairline between two lanes: fainter than `Surface.rule`, since it only groups.
        static let laneRule: Color = Color(.quaternaryLabel)
    }

    enum Space {
        /// The hand's fan: the step between cards at most and at least (it tightens to fit, then
        /// scrolls), and the clearance kept at either side.
        static let handStepMax: CGFloat = 48
        static let handStepMin: CGFloat = 24
        static let handSideClearance: CGFloat = 64
        static let gutter: CGFloat = 20
        static let section: CGFloat = 16
        static let gap: CGFloat = 12
        static let tight: CGFloat = 8
        static let rowVerticalAccessible: CGFloat = 12
        static let monthButtonHorizontal: CGFloat = 16 // the month button's inner horizontal padding
        static let floatingClearance: CGFloat = 80 // bottom inset the list carries until the bottom row is measured
        /// How far the bottom row sits from the screen's bottom and side edges, as Calendar's does:
        /// Today and the pair beside it measured 28.00pt from the bottom, left and right edges on
        /// the iPhone 17 simulator, inside the home indicator's safe area rather than above it.
        static let bottomRowInset: CGFloat = 28
        /// Clear space above and below + in the header row.
        static let headerRowInset: CGFloat = 8
        /// What a month header keeps clear at its trailing end so its text never runs under the
        /// glass pair: the view button and +, the gutter they sit in, and a gap.
        static let headerTrailingClearance: CGFloat = 2 * Size.groupSlot + gutter + gap
        /// Between the category view's arrows and the view-and-+ pair. Drawn, not measured:
        /// Calendar has no two groups side by side.
        static let groupGap: CGFloat = 8
        /// Between a picked-out category's name and its total in the month header: a word space.
        static let figureLabelGap: CGFloat = 4
        /// The month header's clearance in the category view, where the arrows sit left of the pair.
        static let categoryHeaderTrailingClearance: CGFloat = 4 * Size.groupSlot + groupGap + gutter + gap
        /// The lanes' emoji column sits this far from the screen's leading edge; from the prototype.
        static let laneLeading: CGFloat = 12
        /// From the emoji column to day 1; from the prototype.
        static let lanePlotLeading: CGFloat = 22
        /// Two charges on one day sit this far apart, the later one to the right.
        static let sameDayOffset: CGFloat = 5
        /// Above and below the line naming the categories with nothing this month.
        static let quietTop: CGFloat = 10
        static let quietBottom: CGFloat = 4
        /// Above the `Next` list, under its heading, and around each of its rows.
        static let nextTop: CGFloat = 18
        static let nextHeadingBottom: CGFloat = 4
        static let nextRowVertical: CGFloat = 5
        /// The readout's top in the header row. With one charge it is 52pt tall, so it sits
        /// inside the 60pt row, clear of the axis beneath; more charges run down over the lanes.
        static let readoutTop: CGFloat = 4
        static let readoutHorizontal: CGFloat = 12
        static let readoutVertical: CGFloat = 6
        static let readoutDateBottom: CGFloat = 2
        static let readoutRowVertical: CGFloat = 1
        static let readoutGap: CGFloat = 6
        /// Between the calendar's cells and weekday columns; from the prototype.
        static let gridGap: CGFloat = 2
        /// A day's second emoji tucks under the first by this much.
        static let emojiOverlap: CGFloat = 4
        /// Before the "+N" that follows a day's two emoji.
        static let dayMoreGap: CGFloat = 5
        /// Inside a day cell, above its number and below its total.
        static let cellTop: CGFloat = 4
        static let cellBottom: CGFloat = 6
        /// Between the header row and the calendar's month title.
        static let titleTop: CGFloat = 8
        /// Between the title block and the weekday row.
        static let titleBottom: CGFloat = 12
        /// Inside a back button: chevron to name, and its ends; from the prototype.
        static let backButtonGap: CGFloat = 4
        static let backButtonLeading: CGFloat = 10
        static let backButtonTrailing: CGFloat = 14
        /// The year's month cells: across and down, and from a month's name to its days; from the
        /// prototype.
        static let yearColumnGap: CGFloat = 17.5
        static let yearRowGap: CGFloat = 16
        static let yearMiniGap: CGFloat = 5
        /// Between the year's months and the key under them, and the key's lines and their dots.
        static let yearKeyTop: CGFloat = 24
        static let keyLineGap: CGFloat = 6
        static let keyDotGap: CGFloat = 8
        /// All bills: a chip's inner side padding and the gap between chips; from the prototype.
        static let chipHorizontal: CGFloat = 13
        static let chipGap: CGFloat = 8
        /// A card's inset from the screen, its padding, and the gap between cards; from the
        /// prototype.
        static let cardInset: CGFloat = 16
        static let cardTop: CGFloat = 14
        static let cardSides: CGFloat = 16
        static let cardBottom: CGFloat = 8
        static let cardGap: CGFloat = 12
        /// Above and below a bill's row inside a card, and from a card header to its first row.
        static let billRowVertical: CGFloat = 8
        static let cardHeaderBottom: CGFloat = 8
        /// Between the parts of a bill's row, and the ended bills' line above and below.
        static let billRowGap: CGFloat = 8
        static let endedToggleVertical: CGFloat = 14
        /// Above the chips, and above the cards.
        static let chipsTop: CGFloat = 12
        static let cardsTop: CGFloat = 16
        /// The editor's card: its padding, from the sheet's sides, and between its parts. From
        /// the prototype. `editorCardInset` isn't `cardInset`, which is All bills' 16.
        static let cardHorizontal: CGFloat = 18
        static let cardVertical: CGFloat = 16
        static let editorCardInset: CGFloat = 22
        /// Between the date's line and the repeat's.
        static let cardWhenGap: CGFloat = 2
        /// Before the pencil that follows a filled-in part.
        static let cardMarkGap: CGFloat = 4
        /// Inside the name's dashed field.
        static let cardFieldHorizontal: CGFloat = 10
        static let cardFieldVertical: CGFloat = 4
        /// The pockets: between rows and columns, how far apart the peeking bills sit, and above
        /// the first row. From the prototype; the editor's gutter gives the sides.
        static let pocketRow: CGFloat = 22
        static let pocketColumn: CGFloat = 14
        static let pocketPeekStep: CGFloat = 11
        static let pocketsTop: CGFloat = 24
        /// A peeking bill's slip: from the pocket's sides, and its text's inset.
        static let pocketPeekInset: CGFloat = 10
        static let pocketPeekTextHorizontal: CGFloat = 7
        static let pocketPeekTextTop: CGFloat = 2
        /// Inside a pocket's lip, and between its emoji and name.
        static let pocketLipHorizontal: CGFloat = 6
        static let pocketLipGap: CGFloat = 4
        /// Where the front bill peeks out: this far above the lip.
        static let pocketFront: CGFloat = 14
        /// A chosen pocket's lip drops this far as the bill stands in it.
        static let pocketLipDrop: CGFloat = 5
        /// The card's emoji drops into its tile from this far up.
        static let emojiDrop: CGFloat = 6
        /// Where a filed card lands in its pocket: this far in from the pocket's sides, its top this
        /// far above the lip. From the prototype.
        static let pocketCardInset: CGFloat = 6
        static let pocketCardAboveLip: CGFloat = 10
        /// The timeline's Wallet stack, from the prototype: how far each card runs on under the next,
        /// how far in from the screen's sides it sits, where its content starts inside it, and the
        /// clear space under a month's last card. Tuning values.
        static let stackTuck: CGFloat = 12
        static let stackInset: CGFloat = 12
        static let stackTop: CGFloat = 11
        static let stackLeading: CGFloat = 14
        static let stackMonthBottom: CGFloat = 14
    }

    enum Size {
        /// The hand's cards (portrait), and the picture on one.
        static let handCard = CGSize(width: 84, height: 120)
        static let handPicture: CGFloat = 44
        static let row: CGFloat = 52
        /// A row in the timeline's Wallet stack: the part of its card left showing above the next.
        /// From the prototype; the timeline's only, every other list keeps `row`.
        static let stackRow: CGFloat = 64
        /// A card's picture in the stack, from the prototype.
        static let stackPicture: CGFloat = 36
        static let icon: CGFloat = 40
        static let iconAccessible: CGFloat = 44
        /// A category's picture, by where it's drawn: replaces the font each emoji was set in.
        static let pictureDay: CGFloat = 26
        static let pictureDayPair: CGFloat = 22
        static let pictureReadout: CGFloat = 24
        static let pictureNext: CGFloat = 24
        static let pictureBillCard: CGFloat = 34
        static let pictureLip: CGFloat = 22
        static let pictureSettings: CGFloat = 32
        /// A lane's follows the lane's height, as its emoji did.
        static func pictureLane(laneHeight: CGFloat) -> CGFloat {
            min(34, max(22, (0.62 * laneHeight).rounded()))
        }
        static let hairline: CGFloat = 0.5
        /// The row a month header fills and + floats in, with `headerRowInset` clear above and
        /// below +. Headers take it as a minimum height.
        static let headerRow: CGFloat = floatingButton + 2 * Space.headerRowInset
        /// +, at the top. Calendar's top glass buttons, measured on the iPhone 17 simulator
        /// (iOS 26.5, month view, 3x): 44.00pt tall.
        static let floatingButton: CGFloat = 44
        /// One button's width in a top glass group. Calendar's top group measured 158pt for three
        /// icons on the iPhone 17 simulator.
        static let groupSlot: CGFloat = 52
        /// The month button and settings, at the bottom. Calendar's bottom glass buttons, Today and
        /// the pair beside it, measured the same way: 48.00pt tall, 4pt taller than the top ones.
        static let bottomButton: CGFloat = 48
        /// Every editor panel fills exactly this height, so the card never moves. Tuning value:
        /// the graphical calendar is the tallest panel, and a six-row month (August 2026) measures
        /// about 336pt at the default text size, so 340 clears it without clipping.
        static let editorPanel: CGFloat = 340
        /// The picture slot beside a new category's name.
        static let emojiSlot: CGFloat = 48
        /// A symbol in the picker's grid, and the height of the picker where the keypad was.
        static let symbolCell: CGFloat = 44
        static let symbolPicker: CGFloat = 340
        static let categoryField: CGFloat = 44
        static let categoryRow: CGFloat = 48
        /// A category's colour, drawn as a filled circle in Settings and the new-category row.
        static let colourSwatch: CGFloat = 22
        /// Clear space between a chosen swatch and the ring drawn round it.
        static let swatchRingGap: CGFloat = 3
        /// The least a control smaller than this is given to be tapped by: Apple's 44pt minimum.
        static let minimumTapTarget: CGFloat = 44
        /// A lane's height: the lanes shrink between these to fit the screen, then the page
        /// scrolls. See "The category view" in `docs/DESIGN.md`.
        static let laneHeightMax: CGFloat = 60
        static let laneHeightMin: CGFloat = 30
        static let laneEmojiColumn: CGFloat = 40
        /// The lanes' totals, right-aligned in this much at the trailing end.
        static let laneTotalsColumn: CGFloat = 70
        /// The day numbers above the lanes.
        static let laneAxis: CGFloat = 18
        /// A dot's diameter runs from `dotMin` for the smallest charge up to `dotMaxRatio` of the
        /// lane's height, never past `dotMax`, its area following the amount. From the prototype.
        static let dotMin: CGFloat = 7
        static let dotMax: CGFloat = 36
        static let dotMaxRatio: CGFloat = 0.78
        /// A €0 or amountless charge.
        static let dotZero: CGFloat = 8
        /// The ground-coloured ring round every dot, which keeps touching dots apart.
        static let dotHalo: CGFloat = 2
        static let todayLine: CGFloat = 1.5
        /// The line at the day under a dragging finger.
        static let dragLine: CGFloat = 2
        /// How far a tap may land outside a dot and still open it; from the prototype.
        static let dotTapReach: CGFloat = 22
        static let readoutMinWidth: CGFloat = 150
        static let readoutMaxWidth: CGFloat = 250
        /// The repeat wheels' two narrow columns; the end column takes the rest. Tuning values:
        /// a wheel's natural width is unbounded, so equal thirds truncated "12 payments".
        static let wheelInterval: CGFloat = 64
        static let wheelUnit: CGFloat = 96
        /// A calendar row's height; a six-week month shrinks to the second so the grid still fits.
        /// From the prototype.
        static let calendarRow: CGFloat = 80
        static let calendarRowSixWeeks: CGFloat = 68
        /// Today's circle round its day number.
        static let todayCircle: CGFloat = 22
        /// How far a sideways drag must go before it pages the month.
        static let pageSwipe: CGFloat = 60
        /// A scroll target with no height of its own, so landing it needs no target height.
        static let scrollMarker: CGFloat = 0
        /// A day in the year's mini month: a column and a row. From the prototype, where seven
        /// columns make 105pt.
        static let yearDayWidth: CGFloat = 15
        static let yearDayHeight: CGFloat = 13
        /// What a day shows in the year: nothing charged, only monthly bills, and a bill that
        /// isn't monthly (larger when that day's extras reach a fifth of a usual month), and the
        /// ring for a bill that starts, changes or ends. Today is the extra's size.
        static let yearDotQuiet: CGFloat = 2.6
        static let yearDotUsual: CGFloat = 5
        static let yearDotExtra: CGFloat = 7
        static let yearDotExtraLarge: CGFloat = 11
        static let yearDotRing: CGFloat = 7
        /// A category chip in All bills.
        static let chipHeight: CGFloat = 34
        /// The editor's card: a bank card's proportions (ISO/IEC 7810 ID-1), from the prototype.
        static let cardAspect: CGFloat = 1.586
        /// The card's amount, before Dynamic Type scales it; from the prototype's L.
        static let cardAmount: CGFloat = 60
        /// The category's tile on the card, and the pencil badge on its corner, which sits
        /// `cardBadgeOverhang` outside it. From the prototype.
        static let cardCategoryTile: CGFloat = 46
        static let cardBadge: CGFloat = 16
        static let cardBadgeOverhang: CGFloat = 5
        /// A pocket, its lip and a peeking bill's slip, before Dynamic Type scales them, and how
        /// far the chosen one lifts. From the prototype.
        static let pocketWidth: CGFloat = 108
        static let pocketHeight: CGFloat = 86
        static let pocketLip: CGFloat = 46
        static let pocketPeekHeight: CGFloat = 34
        static let pocketLift: CGFloat = 6
        /// The caret after the card's amount. The prototype sizes it from the font: 0.82em tall,
        /// 0.055em wide (never under `caretMinWidth`), 0.04em from the text. Here it's drawn from
        /// the laid-out line, about 1.2em tall in SF, so it follows the amount as it shrinks.
        static let caretHeightOfLine: CGFloat = 0.82 / 1.2
        static let caretWidthOfHeight: CGFloat = 0.055 / 0.82
        static let caretGapOfHeight: CGFloat = 0.04 / 0.82
        /// What the amount keeps clear after itself for the caret, as a fraction of its size.
        static let caretRoomRatio: CGFloat = 0.1
        static let caretMinWidth: CGFloat = 2
    }

    enum Motion {
        /// The hand's fan opens by this many degrees per step, and the card's turn is drawn with this
        /// perspective. From the prototype; not tuned.
        static let handArc: Double = 8
        static let flipPerspective: CGFloat = 0.4
        /// How often a boiling picture swaps to its next drawing; from the prototype.
        static let boilStep: TimeInterval = 0.125
        // The return scroll's duration scales with how far the reader actually has to
        // travel, the way a browser's native smooth scroll does. A fixed duration is the
        // thing that reads badly: measured on device, `.default` moved 2,052 points in
        // 284ms, which lands as a smear rather than as travel. Floor and ceiling keep a
        // short hop from feeling sluggish and a long one from dragging.
        static let returnPointsPerSecond: CGFloat = 3000
        static let returnDurationMin: TimeInterval = 0.35
        static let returnDurationMax: TimeInterval = 0.9
        /// The dots settling onto and off the dragging line; from the prototype.
        static let scrub: TimeInterval = 0.12
        /// A tapped day's rows fading from marked, once the timeline has landed on them.
        static let dayMark: TimeInterval = 1.2
        /// Moving between the year, a month and the days, about what was tapped. Longer than the
        /// prototype's 0.28s, which was for a 7% zoom; this one covers a cell growing to the screen.
        /// A tuning value.
        static let zoomDuration: TimeInterval = 0.38
        static let zoom: Animation = .timingCurve(0.2, 0.8, 0.2, 1, duration: zoomDuration)
        /// The header and its controls fading aside while dragging across the lanes,
        /// and back. Out is quick so nothing lies under the readout as it lands; back is a touch
        /// slower. Guesses: 0.2s both ways felt slow in the Simulator.
        static let asideOut: TimeInterval = 0.08
        static let asideBack: TimeInterval = 0.15
        static func aside(hiding: Bool) -> Animation {
            .easeOut(duration: hiding ? asideOut : asideBack)
        }
        /// The part of the card still needed next: its dashes fade to `breatheOpacity` and back
        /// over `breathe`. From the prototype.
        static let breathe: TimeInterval = 1.8
        static let breatheOpacity: Double = 0.55
        /// How long the amount's caret stays on, then off: half the prototype's 1.06s blink.
        static let caretBlink: TimeInterval = 0.53
        /// Picking a pocket: the card's colour crossfades and its emoji drops in.
        static let pick: TimeInterval = 0.3
        /// Filing on ✓: the card shrinks into its pocket, the pocket bounces, and the sheet closes
        /// `fileHold` after ✓. Reduce Motion fades the card instead. From the prototype.
        static let file: TimeInterval = 0.24
        static let fileCurve: Animation = .timingCurve(0.3, 0.6, 0.35, 1, duration: file)
        static let fileHold: TimeInterval = 0.7
        static let fileFade: TimeInterval = 0.16
        static let pocketBounce: TimeInterval = 0.28
        static let pocketBounceScales: [CGFloat] = [1.06, 0.98, 1]
        /// How long the pockets get to appear and scroll the target into view before the card
        /// leaves. A tuning value.
        static let fileSettle: TimeInterval = 0.05
    }

    /// The editor's card sits on the sheet: the prototype's 0 12 28 at 16% black. A radius is
    /// half the CSS blur.
    enum Shadow {
        static let cardColour: Color = .black.opacity(0.16)
        static let cardRadius: CGFloat = 14
        static let cardY: CGFloat = 12
        /// Under the pencil badge: the prototype's 0 1 2 at 14% black.
        static let badgeColour: Color = .black.opacity(0.14)
        static let badgeRadius: CGFloat = 1
        static let badgeY: CGFloat = 1
        /// Under a pocket's lip and its peeking bills: the prototype's 0 -2 6 at 14% black, 40%
        /// in dark.
        static let pocketColour: Color = Color(UIColor { traits in
            UIColor(white: 0, alpha: traits.userInterfaceStyle == .dark ? 0.4 : 0.14)
        })
        static let pocketRadius: CGFloat = 3
        static let pocketY: CGFloat = -2
        /// Along a charged card's top in the timeline's stack, falling on the card above: the
        /// prototype's 0 -1 2.5 at 16% black.
        static let stackColour: Color = .black.opacity(0.16)
        static let stackRadius: CGFloat = 1.25
        static let stackY: CGFloat = -1
    }

    enum Radius {
        static let icon: CGFloat = 10
        static let iconAccessible: CGFloat = 12
        static let editorButton: CGFloat = 12
        static let readout: CGFloat = 16
        /// An All bills card, and the editor's card; both from their prototypes.
        static let card: CGFloat = 20
        /// The category's tile on the editor's card: 0.28 of its side, from the prototype.
        static let cardCategoryTile: CGFloat = Size.cardCategoryTile * 0.28
        /// The name's dashed field, and the ring round an open date or repeat; from the prototype.
        static let cardField: CGFloat = 9
        static let cardFocus: CGFloat = 6
        /// A pocket's back, its lip's top corners, and a peeking bill's slip. From the prototype.
        static let pocket: CGFloat = 12
        static let pocketLipTop: CGFloat = 10
        static let pocketPeek: CGFloat = 6
        /// A card's top corners in the timeline's stack; a month's last card is round all round.
        static let stackCard: CGFloat = 14
    }
}

extension Tokens {
    /// What each `CategoryColour` looks like, light and dark. Checked for contrast and for telling
    /// apart in both modes with the dataviz validator, 2026-09-24. Green is the same in both.
    enum CategoryColour {
        static func color(_ colour: Tilly.CategoryColour) -> Color {
            Color(uiColor(colour))
        }

        /// A filled circle in the colour, for a menu item's icon. Menus draw a plain symbol in
        /// one ink whatever its `foregroundStyle`, so this one carries its colour in the image.
        static func menuSwatch(_ colour: Tilly.CategoryColour) -> Image {
            let circle = UIImage(systemName: "circle.fill") ?? UIImage()
            return Image(uiImage: circle.withTintColor(uiColor(colour), renderingMode: .alwaysOriginal))
        }

        /// A pocket's lip: the colour lit toward its top left corner and shaded toward its bottom
        /// right, as the prototype draws it (28% white, the colour, then 24% black, at 135°). A lip
        /// without a colour is grey, mixed the same way.
        static func lipFill(_ colour: Tilly.CategoryColour?) -> LinearGradient {
            let base = colour.map(color) ?? Chart.uncoloured
            return LinearGradient(
                colors: [
                    base.mix(with: .white, by: lipLight, in: .device),
                    base,
                    base.mix(with: .black, by: lipShade, in: .device),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        private static let lipLight: Double = 0.28
        private static let lipShade: Double = 0.24

        private static func uiColor(_ colour: Tilly.CategoryColour) -> UIColor {
            switch colour {
            case .blue: blue
            case .orange: orange
            case .aqua: aqua
            case .yellow: yellow
            case .magenta: magenta
            case .green: green
            case .violet: violet
            case .red: red
            }
        }

        private static let blue = dynamic(light: 0x2a78d6, dark: 0x3987e5)
        private static let orange = dynamic(light: 0xeb6834, dark: 0xd95926)
        private static let aqua = dynamic(light: 0x1baf7a, dark: 0x199e70)
        private static let yellow = dynamic(light: 0xeda100, dark: 0xc98500)
        private static let magenta = dynamic(light: 0xe87ba4, dark: 0xd55181)
        private static let green = dynamic(light: 0x008300, dark: 0x008300)
        private static let violet = dynamic(light: 0x4a3aa7, dark: 0x9085e9)
        private static let red = dynamic(light: 0xe34948, dark: 0xe66767)

        private static func dynamic(light: UInt32, dark: UInt32) -> UIColor {
            UIColor { traits in
                rgb(traits.userInterfaceStyle == .dark ? dark : light)
            }
        }

        private static func rgb(_ hex: UInt32) -> UIColor {
            UIColor(
                red: CGFloat((hex >> 16) & 0xff) / 255,
                green: CGFloat((hex >> 8) & 0xff) / 255,
                blue: CGFloat(hex & 0xff) / 255,
                alpha: 1
            )
        }
    }
}

extension Tokens {
    /// The Drawn look: paper with a grain, colour laid down as a wash with a rough, blooming edge.
    /// Every value is the combined prototype's `DT`; Jake tunes them on the phone, so a change here
    /// reaches every drawn thing.
    nonisolated enum Drawn {
        static let paper = dynamic(light: 0xEFEEEA, dark: 0x1D1C1A)
        static let paperCard = dynamic(light: 0xF7F6F2, dark: 0x2B2A27)
        static let ink = dynamic(light: 0x1C1B19, dark: 0xF2F1EE)
        static let ink2 = dynamic(light: 0x8A8883, dark: 0x8D8B86)

        /// The grain: a square tile (pt) made once, each pixel on a random half at this alpha (of 255),
        /// black or white.
        static let grainTile: CGFloat = 160
        static let grainAlpha: UInt8 = 9
        static let grainSeed: UInt64 = 77

        /// An edge's displacement (pt), how fast it varies (per pt), and the pt between sampled points.
        static let edgeWobble: CGFloat = 5
        static let edgeFrequency: CGFloat = 0.012
        static let edgeStep: CGFloat = 3
        /// The second, finer wobble (pt), and its frequency (per pt).
        static let roughAmplitude: CGFloat = 0.6
        static let roughEdgeFrequency: CGFloat = 0.9
        /// How far a fill's alpha varies, and how fast across the card (per pt).
        static let bloom: Float = 0.22
        static let bloomFrequency: Float = 0.006
        static let bloomSeed: Float = 13

        /// A card: fill and edge opacity, and the edge's width.
        static let cardFill: Double = 0.9
        static let cardEdge: Double = 1
        static let edgeWidth: CGFloat = 3
        /// A wash: fill, edge, and as a well behind a picture.
        static let washFill: Double = 0.72
        static let washEdge: Double = 0.85
        static let washWell: Double = 0.24
        /// A symbol sitting on its own solid card: a faint white wash behind it.
        static let onCardWash: Double = 0.35

        /// The dotted outline of what's still to come.
        static let dotWidth: CGFloat = 2
        static let dotDash: [CGFloat] = [0.1, 5]
        static let dotOpacity: Double = 0.9

        /// A picture's symbol and emoji against its side, and the corner of the well behind a symbol.
        static let symbolScale: CGFloat = 0.58
        static let emojiScale: CGFloat = 0.7
        static let wellRadius: CGFloat = 0.28

        /// A symbol roughened as it draws: the noise's frequency (per pt) and how far it moves a pixel.
        static let roughFrequency: Float = 0.32
        static let roughAmount: Float = 1.3
        /// The three drawings swapped to boil a picture.
        static let boilSeeds: [Float] = [1, 2, 3]

        private static func dynamic(light: UInt32, dark: UInt32) -> Color {
            func rgb(_ hex: UInt32) -> UIColor {
                UIColor(
                    red: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255,
                    blue: CGFloat(hex & 0xff) / 255, alpha: 1
                )
            }
            return Color(UIColor { rgb($0.userInterfaceStyle == .dark ? dark : light) })
        }
    }
}
