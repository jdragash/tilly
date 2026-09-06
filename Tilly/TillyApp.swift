import SwiftData
import SwiftUI

@main
struct TillyApp: App {
    let container: ModelContainer = {
        do {
            return try TillyStore.container()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
