import SwiftData
import SwiftUI

/// Settings, opened from the gear at the bottom right. For now it only lists the categories,
/// which are made while adding an expense, in the user's order: drag one to move it, tap its
/// colour to change it. See "The shell" in `docs/DESIGN.md`.
struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
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
                            row(for: category)
                        }
                        .onMove { source, destination in
                            CategoryOrdering.move(categories, from: source, to: destination)
                            try? modelContext.save()
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

    private func row(for category: ExpenseCategory) -> some View {
        HStack(spacing: Tokens.Space.gap) {
            Text(category.emoji)
                .accessibilityHidden(true)
            Text(category.name)
                .foregroundStyle(Tokens.Ink.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            colourMenu(for: category)
        }
    }

    private func colourMenu(for category: ExpenseCategory) -> some View {
        // Every category has a colour once the launch backfill has run; the fallback only
        // covers a store that hasn't been through it, such as a preview's.
        let colour = category.colour ?? CategoryOrdering.nextColour(after: [])
        let selection = Binding<CategoryColour>(
            get: { colour },
            set: { newValue in
                category.colour = newValue
                try? modelContext.save()
            }
        )
        return Menu {
            Picker("Colour", selection: selection) {
                ForEach(CategoryColour.allCases) { option in
                    Label {
                        Text(option.name)
                    } icon: {
                        Tokens.CategoryColour.menuSwatch(option)
                    }
                    .tag(option)
                }
            }
            .pickerStyle(.inline)
        } label: {
            Circle()
                .fill(Tokens.CategoryColour.color(colour))
                .frame(width: Tokens.Size.colourSwatch, height: Tokens.Size.colourSwatch)
                .frame(minWidth: Tokens.Size.minimumTapTarget)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Colour")
        .accessibilityValue(colour.name)
    }
}

#Preview("None yet") {
    SettingsSheet()
        .modelContainer(try! TillyStore.container(inMemory: true))
}

#Preview("Some categories") {
    let container = try! TillyStore.container(inMemory: true)
    for (order, (emoji, name, colour)) in [("🏠", "Home", CategoryColour.blue), ("📺", "Streaming", .orange), ("💳", "Loans", .aqua)].enumerated() {
        container.mainContext.insert(ExpenseCategory(name: name, emoji: emoji, colour: colour, sortOrder: order))
    }
    try! container.mainContext.save()
    return SettingsSheet()
        .modelContainer(container)
}
