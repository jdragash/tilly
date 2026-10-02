import SwiftUI

/// One month as a grid, under the timeline's own header row: the month's name over its figure,
/// the weekdays, and a cell for every day. Pages a month at a time, by the shell's arrows or a
/// sideways swipe, and stops at the window's floor and ceiling. See "The calendar" in
/// `docs/DESIGN.md`.
struct CalendarMonthView: View {
    @Binding var month: MonthKey
    /// Its floor and ceiling bound the paging.
    let window: TimelineWindow
    let calendarMonth: CalendarMonth
    let today: Date
    let onOpenDay: (Date) -> Void

    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    var body: some View {
        let section = calendarMonth.section
        VStack(alignment: .leading, spacing: 0) {
            title(section)
            weekdays
            grid
        }
        .padding(.top, Tokens.Size.headerRow + Tokens.Space.titleTop)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Tokens.Surface.base)
    }

    // MARK: Title

    private func title(_ section: MonthSection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(month.name(in: calendar, relativeTo: today, locale: locale))
                .font(Tokens.Text.calendarTitle)
                .foregroundStyle(Tokens.Ink.primary)
                .accessibilityAddTraits(.isHeader)
            Text(CalendarFormatting.monthFigure(for: section, locale: locale))
                .font(Tokens.Text.monthTotal)
                .monospacedDigit()
                .foregroundStyle(Tokens.Ink.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Tokens.Space.gutter)
        .padding(.bottom, Tokens.Space.titleBottom)
        .accessibilityElement(children: .combine)
    }

    // MARK: Grid

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Tokens.Space.gridGap), count: 7)
    }

    /// The very short weekday names, starting from the calendar's first weekday.
    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return (0..<7).map { symbols[(first + $0) % 7] }
    }

    private var weekdays: some View {
        LazyVGrid(columns: columns, spacing: Tokens.Space.gridGap) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(Tokens.Text.weekday)
                    .foregroundStyle(Tokens.Ink.secondary)
            }
        }
        .padding(.horizontal, Tokens.Space.gutter)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityHidden(true)
    }

    private var grid: some View {
        let rows = (calendarMonth.leadingDays + calendarMonth.days.count + calendarMonth.trailingDays) / 7
        let rowHeight = rows > 5 ? Tokens.Size.calendarRowSixWeeks : Tokens.Size.calendarRow
        let todayStart = calendar.startOfDay(for: today)
        return LazyVGrid(columns: columns, spacing: Tokens.Space.gridGap) {
            // The three blocks share one grid, so each has its own ids: a leading and a trailing
            // block both counting from 0 once collided with the days', and a trailing cell took a
            // day's place ("29, 30, blank, 4" for "29, 30, 1, 4").
            ForEach(neighbours(count: calendarMonth.leadingDays, prefix: "lead") {
                previousMonthDays - calendarMonth.leadingDays + 1 + $0
            }) { cell in
                neighbour(cell.day, height: rowHeight)
            }
            ForEach(calendarMonth.days) { day in
                CalendarDayCell(day: day, isToday: day.date == todayStart) { onOpenDay(day.date) }
                    // From the top, so a cell whose content runs a little long at the largest
                    // size hangs below its row rather than lifting its number off the line.
                    .frame(height: rowHeight, alignment: .top)
            }
            ForEach(neighbours(count: calendarMonth.trailingDays, prefix: "trail") { $0 + 1 }) { cell in
                neighbour(cell.day, height: rowHeight)
            }
        }
        .padding(.horizontal, Tokens.Space.gutter)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture().onEnded { drag in
                guard abs(drag.translation.width) > abs(drag.translation.height) else { return }
                if drag.translation.width < -Tokens.Size.pageSwipe {
                    page(by: 1)
                } else if drag.translation.width > Tokens.Size.pageSwipe {
                    page(by: -1)
                }
            }
        )
    }

    private struct Neighbour: Identifiable {
        let id: String
        let day: Int
    }

    private func neighbours(count: Int, prefix: String, day: (Int) -> Int) -> [Neighbour] {
        (0..<count).map { Neighbour(id: "\(prefix)-\($0)", day: day($0)) }
    }

    /// A day of the month before or after, shown as its number alone.
    private func neighbour(_ day: Int, height: CGFloat) -> some View {
        Text("\(day)")
            .font(Tokens.Text.dayNumber)
            .foregroundStyle(Tokens.Ink.tertiary)
            .frame(height: Tokens.Size.todayCircle)
            .padding(.top, Tokens.Space.cellTop)
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: .top)
            .accessibilityHidden(true)
    }

    private var previousMonthDays: Int {
        let first = calendar.date(from: DateComponents(
            year: month.advanced(by: -1).year, month: month.advanced(by: -1).month, day: 1
        ))
        return first.flatMap { calendar.range(of: .day, in: .month, for: $0)?.count } ?? 30
    }

    private func page(by step: Int) {
        let target = month.advanced(by: step)
        guard target >= window.floor, target <= window.ceiling else { return }
        month = target
    }
}
