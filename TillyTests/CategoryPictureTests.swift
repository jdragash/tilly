import Testing
@testable import Tilly

@Suite struct CategoryPictureTests {
    @Test func symbolWinsOverEmoji() {
        #expect(CategoryPicture(symbol: "house", emoji: "🏠") == .symbol("house"))
    }

    @Test func emojiWhenNoSymbol() {
        #expect(CategoryPicture(symbol: "", emoji: "🏠") == .emoji("🏠"))
    }

    @Test func noneWhenBothEmpty() {
        #expect(CategoryPicture(symbol: "", emoji: "") == .none)
    }

    @Test func nilCategoryIsNone() {
        #expect(CategoryPicture(nil) == .none)
    }

    @Test func whitespaceSymbolIsNone() {
        #expect(CategoryPicture(symbol: "  ", emoji: "") == .none)
    }

    @Test func aCategoryReadsItsSymbolFirst() {
        let category = ExpenseCategory(name: "Home", emoji: "🏠", symbol: "house")
        #expect(CategoryPicture(category) == .symbol("house"))
    }
}
