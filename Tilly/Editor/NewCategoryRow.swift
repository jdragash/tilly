import SwiftUI

/// Where the panel is while a category is being made: a picture slot beside a name field, the eight
/// colours under them, and Tilly's symbols in the keypad's place. Choosing a symbol fills the slot
/// and moves focus to the name, which brings its keyboard up over the symbols; Return creates the
/// category, needing both. With no symbol, Return brings the symbols back. The category button,
/// still shown above, is the way back without creating (`onCancel`), and VoiceOver's escape
/// gesture does the same.
///
/// The next unused colour is already chosen.
struct NewCategoryRow: View {
    /// For the pre-picked colour and the new category's place, last.
    let existing: [ExpenseCategory]
    let onCreate: (ExpenseCategory) -> Void
    let onCancel: () -> Void

    @State private var symbol: String?
    @State private var name = ""
    @State private var colour: CategoryColour
    @FocusState private var nameFocused: Bool

    init(existing: [ExpenseCategory], onCreate: @escaping (ExpenseCategory) -> Void, onCancel: @escaping () -> Void) {
        self.existing = existing
        self.onCreate = onCreate
        self.onCancel = onCancel
        _colour = State(initialValue: CategoryOrdering.nextColour(after: existing.compactMap(\.colour)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.tight) {
            HStack(spacing: Tokens.Space.gap) {
                slot
                TextField("Name", text: $name)
                    .font(Tokens.Text.body)
                    .focused($nameFocused)
                    .submitLabel(.done)
                    .onSubmit(submit)
                    .padding(.horizontal, Tokens.Space.section)
                    .frame(height: Tokens.Size.categoryField)
                    .background(Tokens.Surface.editorButtonActive, in: Capsule())
            }
            swatches
            if !nameFocused {
                SymbolPicker(colour: colour, selection: symbol, onPick: { symbol = $0 })
                    .frame(height: Tokens.Size.symbolPicker)
            }
        }
        .onChange(of: symbol) { _, chosen in
            if chosen != nil { nameFocused = true }
        }
        .accessibilityAction(.escape, onCancel)
    }

    private var slot: some View {
        Button { nameFocused = false } label: {
            ZStack {
                if let symbol {
                    CategoryPictureView(picture: .symbol(symbol), colour: colour, size: Tokens.Size.emojiSlot)
                } else {
                    RoundedRectangle(cornerRadius: Tokens.Size.emojiSlot * Tokens.Drawn.wellRadius, style: .continuous)
                        .strokeBorder(Tokens.Ink.tertiary, style: Tokens.Stroke.emojiSlot)
                    Image(systemName: "square.grid.2x2")
                        .font(Tokens.Text.rowEmoji)
                        .foregroundStyle(Tokens.Ink.tertiary)
                }
            }
            .frame(width: Tokens.Size.emojiSlot, height: Tokens.Size.emojiSlot)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Symbol")
        .accessibilityValue(symbol.flatMap { name in SymbolCatalog.all.first { $0.name == name }?.words.first?.capitalized } ?? "None chosen")
        .accessibilityHint("Shows the symbols")
    }

    private var swatches: some View {
        HStack(spacing: Tokens.Space.tight) {
            ForEach(CategoryColour.allCases) { option in
                let isChosen = option == colour
                Button {
                    colour = option
                } label: {
                    Circle()
                        .fill(Tokens.CategoryColour.color(option))
                        .frame(width: Tokens.Size.colourSwatch, height: Tokens.Size.colourSwatch)
                        .padding(Tokens.Size.swatchRingGap)
                        .overlay {
                            if isChosen {
                                Circle().strokeBorder(Tokens.CategoryColour.color(option), lineWidth: Tokens.Stroke.swatchRing)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.name)
                .accessibilityAddTraits(isChosen ? .isSelected : [])
            }
        }
    }

    private func submit() {
        // A text field drops its focus after `onSubmit`; with no symbol yet, that brings the
        // symbols back, which is what's missing.
        guard let symbol else {
            Task { @MainActor in nameFocused = false }
            return
        }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            Task { @MainActor in nameFocused = true }
            return
        }
        onCreate(ExpenseCategory(
            name: trimmed,
            symbol: symbol,
            colour: colour,
            sortOrder: CategoryOrdering.nextSortOrder(after: existing.map(\.sortOrder))
        ))
    }
}

#Preview {
    NewCategoryRow(existing: [], onCreate: { _ in }, onCancel: {})
        .padding(.horizontal, Tokens.Space.gutter)
}
