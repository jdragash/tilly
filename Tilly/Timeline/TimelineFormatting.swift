import Foundation

/// The timeline's text rendering, kept apart from any view so it can be tested without a
/// simulator. `amount` and `dayLine` are the short forms rows and headings show;
/// `accessibilityLabel` reads the same information as a sentence for VoiceOver.
enum TimelineFormatting {
    /// "−€950". A zero renders unsigned — there is no direction to signal when nothing
    /// moved. A `nil` renders an em dash.
    static func amount(_ value: Decimal?, locale: Locale = .current) -> String {
        guard let value else { return "\u{2014}" }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        let magnitude = formatter.string(from: abs(value) as NSDecimalNumber) ?? "\(abs(value))"

        return value == 0 ? magnitude : "\u{2212}\(magnitude)"
    }

    /// "Mon 28"
    static func dayLine(_ date: Date, calendar: Calendar = .current, locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = locale
        formatter.dateFormat = "EEE d"
        return formatter.string(from: date)
    }

    /// "Rent, Saturday 12 September, 950 US dollars out, upcoming" — name, date, amount
    /// and state read as a sentence, so VoiceOver announces one thing rather than four.
    /// The currency is spoken in full, from the same locale the screen formats against.
    static func accessibilityLabel(for entry: TimelineEntry, calendar: Calendar, locale: Locale) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.timeZone = calendar.timeZone
        dateFormatter.locale = locale
        dateFormatter.dateFormat = "EEEE d MMMM"
        let dateString = dateFormatter.string(from: entry.date)

        let amountString: String
        if let amount = entry.amount {
            amountString = "\(spokenAmount(abs(amount), locale: locale)) out"
        } else {
            amountString = "amount not yet known"
        }

        return "\(entry.name), \(dateString), \(amountString), \(stateWord(for: entry.state))"
    }

    /// "September, total 1,521 US dollars out"
    static func accessibilityLabel(for section: MonthSection, calendar: Calendar, today: Date, locale: Locale) -> String {
        let name = section.month.name(in: calendar, relativeTo: today, locale: locale)
        return "\(name), total \(spokenAmount(abs(section.total), locale: locale)) out"
    }

    private static func stateWord(for state: OccurrenceState) -> String {
        switch state {
        case .upcoming: "upcoming"
        case .charged: "charged"
        case .skipped: "skipped"
        }
    }

    /// "950 US dollars" — the currency named in full, so VoiceOver speaks it rather than
    /// reading a symbol. Taken from `locale`, never assumed: the screen renders whatever
    /// currency the device is set to, and the spoken label has to agree with it.
    private static func spokenAmount(_ value: Decimal, locale: Locale) -> String {
        guard let code = locale.currency?.identifier else {
            return "\(value)"
        }
        return value.formatted(
            .currency(code: code)
                .presentation(.fullName)
                .precision(.fractionLength(0))
                .locale(locale)
        )
    }
}
