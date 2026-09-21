import SwiftData
import SwiftUI

/// The category panel: every category as an emoji and a name, then `New category` last. Tapping
/// a row selects it, and tapping the selected one keeps it selected. See "Pickers open where
/// the keypad was" in `docs/DESIGN.md`.
struct CategoryPicker: View {
    @Binding var selection: UUID?
    let onNew: () -> Void

    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(categories) { category in
                    row(for: category)
                }
                newRow
            }
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func row(for category: ExpenseCategory) -> some View {
        let isSelected = category.id == selection
        return Button {
            selection = category.id
        } label: {
            HStack(spacing: Tokens.Space.gap) {
                Text(category.emoji)
                    .font(Tokens.Text.rowEmoji)
                    .accessibilityHidden(true)
                Text(category.name)
                    .font(Tokens.Text.name)
                    .foregroundStyle(Tokens.Ink.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Tokens.Ink.accent)
                        .accessibilityHidden(true)
                }
            }
            .frame(minHeight: Tokens.Size.categoryRow)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var newRow: some View {
        Button(action: onNew) {
            HStack(spacing: Tokens.Space.gap) {
                Image(systemName: "plus")
                    .font(Tokens.Text.rowEmoji)
                    .frame(minWidth: Tokens.Size.emojiSlot / 2)
                    .accessibilityHidden(true)
                Text("New category")
                    .font(Tokens.Text.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundStyle(Tokens.Ink.accent)
            .frame(minHeight: Tokens.Size.categoryRow)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("Categories") {
    let container = try! TillyStore.container(inMemory: true)
    let home = ExpenseCategory(name: "Home", emoji: "🏠")
    container.mainContext.insert(home)
    container.mainContext.insert(ExpenseCategory(name: "Subscriptions", emoji: "📺"))
    container.mainContext.insert(ExpenseCategory(name: "Car", emoji: "🚗"))
    return CategoryPicker(selection: .constant(home.id), onNew: {})
        .frame(height: Tokens.Size.editorPanel)
        .padding(.horizontal, Tokens.Space.gutter)
        .modelContainer(container)
}

#Preview("None yet") {
    CategoryPicker(selection: .constant(nil), onNew: {})
        .frame(height: Tokens.Size.editorPanel)
        .padding(.horizontal, Tokens.Space.gutter)
        .modelContainer(try! TillyStore.container(inMemory: true))
}
