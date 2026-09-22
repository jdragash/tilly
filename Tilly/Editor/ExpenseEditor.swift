import SwiftData
import SwiftUI
import TillyCore
import os

/// The sheet for adding an expense. The amount is the screen: the keypad is up when it opens,
/// the name sits under it, and date, category and repeat open in the keypad's place at the
/// keypad's height, so the amount never moves. At standard text sizes the keyboard covers the
/// panel rather than pushing the editor up. See "The editor" in `docs/DESIGN.md`.
struct ExpenseEditor: View {
    let today: Date
    /// Set when the editor opened from a row: editing a real charge rather than adding a new
    /// bill. See "Opening a charge edits it" in `docs/DESIGN.md`.
    let session: EditSession?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]

    @State private var draft: ExpenseDraft
    @State private var panel: EditorPanel
    @State private var showingScopeDialog = false
    @State private var showingDeleteDialog = false
    @FocusState private var nameFocused: Bool
    @ScaledMetric(relativeTo: .largeTitle) private var amountSize = Tokens.Size.editorAmountSize
    @ScaledMetric(relativeTo: .title3) private var nameHeight = Tokens.Size.editorNameHeight
    @State private var viewportHeight: CGFloat = 0

    private static let logger = Logger(subsystem: "com.jdragash.Tilly", category: "ExpenseEditor")

    /// `draft` and `panel` exist so previews can open the editor part-way through. With a
    /// `session` and no explicit `draft`, the draft opens from the session's own baseline.
    init(today: Date, draft: ExpenseDraft? = nil, panel: EditorPanel = .keypad, session: EditSession? = nil) {
        self.today = today
        self.session = session
        _draft = State(initialValue: draft ?? session?.draft ?? ExpenseDraft(today: today, calendar: .current))
        _panel = State(initialValue: panel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Tokens.Space.section) {
                    // The amount and name are the flexible part: they centre in whatever height the
                    // buttons and panel leave, so those sit at the bottom. Accessibility sizes
                    // overflow instead, and scroll.
                    VStack(spacing: Tokens.Space.section) {
                        amountView
                        nameField
                    }
                    .frame(maxHeight: .infinity)
                    EditorButtonRow(draft: draft, category: selectedCategory, today: today, panel: $panel)
                    // A new category takes the panel's place, above its keyboard. At accessibility
                    // sizes the keyboard pushes the editor up, so the panel goes while a name is typed.
                    if panel == .newCategory {
                        NewCategoryRow(onCreate: create, onCancel: { panel = .category })
                    } else if keyboardCovers || !nameFocused {
                        // Where the keyboard covers, the panel stays in the layout so nothing above
                        // it moves, and hides so it can't show above a shorter keyboard.
                        panelArea
                            .frame(maxWidth: .infinity)
                            .frame(height: Tokens.Size.editorPanel)
                            .opacity(nameFocused ? 0 : 1)
                            .accessibilityHidden(nameFocused)
                    }
                }
                .padding(.horizontal, Tokens.Space.gutter)
                .frame(minHeight: viewportHeight)
            }
            .scrollBounceBehavior(.basedOnSize)
            .ignoresSafeArea(.keyboard, edges: keyboardCovers ? .bottom : [])
            .onScrollGeometryChange(for: CGFloat.self) { $0.containerSize.height } action: { _, height in
                viewportHeight = height
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .close) { dismiss() }
                }
                if let session {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingDeleteDialog = true
                        } label: {
                            Image(systemName: "trash")
                        }
                        .tint(Tokens.Ink.destructive)
                        .accessibilityLabel("Delete")
                        .confirmationDialog(
                            deleteTitle(for: session), isPresented: $showingDeleteDialog, titleVisibility: .visible
                        ) {
                            deleteButtons(for: session)
                        } message: {
                            Text(deleteMessage(for: session))
                        }
                    }
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                }
                // A half-made category is finished or cancelled before the expense is saved.
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm, action: save)
                        .disabled(!canSave)
                        .confirmationDialog("", isPresented: $showingScopeDialog, titleVisibility: .hidden) {
                            scopeButtons
                        }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: panel) { _, newPanel in
            if newPanel != .keypad { nameFocused = false }
        }
        .onChange(of: nameFocused) { _, focused in
            if focused { panel = .keypad }
        }
    }

    // MARK: Pieces

    private var amountView: some View {
        Button {
            nameFocused = false
            panel = .keypad
        } label: {
            Text(draft.amountText(locale: locale))
                .font(Tokens.Text.editorAmount(size: amountSize))
                .foregroundStyle(draft.digits.isEmpty ? Tokens.Ink.tertiary : Tokens.Ink.primary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(Tokens.Scale.editorAmountMin)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Amount")
        .accessibilityValue(draft.amountText(locale: locale))
        .accessibilityHint("Opens the keypad")
    }

    private var nameField: some View {
        TextField("Name it", text: $draft.name)
            .font(Tokens.Text.editorName)
            .multilineTextAlignment(.center)
            .frame(minHeight: nameHeight)
            .focused($nameFocused)
            .submitLabel(.done)
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
            CategoryPicker(selection: $draft.categoryID, onNew: { panel = .newCategory })
        case .newCategory:
            EmptyView()
        }
    }

    // MARK: State

    /// The keyboard covers the editor at standard sizes. It can't while a category is made, where
    /// the row has to sit directly above the emoji keyboard, or at accessibility sizes, where it
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

    /// A category made in the editor is selected at once, and the list comes back.
    private func create(_ category: ExpenseCategory) {
        modelContext.insert(category)
        do {
            try modelContext.save()
        } catch {
            Self.logger.error("Saving a category failed: \(error)")
        }
        draft.categoryID = category.id
        panel = .category
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
            showingScopeDialog = true
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
            dismiss()
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
            Button("Delete \(draft.name)", role: .destructive) {
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
        session.isFirstCharge ? "Delete \(draft.name)?" : "\(draft.name) repeats \(repeatPhrase)."
    }

    private func deleteMessage(for session: EditSession) -> String {
        guard !session.isFirstCharge else { return "Every charge goes, past ones too." }
        let previous = session.previousChargeDate.map(shortDate) ?? ""
        return "Deleting future charges keeps \(previous) and earlier."
    }

    /// "every month", "every 3 months", "every week" — the trash dialog's own phrasing, apart
    /// from `repeatLabel`'s button-sized noun.
    private var repeatPhrase: String {
        if draft.interval == 1 {
            switch draft.unit {
            case .day: return "every day"
            case .week: return "every week"
            case .month: return "every month"
            case .year: return "every year"
            }
        }
        return "every \(draft.interval) \(draft.unit.rawValue)s"
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

    private func edit(_ session: EditSession, _ operation: (Expense, ExpenseCategory) throws -> Void) {
        guard let category = selectedCategory, let expense = fetchExpense(session.expenseID) else { return }
        performEdit { try operation(expense, category) }
    }

    private func performEdit(_ operation: () throws -> Void) {
        do {
            try operation()
            dismiss()
        } catch {
            Self.logger.error("Editing an expense failed: \(error)")
        }
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
    ExpenseEditor(today: Date())
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
    return ExpenseEditor(today: today, draft: draft)
        .modelContainer(container)
}

#Preview("Repeat panel") {
    ExpenseEditor(today: Date(), panel: .repeat)
        .modelContainer(previewContainer().0)
}

#Preview("Date panel") {
    ExpenseEditor(today: Date(), panel: .date)
        .modelContainer(previewContainer().0)
}

#Preview("Accessibility size") {
    let (container, category) = previewContainer()
    var draft = ExpenseDraft(today: Date(), calendar: .current)
    draft.press(.digit(9))
    draft.name = "Sofa"
    draft.categoryID = category.id
    return ExpenseEditor(today: Date(), draft: draft)
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
    return ExpenseEditor(today: Date(), session: session)
        .modelContainer(container)
}

#Preview("Editing, scope question") {
    let (container, category) = previewContainer()
    let session = previewEditSession(monthsAgo: 3, in: container, category: category)
    var draft = session.draft
    draft.digits = "75"
    return ExpenseEditor(today: Date(), draft: draft, session: session)
        .modelContainer(container)
}

#Preview("Editing, dark, accessibility size") {
    let (container, category) = previewContainer()
    let session = previewEditSession(monthsAgo: 0, in: container, category: category)
    return ExpenseEditor(today: Date(), session: session)
        .modelContainer(container)
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.accessibility3)
}
