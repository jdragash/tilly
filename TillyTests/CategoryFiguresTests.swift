import Foundation
import Testing
import TillyCore
@testable import Tilly

@Suite struct CategoryFiguresTests {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    static let today = date(2027, 1, 15)

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    static func category(_ name: String) -> CategoryInfo {
        CategoryInfo(id: UUID(), picture: .emoji("🏠"), name: name, colour: nil)
    }

    static func input(
        _ name: String, amount: Decimal, every unit: RecurrenceUnit = .month,
        endDate: Date? = nil, category: CategoryInfo?
    ) -> BillInput {
        let id = UUID()
        let rule = RecurrenceRule(interval: 1, unit: unit, anchorDate: date(2026, 6, 10), endDate: endDate)
        return BillInput(
            seriesKey: UUID(), expenseID: id, name: name, categoryID: category?.id,
            snapshot: ExpenseSnapshot(id: id, amount: amount, isEstimate: false, rule: rule, isArchived: false),
            overrides: []
        )
    }

    static func figures(_ inputs: [BillInput], _ categories: [CategoryInfo]) -> [UUID: (bills: Int, monthly: Decimal)] {
        CategoryFigures.figures(inputs, categories: categories, today: today, calendar: calendar)
    }

    @Test func figuresCountRunningBillsOnly() {
        let home = Self.category("Home")
        let empty = Self.category("Empty")
        let inputs = [
            Self.input("Rent", amount: 100, category: home),
            Self.input("Water", amount: 20, category: home),
            Self.input("Old", amount: 50, endDate: Self.date(2026, 12, 1), category: home),
        ]
        let result = Self.figures(inputs, [home, empty])
        #expect(result[home.id]?.bills == 2)
        #expect(result[home.id]?.monthly == 120)
        #expect(result[empty.id]?.bills == 0)
        #expect(result[empty.id]?.monthly == 0)
    }

    @Test func figuresAreMonthlyShares() {
        let home = Self.category("Home")
        // 1,200 a year is 100 a month; 10 a week is 520 a year, 43 a month once rounded.
        let inputs = [
            Self.input("Insurance", amount: 1_200, every: .year, category: home),
            Self.input("Coffee", amount: 10, every: .week, category: home),
        ]
        let result = Self.figures(inputs, [home])
        #expect(result[home.id]?.bills == 2)
        #expect(result[home.id]?.monthly == 143)
    }
}
