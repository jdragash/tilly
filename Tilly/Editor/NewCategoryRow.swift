import SwiftUI

/// Where the panel is while a category is being made, above the emoji keyboard: an emoji slot
/// beside a name field. The emoji keyboard opens first; choosing an emoji moves focus to the
/// name; Return creates the category, needing both. With no emoji, Return sends focus back to
/// the slot. The category button, still shown above, is the way back without creating
/// (`onCancel`), and VoiceOver's escape gesture does the same.
///
/// Under them, the eight colours, the next unused one already chosen.
struct NewCategoryRow: View {
    /// For the pre-picked colour and the new category's place, last.
    let existing: [ExpenseCategory]
    let onCreate: (ExpenseCategory) -> Void
    let onCancel: () -> Void

    @State private var emoji: String?
    @State private var name = ""
    @State private var colour: CategoryColour
    @State private var emojiFocused = true
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
        }
        .onChange(of: emoji) { _, chosen in
            // Moving first responder to the name ends the emoji field's editing on its own, and
            // that clears `emojiFocused`; resigning it here as well makes the keyboard bounce.
            if chosen != nil { nameFocused = true }
        }
        .accessibilityAction(.escape, onCancel)
    }

    private var slot: some View {
        ZStack {
            if let emoji {
                Circle().fill(Tokens.CategoryColour.color(colour))
                Text(emoji).font(Tokens.Text.rowEmoji)
            } else {
                Circle().strokeBorder(
                    emojiFocused ? Tokens.Ink.accent : Tokens.Ink.tertiary,
                    style: Tokens.Stroke.emojiSlot
                )
                Image(systemName: "face.smiling")
                    .font(Tokens.Text.rowEmoji)
                    .foregroundStyle(emojiFocused ? Tokens.Ink.accent : Tokens.Ink.tertiary)
            }
            // Receives the typing; draws nothing. It fills the slot, so tapping the slot opens
            // the emoji keyboard.
            EmojiTextField(emoji: $emoji, isFocused: $emojiFocused)
                .accessibilityLabel("Emoji")
                .accessibilityValue(emoji ?? "None chosen")
                .accessibilityHint("Opens the emoji keyboard")
        }
        .frame(width: Tokens.Size.emojiSlot, height: Tokens.Size.emojiSlot)
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
        // A text field drops its focus after `onSubmit`, so a refocus has to land a turn later.
        guard let emoji else {
            Task { @MainActor in
                nameFocused = false
                emojiFocused = true
            }
            return
        }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            Task { @MainActor in nameFocused = true }
            return
        }
        onCreate(ExpenseCategory(
            name: trimmed,
            emoji: emoji,
            colour: colour,
            sortOrder: CategoryOrdering.nextSortOrder(after: existing.map(\.sortOrder))
        ))
    }
}

#Preview {
    NewCategoryRow(existing: [], onCreate: { _ in }, onCancel: {})
        .padding(.horizontal, Tokens.Space.gutter)
}
