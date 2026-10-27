import Foundation
import TillyCore

/// All bills' text rendering, kept apart from any view so it can be tested without a simulator.
enum BillsFormatting {
    /// What the card of bills with no category is called, as the lanes call theirs.
    static let uncategorisedName = "No category"

    /// A row's note, or "" when it has none: "€640 yearly", "€41 every 2 months", "€15 every 2 weeks"
    /// when the figure isn't the charge (a monthly bill in Yearly, a yearly one in Monthly, anything
    /// else), joined to the state with " · ": "ends this month", "ends next month", "ends 12/26",
    /// "€25 until Nov 10", "from Oct 18". A bill whose figure is its charge says nothing of its
    /// rhythm. An ended row reads "ended 08/26" and nothing else.
    static func note(for row: BillRow, period: BillPeriod, today: Date, calendar: Calendar, locale: Locale) -> String {
        if case .ended(let end) = row.state {
            return "ended \(monthAndYear(end, calendar: calendar, locale: locale))"
        }

        let state: String? = switch row.state {
        case .runs, .ended:
            nil
        case .starts(let date):
            "from \(monthAndDay(date, calendar: calendar, locale: locale))"
        case .changes(let date, let from):
            "\(TimelineFormatting.amount(from, locale: locale)) until \(monthAndDay(date, calendar: calendar, locale: locale))"
        case .ends(let date):
            ends(date, today: today, calendar: calendar, locale: locale)
        }

        let figureIsCharge = row.rule.interval == 1 && row.rule.unit == (period == .month ? .month : .year)
        if figureIsCharge {
            return state ?? ""
        }
        let charge = "\(TimelineFormatting.amount(row.charge, locale: locale)) \(rhythm(row.rule))"
        return state.map { "\(charge) \u{00B7} \($0)" } ?? charge
    }

    /// "ends this month", "ends next month", else "ends 12/26".
    private static func ends(_ date: Date, today: Date, calendar: Calendar, locale: Locale) -> String {
        let from = calendar.dateComponents([.year, .month], from: today)
        let to = calendar.dateComponents([.year, .month], from: date)
        let months = calendar.dateComponents([.month], from: calendar.date(from: from) ?? today, to: calendar.date(from: to) ?? date).month
        switch months {
        case 0: return "ends this month"
        case 1: return "ends next month"
        default: return "ends \(monthAndYear(date, calendar: calendar, locale: locale))"
        }
    }

    /// "€1,563 a month" or "€18,756 a year".
    static func total(_ value: Decimal, period: BillPeriod, locale: Locale) -> String {
        "\(TimelineFormatting.amount(value, locale: locale)) a \(period.rawValue)"
    }

    /// "daily", "weekly", "monthly", "yearly"; "every 2 months" for anything longer.
    private static func rhythm(_ rule: RecurrenceRule) -> String {
        let unit = rule.unit.rawValue
        guard rule.interval == 1 else { return "every \(rule.interval) \(unit)s" }
        switch rule.unit {
        case .day: return "daily"
        case .week: return "weekly"
        case .month: return "monthly"
        case .year: return "yearly"
        }
    }

    /// "Nov 10", in the order the locale reads it.
    private static func monthAndDay(_ date: Date, calendar: Calendar, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter.string(from: date)
    }

    /// "12/26", as the timeline writes a series' end.
    private static func monthAndYear(_ date: Date, calendar: Calendar, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = locale
        formatter.dateFormat = "MM/yy"
        return formatter.string(from: date)
    }
}
