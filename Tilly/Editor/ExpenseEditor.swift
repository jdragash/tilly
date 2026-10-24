import SwiftData
import SwiftUI
import TillyCore
import os

/// Which input fills the area under the card, in the keypad's place.
enum EditorPanel: Equatable {
    case keypad, date, `repeat`, category, newCategory
}

/// The editor, in `EditorSheet` over the timeline, or a system sheet over All bills. The card is
/// the input: tapping a part opens its input in the keypad's place, under the card, at the
/// keypad's height, so the card never moves. At standard
/// text sizes the keyboard covers the panel rather than pushing the sheet up. See "The editor" in
/// `docs/DESIGN.md`.
struct ExpenseEditor: View {
    let today: Date
    /// Set when the editor opened from a row: editing a real charge rather than adding a new
    /// bill. See "Opening a charge edits it" in `docs/DESIGN.md`.
    let session: EditSession?
    /// How it closed: the sheet holding it goes, and a save says which charge to bring into view.
    let onClose: (EditorClose) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.editorSheetContents) private var sheetContents
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]
    @Query private var expenses: [Expense]

    @State private var draft: ExpenseDraft
    @State private var panel: EditorPanel
    @FocusState private var nameFocused: Bool
    @State private var viewportHeight: CGFloat = 0
    /// The category tile's frame (global): where a played card flies to.
    @State private var tileFrame: CGRect = .zero
    @State private var isClosing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The card being dressed: the colour flooding from the tile, the picture's stamp, the dip.
    @State private var flood: CardFlood?
    @State private var stamp: CGFloat = 1
    @State private var dip: CGFloat = 0
    @State private var dressings = 0

    private static let logger = Logger(subsystem: "com.jdragash.Tilly", category: "ExpenseEditor")

    /// `draft` and `panel` exist so previews can open the editor part-way through. With a
    /// `session` and no explicit `draft`, the draft opens from the session's own baseline.
    init(
        today: Date, draft: ExpenseDraft? = nil, panel: EditorPanel = .keypad, session: EditSession? = nil,
        onClose: @escaping (EditorClose) -> Void
    ) {
        self.today = today
        self.session = session
        self.onClose = onClose
        _draft = State(initialValue: draft ?? session?.draft ?? ExpenseDraft(today: today, calendar: .current))
        _panel = State(initialValue: panel)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .opacity(sheetContents)
            ScrollView {
                // The card holds the top and the panel the bottom; the space between them gives
                // way, so neither moves when the panel changes or a keyboard pushes the sheet up.
                // Accessibility sizes overflow instead, and scroll.
                VStack(spacing: Tokens.Space.section) {
                    card
                        .padding(.horizontal, Tokens.Space.editorCardInset)
                    Spacer(minLength: 0)
                    // A new category takes the panel's place, above its keyboard. At accessibility
                    // sizes the keyboard pushes the sheet up, so the panel goes while a name is typed.
                    Group {
                        if panel == .newCategory {
                            NewCategoryRow(existing: categories, onCreate: create, onCancel: { panel = .category })
                        } else if keyboardCovers || !nameFocused {
                            // Where the keyboard covers, the panel stays in the layout so nothing
                            // above it moves, and hides so it can't show above a shorter keyboard.
                            panelArea
                                .frame(maxWidth: .infinity)
                                .frame(height: Tokens.Size.editorPanel)
                                .opacity(nameFocused ? 0 : 1)
                                .accessibilityHidden(nameFocused)
                        }
                    }
                    .padding(.horizontal, Tokens.Space.gutter)
                    .opacity(sheetContents)
                    // The hand's played card flies up over the card to its tile.
                    .zIndex(1)
                }
                .frame(minHeight: viewportHeight)
            }
            .scrollBounceBehavior(.basedOnSize)
            .ignoresSafeArea(.keyboard, edges: keyboardCovers ? .bottom : [])
            .onScrollGeometryChange(for: CGFloat.self) { $0.containerSize.height } action: { _, height in
                viewportHeight = height
            }
        }
        .onChange(of: panel) { _, newPanel in
            if newPanel != .keypad { nameFocused = false }
        }
        .onChange(of: nameFocused) { _, focused in
            if focused { panel = .keypad }
        }
    }

    // MARK: Pieces

    /// ✕ top left; trash, when a charge is open, and ✓ top right. Glass circles the size and place
    /// of the system sheet's toolbar buttons, which this row replaced when the editor stopped being
    /// a system sheet. A half-made category is finished or cancelled before the expense is saved.
    private var header: some View {
        HStack(spacing: Tokens.Space.sheetButtonGap) {
            Button { close(.cancelled) } label: {
                headerSymbol("xmark", ink: Tokens.Ink.primary)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Circle())
            .accessibilityLabel("Close")
            Spacer(minLength: 0)
            if let session {
                // A `Menu`, not a `confirmationDialog`: the dialog ran its button's action only
                // once its closing transition had finished, a second after it had visibly gone
                // (measured), and it couldn't be dismissed while opening.
                Menu {
                    Section {
                        deleteButtons(for: session)
                    } header: {
                        Text("\(deleteTitle(for: session)) \(deleteMessage(for: session))")
                    }
                } label: {
                    headerSymbol("trash", ink: Tokens.Ink.destructive)
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: Circle())
                .accessibilityLabel("Delete")
            }
            confirm
        }
        .padding(.horizontal, Tokens.Space.sheetButtonInset)
        .padding(.top, Tokens.Space.sheetButtonInset)
        .padding(.bottom, Tokens.Space.sheetHeaderBottom)
    }

    /// ✓: the system's prominent checkmark, grey while there's nothing to save, and a menu of
    /// "this charge or future charges" when a save has to ask.
    @ViewBuilder
    private var confirm: some View {
        let glass = Glass.regular.tint(canSave ? Tokens.Ink.accent : Tokens.Surface.confirmDisabled).interactive(canSave)
        if asksScope {
            // A `Menu` for the same reason as trash.
            Menu {
                scopeButtons
            } label: {
                headerSymbol("checkmark", ink: Tokens.Ink.onProminent)
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .glassEffect(glass, in: Circle())
            .accessibilityLabel("Save")
        } else {
            Button(action: save) {
                headerSymbol("checkmark", ink: Tokens.Ink.onProminent)
            }
            // Not `.plain`, which dims a disabled label: the system's disabled ✓ keeps it white
            // on grey glass.
            .buttonStyle(UndimmedButtonStyle())
            .glassEffect(glass, in: Circle())
            .disabled(!canSave)
            .accessibilityLabel("Save")
        }
    }

    private func headerSymbol(_ name: String, ink: Color) -> some View {
        Image(systemName: name)
            .font(Tokens.Text.floatingSymbol)
            // Fixed, as toolbar symbols are: the circle doesn't grow with the text.
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .foregroundStyle(ink)
            .frame(width: Tokens.Size.floatingButton, height: Tokens.Size.floatingButton)
            .contentShape(Circle())
    }

    private var card: some View {
        EditorCard(
            draft: draft,
            name: $draft.name,
            nameFocus: $nameFocused,
            category: selectedCategory,
            progress: progress,
            focused: focusedPart,
            today: today,
            onTap: open,
            onNameSubmit: submitName,
            onTileFrame: { tileFrame = $0 },
            flood: flood,
            stamp: stamp,
            dip: dip
        )
        .sensoryFeedback(.impact(weight: .medium), trigger: dressings)
        .submitLabel(afterName == nil ? .done : .next)
    }

    /// Where Return goes from the name: the next part still missing besides the name itself. The
    /// keyboard reads its label when the field focuses, and nothing else changes while it's up.
    private var afterName: CardPart? {
        progress.next(after: .name).flatMap { $0 == .name ? nil : $0 }
    }

    /// Each part opens its input; the card's background opens the category, as its tile does.
    private func open(_ part: CardPart?) {
        switch part {
        case .amount:
            nameFocused = false
            panel = .keypad
        case .name:
            nameFocused = true
        case .date:
            panel = .date
        case .repeat:
            panel = .repeat
        case .category, nil:
            panel = .category
        }
    }

    /// Return goes to whatever's still missing, or puts the keyboard away.
    private func submitName() {
        if let next = afterName {
            open(next)
        } else {
            nameFocused = false
        }
    }

    @ViewBuilder
    private var panelArea: some View {
        switch panel {
        case .keypad:
            Keypad { draft.press($0) }
        case .date:
            DatePicker("Date", selection: dateBinding, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
        case .repeat:
            RepeatWheel(draft: $draft)
        case .category:
            CategoryHand(
                categories: categories,
                selection: draft.categoryID,
                newBreathes: categories.isEmpty && !progress.isMissing(.amount) && !progress.isMissing(.name),
                tileFrame: tileFrame,
                onPlay: dress,
                onNew: { panel = .newCategory }
            )
        case .newCategory:
            EmptyView()
        }
    }

    // MARK: State

    private var progress: CardProgress {
        CardProgress(draft: draft, categoryExists: selectedCategory != nil, isMakingCategory: panel == .newCategory)
    }

    /// The part whose input is open: the name while it's typed in, otherwise the panel's own part.
    private var focusedPart: CardPart {
        if nameFocused { return .name }
        switch panel {
        case .keypad: return .amount
        case .date: return .date
        case .repeat: return .repeat
        case .category, .newCategory: return .category
        }
    }

    /// The keyboard covers the editor at standard sizes. It can't while a category is made, where
    /// the symbols take the keypad's place and the name's keyboard pushes the sheet up, or at accessibility sizes, where it
    /// would cover the name field.
    private var keyboardCovers: Bool {
        !dynamicTypeSize.isAccessibilitySize && panel != .newCategory
    }

    private var selectedCategory: ExpenseCategory? {
        categories.first { $0.id == draft.categoryID }
    }

    private var isValid: Bool {
        draft.isValid { id in categories.contains { $0.id == id } }
    }

    /// ✓ waits for a change once there's a charge open — an untouched edit has nothing to save.
    private var canSave: Bool {
        guard panel != .newCategory else { return false }
        guard session != nil else { return isValid }
        return isValid && draft.changes.any
    }

    private var dateBinding: Binding<Date> {
        Binding(
            get: { draft.date },
            set: { draft.date = calendar.startOfDay(for: $0) }
        )
    }

    /// Dresses the card in the category: the new colour floods out from the tile, the picture stamps
    /// (1.3, then 0.95, then 1) and the card dips. Reduce Motion crossfades the colour and does
    /// nothing else.
    private func dress(_ id: UUID) {
        let previous = selectedCategory?.colour
        guard !reduceMotion else {
            withAnimation(.easeInOut(duration: Tokens.Motion.Card.flood)) { draft.categoryID = id }
            return
        }
        var instant = Transaction()
        instant.disablesAnimations = true
        withTransaction(instant) {
            draft.categoryID = id
            flood = CardFlood(previous: previous, progress: 0)
            stamp = Tokens.Motion.Card.stampScale
        }
        dressings += 1
        withAnimation(.easeOut(duration: Tokens.Motion.Card.flood)) {
            flood?.progress = 1
        } completion: {
            flood = nil
        }
        withAnimation(.easeOut(duration: Tokens.Motion.Card.stampDown)) {
            stamp = Tokens.Motion.Card.stampUnder
        } completion: {
            withAnimation(.easeInOut(duration: Tokens.Motion.Card.stampSettle)) { stamp = 1 }
        }
        withAnimation(.easeOut(duration: 0.07)) {
            dip = Tokens.Motion.Card.dip
        } completion: {
            withAnimation(.easeOut(duration: 0.13)) { dip = 0 }
        }
    }

    /// A category made in the editor dresses the card at once, and the hand comes back.
    private func create(_ category: ExpenseCategory) {
        modelContext.insert(category)
        do {
            try modelContext.save()
        } catch {
            Self.logger.error("Saving a category failed: \(error)")
        }
        dress(category.id)
        panel = .category
    }

    /// Whether ✓ asks "this charge or future charges" rather than saving.
    private var asksScope: Bool {
        guard let session, canSave else { return false }
        return draft.saveIntent(hasLaterCharge: session.hasLaterCharge) == .askScope
    }

    private func save() {
        guard let session else {
            saveNewExpense()
            return
        }
        guard canSave else { return }
        switch draft.saveIntent(hasLaterCharge: session.hasLaterCharge) {
        case .nothing:
            break
        case .askScope:
            break // ✓ is a menu then, and never calls save()
        case .thisCharge:
            saveThisCharge(session)
        case .futureCharges:
            saveFutureCharges(session)
        case .wholeBill:
            saveWholeBill(session)
        }
    }

    private func saveNewExpense() {
        guard isValid, let amount = draft.amount, let category = selectedCategory else { return }
        let expense = Expense(
            name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amount,
            recurrenceInterval: draft.interval,
            recurrenceUnit: draft.unit,
            anchorDate: draft.date,
            endDate: draft.rule(calendar: calendar).endDate,
            category: category
        )
        modelContext.insert(expense)
        do {
            try modelContext.save()
            close(.saved(expenseID: expense.id, date: draft.date))
        } catch {
            Self.logger.error("Saving an expense failed: \(error)")
        }
    }

    // MARK: Editing

    @ViewBuilder
    private var scopeButtons: some View {
        if let session {
            Button("Save for this charge only") { saveThisCharge(session) }
            Button("Save for future charges") { saveFutureCharges(session) }
        }
    }

    private func saveThisCharge(_ session: EditSession) {
        edit(session) { expense, category in
            try BillEditor.saveThisCharge(
                draft, expense: expense, scheduledDate: session.scheduledDate, category: category,
                context: modelContext, calendar: calendar
            )
        }
    }

    private func saveFutureCharges(_ session: EditSession) {
        edit(session) { expense, category in
            try BillEditor.saveFutureCharges(
                draft, expense: expense, scheduledDate: session.scheduledDate, category: category,
                context: modelContext, calendar: calendar
            )
        }
    }

    private func saveWholeBill(_ session: EditSession) {
        edit(session) { expense, category in
            try BillEditor.saveWholeBill(draft, expense: expense, category: category, context: modelContext, calendar: calendar)
        }
    }

    @ViewBuilder
    private func deleteButtons(for session: EditSession) -> some View {
        if session.isFirstCharge {
            Button("Delete \(deleteBillName)", role: .destructive) {
                deleteAllCharges(session)
            }
        } else {
            Button("Delete All Future Charges", role: .destructive) {
                deleteFutureCharges(session)
            }
            Button("Delete All Charges", role: .destructive) {
                deleteAllCharges(session)
            }
        }
    }

    private func deleteFutureCharges(_ session: EditSession) {
        guard let expense = fetchExpense(session.expenseID) else { return }
        performEdit {
            try BillEditor.deleteFutureCharges(
                from: session.scheduledDate, of: expense, context: modelContext, calendar: calendar
            )
        }
    }

    private func deleteAllCharges(_ session: EditSession) {
        guard let expense = fetchExpense(session.expenseID) else { return }
        performEdit {
            try BillEditor.deleteAllCharges(of: expense, context: modelContext)
        }
    }

    private func deleteTitle(for session: EditSession) -> String {
        session.isFirstCharge ? "Delete \(deleteBillName)?" : "\(deleteBillName) repeats \(deleteRepeatPhrase)."
    }

    private func deleteMessage(for session: EditSession) -> String {
        guard !session.isFirstCharge else { return "Every charge goes, past ones too." }
        let previous = session.previousChargeDate.map(shortDate) ?? ""
        return "Deleting future charges keeps \(previous) and earlier."
    }

    /// The bill's name as saved, not as the live draft reads it: renaming, then tapping
    /// trash before saving, still asks about the bill on record ("Delete Gym", not "Delete
    /// Gym2"). Falls back to the live name only when there's no baseline to read, which
    /// doesn't happen while `session` exists.
    private var deleteBillName: String {
        draft.baseline?.name ?? draft.name
    }

    /// "every month", "every 3 months", "every week" — the trash dialog's own phrasing, apart
    /// from `repeatLabel`'s button-sized noun. Reads the saved repeat, not the live draft, for
    /// the same reason as `deleteBillName`.
    private var deleteRepeatPhrase: String {
        let interval = draft.baseline?.interval ?? draft.interval
        let unit = draft.baseline?.unit ?? draft.unit
        if interval == 1 {
            switch unit {
            case .day: return "every day"
            case .week: return "every week"
            case .month: return "every month"
            case .year: return "every year"
            }
        }
        return "every \(interval) \(unit.rawValue)s"
    }

    /// "Oct 31", never a year — matches `ExpenseDraft.dateLabel`.
    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter.string(from: date)
    }

    /// A saved edit closes the sheet.
    private func edit(_ session: EditSession, _ operation: (Expense, ExpenseCategory) throws -> Void) {
        guard let category = selectedCategory, let expense = fetchExpense(session.expenseID) else { return }
        performEdit({ try operation(expense, category) }, then: .saved(expenseID: expense.id, date: draft.date))
    }

    /// Runs an edit, then closes as `close` says: a delete by default, a save when one passes it.
    private func performEdit(_ operation: () throws -> Void, then close: EditorClose = .deleted) {
        do {
            try operation()
            self.close(close)
        } catch {
            Self.logger.error("Editing an expense failed: \(error)")
        }
    }

    // MARK: Closing

    /// Closes the sheet once: ✓ pressed twice is ignored.
    private func close(_ how: EditorClose) {
        guard !isClosing else { return }
        isClosing = true
        nameFocused = false
        onClose(how)
    }

    private func fetchExpense(_ id: UUID) -> Expense? {
        (try? modelContext.fetch(FetchDescriptor<Expense>()))?.first { $0.id == id }
    }
}

