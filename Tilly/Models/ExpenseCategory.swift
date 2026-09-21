import Foundation
import SwiftData

/// An emoji and a name, both required by the editor and no colour. The app ships with none;
/// people make their own while adding an expense.
@Model
final class ExpenseCategory {
    var id: UUID = UUID()
    var name: String = ""
    var emoji: String = ""
    var createdAt: Date = Date()

    /// Nullify, not cascade: deleting a category must never delete the bills filed under it.
    @Relationship(deleteRule: .nullify, inverse: \Expense.category)
    var expenses: [Expense]?

    init(id: UUID = UUID(), name: String, emoji: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.createdAt = createdAt
    }
}
