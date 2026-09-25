import SwiftData
import SwiftUI

/// One month of categories as lanes, under the timeline's own header, with the categories that
/// have nothing this month named in one line and, on the current month, the next three charges.
/// See "The category view" in `docs/DESIGN.md` and "The category view is lanes across one month"
/// in `docs/DECISIONS.md`.
struct CategoryView: View {
    @Binding var month: MonthKey
    /// Its floor and ceiling bound the arrows.
    let window: TimelineWindow
    let expenses: [Expense]
    let today: Date
    /// What the bottom row needs clear above the safe area, as the timeline's list is given.
    let bottomClearance: CGFloat
    let onOpen: (TimelineEntry) -> Void

    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    /// The lane picked out, by `CategoryLane.id`. Cleared when the month changes.
    @State private var picked: String?
    @State private var containerHeight: CGFloat = 0
    @State private var footerHeight: CGFloat = 0
    @State private var isScrolled = false

    var body: some View {
        let built = categoryMonth
        let pickedLane = built.lanes.first { $0.id == picked }
        let laneHeight = laneHeight(lanes: built.lanes.count)
        VStack(spacing: 0) {
            MonthHeader(
                section: built.section, today: today, isPinned: isScrolled,
                figure: pickedLane.map { TimelineFormatting.amount($0.total, locale: locale) },
                figureLabel: pickedLane.map(CategoryFormatting.focusLabel),
                trailingClearance: Tokens.Space.categoryHeaderTrailingClearance
            )
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    LanesView(
                        month: built, laneHeight: laneHeight, today: today, picked: pickedLane?.id,
                        onPick: { lane in picked = picked == lane.id ? nil : lane.id },
                        onOpen: onOpen
                    )
                    footer(built)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { footerHeight = $0 }
                }
            }
            .scrollDisabled(fits(laneHeight: laneHeight, lanes: built.lanes.count))
            .contentMargins(.bottom, bottomClearance, for: .scrollContent)
            .onScrollGeometryChange(for: CGFloat.self) { $0.containerSize.height } action: { _, height in
                containerHeight = height
            }
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top > Tokens.Size.hairline
            } action: { _, scrolled in
                isScrolled = scrolled
            }
        }
        .background(Tokens.Surface.base)
        .onChange(of: month) { _, _ in picked = nil }
    }

    // MARK: Fitting

    /// The lanes share what the screen has between the axis and the footer, each between
    /// `laneHeightMin` and `laneHeightMax`; below the minimum the page scrolls instead.
    private func laneHeight(lanes: Int) -> CGFloat {
        guard lanes > 0, containerHeight > 0 else { return Tokens.Size.laneHeightMax }
        let available = containerHeight - Tokens.Size.laneAxis - footerHeight
        let share = (available / CGFloat(lanes)).rounded(.down)
        return min(Tokens.Size.laneHeightMax, max(Tokens.Size.laneHeightMin, share))
    }

    private func fits(laneHeight: CGFloat, lanes: Int) -> Bool {
        Tokens.Size.laneAxis + laneHeight * CGFloat(lanes) + footerHeight <= containerHeight + Tokens.Size.hairline
    }

    // MARK: Under the lanes

    private func footer(_ built: CategoryMonth) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            let monthName = built.section.month.name(in: calendar, relativeTo: today, locale: locale)
            if let quiet = CategoryFormatting.quietLine(built.quiet, month: monthName, calendar: calendar, locale: locale) {
                Text(quiet)
                    .font(Tokens.Text.quietLine)
                    .foregroundStyle(Tokens.Ink.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Tokens.Space.quietTop)
                    .padding(.bottom, Tokens.Space.quietBottom)
            }
            if !built.next.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Next")
                        .font(Tokens.Text.nextHeading)
                        .textCase(.uppercase)
                        .foregroundStyle(Tokens.Ink.secondary)
                        .padding(.bottom, Tokens.Space.nextHeadingBottom)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(built.next) { next in
                        nextRow(next)
                    }
                }
                .padding(.top, Tokens.Space.nextTop)
            }
        }
        .padding(.horizontal, Tokens.Space.gutter)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func nextRow(_ next: NextCharge) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.tight) {
            Text(next.category?.emoji ?? next.entry.emoji ?? "")
            Text(next.entry.name)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(CategoryFormatting.relativeDay(next.entry.date, today: today, calendar: calendar, locale: locale))
                .foregroundStyle(Tokens.Ink.secondary)
                .lineLimit(1)
            Text(TimelineFormatting.amount(next.entry.amount, locale: locale))
                .monospacedDigit()
                .lineLimit(1)
        }
        .font(Tokens.Text.nextRow)
        .padding(.vertical, Tokens.Space.nextRowVertical)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(TimelineFormatting.accessibilityLabel(for: next.entry, calendar: calendar, locale: locale))
    }

    // MARK: Data

    /// Built on every change rather than cached: a saved edit changes the same `Expense`
    /// instances this view holds, which `.onChange(of:)` can't see (see
    /// `.claude/rules/swiftui-controls.md`).
    private var categoryMonth: CategoryMonth {
        let infos = categories.map {
            CategoryInfo(id: $0.id, emoji: $0.emoji, name: $0.name, colour: $0.colour)
        }
        return CategoryMonthBuilder.month(
            month, expenses: Expense.timelineExpenses(expenses), categoryOf: Expense.categoryMap(expenses),
            categories: infos, today: today, calendar: calendar, isCurrent: month == window.current
        )
    }
}
