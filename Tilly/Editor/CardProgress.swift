import Foundation

/// The parts of the card, in the order the accessibility layout stacks them.
enum CardPart: CaseIterable, Equatable, Sendable {
    case amount, name, date, `repeat`, category
}

/// What the card still needs. Pure: built from the draft and two facts the view knows.
struct CardProgress: Equatable, Sendable {
    /// The parts that can be missing, in the order the card walks them.
    private static let required: [CardPart] = [.amount, .name, .category]

    private let amountMissing: Bool
    private let nameMissing: Bool
    private let categoryMissing: Bool
    private let isMakingCategory: Bool

    init(draft: ExpenseDraft, categoryExists: Bool, isMakingCategory: Bool) {
        let editAtZero = draft.baseline != nil && draft.isZero
        self.amountMissing = draft.amount == nil && !editAtZero
        self.nameMissing = draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        self.categoryMissing = !categoryExists
        self.isMakingCategory = isMakingCategory
    }

    /// Amount: `draft.amount == nil`, except an edit at €0 (`baseline != nil && isZero`), which is
    /// filled. Name: trimmed empty. Category: `!categoryExists`. Date and repeat: never.
    func isMissing(_ part: CardPart) -> Bool {
        switch part {
        case .amount: amountMissing
        case .name: nameMissing
        case .category: categoryMissing
        case .date, .repeat: false
        }
    }

    /// The first missing part after `part` in the order amount, name, category, wrapping round;
    /// `nil` when nothing is missing. Skips the category while one is being made. With no part,
    /// the first missing from the start. Date and repeat sit where `CardPart` places them, so
    /// after either comes the category.
    func next(after part: CardPart?) -> CardPart? {
        let start: Int
        if let part {
            let position = CardPart.allCases.firstIndex(of: part)!
            start = Self.required.firstIndex { CardPart.allCases.firstIndex(of: $0)! > position }
                ?? Self.required.count
        } else {
            start = 0
        }
        let order = Self.required[start...] + Self.required[..<start]
        return order.first(where: isOpen)
    }

    /// The part that breathes: the first missing of amount, name, category, but never the one
    /// focused, never while the amount is missing, and never the category while one is made.
    func breathing(focused: CardPart?) -> CardPart? {
        guard !amountMissing else { return nil }
        return Self.required.first { $0 != focused && isOpen($0) }
    }

    /// Missing, and not the category while one is being made.
    private func isOpen(_ part: CardPart) -> Bool {
        isMissing(part) && !(part == .category && isMakingCategory)
    }
}
