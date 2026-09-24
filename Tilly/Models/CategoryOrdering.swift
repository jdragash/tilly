import Foundation

/// The order categories appear in and the colour each one carries, both the user's to set.
/// See "Every expense has a category, and a category is an emoji, a name and a colour" in
/// `docs/DECISIONS.md`.
enum CategoryOrdering {
    /// The first colour in `CategoryColour.allCases` order not in `used`; once all eight are
    /// used, the least-used, ties to the earlier case.
    static func nextColour(after used: [CategoryColour]) -> CategoryColour {
        let counts = Dictionary(used.map { ($0, 1) }, uniquingKeysWith: +)
        // `min(by:)` keeps the first of equal elements, so a tie goes to the earlier case.
        return CategoryColour.allCases.min { counts[$0, default: 0] < counts[$1, default: 0] }!
    }

    /// One past the largest; 0 when there are none.
    static func nextSortOrder(after existing: [Int]) -> Int {
        (existing.max() ?? -1) + 1
    }

    /// Renumbers `sortOrder` 0..<n by (sortOrder, createdAt, name), which orders a freshly migrated
    /// store (all 0) by creation; then gives each category without a colour `nextColour(after:)`
    /// the colours already held, in that order. Idempotent.
    static func backfill(_ categories: [ExpenseCategory]) {
        let ordered = categories.sorted {
            ($0.sortOrder, $0.createdAt, $0.name) < ($1.sortOrder, $1.createdAt, $1.name)
        }
        renumber(ordered)

        var held = ordered.compactMap(\.colour)
        for category in ordered where category.colour == nil {
            let colour = nextColour(after: held)
            category.colour = colour
            held.append(colour)
        }
    }

    /// Applies a List move and renumbers 0..<n. `categories` is in their current order.
    static func move(_ categories: [ExpenseCategory], from source: IndexSet, to destination: Int) {
        // What `move(fromOffsets:toOffset:)` does, without importing SwiftUI into the model layer.
        let moving = source.map { categories[$0] }
        var reordered = categories.enumerated().filter { !source.contains($0.offset) }.map(\.element)
        let insertAt = destination - source.count(in: 0..<destination)
        reordered.insert(contentsOf: moving, at: insertAt)
        renumber(reordered)
    }

    private static func renumber(_ ordered: [ExpenseCategory]) {
        // Only writes what changed, so a backfill over an ordered store leaves nothing dirty.
        for (index, category) in ordered.enumerated() where category.sortOrder != index {
            category.sortOrder = index
        }
    }
}
