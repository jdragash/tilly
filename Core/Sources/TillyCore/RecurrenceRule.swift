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
