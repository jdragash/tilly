import NaturalLanguage
import Testing
@testable import Tilly

@Suite struct SymbolGuessTests {
    @Test func netflixIsTV() {
        #expect(SymbolGuess.guess(for: "Netflix") == "tv")
    }

    @Test func electricityIsBolt() {
        #expect(SymbolGuess.guess(for: "Electricity") == "bolt")
    }

    @Test func rentIsHouse() {
        #expect(SymbolGuess.guess(for: "Rent") == "house")
    }

    @Test func emptyIsNil() {
        #expect(SymbolGuess.guess(for: "") == nil)
        #expect(SymbolGuess.guess(for: "   ") == nil)
    }

    @Test func gibberishIsNil() {
        #expect(SymbolGuess.guess(for: "zzzzqx") == nil)
    }

    @Test func caseAndAccentsFold() {
        #expect(SymbolGuess.guess(for: "NETFLIX") == "tv")
        #expect(SymbolGuess.guess(for: "Café") == SymbolGuess.guess(for: "cafe"))
        #expect(SymbolGuess.guess(for: "Café") != nil)
    }

    @Test(.enabled(if: NLEmbedding.wordEmbedding(for: .english) != nil))
    func rugbyIsSport() {
        let sport: Set = ["figure.tennis", "figure.golf", "sportscourt", "soccerball", "basketball", "tennisball",
                          "figure.run", "dumbbell", "figure.strengthtraining.traditional"]
        let symbol = SymbolGuess.guess(for: "Rugby")
        #expect(symbol.map(sport.contains) == true, "Rugby guessed \(symbol ?? "nil")")
    }
}
