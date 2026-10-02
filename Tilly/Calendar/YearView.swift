import SwiftUI

/// The next twelve months at once, from this one: each with its total and its days as marks, so
/// what comes on top of a usual month shows in colour. Under them, a key. Tapping a month opens
/// it. See "The calendar" in `docs/DESIGN.md`.
struct YearView: View {
    let overview: YearOverview
    let extrasOnly: Bool
    let today: Date
    /// What the title keeps clear for the All / Extras toggle floating over its trailing end.
    let titleTrailingClearance: CGFloat
    let onOpenMonth: (MonthKey) -> Void

    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                title
                grid
                key
            }
            .padding(.top, Tokens.Space.titleTop)
        }
        // The bottom row floats over the end of the page: the same clear space the list leaves.
        .contentMargins(.bottom, Tokens.Space.floatingClearance, for: .scrollContent)
        .scrollBounceBehavior(.basedOnSize)
        .padding(.top, Tokens.Size.headerRow)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Tokens.Surface.base)
    }

    // MARK: Title

    private var title: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(CalendarFormatting.yearRange(overview, calendar: calendar, locale: locale))
                .font(Tokens.Text.calendarTitle)
                .foregroundStyle(Tokens.Ink.primary)
                .accessibilityAddTraits(.isHeader)
                // Only the name shares a line with the toggle; the figure beneath runs the width.
                // The clearance includes the gutter this block already keeps.
                .padding(.trailing, max(0, titleTrailingClearance - Tokens.Space.gutter))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(CalendarFormatting.yearFigure(overview, extrasOnly: extrasOnly, locale: locale))
                .font(Tokens.Text.monthTotal)
                .monospacedDigit()
                .foregroundStyle(Tokens.Ink.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Tokens.Space.gutter)
        .padding(.bottom, Tokens.Space.titleBottom)
        .accessibilityElement(children: .combine)
    }

    // MARK: Months

    private var grid: some View {
        let current = MonthKey(containing: today, calendar: calendar)
        let columns = Array(repeating: GridItem(.flexible(), spacing: Tokens.Space.yearColumnGap, alignment: .topLeading), count: 3)
        return LazyVGrid(columns: columns, alignment: .leading, spacing: Tokens.Space.yearRowGap) {
            ForEach(overview.months) { month in
                YearMonthCell(
                    month: month, extrasOnly: extrasOnly, isCurrent: month.month == current,
                    onOpen: { onOpenMonth(month.month) }
                )
            }
        }
        .padding(.horizontal, Tokens.Space.gutter)
    }

    // MARK: Key

    private var key: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.keyLineGap) {
            if overview.hasExtras {
                keyLine(.extra(nil, isLarge: false), "A bill that isn\u{2019}t monthly, in its category\u{2019}s colour")
                keyLine(.change(nil, isZero: false), "A monthly bill that starts, changes price or ends")
                keyLine(.usual, "A day with only monthly bills")
                Text("Each month shows its total. Tap a month to open it.")
                    .foregroundStyle(Tokens.Ink.secondary)
            } else {
                keyLine(.usual, "A day with only monthly bills")
                let usual = TimelineFormatting.amount(overview.usualMonth, locale: locale)
                Text("Every month is \(usual). A yearly renewal would show in colour.")
                    .foregroundStyle(Tokens.Ink.secondary)
            }
        }
        .font(Tokens.Text.yearKey)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Tokens.Space.gutter)
        .padding(.top, Tokens.Space.yearKeyTop)
    }

    private func keyLine(_ mark: YearMark, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.keyDotGap) {
            YearMarkView(mark: mark)
                .frame(width: Tokens.Size.yearDotExtraLarge)
                .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + Tokens.Size.yearDotExtra / 2 }
            Text(text)
                .foregroundStyle(Tokens.Ink.primary)
        }
    }
}