// MARK: Previews

private func previewContainer() -> (ModelContainer, ExpenseCategory) {
    let container = try! TillyStore.container(inMemory: true)
    let category = ExpenseCategory(name: "Loans", emoji: "💳")
    container.mainContext.insert(category)
    try! container.mainContext.save()
    return (container, category)
}

#Preview("Empty") {
    ExpenseEditor(today: Date(), onClose: { _ in })
        .drawnGround()
        .modelContainer(previewContainer().0)
}

#Preview("Filled, future date, counted repeat") {
    let (container, category) = previewContainer()
    let calendar = Calendar.current
    let today = Date()
    var draft = ExpenseDraft(today: today, calendar: calendar)
    for key: KeypadKey in [.digit(1), .digit(2), .digit(5), .digit(0), .decimal, .digit(5)] { draft.press(key) }
    draft.name = "Sofa"
    draft.date = calendar.date(byAdding: .day, value: 12, to: calendar.startOfDay(for: today))!
    draft.paymentCount = 12
    draft.categoryID = category.id
    return ExpenseEditor(today: today, draft: draft, onClose: { _ in })
        .drawnGround()
        .modelContainer(container)
}

#Preview("Repeat panel") {
    ExpenseEditor(today: Date(), panel: .repeat, onClose: { _ in })
        .drawnGround()
        .modelContainer(previewContainer().0)
}

