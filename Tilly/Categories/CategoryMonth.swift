import Foundation

/// A category reduced to what the category view needs, so the builder is pure and tested
/// without SwiftData.
struct CategoryInfo: Equatable, Sendable {
    let id: UUID
    let emoji: String
    let name: String
    let colour: CategoryColour?
}

/// One charge in a lane, on its day of the month.
struct LaneDot: Identifiable, Equatable, Sendable {
    let entry: TimelineEntry
    var id: String { entry.id }
    var day: Int
}

/// One category's charges across a month. See "The category view" in `docs/DESIGN.md`.
struct CategoryLane: Identifiable, Equatable, Sendable {
    /// nil: charges saved before categories existed.
    let category: CategoryInfo?
    /// By day ascending, a day's by amount descending.
    let dots: [LaneDot]
    /// The sum of its dots' amounts. Skipped charges are never dots.
    let total: Decimal
    var id: String { category?.id.uuidString ?? "uncategorised" }
}

/// A category with bills but nothing this month, and when it next charges.
struct QuietCategory: Equatable, Sendable {
    let category: CategoryInfo
    /// nil when every bill in it has ended.
    let next: Date?
}

struct NextCharge: Identifiable, Equatable, Sendable {
    let entry: TimelineEntry
    let category: CategoryInfo?
    var id: String { entry.id }
}

struct CategoryMonth: Equatable, Sendable {
    /// The timeline's own month, which the header reads.
    let section: MonthSection
    /// Categories with a charge this month, in the Settings order; uncategorised last.
    let lanes: [CategoryLane]
    /// Categories with bills but none this month, in the Settings order.
    let quiet: [QuietCategory]
    /// The current month only: the three soonest charges after today, at most one per category.
    let next: [NextCharge]
    /// The largest amount any bill's rule or override has ever set: the same for every month, so
    /// paging never resizes a dot.
    let dotScale: Decimal
}
