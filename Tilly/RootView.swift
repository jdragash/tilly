import SwiftData
import SwiftUI

struct RootView: View {
    @Query private var expenses: [Expense]

    var body: some View {
        VStack {
            Text("Tilly")
                .font(Tokens.Text.amount)
                .foregroundStyle(Tokens.Ink.primary)
            Text("\(expenses.count) expenses")
                .font(Tokens.Text.caption)
                .foregroundStyle(Tokens.Ink.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Tokens.Surface.base)
    }
}

#Preview {
    RootView()
        .modelContainer(try! TillyStore.container(inMemory: true))
}
