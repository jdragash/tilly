import Foundation

/// What one pocket on the editor's card shows: its category and the bills peeking out of it.
struct PocketContent: Identifiable, Equatable {
    let id: UUID                 // the category's
    let emoji: String
    let name: String
    let colour: CategoryColour?
    let peeking: [String]        // up to three bill names, the one in front last
}

enum PocketContents {
    static let maxPeeking = 3

    /// One per category, in `sortOrder`. A bill is a series (`seriesKey`), read from its record
    /// with the latest anchor, and counts while that record has no `endDate` or ends on or after
    /// `today`. The latest anchor goes in front. `excluding` drops the series being edited.
    static func make(
        categories: [ExpenseCategory],
        expenses: [Expense],
        excluding seriesKey: UUID?,
        today: Date,
        calendar: Calendar
    ) -> [PocketContent] {
        let startOfToday = calendar.startOfDay(for: today)

        // The latest record of each series stands for the bill.
        var latest: [UUID: Expense] = [:]
        for expense in expenses where !expense.isArchived && expense.seriesKey != seriesKey {
            if let current = latest[expense.seriesKey], current.anchorDate >= expense.anchorDate { continue }
            latest[expense.seriesKey] = expense
        }

        var byCategory: [UUID: [Expense]] = [:]
        for bill in latest.values {
            guard let category = bill.category else { continue }
            if let end = bill.endDate, calendar.startOfDay(for: end) < startOfToday { continue }
            byCategory[category.id, default: []].append(bill)
        }

        return categories.sorted { $0.sortOrder < $1.sortOrder }.map { category in
            let names = (byCategory[category.id] ?? [])
                .sorted { $0.anchorDate < $1.anchorDate }
                .suffix(maxPeeking)
                .map(\.name)
            return PocketContent(
                id: category.id, emoji: category.emoji, name: category.name,
                colour: category.colour, peeking: Array(names)
            )
        }
    }
}
