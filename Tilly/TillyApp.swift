import OSLog
import SwiftData
import SwiftUI

@main
struct TillyApp: App {
    #if DEBUG
    /// Debug builds can switch to a sample scenario from Settings. See `DeveloperSession`.
    @State private var session = DeveloperSession()
    #else
    /// nil when the store wouldn't open, and the app shows `StoreUnavailableView` instead.
    let container: ModelContainer? = {
        do {
            let container = try TillyStore.container()
            TillyApp.backfillCategories(in: container)
            return container
        } catch {
            TillyStore.logger.error("The store didn't open: \(error, privacy: .public)")
            return nil
        }
    }()
    #endif

    #if DEBUG
    init() {
        // The layout's dials: DialKit's Mac inspector in the Simulator, its drawer on a phone (shake).
        #if targetEnvironment(simulator)
        CategoryDials.shared.start()
        #else
        CategoryDrawer.shared.start()
        #endif
    }
    #endif

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if session.openFailed {
                StoreUnavailableView()
                    .fontDesign(Tokens.Text.design)
                    .drawnGround()
            } else {
                TimelineView()
                    .id(session.generation)
                    .environment(session)
                    .environment(\.timelinePlaceStore, session.placeStore)
                    .modelContainer(session.container)
                    .fontDesign(Tokens.Text.design)
                    .drawnGround()
                    // Every load swaps the store, so each one is backfilled as it arrives.
                    .onChange(of: session.generation, initial: true) {
                        TillyApp.backfillCategories(in: session.container)
                    }
            }
            #else
            if let container {
                TimelineView()
                    .modelContainer(container)
                    .fontDesign(Tokens.Text.design)
                    .drawnGround()
            } else {
                StoreUnavailableView()
                    .fontDesign(Tokens.Text.design)
                    .drawnGround()
            }
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