#Preview("Date panel") {
    ExpenseEditor(today: Date(), panel: .date, onClose: { _ in })
        .drawnGround()
        .modelContainer(previewContainer().0)
}

#Preview("Accessibility size") {
    let (container, category) = previewContainer()
    var draft = ExpenseDraft(today: Date(), calendar: .current)
    draft.press(.digit(9))
    draft.name = "Sofa"
    draft.categoryID = category.id
    return ExpenseEditor(today: Date(), draft: draft, onClose: { _ in })
        .drawnGround()
        .modelContainer(container)
        .dynamicTypeSize(.accessibility3)
}

/// A bill running on with no end, anchored `monthsAgo` months back, so the charge opened
/// always has a later one — `EditSession.make` reads it straight from the store, the same
/// way a real row tap would.
private func previewEditSession(monthsAgo: Int, in container: ModelContainer, category: ExpenseCategory) -> EditSession {
    let context = container.mainContext
    let calendar = Calendar.current
    let anchor = calendar.date(byAdding: .month, value: -monthsAgo, to: calendar.startOfDay(for: Date()))!
    let expense = Expense(name: "Gym", amount: 50, anchorDate: anchor, category: category)
    context.insert(expense)
    try! context.save()
    return try! EditSession.make(expenseID: expense.id, scheduledDate: anchor, context: context, calendar: calendar)!
}

#Preview("Editing a charge") {
    let (container, category) = previewContainer()
    let session = previewEditSession(monthsAgo: 0, in: container, category: category)
    return ExpenseEditor(today: Date(), session: session, onClose: { _ in })
        .drawnGround()
        .modelContainer(container)
}

#Preview("Editing, scope question") {
    let (container, category) = previewContainer()
    let session = previewEditSession(monthsAgo: 3, in: container, category: category)
    var draft = session.draft
    draft.digits = "75"
    return ExpenseEditor(today: Date(), draft: draft, session: session, onClose: { _ in })
        .drawnGround()
        .modelContainer(container)
}

#Preview("Editing, dark, accessibility size") {
    let (container, category) = previewContainer()
    let session = previewEditSession(monthsAgo: 0, in: container, category: category)
    return ExpenseEditor(today: Date(), session: session, onClose: { _ in })
        .drawnGround()
        .modelContainer(container)
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.accessibility3)
}

/// A button that draws its label as it is, enabled or not; its glass answers the press.
private struct UndimmedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
