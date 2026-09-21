import SwiftData
import SwiftUI

@main
struct TillyApp: App {
    #if DEBUG
    /// Debug builds can switch to a sample scenario from Settings. See `DeveloperSession`.
    @State private var session = DeveloperSession()
    #else
    let container: ModelContainer = {
        do {
            return try TillyStore.container()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
    #endif

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            TimelineView()
                .id(session.generation)
                .environment(session)
                .environment(\.timelinePlaceStore, session.placeStore)
                .modelContainer(session.container)
            #else
            TimelineView()
                .modelContainer(container)
            #endif
        }
    }
}
