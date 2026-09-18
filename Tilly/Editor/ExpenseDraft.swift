import Foundation
import TillyCore

enum KeypadKey: Equatable, Sendable {
    case digit(Int), decimal, delete
}

/// Everything the expense editor is holding before Save, as a plain value so the rules of
/// entry are tested without a view. The amount is kept as typed text (`digits`, always with
/// "." for the point) so a trailing decimal survives mid-entry; the locale only renders it.
struct ExpenseDraft: Equatable, Sendable {
    static let maxWholeDigits = 7
    static let maxDecimals = 2

    var digits: String = ""
    var name: String = ""
    var date: Date // start of day
    var interval: Int = 1 // 1...30
    var unit: RecurrenceUnit = .month
    var paymentCount: Int? = nil // nil = no end; otherwise 2...120
    var categoryID: UUID? = nil

    init(today: Date, calendar: Calendar) {
        self.date = calendar.startOfDay(for: today)
    }

    // MARK: Keypad

    mutating func press(_ key: KeypadKey) {
        switch key {
        case .digit(let digit):
            guard (0...9).contains(digit) else { return }
            if digits == "0" {
                digits = String(digit)
            } else if canAppendDigit {
                digits.append(String(digit))
            }
        case .decimal:
            guard !digits.contains(".") else { return }
            digits = digits.isEmpty ? "0." : digits + "."
        case .delete:
            digits = String(digits.dropLast())
        }
    }

    private var canAppendDigit: Bool {
        let parts = digits.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        if parts.count == 2 {
            return parts[1].count < Self.maxDecimals
        }
        return digits.count < Self.maxWholeDigits
    }

    // MARK: Meaning

    /// `nil` when empty or zero.
    var amount: Decimal? {
        let trimmed = digits.hasSuffix(".") ? String(digits.dropLast()) : digits
        guard !trimmed.isEmpty,
              let value = Decimal(string: trimmed, locale: Locale(identifier: "en_US_POSIX")),
              value > 0 else { return nil }
        return value
    }

    func isValid(categoryExists: (UUID) -> Bool) -> Bool {
        guard amount != nil,
              !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let categoryID else { return false }
        return categoryExists(categoryID)
    }

    /// Strictly after today.
    func isFuture(today: Date, calendar: Calendar) -> Bool {
        date > calendar.startOfDay(for: today)
    }

    func rule(calendar: Calendar) -> RecurrenceRule {
        RecurrenceRule(
            interval: interval,
            unit: unit,
            anchorDate: date,
            endDate: lastPaymentDate(calendar: calendar)
        )
    }

    /// The date of the final payment, from the engine, when a count is set.
    func lastPaymentDate(calendar: Calendar) -> Date? {
        guard let paymentCount else { return nil }
        let open = RecurrenceRule(interval: interval, unit: unit, anchorDate: date)
        return RecurrenceEngine.date(ofPayment: max(1, paymentCount) - 1, for: open, calendar: calendar)
    }

    // MARK: Labels

    /// "€0" when empty, "€1,250.5" mid-entry. The currency and separators are the locale's.
    func amountText(locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale

        let parts = digits.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let whole = parts.first.map(String.init) ?? ""
        let fraction = parts.count == 2 ? String(parts[1]) : ""
        formatter.minimumFractionDigits = fraction.count
        formatter.maximumFractionDigits = fraction.count
        formatter.alwaysShowsDecimalSeparator = digits.contains(".")

        let value = Decimal(string: whole.isEmpty ? "0" : whole + (fraction.isEmpty ? "" : "." + fraction),
                            locale: Locale(identifier: "en_US_POSIX")) ?? 0
        return formatter.string(from: value as NSDecimalNumber) ?? digits
    }

    /// "Oct 31", never a year.
    func dateLabel(calendar: Calendar, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter.string(from: date)
    }

    /// "Monthly", "3 months", or "05/27" once the bill ends.
    func repeatLabel(calendar: Calendar, locale: Locale) -> String {
        if let last = lastPaymentDate(calendar: calendar) {
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.timeZone = calendar.timeZone
            formatter.locale = locale
            formatter.dateFormat = "MM/yy"
            return formatter.string(from: last)
        }
        if interval == 1 {
            switch unit {
            case .day: return "Daily"
            case .week: return "Weekly"
            case .month: return "Monthly"
            case .year: return "Yearly"
            }
        }
        return "\(interval) \(unit.rawValue)s"
    }

    /// "Last payment Sep 30, 2027"; `nil` without a count.
    func lastPaymentCaption(calendar: Calendar, locale: Locale) -> String? {
        guard let last = lastPaymentDate(calendar: calendar) else { return nil }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "Last payment \(formatter.string(from: last))"
    }
}

enum EmojiInput {
    /// The last emoji character in `text`, or `nil`. A `Character` is a whole grapheme
    /// cluster, so flags, skin tones and joined sequences arrive in one piece.
    static func emoji(from text: String) -> String? {
        text.reversed().first(where: isEmoji).map(String.init)
    }

    private static func isEmoji(_ character: Character) -> Bool {
        let scalars = character.unicodeScalars
        // Emoji presentation, or an explicit variation selector, makes it an emoji outright.
        if scalars.contains(where: { $0.value == 0xFE0F || $0.properties.isEmojiPresentation }) {
            return true
        }
        // Digits, "#" and "*" carry the emoji property as keycap bases, and so do a few
        // symbols below U+238C ("©"); none of those is an emoji without a selector.
        guard let first = scalars.first else { return false }
        return first.properties.isEmoji && first.value > 0x238C
    }
}
