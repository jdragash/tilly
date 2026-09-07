import Testing
@testable import Tilly

@Suite struct TimelineRangeTests {
    static let anchor = MonthKey(year: 2027, month: 6)

    @Test func aNewRangeHoldsOnlyItsAnchor() {
        let range = ExpandedRange(anchor: Self.anchor)
        #expect(range.months == [Self.anchor])
    }

    @Test func theBarsSitOneMonthEitherSideOfTheRange() {
        let range = ExpandedRange(anchor: Self.anchor)
        #expect(range.barAbove == Self.anchor.advanced(by: 1))
        #expect(range.barBelow == Self.anchor.advanced(by: -1))
    }

    @Test func openingAboveAddsTheLaterMonth() {
        var range = ExpandedRange(anchor: Self.anchor)
        range.openAbove()
        #expect(range.months == [Self.anchor.advanced(by: 1), Self.anchor])
    }

    @Test func openingBelowAddsTheEarlierMonth() {
        var range = ExpandedRange(anchor: Self.anchor)
        range.openBelow()
        #expect(range.months == [Self.anchor, Self.anchor.advanced(by: -1)])
    }

    @Test func aThirdMonthOpenedAboveDropsTheEarliestOne() {
        var range = ExpandedRange(anchor: Self.anchor)
        range.openAbove()
        range.openAbove()
        #expect(range.months.count == 2)
        #expect(range.barBelow == Self.anchor)
    }

    @Test func aThirdMonthOpenedBelowDropsTheLatestOne() {
        var range = ExpandedRange(anchor: Self.anchor)
        range.openBelow()
        range.openBelow()
        #expect(range.months.count == 2)
        #expect(range.barAbove == Self.anchor)
    }

    @Test func openingAcrossADecemberBoundaryLandsInJanuary() {
        var range = ExpandedRange(anchor: MonthKey(year: 2027, month: 12))
        range.openAbove()
        #expect(range.months.contains(MonthKey(year: 2028, month: 1)))
    }

    @Test func includingTheCurrentMonthExtendsUpwardAndStaysWithinTheCap() {
        var range = ExpandedRange(anchor: Self.anchor)
        range.openBelow()
        let newCurrent = Self.anchor.advanced(by: 2)
        range.includeCurrentMonth(newCurrent)
        #expect(range.months.count == 2)
        #expect(range.months.first == newCurrent)
    }

    @Test func theCapEngagesAcrossAYearBoundary() {
        var range = ExpandedRange(anchor: MonthKey(year: 2026, month: 12))
        range.openAbove()
        range.openAbove()
        #expect(range.months.count == 2)
        #expect(range.months == [MonthKey(year: 2027, month: 2), MonthKey(year: 2027, month: 1)])
        #expect(range.barBelow == MonthKey(year: 2026, month: 12))
    }

    @Test func includingAMonthNotAfterHighIsANoOp() {
        var range = ExpandedRange(anchor: Self.anchor)
        let before = range
        range.includeCurrentMonth(Self.anchor)
        #expect(range == before)
        range.includeCurrentMonth(Self.anchor.advanced(by: -1))
        #expect(range == before)
    }

    @Test func includingTheCurrentMonthWithAGapStillCapsToTwo() {
        var range = ExpandedRange(anchor: Self.anchor)
        let farFuture = Self.anchor.advanced(by: 5)
        range.includeCurrentMonth(farFuture)
        #expect(range.months.count == 2)
        #expect(range.months == [farFuture, farFuture.advanced(by: -1)])
    }

    @Test func monthsIsContiguousAndDescending() {
        var range = ExpandedRange(anchor: Self.anchor)
        range.openBelow()
        let months = range.months
        #expect(months == months.sorted(by: >))
        for (later, earlier) in zip(months, months.dropFirst()) {
            #expect(later.advanced(by: -1) == earlier)
        }
    }
}
