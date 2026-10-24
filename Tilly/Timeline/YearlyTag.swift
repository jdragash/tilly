import SwiftUI

/// "Yearly", outlined in `Drawn.ink2`, after the date.
struct YearlyTag: View {
    var body: some View {
        Text("Yearly")
            .font(Tokens.Text.tag)
            .foregroundStyle(Tokens.Drawn.ink2)
            .padding(.horizontal, Tokens.Space.tagHorizontal)
            .padding(.vertical, Tokens.Space.tagVertical)
            .overlay {
                RoundedRectangle(cornerRadius: Tokens.Radius.tag, style: .continuous)
                    .strokeBorder(Tokens.Drawn.ink2, lineWidth: Tokens.Stroke.tag)
            }
    }
}
