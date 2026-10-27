import SwiftData
import SwiftUI

/// Settings, opened from the gear at the bottom right. One row for now, Categories, which opens
/// them as the picker's grid of cards; more join the list as they arrive. See "The shell" in
/// `docs/DESIGN.md`.
struct SettingsSheet: View {
    /// For the categories' monthly figures.
    let today: Date

    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [ExpenseCategory]
    #if DEBUG
    @Environment(DeveloperSession.self) private var session: DeveloperSession?
    #endif

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        CategoriesPage(today: today)
                    } label: {
                        HStack(spacing: Tokens.Space.gap) {
                            Image(systemName: "square.grid.2x2.fill")
                                .font(Tokens.SettingsCategories.tileSymbol)
                                .foregroundStyle(Tokens.Ink.onProminent)
                                .frame(width: Tokens.SettingsCategories.tile, height: Tokens.SettingsCategories.tile)
                                .background(
                                    Tokens.SettingsCategories.tileColour,
                                    in: RoundedRectangle(cornerRadius: Tokens.SettingsCategories.tileRadius, style: .continuous)
                                )
                                .accessibilityHidden(true)
                            Text("Categories")
                                .foregroundStyle(Tokens.Ink.primary)
                            Spacer(minLength: 0)
                            Text(categories.count, format: .number)
                                .foregroundStyle(Tokens.Drawn.ink2)
                        }
                    }
                    .listRowBackground(Tokens.Drawn.paperCard)
                } footer: {
                    Text("More settings join this list as they arrive.")
                }
                #if DEBUG
                if let session { DeveloperSection(session: session) }
                #endif
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .close) { dismiss() }
                }
            }
        }
        .drawnGround()
    }
}

#Preview("None yet") {
    SettingsSheet(today: Date())
        .modelContainer(try! TillyStore.container(inMemory: true))
}

#Preview("Some categories") {
    let container = try! TillyStore.container(inMemory: true)
    for (order, (symbol, name, colour)) in [("house", "Home", CategoryColour.blue), ("tv", "Streaming", .orange), ("creditcard", "Loans", .aqua)].enumerated() {
        container.mainContext.insert(ExpenseCategory(name: name, symbol: symbol, colour: colour, sortOrder: order))
    }
    try! container.mainContext.save()
    return SettingsSheet(today: Date())
        .modelContainer(container)
}
