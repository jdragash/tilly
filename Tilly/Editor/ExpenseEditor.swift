import SwiftData
import SwiftUI
import TillyCore
import os

/// The sheet for adding an expense. The amount is the screen: the keypad is up when it opens,
/// the name sits under it, and date, repeat and category open in the keypad's place at the
/// keypad's height, so the amount never moves. See "The editor" in `docs/DESIGN.md`.
struct ExpenseEditor: View {
    let today: Date

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]

    @State private var draft: ExpenseDraft
    @State private var panel: EditorPanel
    @FocusState private var nameFocused: Bool
    @ScaledMetric(relativeTo: .largeTitle) private var amountSize = Tokens.Size.editorAmountSize
    @State private var viewportHeight: CGFloat = 0

    private static let logger = Logger(subsystem: "com.jdragash.Tilly", category: "ExpenseEditor")

    /// `draft` and `panel` exist so previews can open the editor part-way through.
    init(today: Date, draft: ExpenseDraft? = nil, panel: EditorPanel = .keypad) {
        self.today = today
        _draft = State(initialValue: draft ?? ExpenseDraft(today: today, calendar: .current))
        _panel = State(initialValue: panel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Tokens.Space.section) {
                    // The amount and name are the flexible part: they centre in whatever height the
                    // buttons and panel leave, so those sit on Save. Accessibility sizes overflow
                    // instead, and scroll.
                    VStack(spacing: Tokens.Space.section) {
                        amountView
                        nameField
                    }
                    .frame(maxHeight: .infinity)
                    EditorButtonRow(draft: draft, category: selectedCategory, today: today, panel: $panel)
                    if !nameFocused {
                        panelArea
                            .frame(maxWidth: .infinity)
                            .frame(height: Tokens.Size.editorPanel)
                    }
                }
                .padding(.horizontal, Tokens.Space.gutter)
                .frame(minHeight: viewportHeight)
            }
            .scrollBounceBehavior(.basedOnSize)
            .onScrollGeometryChange(for: CGFloat.self) { $0.containerSize.height } action: { _, height in
                viewportHeight = height
            }
            .safeAreaInset(edge: .bottom) { saveButton }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .close) { dismiss() }
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
        case .category, .newCategory:
            // Filled in by the next step.
            Text("Category")
                .font(Tokens.Text.body)
                .foregroundStyle(Tokens.Ink.secondary)
        }
    }

    private var saveButton: some View {
        Button(action: save) {
            Text("Save")
                .frame(maxWidth: .infinity)
                // The tint is `Ink.primary`, which is white in dark mode, so an enabled label needs
                // the opposite ground or it vanishes into the button. Forcing it always would also
                // override the disabled dimming, so a disabled one steps back instead.
                .foregroundStyle(isValid ? Tokens.Surface.base : Tokens.Ink.tertiary)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.extraLarge)
        .tint(Tokens.Ink.primary)
        .disabled(!isValid)
        .padding(.horizontal, Tokens.Space.gutter)
        .padding(.top, Tokens.Space.tight)
    }

    // MARK: State

    private var selectedCategory: ExpenseCategory? {
        categories.first { $0.id == draft.categoryID }
    }

    private var isValid: Bool {
        draft.isValid { id in categories.contains { $0.id == id } }
    }

    private var dateBinding: Binding<Date> {
        Binding(
            get: { draft.date },
            set: { draft.date = calendar.startOfDay(for: $0) }
        )
    }

    private func save() {
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
