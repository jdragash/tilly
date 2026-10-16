import Foundation

/// How far the Calendar view is zoomed: the year, one month as a grid, or the days themselves,
/// which is the timeline. The app opens on the level it was left on.
enum CalendarLevel: String, Sendable {
    // The raw values are stored in `@AppStorage`: never rename them.
    case year, month, day
}
