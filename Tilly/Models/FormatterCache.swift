import Foundation

/// Date and number formatters, made once and kept. Making one is slow (measured at a third of the time a
/// scroll spent on the main thread), and a row or a header makes several every time it is drawn. A formatter
/// from here must not be changed: ask for the format you want, and ask again for another.
nonisolated enum FormatterCache {
    nonisolated(unsafe) private static var dates: [String: DateFormatter] = [:]
    nonisolated(unsafe) private static var numbers: [String: NumberFormatter] = [:]
    private static let lock = NSLock()

    /// A date formatter for `format`, in this calendar's time zone and this locale.
    static func date(format: String, calendar: Calendar, locale: Locale) -> DateFormatter {
        let key = "\(calendar.identifier)|\(calendar.timeZone.identifier)|\(locale.identifier)|\(format)"
        lock.lock()
        defer { lock.unlock() }
        if let hit = dates[key] { return hit }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = locale
        formatter.dateFormat = format
        dates[key] = formatter
        return formatter
    }

    /// A whole-unit currency formatter in `locale`.
    static func wholeCurrency(locale: Locale) -> NumberFormatter {
        let key = locale.identifier
        lock.lock()
        defer { lock.unlock() }
        if let hit = numbers[key] { return hit }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        numbers[key] = formatter
        return formatter
    }
}
