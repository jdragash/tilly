import Foundation

/// The unit a recurrence interval is measured in.
///
/// A rule is always "every `interval` `unit`s from `anchorDate`" — see
/// `docs/DECISIONS.md` for why generation is anchored rather than incremental.
public enum RecurrenceUnit: String, Codable, Sendable, CaseIterable {
    case day, week, month, year
}
