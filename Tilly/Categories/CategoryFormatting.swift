import Foundation

/// The category view's text, kept apart from any view so it's tested without a simulator.
enum CategoryFormatting {
    /// "Tomorrow", a weekday within six days ("Saturday"), then month and day ("Oct 15").
    static func relativeDay(_ date: Date, today: Date, calendar: Calendar, locale: Locale) -> String {
        let days = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: today), to: calendar.startOfDay(for: date)
        ).day ?? 0
        if days == 0 || days == 1 {
            // From the day count, not the date: a relative date format measures from the real
            // clock, not from `today`.
            let relative = RelativeDateTimeFormatter()
            relative.locale = locale
            relative.dateTimeStyle = .named
            relative.formattingContext = .beginningOfSentence
            return relative.localizedString(from: DateComponents(day: days))
        }
        let formatter = formatter(calendar: calendar, locale: locale)
        switch days {
        case 2...6:
            formatter.setLocalizedDateFormatFromTemplate("EEEE")
        default:
            formatter.setLocalizedDateFormatFromTemplate("MMMd")
        }
        return formatter.string(from: date)
    }

    /// "Nothing in September: 📗 next Nov 3 · ✈️ next Jan 12". A category with no next charge
    /// shows its emoji alone. nil when nothing is quiet.
    static func quietLine(_ quiet: [QuietCategory], month: String, calendar: Calendar, locale: Locale) -> String? {
        guard !quiet.isEmpty else { return nil }
        let formatter = formatter(calendar: calendar, locale: locale)
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        let items = quiet.map { item in
            item.next.map { "\(item.category.emoji) next \(formatter.string(from: $0))" } ?? item.category.emoji
        }
        return "Nothing in \(month): \(items.joined(separator: " \u{00B7} "))"
    }

    /// "🏠 Home −€1,259": the header's figure while a category is picked out.
    static func focusFigure(_ lane: CategoryLane, locale: Locale) -> String {
        "\(focusLabel(lane)) \(TimelineFormatting.amount(lane.total, locale: locale))"
    }

    /// "🏠 Home": the part of `focusFigure` before the total, which the header truncates first.
    static func focusLabel(_ lane: CategoryLane) -> String {
        lane.category.map { "\($0.emoji) \($0.name)" } ?? uncategorisedName
    }

    /// "Home, 1,259 euros out, 3 charges", for VoiceOver: the currency spoken in full, as the
    /// timeline's labels do.
    static func laneLabel(_ lane: CategoryLane, locale: Locale) -> String {
        let name = lane.category?.name ?? uncategorisedName
        let count = lane.dots.count == 1 ? "1 charge" : "\(lane.dots.count) charges"
        return "\(name), \(TimelineFormatting.spokenAmount(abs(lane.total), locale: locale)) out, \(count)"
    }

    /// "Sat 12 Sep" in the UK; the device's own order elsewhere.
    static func readoutDate(_ date: Date, calendar: Calendar, locale: Locale) -> String {
        let formatter = formatter(calendar: calendar, locale: locale)
        formatter.setLocalizedDateFormatFromTemplate("EEEdMMM")
        return formatter.string(from: date)
    }

    /// What a lane of charges saved before categories existed is called.
    private static let uncategorisedName = "No category"

    private static func formatter(calendar: Calendar, locale: Locale) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = locale
        return formatter
    }
}
