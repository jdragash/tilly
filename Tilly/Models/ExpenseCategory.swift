import Foundation
import SwiftData

/// A picture (a symbol, or the emoji it was made with), a name and a colour, and a place in the user's order. The app ships with none;
/// people make their own while adding an expense. `CategoryOrdering` sets the colour and order
/// of any saved before either existed.
@Model
final class ExpenseCategory {
    var id: UUID = UUID()
    var name: String = ""
    var emoji: String = ""
    /// An SF Symbol name; "" until one is picked. Defaulted, so the store needs no migration.
    var symbol: String = ""
    var createdAt: Date = Date()
    /// A `CategoryColour` raw value; "" until backfilled.
    var colourRaw: String = ""
    var sortOrder: Int = 0

    /// Nullify, not cascade: deleting a category must never delete the bills filed under it.
    @Relationship(deleteRule: .nullify, inverse: \Expense.category)
    var expenses: [Expense]?

    /// nil when `colourRaw` doesn't name a case.
    var colour: CategoryColour? {
        get { CategoryColour(rawValue: colourRaw) }
        set { colourRaw = newValue?.rawValue ?? "" }
    }

    init(id: UUID = UUID(), name: String, emoji: String = "", symbol: String = "", colour: CategoryColour? = nil,
         sortOrder: Int = 0, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.symbol = symbol
        self.colourRaw = colour?.rawValue ?? ""
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}
