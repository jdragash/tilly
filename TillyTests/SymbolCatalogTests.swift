import Testing
import UIKit
@testable import Tilly

@Suite struct SymbolCatalogTests {
    @Test func everyNameResolves() {
        let missing = SymbolCatalog.all.map(\.name).filter { UIImage(systemName: $0) == nil }
        #expect(missing.isEmpty, "Not SF Symbols on this OS: \(missing)")
    }

    @Test func noDuplicateNames() {
        let names = SymbolCatalog.all.map(\.name)
        let duplicates = Dictionary(grouping: names, by: { $0 }).filter { $0.value.count > 1 }.keys.sorted()
        #expect(duplicates.isEmpty, "Twice: \(duplicates)")
    }

    @Test func countWithinBounds() {
        #expect((250...400).contains(SymbolCatalog.all.count), "\(SymbolCatalog.all.count) symbols")
    }

    @Test func sectionsAreInOrder() {
        #expect(SymbolCatalog.sections.map(\.title) == [
            "Home", "Utilities", "Transport", "Phone & internet", "Subscriptions & media", "Health",
            "Insurance & money", "Learning & work", "Family & pets", "Shopping", "Travel", "Giving", "Other",
        ])
    }

    @Test func noFillVariants() {
        #expect(SymbolCatalog.all.filter { $0.name.hasSuffix(".fill") }.isEmpty)
    }

    @Test func blankQueryReturnsAll() {
        #expect(SymbolCatalog.search("").count == SymbolCatalog.all.count)
        #expect(SymbolCatalog.search("   ").count == SymbolCatalog.all.count)
    }

    @Test func searchIsCaseAndDiacriticInsensitive() {
        #expect(SymbolCatalog.search("CAFÉ").contains { $0.name == "cup.and.saucer" })
        #expect(SymbolCatalog.search("cafe").contains { $0.name == "cup.and.saucer" })
    }

    @Test func searchMatchesNameComponents() {
        #expect(SymbolCatalog.search("car").contains { $0.name == "car" })
    }

    @Test func searchMatchesWords() {
        #expect(SymbolCatalog.search("rent").contains { $0.name == "house" })
    }

    @Test func everyWordMustMatch() {
        let water = SymbolCatalog.search("water")
        let waterBill = SymbolCatalog.search("water bill")
        #expect(!waterBill.isEmpty)
        #expect(waterBill.count < water.count)
    }

    @Test func unknownQueryIsEmpty() {
        #expect(SymbolCatalog.search("zzzzqx").isEmpty)
    }
}
