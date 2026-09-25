import SwiftUI
import UIKit

enum Tokens {
    enum Text {
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
        static let editorName: Font = .title3.weight(.medium)
        static let editorButton: Font = .subheadline
        static let keypadKey: Font = .title
        /// The editor's amount is the largest thing on the screen. The view scales
        /// `Size.editorAmountSize` with `@ScaledMetric` and builds the font here, where a
        /// fixed-size font belongs.
        static func editorAmount(size: CGFloat) -> Font { .system(size: size, weight: .semibold) }
        /// A lane's emoji follows the lane's height, which already answers to the screen, so it
        /// doesn't scale with Dynamic Type too. From the prototype.
        static func laneEmoji(laneHeight: CGFloat) -> Font {
            .system(size: min(26, max(15, (0.46 * laneHeight).rounded())))
        }
        static let laneTotal: Font = .subheadline
        static let axisDay: Font = .caption2
        static let axisToday: Font = .caption2.weight(.semibold)
        static let quietLine: Font = .footnote
        static let nextHeading: Font = .footnote.weight(.semibold)
        static let nextRow: Font = .subheadline
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
    }

    /// How far text may shrink to fit a line before it truncates.
    enum Scale {
        static let editorAmountMin: CGFloat = 0.3
        static let editorButtonMin: CGFloat = 0.8
        /// A month header's name and a picked-out category's name, before they truncate.
        static let headerMin: CGFloat = 0.8
        /// A lane's total, before it would run out of its column.
        static let laneTotalMin: CGFloat = 0.5
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
    }

    enum Ink {
        static let primary: Color = .primary
        static let secondary: Color = .secondary
        static let tertiary: Color = Color(.tertiaryLabel)
        static let quaternary: Color = Color(.quaternaryLabel)
        static let accent: Color = .accentColor
        /// The editor's trash button, and its confirmation dialog's destructive buttons.
        static let destructive: Color = .red
    }

    enum Surface {
        static let base: Color = Color(.systemBackground)
        static let iconWell: Color = Color(.quaternarySystemFill)
        static let rule: Color = Color(.separator)
        /// The pinned month header's ground. Opaque, and deliberately the same paper as
        /// the page: a pinned header hides what passes beneath it rather than tinting it.
        /// Because it matches `base`, the header can carry it at rest too — see the note in
        /// `MonthHeader`. Liquid Glass is for things that float *over* content, which the
        /// floating buttons are and a full-bleed sticky header is not.
        static let pinned: Color = Color(.systemBackground)
        static let editorButtonActive: Color = Color(.tertiarySystemFill)
        /// Behind a picked-out lane's emoji.
        static let pickedLane: Color = Color(.secondarySystemFill)
    }

    enum Chart {
        /// A dot for a category without a colour, or charges with no category.
        static let uncoloured: Color = Color(.systemGray)
        /// The hairline between two lanes: fainter than `Surface.rule`, since it only groups.
        static let laneRule: Color = Color(.quaternaryLabel)
    }

    enum Space {
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
    }

    enum Size {
        static let row: CGFloat = 52
        static let icon: CGFloat = 40
        static let iconAccessible: CGFloat = 44
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
        static let editorButton: CGFloat = 40
        static let editorButtonStroke: CGFloat = 1
        static let editorAmountSize: CGFloat = 80 // the amount's base size, before Dynamic Type scales it
        /// The name field's least height, before Dynamic Type scales it. A focused field grows from
        /// 24.0 to 25.67pt (measured), which moves the amount above it by half that; a minimum
        /// above the larger keeps its height, and the amount, still.
        static let editorNameHeight: CGFloat = 28
        /// Every editor panel fills exactly this height, so the amount never moves. Tuning value:
        /// the graphical calendar is the tallest panel, and a six-row month (August 2026) measures
        /// about 336pt at the default text size, so 340 clears it without clipping.
        static let editorPanel: CGFloat = 340
        static let emojiSlot: CGFloat = 48
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
        /// The repeat wheels' two narrow columns; the end column takes the rest. Tuning values:
        /// a wheel's natural width is unbounded, so equal thirds truncated "12 payments".
        static let wheelInterval: CGFloat = 64
        static let wheelUnit: CGFloat = 96
    }

    enum Motion {
        // The return scroll's duration scales with how far the reader actually has to
        // travel, the way a browser's native smooth scroll does. A fixed duration is the
        // thing that reads badly: measured on device, `.default` moved 2,052 points in
        // 284ms, which lands as a smear rather than as travel. Floor and ceiling keep a
        // short hop from feeling sluggish and a long one from dragging.
        static let returnPointsPerSecond: CGFloat = 3000
        static let returnDurationMin: TimeInterval = 0.35
        static let returnDurationMax: TimeInterval = 0.9
    }

    enum Radius {
        static let icon: CGFloat = 10
        static let iconAccessible: CGFloat = 12
        static let editorButton: CGFloat = 12
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
