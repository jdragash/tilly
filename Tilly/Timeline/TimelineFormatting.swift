import Foundation

/// The timeline's text rendering, kept apart from any view so it can be tested without a
/// simulator. `amount`, `rowDate` and `dayLine` are the short forms rows and headings show;
/// `accessibilityLabel` reads the same information as a sentence for VoiceOver.
enum TimelineFormatting {
    /// "€950": the magnitude alone, with no minus sign, and a zero as "€0". A `nil` renders an
    /// em dash.
    static func amount(_ value: Decimal?, locale: Locale = .current) -> String {
        guard let value else { return "\u{2014}" }

        return FormatterCache.wholeCurrency(locale: locale)
            .string(from: abs(value) as NSDecimalNumber) ?? "\(abs(value))"
    }

    /// "Mon 28"
    static func dayLine(_ date: Date, calendar: Calendar = .current, locale: Locale = .current) -> String {
        FormatterCache.date(format: "EEE d", calendar: calendar, locale: locale).string(from: date)
    }

    /// "24 Oct"; within a day of `today`, "Yesterday · 23 Oct", "Today · 24 Oct", "Tomorrow · 25 Oct".
    static func rowDate(_ date: Date, today: Date, calendar: Calendar = .current, locale: Locale = .current) -> String {
        let day = FormatterCache.date(format: "d MMM", calendar: calendar, locale: locale).string(from: date)
        guard let word = nearWord(date, today: today, calendar: calendar) else { return day }
        return "\(word) \u{00B7} \(day)"
    }

    /// "Last payment" on the last charge; "ends this month", "ends next month", then "ends 05/27",
    /// counted in calendar months from `today`'s; "ended 08/26" on an earlier charge once the end
    /// has passed; nil with no end.
    static func endLine(for entry: TimelineEntry, today: Date, calendar: Calendar = .current, locale: Locale = .current) -> String? {
        guard let endDate = entry.endDate else { return nil }
        if entry.isLastPayment { return "Last payment" }

        let numeric = FormatterCache.date(format: "MM/yy", calendar: calendar, locale: locale).string(from: endDate)
        if entry.endHasPassed { return "ended \(numeric)" }
        switch monthsAhead(endDate, today: today, calendar: calendar) {
        case 0: return "ends this month"
        case 1: return "ends next month"
        default: return "ends \(numeric)"
        }
    }

    /// "Today, 24 Oct", for the divider.
    static func todayDivider(_ today: Date, calendar: Calendar = .current, locale: Locale = .current) -> String {
        "Today, \(FormatterCache.date(format: "d MMM", calendar: calendar, locale: locale).string(from: today))"
    }

    /// "Today, 24 October": the divider as VoiceOver reads it.
    static func spokenTodayDivider(_ today: Date, calendar: Calendar = .current, locale: Locale = .current) -> String {
        "Today, \(FormatterCache.date(format: "d MMMM", calendar: calendar, locale: locale).string(from: today))"
    }

    /// "Rent, today, Saturday 24 October, 950 US dollars out, yearly, last payment, upcoming" —
    /// name, the near word within a day, date, amount, yearly, the end when there is one, and
    /// state read as a sentence, so VoiceOver announces one thing rather than six. The currency
    /// is spoken in full, from the same locale the screen formats against.
    static func accessibilityLabel(for entry: TimelineEntry, today: Date, calendar: Calendar, locale: Locale) -> String {
        let dateString = FormatterCache.date(format: "EEEE d MMMM", calendar: calendar, locale: locale)
            .string(from: entry.date)

        let amountString: String
        if let amount = entry.amount {
            amountString = "\(spokenAmount(abs(amount), locale: locale)) out"
        } else {
            amountString = "amount not yet known"
        }

        var parts = [entry.name]
        if let word = nearWord(entry.date, today: today, calendar: calendar) {
            parts.append(word.lowercased())
        }
        parts += [dateString, amountString]
        if entry.isYearly { parts.append("yearly") }
        if let end = spokenEnd(for: entry, today: today, calendar: calendar, locale: locale) {
            parts.append(end)
        }
        parts.append(stateWord(for: entry.state))
        return parts.joined(separator: ", ")
    }

    /// `endLine` as VoiceOver says it: a month and year in full where the screen shows "05/27".
    private static func spokenEnd(for entry: TimelineEntry, today: Date, calendar: Calendar, locale: Locale) -> String? {
        guard let endDate = entry.endDate else { return nil }
        if entry.isLastPayment { return "last payment" }

        let spoken = FormatterCache.date(format: "MMMM yyyy", calendar: calendar, locale: locale).string(from: endDate)
        if entry.endHasPassed { return "ended \(spoken)" }
        switch monthsAhead(endDate, today: today, calendar: calendar) {
        case 0: return "ends this month"
        case 1: return "ends next month"
        default: return "ends \(spoken)"
        }
    }

    /// "Today", "Tomorrow" or "Yesterday" within a day of `today`; nil further off.
    private static func nearWord(_ date: Date, today: Date, calendar: Calendar) -> String? {
        let days = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: today), to: calendar.startOfDay(for: date)
        ).day
        switch days {
        case 0: return "Today"
        case 1: return "Tomorrow"
        case -1: return "Yesterday"
        default: return nil
        }
    }

    /// Calendar months from `today`'s month to `date`'s: 20 Dec to 5 Jan is one.
    private static func monthsAhead(_ date: Date, today: Date, calendar: Calendar) -> Int {
        let from = calendar.dateComponents([.year, .month], from: today)
        let to = calendar.dateComponents([.year, .month], from: date)
        return ((to.year ?? 0) - (from.year ?? 0)) * 12 + (to.month ?? 0) - (from.month ?? 0)
    }

    /// "€162 left" for the current month; "€1,539" for every other month. A current month
    /// with nothing left reads "€0 left". A section built with only extras reads "+€351 on top"
    /// for every month, the current one included, or "Nothing on top" when it has no entries.
    static func headerFigure(for section: MonthSection, locale: Locale = .current) -> String {
        if section.showsExtrasOnly {
            return section.isEmpty ? "Nothing on top" : "+\(amount(section.total, locale: locale)) on top"
        }
        guard section.isCurrent else { return amount(section.total, locale: locale) }
        return "\(amount(section.remaining, locale: locale)) left"
    }

    /// "September, 162 US dollars left" for the current month; "August, total 1,539 US
    /// dollars out" for every other month.
    static func accessibilityLabel(for section: MonthSection, calendar: Calendar, today: Date, locale: Locale) -> String {
        let name = section.month.spokenName(in: calendar, relativeTo: today, locale: locale)
        if section.isCurrent {
            return "\(name), \(spokenAmount(abs(section.remaining), locale: locale)) left"
        }
        return "\(name), total \(spokenAmount(abs(section.total), locale: locale)) out"
    }

    private static func stateWord(for state: OccurrenceState) -> String {
        switch state {
        case .upcoming: "upcoming"
        case .charged: "charged"
        case .skipped: "skipped"
        }
    }

    /// "950 euros" — `Money`'s currency named in full, so VoiceOver speaks it rather than
    /// reading a symbol, in the words of `locale`.
    static func spokenAmount(_ value: Decimal, locale: Locale) -> String {
        value.formatted(
            .currency(code: Money.currencyCode)
                .presentation(.fullName)
                .precision(.fractionLength(0))
                .locale(locale)
        )
    }
}
