import SwiftData
import SwiftUI

/// Settings, opened from the gear at the bottom right. For now it only lists the categories,
/// which are made while adding an expense. See "The shell" in `docs/DESIGN.md`.
struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]
    #if DEBUG
    @Environment(DeveloperSession.self) private var session: DeveloperSession?
    #endif

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if categories.isEmpty {
                        Text("None yet.")
                            .foregroundStyle(Tokens.Ink.secondary)
                    } else {
                        ForEach(categories) { category in
                            HStack(spacing: Tokens.Space.gap) {
                                Text(category.emoji)
                                    .accessibilityHidden(true)
                                Text(category.name)
                                    .foregroundStyle(Tokens.Ink.primary)
                            }
                        }
                    }
                } header: {
                    Text("Categories")
                } footer: {
                    Text("New categories are made while adding an expense.")
                }
                #if DEBUG
                if let session { DeveloperSection(session: session) }
                #endif
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .close) { dismiss() }
                }
            }
        }
    }
}

#Preview("None yet") {
    SettingsSheet()
        .modelContainer(try! TillyStore.container(inMemory: true))
}

#Preview("Some categories") {
    let container = try! TillyStore.container(inMemory: true)
    for (emoji, name) in [("🏠", "Home"), ("📺", "Streaming"), ("💳", "Loans")] {
        container.mainContext.insert(ExpenseCategory(name: name, emoji: emoji))
    }
    try! container.mainContext.save()
    return SettingsSheet()
        .modelContainer(container)
}
