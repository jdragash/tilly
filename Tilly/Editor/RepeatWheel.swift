import SwiftUI
import TillyCore

/// "Every", then interval, unit and end as three wheels. The end column rests on "no end" and
/// rolls into payment counts; a count is the only way to set an end. The caption under the
/// wheels always takes its line, so it appearing never moves them.
struct RepeatWheel: View {
    @Binding var draft: ExpenseDraft

    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    private static let intervals = Array(1...30)

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("Every")
                    .font(Tokens.Text.body)
                    .foregroundStyle(Tokens.Ink.secondary)
                wheel(selection: $draft.interval) {
                    ForEach(Self.intervals, id: \.self) { Text(String($0)).tag($0) }
                }
                .frame(width: Tokens.Size.wheelInterval)
                .accessibilityLabel("Interval")
                wheel(selection: $draft.unit) {
                    ForEach(RecurrenceUnit.allCases, id: \.self) { unit in
                        Text(unitName(unit)).tag(unit)
                    }
                }
                .frame(width: Tokens.Size.wheelUnit)
                .accessibilityLabel("Unit")
                // Takes what's left: "120 payments" is the widest row and must not truncate.
                // The lowest count offered is the open charge's own — editing never offers an
                // end before it.
                wheel(selection: $draft.paymentCount) {
                    Text("no end").tag(Int?.none)
                    ForEach(counts, id: \.self) { Text("\($0) payments").tag(Int?.some($0)) }
                }
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Ends after")
            }
            Text(draft.lastPaymentCaption(calendar: calendar, locale: locale) ?? " ")
                .font(Tokens.Text.caption)
                .foregroundStyle(Tokens.Ink.secondary)
        }
    }

    private func wheel<Value: Hashable, Content: View>(
        selection: Binding<Value>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Picker("", selection: selection, content: content)
            .pickerStyle(.wheel)
            .labelsHidden()
            .compositingGroup()
            .clipped()
    }

    private func unitName(_ unit: RecurrenceUnit) -> String {
        draft.interval == 1 ? unit.rawValue : unit.rawValue + "s"
    }

    private var counts: [Int] { Array(draft.minimumPaymentCount...120) }
}
