import Foundation

/// The two ways of reading the same bills, switched in place from the view button's menu. The app
/// opens on the one it was left on. See "The shell" in `docs/DESIGN.md`.
enum ViewMode: String, CaseIterable, Identifiable, Sendable {
    // The raw values are stored in `@AppStorage`: never rename them.
    case timeline, categories

    /// What the app opens on before a view has ever been chosen.
    static let firstRun: ViewMode = .timeline

    var id: String { rawValue }

    var title: String {
        switch self {
        case .timeline: "Timeline"
        case .categories: "Categories"
        }
    }

    var systemImage: String {
        switch self {
        case .timeline: "list.bullet"
        case .categories: "chart.dots.scatter"
        }
    }
}
