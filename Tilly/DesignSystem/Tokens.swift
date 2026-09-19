import SwiftUI

enum Tokens {
    enum Text {
        static let monthName: Font = .title3.weight(.semibold)
        static let monthTotal: Font = .subheadline
        static let barName: Font = .callout
        static let barTotal: Font = .callout
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
    }

    enum Surface {
        static let base: Color = Color(.systemBackground)
        static let iconWell: Color = Color(.quaternarySystemFill)
        static let rule: Color = Color(.separator)
        /// The pinned month header's ground. Opaque, and deliberately the same paper as
        /// the page: a pinned header hides what passes beneath it rather than tinting it.
        /// Because it matches `base`, the header can carry it at rest too — see the note in
        /// `MonthHeader`. Liquid Glass is for things that float *over* content, which the
        /// floating pill is and a full-bleed sticky header is not.
        static let pinned: Color = Color(.systemBackground)
        static let editorButtonActive: Color = Color(.tertiarySystemFill)
    }

    enum Space {
        static let gutter: CGFloat = 20
        static let section: CGFloat = 16
        static let gap: CGFloat = 12
        static let tight: CGFloat = 8
        static let rowVerticalAccessible: CGFloat = 12
        static let pillHorizontal: CGFloat = 16 // the "back to" pill's inner horizontal padding
        static let floatingClearance: CGFloat = 64 // bottom inset the list carries so the floor line clears the pill
        static let returnThreshold: CGFloat = 240 // how far from the current month the "back to" pill appears
    }

    enum Size {
        static let row: CGFloat = 52
        static let monthBar: CGFloat = 48
        static let monthBarAccessible: CGFloat = 56
        static let icon: CGFloat = 40
        static let iconAccessible: CGFloat = 44
        static let hairline: CGFloat = 0.5
        static let pill: CGFloat = 36 // minimum height of the floating "back to" control
        static let editorButton: CGFloat = 40
        static let editorButtonStroke: CGFloat = 1
        static let editorAmountSize: CGFloat = 80 // the amount's base size, before Dynamic Type scales it
        /// Every editor panel fills exactly this height, so the amount never moves. Tuning value:
        /// the graphical calendar is the tallest panel, and a six-row month (August 2026) measures
        /// about 336pt at the default text size, so 340 clears it without clipping.
        static let editorPanel: CGFloat = 340
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
