import SwiftData
import SwiftUI

/// Makes a category or changes one, over the bill editor or Settings. Fixed at its top: the
/// category's card, its name typed on it, and the eight colours; under them the symbols scroll.
/// A new category starts on a tag, and while nothing is picked the name's guess replaces it,
/// marked with a spark. Changing one adds a trash button, which deletes it and its bills after
/// an alert that says so.
struct CategorySheet: View {
    enum Subject {
        /// `existing` sets the new one's colour, the next unused, and its place, last.
        case new(existing: [ExpenseCategory])
        case change(ExpenseCategory)
    }

    let subject: Subject
    let onSave: (ExpenseCategory) -> Void     // the made or changed category
    let onDelete: () -> Void                  // after the delete, for the host to tidy up

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var name: String
    @State private var picture: CategoryPicture
    @State private var colour: CategoryColour
    /// A symbol was chosen, so the name no longer guesses one.
    @State private var picked: Bool
    @State private var guessed = false
    @State private var scrollToTop = 0
    @State private var deleting: ExpenseCategory?
    @FocusState private var nameFocused: Bool
    private let seed: UInt64
    /// What the changed category was, read once: after a delete the sheet may draw once more, and
    /// the deleted model can't be read.
    private var original: (name: String, picture: CategoryPicture, colour: CategoryColour?)?
    private let searching: String

    /// `typed` and `searching` open the sheet part-way through, for previews.
    init(
        subject: Subject, typed: String? = nil, searching: String = "",
        onSave: @escaping (ExpenseCategory) -> Void, onDelete: @escaping () -> Void
    ) {
        self.subject = subject
        self.searching = searching
        self.onSave = onSave
        self.onDelete = onDelete
        switch subject {
        case .new(let existing):
            _name = State(initialValue: "")
            _picture = State(initialValue: .symbol(SymbolGuess.fallback))
            _colour = State(initialValue: CategoryOrdering.nextColour(after: existing.compactMap(\.colour)))
            _picked = State(initialValue: false)
            seed = stableSeed(UUID().uuidString)
            if let typed, let match = SymbolGuess.guess(for: typed) {
                _picture = State(initialValue: .symbol(match))
                _guessed = State(initialValue: true)
            }
        case .change(let category):
            _name = State(initialValue: category.name)
            _picture = State(initialValue: CategoryPicture(category))
            _colour = State(initialValue: category.colour ?? CategoryColour.allCases[0])
            original = (category.name, CategoryPicture(category), category.colour)
            _picked = State(initialValue: true)
            seed = stableSeed(category.id.uuidString)
        }
        if let typed { _name = State(initialValue: typed) }
    }

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var changing: ExpenseCategory? {
        if case .change(let category) = subject { category } else { nil }
    }

    private var symbol: String? {
        if case .symbol(let name) = picture { name } else { nil }
    }

