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
        static let pinned: Material = .bar
    }

    enum Space {
        static let gutter: CGFloat = 20
        static let section: CGFloat = 16
        static let gap: CGFloat = 12
        static let tight: CGFloat = 8
        static let hairlineGap: CGFloat = 4
        static let rowVerticalAccessible: CGFloat = 12
    }

    enum Size {
        static let row: CGFloat = 52
        static let monthBar: CGFloat = 48
        static let monthBarAccessible: CGFloat = 56
        static let icon: CGFloat = 40
        static let iconAccessible: CGFloat = 44
        static let hairline: CGFloat = 0.5
    }

    enum Radius {
        static let icon: CGFloat = 10
        static let iconAccessible: CGFloat = 12
    }
}
