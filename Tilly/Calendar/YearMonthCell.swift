import SwiftUI

/// One month of the year overview: its short name, its total, and its days as marks. A button
/// that opens the month.
struct YearMonthCell: View {
    let month: YearMonth
    let extrasOnly: Bool
    let isCurrent: Bool
    let onOpen: () -> Void

    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    private var width: CGFloat { 7 * Tokens.Size.yearDayWidth }

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: Tokens.Space.yearMiniGap) {
                label
                days
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel)
    }

    private var figure: String {
        CalendarFormatting.monthLabel(month, extrasOnly: extrasOnly, locale: locale)
    }

    private var label: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(CalendarFormatting.abbreviatedName(month.month, calendar: calendar, locale: locale))
                .font(Tokens.Text.yearMonthName)
                .foregroundStyle(isCurrent ? Tokens.Ink.today : Tokens.Ink.primary)
            Spacer(minLength: 0)
            Text(figure)
                .font(month.isHeavy ? Tokens.Text.yearMonthLabelHeavy : Tokens.Text.yearMonthLabel)
                .monospacedDigit()
                .foregroundStyle(month.isHeavy ? Tokens.Ink.primary : Tokens.Ink.secondary)
        }
        .lineLimit(1)
        .minimumScaleFactor(Tokens.Scale.dayTotalMin)
        .frame(width: width)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    /// Seven columns of marks, the first row starting after the month's leading blank cells.
    private var days: some View {
        let cells = Array(repeating: Optional<YearMark>.none, count: month.leadingDays) + month.marks.map { Optional($0) }
        let columns = Array(repeating: GridItem(.fixed(Tokens.Size.yearDayWidth), spacing: 0), count: 7)
        return LazyVGrid(columns: columns, spacing: 0) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, mark in
                ZStack {
                    if let mark { YearMarkView(mark: mark) }
                }
                .frame(width: Tokens.Size.yearDayWidth, height: Tokens.Size.yearDayHeight)
            }
        }
        .frame(width: width)
    }

    /// "October 2026, €1,166", or "October 2026, nothing".
    private var spokenLabel: String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = locale
        formatter.dateFormat = "MMMM yyyy"
        let first = calendar.date(from: DateComponents(year: month.month.year, month: month.month.month, day: 1))!
        return "\(formatter.string(from: first)), \(figure.isEmpty ? "nothing" : figure)"
    }
}

/// What one day looks like in the year: a dot, or a ring, centred in its cell.
struct YearMarkView: View {
    let mark: YearMark

    var body: some View {
        switch mark {
        case .quiet:
            Circle()
                .fill(Tokens.Ink.tertiary)
                .frame(width: Tokens.Size.yearDotQuiet, height: Tokens.Size.yearDotQuiet)
        case .usual:
            Circle()
                .fill(Tokens.Ink.secondary)
                .frame(width: Tokens.Size.yearDotUsual, height: Tokens.Size.yearDotUsual)
        case let .extra(colour, isLarge):
            let size = isLarge ? Tokens.Size.yearDotExtraLarge : Tokens.Size.yearDotExtra
            Circle()
                .fill(Self.tint(colour))
                .frame(width: size, height: size)
        case let .change(colour, isZero):
            Circle()
                .strokeBorder(
                    Self.tint(colour),
                    style: isZero ? Tokens.Stroke.zeroDot : StrokeStyle(lineWidth: Tokens.Stroke.yearRing)
                )
                .frame(width: Tokens.Size.yearDotRing, height: Tokens.Size.yearDotRing)
        case .today:
            Circle()
                .fill(Tokens.Ink.today)
                .frame(width: Tokens.Size.yearDotExtra, height: Tokens.Size.yearDotExtra)
        }
    }

    /// A category's colour, or the plain dot's when it has none.
    static func tint(_ colour: CategoryColour?) -> Color {
        colour.map(Tokens.CategoryColour.color) ?? Tokens.Chart.uncoloured
    }
}
