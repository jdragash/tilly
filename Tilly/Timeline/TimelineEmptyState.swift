import SwiftUI

/// First run. Categories ship empty, so this screen is doing the teaching — see "Empty
/// states" in `docs/DESIGN.md`.
struct TimelineEmptyState: View {
    var body: some View {
        VStack(spacing: Tokens.Space.tight) {
            Text("Nothing recurring yet")
                .font(Tokens.Text.emptyTitle)
                .foregroundStyle(Tokens.Ink.primary)
            Text("Add a bill or a subscription and it shows up here before it goes out.")
                .font(Tokens.Text.name)
                .foregroundStyle(Tokens.Ink.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Tokens.Space.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Tokens.Surface.base)
    }
}

#Preview {
    TimelineEmptyState()
}
