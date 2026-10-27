import Foundation

/// Where each day of a month without a charge would fall among that month's rows, which run newest
/// first. Keyed by the index of the row it sits above; `section.entries.count` means after the last
/// row. Where the Today divider sits before row `i`, the days keyed `i` straddle it: a day still to
/// come sits above it and a passed one below, so a view splits them by date. Today itself is left
/// out when the divider shows, since landing on the divider covers it.
enum DaySeams {
    static func seams(for section: MonthSection, today: Date, calendar: Calendar) -> [Int: [Date]] {
        let interval = section.month.interval(in: calendar)
        guard let days = calendar.range(of: .day, in: .month, for: interval.start) else { return [:] }
        let todayStart = calendar.startOfDay(for: today)
        let dividerShows = section.isCurrent && section.hasChargedEntry
        let chargedDays = Set(section.entries.map(\.date))

        var result: [Int: [Date]] = [:]
        // Newest day first, so each list comes out newest first.
        for offset in days.reversed() {
            guard let day = calendar.date(byAdding: .day, value: offset - 1, to: interval.start) else { continue }
            let start = calendar.startOfDay(for: day)
            if chargedDays.contains(start) { continue }
            if dividerShows, start == todayStart { continue }
            let index = section.entries.firstIndex { $0.date < start } ?? section.entries.count
            result[index, default: []].append(start)
        }
        return result
    }
}
