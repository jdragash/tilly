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
}
