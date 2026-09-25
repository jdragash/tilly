/// Identity only. What each one looks like lives in `Tokens.CategoryColour`.
///
/// The raw values are stored on `ExpenseCategory`; never rename a case. The declaration order
/// is the order a new category's colour is pre-picked in.
enum CategoryColour: String, CaseIterable, Identifiable, Sendable {
    case blue, orange, aqua, yellow, magenta, green, violet, red

    var id: String { rawValue }

    var name: String {
        switch self {
        case .blue: "Blue"
        case .orange: "Orange"
        case .aqua: "Aqua"
        case .yellow: "Yellow"
        case .magenta: "Pink"
        case .green: "Green"
        case .violet: "Violet"
        case .red: "Red"
        }
    }
}
