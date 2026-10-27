import SwiftUI

/// After a sort, a dark capsule saying what it sorted by, with `Undo`, the only way back from it.
/// The page that sorted holds `SortUndo.Shown` and clears it after `Tokens.SettingsCategories.undoSeconds`.
struct SortUndo: View {
    struct Shown: Equatable {
        let sort: CategorySort
        /// The order the sort replaced, for `CategoryOrdering.restore`.
        let previous: [UUID]
        /// Tells two sorts by the same key apart, so the older one's timer leaves the newer alone.
        let id = UUID()
    }

    let shown: Shown
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Text("Sorted by \(shown.sort.title.lowercased()) · ")
            Button("Undo", action: onUndo)
                .underline()
                .buttonStyle(.plain)
        }
        .font(Tokens.SettingsCategories.undoFont)
        .foregroundStyle(Tokens.SettingsCategories.undoInk)
        .padding(.vertical, Tokens.SettingsCategories.undoVertical)
        .padding(.horizontal, Tokens.SettingsCategories.undoHorizontal)
        .background(Tokens.SettingsCategories.undoGround, in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: "Undo", onUndo)
    }
}
