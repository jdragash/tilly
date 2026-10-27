import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Settings → Categories: the picker's grid of cards, four across, each with what its bills cost a
/// month under its name, and `New` last. Tap one to change or delete it on its sheet; hold one and
/// drag it to a new place. Sort, top right, arranges the order once, with Undo; then it holds as the
/// person's own and never re-sorts as bills change.
struct CategoriesPage: View {
    let today: Date

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    @Query private var expenses: [Expense]

    @State private var changing: ExpenseCategory?
    @State private var making = false
    /// The card being dragged. The order is written as it passes over others, since a drop back on
    /// its own place is cancelled by the system and never arrives.
    @State private var dragging: UUID?
    @State private var undo: SortUndo.Shown?

    /// The grid's largest text size, as the picker's.
    private static let cap = DynamicTypeSize.xxxLarge

    private var figures: [UUID: (bills: Int, monthly: Decimal)] {
        CategoryFigures.figures(
            Expense.billInputs(expenses), categories: categories.map(CategoryInfo.init), today: today, calendar: .current
        )
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Tokens.Space.pickerGap), count: Tokens.Size.pickerColumns)
    }

    var body: some View {
        let figures = figures
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.tight) {
                LazyVGrid(columns: columns, spacing: Tokens.Space.pickerGap) {
                    ForEach(categories) { category in
                        card(category, figure: figures[category.id])
                    }
                    Button { making = true } label: { newCard }
                        .buttonStyle(.plain)
                        .accessibilityLabel("New category")
                }
                // Capped as the picker's grid is: the cards hold their size, and a name past two
                // lines would run into the figure under it.
                .dynamicTypeSize(...Self.cap)
                Text("Tap a category to change or delete it. Hold and drag to reorder.")
                    .font(Tokens.Text.caption)
                    .foregroundStyle(Tokens.Drawn.ink2)
                    .padding(.horizontal, Tokens.Space.pickerNameSide)
            }
            .padding(.horizontal, Tokens.Space.pickerSide)
            .padding(.top, Tokens.Space.pickerTop)
            // A card let go between cards is taken, so it doesn't fly back.
            .onDrop(of: [.text], isTargeted: nil) { _ in true }
        }
        .scrollBounceBehavior(.basedOnSize)
        // A pushed page draws its own ground; without it the stack shows white.
        .drawnPaper()
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { sortMenu(figures) }
        }
        .overlay(alignment: .bottom) {
            if let undo {
                SortUndo(shown: undo, onUndo: { restore(undo) })
                    .padding(.bottom, Tokens.SettingsCategories.undoBottom)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: Tokens.Motion.categoryFade), value: undo)
        .sheet(item: $changing) { category in
            CategorySheet(subject: .change(category), onSave: { _ in }, onDelete: {})
        }
        .sheet(isPresented: $making) {
            CategorySheet(subject: .new(existing: categories), onSave: { _ in }, onDelete: {})
        }
    }

    // MARK: Cards

    private func card(_ category: ExpenseCategory, figure: (bills: Int, monthly: Decimal)?) -> some View {
        let line = figureLine(figure)
        return Button { changing = category } label: {
            CategoryCardFace(
                colour: category.colour, seed: stableSeed(category.id.uuidString), metrics: .settings(min(dynamicTypeSize, Self.cap)), name: category.name
            ) {
                CategoryPictureView(
                    picture: CategoryPicture(category), colour: category.colour,
                    size: Tokens.Size.pickerPicture, round: true, place: .editor
                )
            }
            .overlay(alignment: .bottom) {
                CategoryFigure(text: line)
                    .padding(.horizontal, Tokens.SettingsCategories.figureSide)
                    .padding(.bottom, Tokens.SettingsCategories.figureBottom)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.name)
        .accessibilityValue(line)
        .accessibilityHint("Changes or deletes it")
        // Dragging is invisible to VoiceOver and Switch Control; these move a card one place.
        .accessibilityAction(named: "Move earlier") { move(category, by: -1) }
        .accessibilityAction(named: "Move later") { move(category, by: 1) }
        .onDrag {
            dragging = category.id
            return NSItemProvider(object: category.id.uuidString as NSString)
        }
        .onDrop(of: [.text], delegate: CardDrop(target: category, page: self))
    }

    /// `€95/mo`, or `No bills` for a category with none running.
    private func figureLine(_ figure: (bills: Int, monthly: Decimal)?) -> String {
        guard let figure, figure.bills > 0 else { return String(localized: "No bills") }
        return "\(TimelineFormatting.amount(figure.monthly))/mo"
    }

    /// The picker's `New`: a dashed outline, a light plus and its name, as tall as the cards.
    private var newCard: some View {
        RoundedRectangle(cornerRadius: Tokens.Radius.pickerCard, style: .continuous)
            .strokeBorder(Tokens.Drawn.ink2, style: Tokens.Stroke.pickerNew)
            .frame(minHeight: Tokens.SettingsCategories.cardHeightFigure, maxHeight: .infinity)
            .overlay(alignment: .top) {
                Text(verbatim: "+")
                    .font(Tokens.Text.pickerPlus)
                    .frame(height: Tokens.Size.pickerPlus)
                    .padding(.top, Tokens.Space.pickerPlusTop)
            }
            .overlay(alignment: .bottom) {
                CategoryCardName(name: String(localized: "New"), ink: Tokens.Drawn.ink2)
                    .padding(.bottom, Tokens.SettingsCategories.nameBottomFigure)
            }
            .foregroundStyle(Tokens.Drawn.ink2)
            .contentShape(Rectangle())
    }

    // MARK: Sorting

    private func sortMenu(_ figures: [UUID: (bills: Int, monthly: Decimal)]) -> some View {
        Menu {
            Section("Arrange once, then drag as you like") {
                ForEach(CategorySort.allCases, id: \.self) { sort in
                    Button { arrange(by: sort, figures: figures) } label: {
                        Text(sort.title)
                        Text(sort.detail)
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .accessibilityLabel("Sort")
    }

    private func arrange(by sort: CategorySort, figures: [UUID: (bills: Int, monthly: Decimal)]) {
        let previous = CategoryOrdering.arrange(categories, by: sort, figures: figures)
        try? modelContext.save()
        let shown = SortUndo.Shown(sort: sort, previous: previous)
        undo = shown
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Tokens.SettingsCategories.undoSeconds))
            if undo == shown { undo = nil }
        }
    }

    private func restore(_ shown: SortUndo.Shown) {
        CategoryOrdering.restore(categories, order: shown.previous)
        try? modelContext.save()
        undo = nil
    }

    // MARK: Moving

    /// While a card is held over another, it takes that one's place, written at once.
    fileprivate func hover(over target: ExpenseCategory) {
        guard let dragging, dragging != target.id,
              let from = categories.firstIndex(where: { $0.id == dragging }),
              let to = categories.firstIndex(where: { $0.id == target.id }) else { return }
        var order = categories.map(\.id)
        order.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        withAnimation(.easeInOut(duration: Tokens.Motion.categoryFade)) {
            CategoryOrdering.restore(categories, order: order)
        }
        try? modelContext.save()
    }

    fileprivate func finishDrag() { dragging = nil }

    private func move(_ category: ExpenseCategory, by step: Int) {
        guard let index = categories.firstIndex(where: { $0.id == category.id }) else { return }
        let destination = index + step
        guard categories.indices.contains(destination) else { return }
        var order = categories.map(\.id)
        order.swapAt(index, destination)
        CategoryOrdering.restore(categories, order: order)
        try? modelContext.save()
    }
}

/// The line under a card's name, reading the text size inside the grid's cap.
private struct CategoryFigure: View {
    let text: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Text(text)
            .font(Tokens.SettingsCategories.figureFont(dynamicTypeSize))
            .foregroundStyle(Tokens.SettingsCategories.figureInk)
            .lineLimit(1)
    }
}

/// A card under a held one: it moves aside as the held card passes, and the drop writes the order.
private struct CardDrop: DropDelegate {
    let target: ExpenseCategory
    let page: CategoriesPage

    func dropEntered(info: DropInfo) { page.hover(over: target) }

    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }

    func performDrop(info: DropInfo) -> Bool {
        page.finishDrag()
        return true
    }
}

#Preview {
    let container = try! TillyStore.container(inMemory: true)
    let context = container.mainContext
    let made = [
        ExpenseCategory(name: "Home", symbol: "house", colour: .blue, sortOrder: 0),
        ExpenseCategory(name: "Energy", symbol: "bolt", colour: .orange, sortOrder: 1),
        ExpenseCategory(name: "Phone & internet", symbol: "wifi", colour: .aqua, sortOrder: 2),
        ExpenseCategory(name: "Subscriptions", symbol: "tv", colour: .yellow, sortOrder: 3),
    ]
    made.forEach(context.insert)
    context.insert(Expense(name: "Rent", amount: 950, category: made[0]))
    try! context.save()
    return NavigationStack { CategoriesPage(today: Date()) }
        .drawnGround()
        .modelContainer(container)
}
