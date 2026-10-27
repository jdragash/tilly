import UIKit

/// How large a category's name can be on a card: its full size while the longest word fits across
/// and the whole fits two lines, then smaller, to `Tokens.Scale.cardName` of it at least. A word
/// still too wide there keeps shrinking until it fits across, to `Tokens.Scale.cardNameWord`, so
/// `Subscriptions` stays whole. SwiftUI would rather break a long word mid-way than shrink it, and
/// a text field can't shrink at all.
enum NameFit {
    /// Measured in the app's rounded bold face, as both cards draw a name.
    static func size(_ name: String, full: CGFloat, width: CGFloat) -> CGFloat {
        let floor = full * Tokens.Scale.cardName
        guard width > 0 else { return full }
        let words: [String] = name.components(separatedBy: .whitespacesAndNewlines)
        let longest = words.max { $0.count < $1.count } ?? name
        var size = full
        while size > floor {
            let font = roundedBold(size)
            let height = (name as NSString).boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil
            ).height
            if wordWidth(longest, size) <= width && height <= font.lineHeight * 2 + 1 { break }
            size -= Tokens.Scale.nameFitStep
        }
        size = max(size, floor)
        // Past the floor only the longest word counts: the rest may be cut, a word may not break.
        let wordFloor = full * Tokens.Scale.cardNameWord
        while size > wordFloor && wordWidth(longest, size) > width {
            size -= Tokens.Scale.nameFitStep
        }
        return max(size, wordFloor)
    }

    private static func wordWidth(_ word: String, _ size: CGFloat) -> CGFloat {
        (word as NSString).size(withAttributes: [.font: roundedBold(size)]).width
    }

    private static func roundedBold(_ size: CGFloat) -> UIFont {
        let font = UIFont.systemFont(ofSize: size, weight: .bold)
        return font.fontDescriptor.withDesign(.rounded).map { UIFont(descriptor: $0, size: size) } ?? font
    }
}
