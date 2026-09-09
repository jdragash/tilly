import SwiftUI

enum Tokens {
    enum Text {
        static let monthName: Font = .title3.weight(.semibold)
        static let monthTotal: Font = .subheadline
        static let barName: Font = .callout
        static let barTotal: Font = .callout
        static let name: Font = .body
        static let amount: Font = .body
        static let dayHeading: Font = .footnote.weight(.semibold)
        static let dayTotal: Font = .footnote
        static let caption: Font = .footnote
        static let body: Font = .body
        static let emptyTitle: Font = .title2.weight(.semibold)
    }

    enum Tracking {
        static let dayHeading: CGFloat = 0.3
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
    }

    enum Space {
        static let gutter: CGFloat = 20
        static let section: CGFloat = 16
        static let gap: CGFloat = 12
        static let tight: CGFloat = 8
        static let hairlineGap: CGFloat = 4
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
    }
}
