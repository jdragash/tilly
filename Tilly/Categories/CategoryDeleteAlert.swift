import SwiftData
import SwiftUI

/// The one alert that deletes a category and its bills, wherever the delete starts: the category
/// sheet's trash, or the bill editor's long-press. Set `category` to present it; the delete runs
/// through `CategoryRemoval`, then `onDeleted` gets the deleted category's id.
private struct CategoryDeleteAlert: ViewModifier {
    @Binding var category: ExpenseCategory?
    let onDeleted: (UUID) -> Void

    @Environment(\.modelContext) private var modelContext
    /// The words, kept apart from the model so the alert still reads while it goes, after the delete.
    @State private var words = Words(name: "", billCount: 0)

    private struct Words {
        let name: String
        let billCount: Int

        var title: String { "Delete “\(name)”?" }

        var message: String {
            switch billCount {
            case 0: "No bills use it."
            case 1: "Its bill goes too, past and future. This can’t be undone."
            default: "Its \(billCount) bills go too, past and future. This can’t be undone."
            }
        }

        var button: String {
            switch billCount {
            case 0: "Delete Category"
            case 1: "Delete Category and Bill"
            default: "Delete Category and Bills"
            }
        }
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: category) { _, new in
                if let new { words = Words(name: new.name, billCount: CategoryRemoval.billCount(of: new)) }
            }
            .alert(
                words.title,
                isPresented: Binding(get: { category != nil }, set: { if !$0 { category = nil } })
            ) {
                Button(words.button, role: .destructive, action: delete)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(words.message)
            }
    }

    private func delete() {
        guard let target = category else { return }
        let id = target.id
        try? CategoryRemoval.delete(target, context: modelContext)
        category = nil
        onDeleted(id)
    }
}

extension View {
    /// Asks, then deletes `category` with its bills. `onDeleted` runs after, with the category's id.
    func categoryDeleteAlert(for category: Binding<ExpenseCategory?>, onDeleted: @escaping (UUID) -> Void) -> some View {
        modifier(CategoryDeleteAlert(category: category, onDeleted: onDeleted))
    }
}
