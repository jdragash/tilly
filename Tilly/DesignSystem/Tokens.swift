import SwiftUI

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
    }

    enum Stroke {
        /// The empty emoji slot's dashed outline.
        static let emojiSlot = StrokeStyle(lineWidth: 1.5, dash: [4, 3])
    }

    /// How far text may shrink to fit a line before it truncates.
    enum Scale {
        static let editorAmountMin: CGFloat = 0.3
        static let editorButtonMin: CGFloat = 0.8
    }

    enum Opacity {
        /// How far an upcoming or skipped row's icon well sits back; from the prototype.
        static let upcomingIcon: Double = 0.55
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
