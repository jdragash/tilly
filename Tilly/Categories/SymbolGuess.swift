import Foundation
import NaturalLanguage

/// Guesses a catalogue symbol from a category's name: first by plain words, then by how close the
/// words are in meaning, using the word model that ships with the system.
enum SymbolGuess {
    /// What a category wears when nothing matches.
    static let fallback = "tag"

    /// A catalogue symbol for `name`, or nil. Keywords first, then word similarity.
    static func guess(for name: String) -> String? {
        let words = words(in: name)
        guard !words.isEmpty else { return nil }
        if let hit = keywordMatch(words) { return hit }
        return similarMatch(words)
    }

    /// Up to `limit` symbols close to `query`, for a search with no matches.
    static func closest(to query: String, limit: Int) -> [String] {
        let words = words(in: query)
        guard !words.isEmpty, limit > 0, let embedding else { return [] }
        var best: [String: Double] = [:]
        for word in words where embedding.contains(word) {
            for (candidate, symbol) in vocabulary {
                let distance = embedding.distance(between: word, and: candidate)
                guard distance <= Tokens.Guess.maxDistance else { continue }
                best[symbol] = min(best[symbol] ?? .infinity, distance)
            }
        }
        return best.sorted { $0.value < $1.value }.prefix(limit).map(\.key)
    }

    // MARK: Keywords

    /// Services people name categories after, and the symbol each wears. A term of several words
    /// matches when the name holds those words side by side.
    private static let brands: [(symbol: String, terms: [String])] = [
        ("tv", ["netflix", "disney", "hbo", "prime video", "hulu", "apple tv", "paramount", "now tv",
                "crunchyroll", "youtube", "dazn", "sky"]),
        ("music.note", ["spotify", "apple music", "tidal", "deezer", "soundcloud"]),
        ("icloud", ["icloud", "dropbox", "google one", "onedrive", "adobe", "notion", "github", "vpn",
                    "1password"]),
        ("gamecontroller", ["twitch", "roblox", "game pass", "ps plus"]),
        ("book", ["audible", "kindle", "duolingo", "udemy", "coursera", "masterclass"]),
        ("fork.knife", ["deliveroo", "uber eats", "hellofresh", "just eat", "doordash"]),
        ("dumbbell", ["peloton", "strava", "classpass"]),
        ("car", ["uber", "lyft"]),
    ]

    private static func keywordMatch(_ words: [String]) -> String? {
        let joined = " " + words.joined(separator: " ") + " "
        for word in words {
            if let entry = SymbolCatalog.all.first(where: { SymbolCatalog.candidateWords($0).contains(word) }) {
                return entry.name
            }
            if let brand = brands.first(where: { $0.terms.contains { term in
                term.contains(" ") ? joined.contains(" \(term) ") : term == word
            } }) {
                return brand.symbol
            }
        }
        return nil
    }

    // MARK: Similarity

    private static func similarMatch(_ words: [String]) -> String? {
        guard let embedding else { return nil }
        var best: (symbol: String, distance: Double)?
        for word in words where embedding.contains(word) {
            for (candidate, symbol) in vocabulary {
                let distance = embedding.distance(between: word, and: candidate)
                if distance < Tokens.Guess.maxDistance, distance < (best?.distance ?? .infinity) {
                    best = (symbol, distance)
                }
            }
        }
        return best?.symbol
    }

    /// Loaded once; nil when the system has no English word model.
    private static let embedding = NLEmbedding.wordEmbedding(for: .english)

    /// Each catalogue word the model knows, with the symbol it belongs to; first symbol wins a word.
    private static let vocabulary: [(word: String, symbol: String)] = {
        guard let embedding else { return [] }
        var seen = Set<String>()
        var pairs: [(String, String)] = []
        for entry in SymbolCatalog.all {
            for word in SymbolCatalog.candidateWords(entry) where word.count >= 3 && embedding.contains(word) {
                if seen.insert(word).inserted { pairs.append((word, entry.name)) }
            }
        }
        return pairs
    }()

    // MARK: Text

    private static func words(in text: String) -> [String] {
        SymbolCatalog.fold(text).split { !$0.isLetter && !$0.isNumber }.map(String.init)
    }
}
