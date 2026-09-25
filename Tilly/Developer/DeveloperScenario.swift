#if DEBUG
import Foundation
import SwiftData
import TillyCore

/// A state the app can be put in for testing on a phone, from the Developer section in
/// Settings. Every sample scenario seeds its own in-memory store; `yourData` is the person's
/// own store and is never seeded. Debug builds only.
enum DeveloperScenario: String, CaseIterable, Identifiable, Sendable {
    case yourData, empty, oneExpense, typicalYear, longHistory, nothingChargedYet, manyCategories

    var id: String { rawValue }

    var title: String {
        switch self {
        case .yourData: "Your data"
        case .empty: "Empty"
        case .oneExpense: "One expense"
        case .typicalYear: "Typical year"
        case .longHistory: "Long history"
        case .nothingChargedYet: "Nothing charged yet"
        case .manyCategories: "Many categories"
        }
    }

    var isSample: Bool { self != .yourData }

    /// Inserts this scenario's data and saves. `.yourData` and `.empty` insert nothing.
    func seed(into context: ModelContext, today: Date, calendar: Calendar) throws {
        switch self {
        case .yourData, .empty:
            return
        case .oneExpense:
            let subscriptions = ExpenseCategory(name: "Subscriptions", emoji: "📺", colour: .blue, sortOrder: 0)
            context.insert(subscriptions)
            context.insert(Expense(name: "Music", amount: 15, anchorDate: calendar.startOfDay(for: today), category: subscriptions))
        case .typicalYear:
            try PreviewData.insert(into: context, today: today, calendar: calendar)
        case .longHistory:
            try PreviewData.insert(into: context, today: today, calendar: calendar, historyMonths: 36)
        case .nothingChargedYet:
            let home = ExpenseCategory(name: "Home", emoji: "🏠", colour: .blue, sortOrder: 0)
            context.insert(home)
            let start = calendar.startOfDay(for: today)
            let internet = calendar.date(byAdding: .day, value: 2, to: start)!
            let water = calendar.date(byAdding: .day, value: 5, to: start)!
            context.insert(Expense(name: "Internet", amount: 30, anchorDate: internet, category: home))
            context.insert(Expense(name: "Water", amount: 45, anchorDate: water, category: home))
        case .manyCategories:
            try Self.insertManyCategories(into: context, today: today, calendar: calendar)
        }
        try context.save()
    }

    /// Fourteen categories, more than the lanes fit at their largest, and more than there are
    /// colours: the category view's hardest month. Invented bills, anchored three months back so
    /// the current month has charged and upcoming dots; one quarterly and one yearly bill leave
    /// categories quiet in some months.
    private static func insertManyCategories(into context: ModelContext, today: Date, calendar: Calendar) throws {
        let components = calendar.dateComponents([.year, .month], from: today)
        func anchor(day: Int, monthOffset: Int = -3) -> Date {
            calendar.date(from: DateComponents(year: components.year, month: (components.month ?? 1) + monthOffset, day: day))!
        }
        // (emoji, name, [(bill, amount, day, months between)])
        let plan: [(String, String, [(String, Decimal, Int, Int)])] = [
            ("🏠", "Home", [("Rent", 1150, 1, 1), ("Electricity", 68, 12, 1), ("Water", 41, 27, 2)]),
            ("🚗", "Car", [("Parking", 35, 5, 1), ("Car insurance", 640, 29, 12)]),
            ("📱", "Phone & internet", [("Broadband", 38, 15, 1), ("Phone", 22, 20, 1)]),
            ("🎬", "Subscriptions", [("Film club", 13, 8, 1), ("Music", 11, 17, 1), ("Cloud storage", 3, 26, 1)]),
            ("💪", "Health", [("Gym", 25, 10, 1), ("Dentist plan", 16, 25, 1)]),
            ("📗", "Learning", [("Language course", 90, 3, 3)]),
            ("🐶", "Pet", [("Pet insurance", 18, 3, 1), ("Vet plan", 12, 21, 1)]),
            ("🧒", "Kids", [("Swimming", 30, 6, 1), ("School trip fund", 20, 16, 1)]),
            ("💻", "Software", [("Design app", 12, 19, 1)]),
            ("🌱", "Garden", [("Seed box", 15, 23, 2)]),
            ("🎁", "Giving", [("Charity", 10, 2, 1)]),
            ("🎨", "Hobbies", [("Pottery class", 45, 14, 1)]),
            ("☕️", "Coffee", [("Coffee beans", 24, 11, 1)]),
            ("🎮", "Games", [("Game pass", 15, 4, 1)]),
        ]
        var colours: [CategoryColour] = []
        for (order, (emoji, name, bills)) in plan.enumerated() {
            let colour = CategoryOrdering.nextColour(after: colours)
            colours.append(colour)
            let category = ExpenseCategory(name: name, emoji: emoji, colour: colour, sortOrder: order)
            context.insert(category)
            for (bill, amount, day, interval) in bills {
                let yearly = interval == 12
                context.insert(Expense(
                    name: bill, amount: amount,
                    recurrenceInterval: yearly ? 1 : interval, recurrenceUnit: yearly ? .year : .month,
                    anchorDate: anchor(day: day, monthOffset: yearly ? -11 : -3), category: category
                ))
            }
        }
    }
}
#endif
