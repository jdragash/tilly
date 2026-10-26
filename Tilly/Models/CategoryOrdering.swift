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

    /// Sorts once: rewrites `sortOrder` 0..<n to the chosen order and returns the order it replaced
    /// (ids, by the old `sortOrder`), so Undo can `restore` it. Ties fall back to name, then to the
    /// order they were already in. A category with no figures counts as none.
    @discardableResult
    static func arrange(
        _ categories: [ExpenseCategory], by sort: CategorySort,
        figures: [UUID: (bills: Int, monthly: Decimal)]
    ) -> [UUID] {
        let previous = categories.sorted { ($0.sortOrder, $0.createdAt) < ($1.sortOrder, $1.createdAt) }
        let position = Dictionary(uniqueKeysWithValues: previous.enumerated().map { ($1.id, $0) })

        // Orders by `key` ascending; a larger key ties to the name, then to the previous order.
        func ordered(by key: (ExpenseCategory) -> Int) -> [ExpenseCategory] {
            previous.sorted { lhs, rhs in
                if key(lhs) != key(rhs) { return key(lhs) < key(rhs) }
                let names = lhs.name.localizedStandardCompare(rhs.name)
                if names != .orderedSame { return names == .orderedAscending }
                return position[lhs.id]! < position[rhs.id]!
            }
        }

        let arranged: [ExpenseCategory]
        switch sort {
        case .colour:
            arranged = ordered { rainbowRank($0.colour) }
        case .name:
            arranged = ordered { _ in 0 }
        case .monthlyCost:
            // Whole units, so the key is an Int; the card totals are already whole.
            arranged = ordered { -(NSDecimalNumber(decimal: figures[$0.id]?.monthly ?? 0).intValue) }
        case .billCount:
            arranged = ordered { -(figures[$0.id]?.bills ?? 0) }
        }
        renumber(arranged)
        return previous.map(\.id)
    }

    /// Puts an order from `arrange` back. Ids that no longer name a category are skipped, and
    /// categories the order doesn't mention follow it, in their current order.
    static func restore(_ categories: [ExpenseCategory], order: [UUID]) {
        let byID = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        let named = order.compactMap { byID[$0] }
        let mentioned = Set(named.map(\.id))
        let rest = categories
            .filter { !mentioned.contains($0.id) }
            .sorted { ($0.sortOrder, $0.createdAt) < ($1.sortOrder, $1.createdAt) }
        renumber(named + rest)
    }

    /// Red, orange, yellow, green, teal, blue, purple, pink; no colour last.
    private static func rainbowRank(_ colour: CategoryColour?) -> Int {
        switch colour {
        case .red: 0
        case .orange: 1
        case .yellow: 2
        case .green: 3
        case .aqua: 4
        case .blue: 5
        case .violet: 6
        case .magenta: 7
        case nil: 8
        }
    }

    private static func renumber(_ ordered: [ExpenseCategory]) {
        // Only writes what changed, so a backfill over an ordered store leaves nothing dirty.
        for (index, category) in ordered.enumerated() where category.sortOrder != index {
            category.sortOrder = index
        }
    }
}

/// How Settings can arrange the categories, once.
enum CategorySort: CaseIterable, Sendable {
    case colour, name, monthlyCost, billCount

    var title: String {
        switch self {
        case .colour: "Colour"
        case .name: "Name"
        case .monthlyCost: "Monthly cost"
        case .billCount: "Number of bills"
        }
    }

    var detail: String {
        switch self {
        case .colour: "rainbow"
        case .name: "A to Z"
        case .monthlyCost, .billCount: "most first"
        }
    }
}
