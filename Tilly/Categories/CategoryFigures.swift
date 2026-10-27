import Foundation

/// What a category's card says under its name: how many bills run in it and what they cost a
/// month. Read from the same rows All bills shows, so the two always agree.
enum CategoryFigures {
    /// Every category, so one with no running bills is `(0, 0)`.
    static func figures(
        _ inputs: [BillInput],
        categories: [CategoryInfo],
        today: Date,
        calendar: Calendar
    ) -> [UUID: (bills: Int, monthly: Decimal)] {
        let all = AllBillsBuilder.bills(inputs, categories: categories, period: .month, today: today, calendar: calendar)
        var result = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, (bills: 0, monthly: Decimal(0))) })
        for card in all.cards {
            guard let id = card.category?.id else { continue }
            result[id] = (bills: card.rows.count, monthly: card.total)
        }
        return result
    }
}