    /// A name, and something different from what was there.
    private var canSave: Bool {
        guard !trimmed.isEmpty else { return false }
        guard let original else { return true }
        return trimmed != original.name || picture != original.picture || colour != original.colour
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: changing == nil ? "New Category" : "Edit Category", closeLabel: "Cancel", onClose: { dismiss() }) {
                if changing != nil {
                    Button { deleting = changing } label: {
                        SheetHeaderSymbol(name: "trash", ink: Tokens.Ink.destructive)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: Circle())
                    .accessibilityLabel("Delete category")
                }
                Button(action: save) {
                    SheetHeaderSymbol(name: "checkmark", ink: Tokens.Ink.onProminent)
                }
                .buttonStyle(UndimmedButtonStyle())
                .glassEffect(
                    Glass.regular.tint(canSave ? Tokens.Ink.accent : Tokens.Surface.confirmDisabled).interactive(canSave),
                    in: Circle()
                )
                .disabled(!canSave)
                .accessibilityLabel("Save")
            }
            card
                .padding(.top, Tokens.CategorySheet.cardTop)
                .padding(.bottom, Tokens.CategorySheet.cardBottom)
            swatches
                .padding(.horizontal, Tokens.CategorySheet.gutter)
                .padding(.top, Tokens.CategorySheet.swatchTop)
                .padding(.bottom, Tokens.CategorySheet.swatchBottom)
            Rectangle()
                .fill(Tokens.Drawn.hairline)
                .frame(height: Tokens.CategorySheet.hairline)
                .padding(.top, Tokens.Space.tight)
            SymbolPicker(colour: colour, selection: symbol, scrollToTop: scrollToTop, query: searching) { chosen in
                picture = .symbol(chosen)
                picked = true
                guessed = false
            }
        }
        .drawnGround()
        .onAppear {
            if changing == nil { nameFocused = true }
        }
        .categoryDeleteAlert(for: $deleting) { _ in
            onDelete()
            dismiss()
        }
    }

    // MARK: The card

    private var card: some View {
        CategoryCardFace(colour: colour, seed: seed, metrics: .sheet) {
            Button { scrollToTop += 1 } label: {
                CategoryPictureView(
                    picture: picture, colour: colour, size: Tokens.CategorySheet.pictureSize, round: true, place: .editor
                )
                .overlay(alignment: .topTrailing) {
                    if guessed { spark }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Symbol")
            .accessibilityValue(symbolName)
            .accessibilityHint("Shows the symbols from the top")
        } name: {
            nameField
        }
        .frame(width: Tokens.CategorySheet.cardWidth)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// The guess's mark: a sparkle on a paper badge at the picture's corner.
    private var spark: some View {
        Image(systemName: "sparkle")
            .font(Tokens.CategorySheet.sparkFont)
            .foregroundStyle(Tokens.Drawn.ink2)
            .frame(width: Tokens.CategorySheet.sparkSize, height: Tokens.CategorySheet.sparkSize)
            .background(Tokens.Drawn.paperCard, in: Circle())
            .overlay { Circle().strokeBorder(Tokens.Drawn.hairline, lineWidth: Tokens.Size.hairline) }
            .offset(x: Tokens.CategorySheet.sparkRight, y: -Tokens.CategorySheet.sparkUp)
            .accessibilityHidden(true)
    }

    /// Typed on the card: two lines, then smaller, then it scrolls. Return saves when ✓ would,
    /// else puts the keyboard away; it never breaks the line.
    private var nameField: some View {
        let full = Tokens.CategorySheet.nameSize(dynamicTypeSize)
        return TextField("Name", text: $name, axis: .vertical)
            .font(Tokens.CategorySheet.nameFont(size: Tokens.CategorySheet.fittedNameSize(name, full: full)))
            .foregroundStyle(Tokens.Ink.primary)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .textInputAutocapitalization(.words)
            .submitLabel(.done)
            .focused($nameFocused)
            .frame(minHeight: Tokens.CategorySheet.nameFieldMinHeight)
            .overlay {
                if trimmed.isEmpty {
                    RoundedRectangle(cornerRadius: Tokens.CategorySheet.outlineRadius, style: .continuous)
                        .strokeBorder(
                            Tokens.Drawn.ink2,
                            style: StrokeStyle(lineWidth: Tokens.CategorySheet.outlineWidth, dash: Tokens.Stroke.pickerNew.dash)
                        )
                        .opacity(Tokens.CategorySheet.outlineOpacity)
                        .allowsHitTesting(false)
                }
            }
            .onChange(of: name) { _, typed in
                if typed.contains("\n") {
                    name = typed.replacingOccurrences(of: "\n", with: "")
                    submit()
                    return
                }
                if typed.count > Tokens.CategorySheet.nameMaxLength {
                    name = String(typed.prefix(Tokens.CategorySheet.nameMaxLength))
                }
                guess()
            }
    }

    private var swatches: some View {
        HStack(spacing: 0) {
            ForEach(Array(CategoryColour.allCases.enumerated()), id: \.element) { index, option in
                if index > 0 { Spacer(minLength: 0) }
                let isChosen = option == colour
                Button { colour = option } label: {
                    Circle()
                        .fill(Tokens.CategoryColour.color(option))
                        .frame(width: Tokens.CategorySheet.swatchDot, height: Tokens.CategorySheet.swatchDot)
                        .frame(width: Tokens.CategorySheet.swatchTarget, height: Tokens.CategorySheet.swatchTarget)
                        .overlay {
                            if isChosen {
                                let ring = Tokens.CategorySheet.swatchDot + 2 * Tokens.CategorySheet.swatchRingOutset
                                Circle()
                                    .strokeBorder(Tokens.CategoryColour.color(option), lineWidth: Tokens.CategorySheet.swatchRingWidth)
                                    .frame(width: ring, height: ring)
                            }
                        }
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.name)
                .accessibilityAddTraits(isChosen ? .isSelected : [])
            }
        }
    }

    private var symbolName: String {
        guard let symbol else { return "Emoji" }
        return SymbolCatalog.all.first { $0.name == symbol }?.words.first?.capitalized ?? symbol
    }

    // MARK: Acting

    /// While nothing is picked, the name's best guess wears the card, or the tag.
    private func guess() {
        guard !picked else { return }
        let match = SymbolGuess.guess(for: name)
        picture = .symbol(match ?? SymbolGuess.fallback)
        guessed = match != nil
    }

    private func submit() {
        if canSave { save() } else { nameFocused = false }
    }

    private func save() {
        guard canSave else { return }
        let category: ExpenseCategory
        switch subject {
        case .new(let existing):
            category = ExpenseCategory(
                name: trimmed, symbol: symbol ?? SymbolGuess.fallback, colour: colour,
                sortOrder: CategoryOrdering.nextSortOrder(after: existing.map(\.sortOrder))
            )
            modelContext.insert(category)
        case .change(let existing):
            category = existing
            category.name = trimmed
            if let symbol { category.symbol = symbol }
            category.colour = colour
        }
        try? modelContext.save()
        onSave(category)
        dismiss()
    }
}

// MARK: Previews

@MainActor
private func previewCategories() -> (ModelContainer, [ExpenseCategory]) {
    let container = try! TillyStore.container(inMemory: true)
    let context = container.mainContext
    let made = [
        ExpenseCategory(name: "Home", symbol: "house", colour: .blue, sortOrder: 0),
        ExpenseCategory(name: "Energy", symbol: "bolt", colour: .orange, sortOrder: 1),
        ExpenseCategory(name: "Phone & internet", symbol: "wifi", colour: .aqua, sortOrder: 2),
    ]
    made.forEach(context.insert)
    context.insert(Expense(name: "Rent", amount: 950, category: made[0]))
    context.insert(Expense(name: "Water", amount: 31, category: made[0]))
    try! context.save()
    return (container, made)
}

#Preview("New") {
    let (container, made) = previewCategories()
    return CategorySheet(subject: .new(existing: made), onSave: { _ in }, onDelete: {})
        .modelContainer(container)
}

#Preview("New, guessed") {
    let (container, made) = previewCategories()
    return CategorySheet(subject: .new(existing: made), typed: "Netflix", onSave: { _ in }, onDelete: {})
        .modelContainer(container)
}

#Preview("New, searching") {
    let (container, made) = previewCategories()
    return CategorySheet(subject: .new(existing: made), typed: "Boxing club", searching: "box", onSave: { _ in }, onDelete: {})
        .modelContainer(container)
}

#Preview("Changing") {
    let (container, made) = previewCategories()
    return CategorySheet(subject: .change(made[2]), onSave: { _ in }, onDelete: {})
        .modelContainer(container)
}

#Preview("Changing, dark, accessibility size") {
    let (container, made) = previewCategories()
    return CategorySheet(subject: .change(made[0]), onSave: { _ in }, onDelete: {})
        .modelContainer(container)
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.accessibility3)
}
