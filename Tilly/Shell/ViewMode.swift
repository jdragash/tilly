import Foundation

/// The two ways of reading the same bills, switched in place from the view button's menu. The app
/// opens on the one it was left on. See "The shell" in `docs/DESIGN.md`.
enum ViewMode: String, Sendable {
    // The raw values are stored in `@AppStorage`: never rename them.
    case timeline, categories
}
