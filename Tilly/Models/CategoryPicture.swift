import SwiftUI

/// What draws a category: its symbol, or the emoji it was made with before symbols, or nothing
/// for data saved before categories existed.
nonisolated enum CategoryPicture: Equatable, Hashable, Sendable {
    case symbol(String)
    case emoji(String)
    case none

    /// The symbol wins when it has a name, then the emoji, else nothing.
    init(symbol: String, emoji: String) {
        let symbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        let emoji = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        if !symbol.isEmpty {
            self = .symbol(symbol)
        } else if !emoji.isEmpty {
            self = .emoji(emoji)
        } else {
            self = .none
        }
    }

    init(_ category: ExpenseCategory?) {
        guard let category else {
            self = .none
            return
        }
        self.init(symbol: category.symbol, emoji: category.emoji)
    }

    /// For a line of text: the symbol as `Image(systemName:)`, plain, or the emoji. Empty for `.none`.
    var inline: Text {
        switch self {
        case .symbol(let name): Text(Image(systemName: name))
        case .emoji(let emoji): Text(emoji)
        case .none: Text(verbatim: "")
        }
    }

    var isNone: Bool { self == .none }
}
