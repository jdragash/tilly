import UIKit

/// How large a category's name can be on a card: its full size while the longest word fits across
/// and the whole fits two lines, then smaller, to `Tokens.Scale.cardName` of it at least. SwiftUI
/// would rather break a long word mid-way than shrink it, and a text field can't shrink at all.
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
            let wordWidth = (longest as NSString).size(withAttributes: [.font: font]).width
            let height = (name as NSString).boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil
            ).height
            if wordWidth <= width && height <= font.lineHeight * 2 + 1 { break }
            size -= Tokens.Scale.nameFitStep
        }
        return max(size, floor)
    }

    private static func roundedBold(_ size: CGFloat) -> UIFont {
        let font = UIFont.systemFont(ofSize: size, weight: .bold)
        return font.fontDescriptor.withDesign(.rounded).map { UIFont(descriptor: $0, size: size) } ?? font
    }
}
