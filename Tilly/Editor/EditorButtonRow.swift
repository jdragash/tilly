import SwiftUI

/// Which panel fills the area under the buttons. Tapping the open panel's button again
/// returns to the keypad.
enum EditorPanel: Equatable {
    case keypad, date, `repeat`, category, newCategory
}

/// Date, category and repeat as three equal thirds; the icon says what kind of thing, the
/// label says its value. At accessibility text sizes they stack, full width, in the same order.
/// See "Three buttons" in `docs/DESIGN.md`.
struct EditorButtonRow: View {
    let draft: ExpenseDraft
    let category: ExpenseCategory?
    let today: Date
    @Binding var panel: EditorPanel

    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Tokens.Space.tight))
            : AnyLayout(HStackLayout(spacing: Tokens.Space.tight))
        layout {
            dateButton
            categoryButton
            repeatButton
        }
    }

    private var dateButton: some View {
        button(for: .date, isOpen: panel == .date, label: "Date", value: dateValue) {
            Image(systemName: draft.isFuture(today: today, calendar: calendar) ? "calendar.badge.clock" : "calendar")
                .foregroundStyle(Tokens.Ink.secondary)
            Text(dateValue)
        }
    }

    private var repeatButton: some View {
        button(for: .repeat, isOpen: panel == .repeat, label: "Repeat", value: repeatValue) {
            Image(systemName: draft.paymentCount == nil ? "repeat" : "arrow.right.to.line")
                .foregroundStyle(Tokens.Ink.secondary)
            Text(repeatValue)
        }
    }

    private var categoryButton: some View {
        button(
            for: .category,
            isOpen: panel == .category || panel == .newCategory,
            label: "Category",
            value: category?.name ?? "None"
        ) {
            if let category {
                Text(category.emoji)
                    .font(Tokens.Text.rowEmoji)
            } else {
                Image(systemName: "tag")
                    .foregroundStyle(Tokens.Ink.secondary)
            }
        }
    }

    /// Tapping the open panel's button puts the keypad back, except while a category is being
    /// made: there the category button goes back to the list, which is how that is cancelled.
    private func select(_ target: EditorPanel, isOpen: Bool) {
        if panel == .newCategory, target == .category {
            panel = .category
        } else {
            panel = isOpen ? .keypad : target
        }
    }

    private var dateValue: String { draft.dateLabel(calendar: calendar, locale: locale) }
    private var repeatValue: String { draft.repeatLabel(calendar: calendar, locale: locale) }

    private func button<Content: View>(
        for target: EditorPanel,
        isOpen: Bool,
        label: String,
        value: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: Tokens.Radius.editorButton, style: .continuous)
        return Button {
            select(target, isOpen: isOpen)
        } label: {
            HStack(spacing: Tokens.Space.tight) {
                content()
            }
            .font(Tokens.Text.editorButton)
            .foregroundStyle(Tokens.Ink.primary)
            .lineLimit(1)
            .minimumScaleFactor(Tokens.Scale.editorButtonMin)
            .frame(maxWidth: .infinity, minHeight: Tokens.Size.editorButton)
            .background(isOpen ? Tokens.Surface.editorButtonActive : Color.clear, in: shape)
            .overlay(shape.strokeBorder(Tokens.Ink.quaternary, lineWidth: Tokens.Size.editorButtonStroke))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(value)
        .accessibilityAddTraits(isOpen ? .isSelected : [])
    }
}
