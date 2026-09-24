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
            let container = try TillyStore.container()
            TillyApp.backfillCategories(in: container)
            return container
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
                // Every load swaps the store, so each one is backfilled as it arrives.
                .onChange(of: session.generation, initial: true) {
                    TillyApp.backfillCategories(in: session.container)
                }
            #else
            TimelineView()
                .modelContainer(container)
            #endif
        }
    }

    /// Gives categories saved before colour and order existed both, once, at launch.
    /// See `CategoryOrdering.backfill`.
    @MainActor
    static func backfillCategories(in container: ModelContainer) {
        let context = container.mainContext
        guard let categories = try? context.fetch(FetchDescriptor<ExpenseCategory>()) else { return }
        CategoryOrdering.backfill(categories)
        if context.hasChanges { try? context.save() }
    }
}
