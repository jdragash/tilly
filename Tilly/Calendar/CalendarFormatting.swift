import Foundation

/// The calendar's text rendering, kept apart from any view so it can be tested without a
/// simulator. Builds on `TimelineFormatting`'s forms.
enum CalendarFormatting {
    /// `TimelineFormatting.headerFigure`, except an empty month that isn't the current one:
    /// "Nothing this month", or "Nothing on top" with extras only.
    static func monthFigure(for section: MonthSection, locale: Locale) -> String {
        if section.isEmpty && !section.isCurrent && !section.showsExtrasOnly {
            return "Nothing this month"
        }
        return TimelineFormatting.headerFigure(for: section, locale: locale)
    }

    /// "Mon 5, 2 charges, 1,185 euros out": VoiceOver for a day cell, the currency spoken in full as
    /// the timeline's labels do. "Mon 5, no charges" for an empty one.
    static func dayLabel(_ day: CalendarDay, calendar: Calendar, locale: Locale) -> String {
        let name = TimelineFormatting.dayLine(day.date, calendar: calendar, locale: locale)
        guard !day.entries.isEmpty else { return "\(name), no charges" }
        let count = day.entries.count == 1 ? "1 charge" : "\(day.entries.count) charges"
        return "\(name), \(count), \(TimelineFormatting.spokenAmount(day.total, locale: locale)) out"
    }

    /// "Sep \u{2013} Aug": the first and last months the year overview covers.
    static func yearRange(_ overview: YearOverview, calendar: Calendar, locale: Locale) -> String {
        guard let first = overview.months.first, let last = overview.months.last else { return "" }
        return "\(abbreviatedName(first.month, calendar: calendar, locale: locale)) \u{2013} "
            + abbreviatedName(last.month, calendar: calendar, locale: locale)
    }

    /// "€19,610 · usual month €1,402"; with extras only "+€2,775 on top · usual month €1,402",
    /// or "Nothing on top · usual month €1,390" when there are none.
    static func yearFigure(_ overview: YearOverview, extrasOnly: Bool, locale: Locale) -> String {
        let usual = "usual month \(TimelineFormatting.amount(overview.usualMonth, locale: locale))"
        let lead: String
        if !extrasOnly {
            lead = TimelineFormatting.amount(overview.total, locale: locale)
        } else if overview.hasExtras {
            lead = "+\(TimelineFormatting.amount(overview.extrasTotal, locale: locale)) on top"
        } else {
            lead = "Nothing on top"
        }
        return "\(lead) \u{00B7} \(usual)"
    }

    /// A month's total under its name in the year overview, "+€351" with extras only, and empty
    /// for a month with nothing to show.
    static func monthLabel(_ month: YearMonth, extrasOnly: Bool, locale: Locale) -> String {
        if extrasOnly {
            return month.extrasTotal == 0 ? "" : "+\(TimelineFormatting.amount(month.extrasTotal, locale: locale))"
        }
        return month.total == 0 ? "" : TimelineFormatting.amount(month.total, locale: locale)
    }

    /// "Sep": a month's short name, as the year labels it.
    static func abbreviatedName(_ month: MonthKey, calendar: Calendar, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = locale
        formatter.dateFormat = "MMM"
        let first = calendar.date(from: DateComponents(year: month.year, month: month.month, day: 1))!
        return formatter.string(from: first)
    }
}
