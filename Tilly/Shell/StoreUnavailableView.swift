import SwiftUI

/// Shown instead of the timeline when the store won't open. It changes nothing: the file stays
/// where it is, as it is, so a later build (or a person with the file) can still read it.
struct StoreUnavailableView: View {
    var body: some View {
        VStack(spacing: Tokens.Space.tight) {
            Text("Your bills couldn’t be opened")
                .font(Tokens.Text.emptyTitle)
                .foregroundStyle(Tokens.Ink.primary)
            Text("Nothing has been changed or deleted. Close Tilly and open it again to try once more.")
                .font(Tokens.Text.name)
                .foregroundStyle(Tokens.Ink.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, Tokens.Space.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .drawnPaper()
    }
}

#Preview {
    StoreUnavailableView()
}
