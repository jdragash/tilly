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
}
