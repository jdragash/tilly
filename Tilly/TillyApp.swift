import SwiftData
import SwiftUI
import os

@main
struct TillyApp: App {
    let container: ModelContainer = {
        do {
            return try TillyStore.container()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    init() {
        do {
            try SampleData.seedIfNeeded(into: container.mainContext)
        } catch {
            Logger(subsystem: "com.jdragash.Tilly", category: "SampleData").error("Seeding failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
