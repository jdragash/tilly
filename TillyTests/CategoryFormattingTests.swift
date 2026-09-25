import Foundation
import Testing
@testable import Tilly

@Suite struct CategoryFormattingTests {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    static let us = Locale(identifier: "en_US")
    static let euro = Locale(identifier: "en_IE")
    static let today = date(2027, 1, 15) // a Friday

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    static func info(_ name: String, _ emoji: String) -> CategoryInfo {
        CategoryInfo(id: UUID(), emoji: emoji, name: name, colour: .blue)
    }

    static func lane(_ category: CategoryInfo?, amounts: [Decimal]) -> CategoryLane {
        let dots = amounts.enumerated().map { index, amount in
            LaneDot(
                entry: TimelineEntry(
                    id: "\(index)", expenseID: UUID(), scheduledDate: today, name: "Bill", emoji: category?.emoji,
                    date: today, amount: amount, state: .charged, endDate: nil, endHasPassed: false
                ),
                day: 15
            )
        }
        return CategoryLane(category: category, dots: dots, total: amounts.reduce(0, +))
    }

    // MARK: relativeDay

    @Test func relativeDayTomorrow() {
        let text = CategoryFormatting.relativeDay(Self.date(2027, 1, 16), today: Self.today, calendar: Self.calendar, locale: Self.us)
        #expect(text == "Tomorrow")
    }

    @Test func relativeDayNamesTheWeekdayWithinSixDays() {
        let two = CategoryFormatting.relativeDay(Self.date(2027, 1, 17), today: Self.today, calendar: Self.calendar, locale: Self.us)
        let six = CategoryFormatting.relativeDay(Self.date(2027, 1, 21), today: Self.today, calendar: Self.calendar, locale: Self.us)
        #expect(two == "Sunday")
        #expect(six == "Thursday")
    }

    @Test func relativeDayFallsBackToMonthAndDay() {
        let text = CategoryFormatting.relativeDay(Self.date(2027, 1, 22), today: Self.today, calendar: Self.calendar, locale: Self.us)
        #expect(text == "Jan 22")
    }

    // MARK: quietLine

    @Test func quietLineJoinsCategoriesWithTheirNext() {
        let quiet = [
            QuietCategory(category: Self.info("Books", "📗"), next: Self.date(2026, 11, 3)),
            QuietCategory(category: Self.info("Travel", "✈️"), next: Self.date(2027, 1, 12)),
        ]
        let line = CategoryFormatting.quietLine(quiet, month: "September", calendar: Self.calendar, locale: Self.us)
        #expect(line == "Nothing in September: 📗 next Nov 3 · ✈️ next Jan 12")
    }

    @Test func quietLineShowsAnEmojiAloneWithNoNext() {
        let quiet = [QuietCategory(category: Self.info("Books", "📗"), next: nil)]
        let line = CategoryFormatting.quietLine(quiet, month: "September", calendar: Self.calendar, locale: Self.us)
        #expect(line == "Nothing in September: 📗")
    }

    @Test func quietLineIsNilWhenNothingIsQuiet() {
        #expect(CategoryFormatting.quietLine([], month: "September", calendar: Self.calendar, locale: Self.us) == nil)
    }

    // MARK: Lane text

    @Test func focusLabelIsTheFigureWithoutItsTotal() {
        let lane = Self.lane(Self.info("Home", "🏠"), amounts: [950])
        #expect(CategoryFormatting.focusLabel(lane) == "🏠 Home")
    }

    @Test func focusFigureReadsEmojiNameAndTotal() {
        let lane = Self.lane(Self.info("Home", "🏠"), amounts: [950, 241, 68])
        #expect(CategoryFormatting.focusFigure(lane, locale: Self.euro) == "🏠 Home \u{2212}€1,259")
    }

    @Test func laneLabelCountsCharges() {
        let three = Self.lane(Self.info("Home", "🏠"), amounts: [950, 241, 68])
        let one = Self.lane(Self.info("Car", "🚗"), amounts: [120])
        #expect(CategoryFormatting.laneLabel(three, locale: Self.euro) == "Home, 1,259 euros out, 3 charges")
        #expect(CategoryFormatting.laneLabel(one, locale: Self.euro) == "Car, 120 euros out, 1 charge")
    }

    @Test func laneTextInDollars() {
        let lane = Self.lane(Self.info("Home", "🏠"), amounts: [950, 309])
        #expect(CategoryFormatting.focusFigure(lane, locale: Self.us) == "🏠 Home \u{2212}$1,259")
        #expect(CategoryFormatting.laneLabel(lane, locale: Self.us) == "Home, 1,259 US dollars out, 2 charges")
    }

    @Test func anUncategorisedLaneIsNamedNoCategory() {
        let lane = Self.lane(nil, amounts: [13])
        #expect(CategoryFormatting.focusFigure(lane, locale: Self.euro) == "No category \u{2212}€13")
        #expect(CategoryFormatting.laneLabel(lane, locale: Self.euro) == "No category, 13 euros out, 1 charge")
    }

    // MARK: readoutDate

    @Test func readoutDateReadsWeekdayDayAndMonth() {
        let date = Self.date(2026, 9, 12)
        #expect(CategoryFormatting.readoutDate(date, calendar: Self.calendar, locale: Locale(identifier: "en_GB")) == "Sat 12 Sep")
    }
}
