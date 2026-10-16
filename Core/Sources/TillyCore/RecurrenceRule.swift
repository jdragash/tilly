import Foundation

/// Every `interval` `unit`s from `anchorDate` — see `docs/DECISIONS.md` for why
/// generation is anchored rather than incremental.
public struct RecurrenceRule: Equatable, Sendable, Codable {
    public let interval: Int
    public let unit: RecurrenceUnit
    public let anchorDate: Date
    public let endDate: Date?

    public init(interval: Int, unit: RecurrenceUnit, anchorDate: Date, endDate: Date? = nil) {
        self.interval = max(1, interval)
        self.unit = unit
        self.anchorDate = anchorDate
        self.endDate = endDate
    }

    private enum CodingKeys: String, CodingKey {
        case interval, unit, anchorDate, endDate
    }

    /// Written out by hand so decoding routes through `init` and inherits the clamp.
    /// Synthesized `Decodable` writes stored properties directly, which would let a
    /// persisted or migrated rule arrive with `interval` 0 and hang the engine.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            interval: try container.decode(Int.self, forKey: .interval),
            unit: try container.decode(RecurrenceUnit.self, forKey: .unit),
            anchorDate: try container.decode(Date.self, forKey: .anchorDate),
            endDate: try container.decodeIfPresent(Date.self, forKey: .endDate)
        )
    }
}

extension RecurrenceRule {
    /// True when every calendar month holds at least one charge while the rule runs: every 1–28
    /// days, every 1–4 weeks, or every month. Every N months for N ≥ 2, and every year, are
    /// extras. Ignores `endDate`: this describes the rhythm, not the span.
    public var chargesEveryMonth: Bool {
        switch unit {
        case .day: interval <= 28
        case .week: interval <= 4
        case .month: interval == 1
        case .year: false
        }
    }

    /// Charges in a year at this rhythm: 12/N for months, 1/N for years, 52/N for weeks,
    /// 365/N for days. A fixed count, not a calendar walk: All bills normalises a rhythm, it
    /// doesn't count a particular year.
    public var paymentsPerYear: Decimal {
        let perYear: Int
        switch unit {
        case .day: perYear = 365
        case .week: perYear = 52
        case .month: perYear = 12
        case .year: perYear = 1
        }
        return Decimal(perYear) / Decimal(interval)
    }
}
