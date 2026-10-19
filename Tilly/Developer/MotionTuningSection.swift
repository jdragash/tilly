#if DEBUG
import SwiftUI
import UIKit

/// Every value of the card's motion as a slider, live, so a feel can be tuned on the phone and the
/// result copied into `Tokens.swift`.
struct MotionTuningSection: View {
    @State private var tuning = MotionTuning.shared

    var body: some View {
        Section {
            ForEach(MotionTuning.values) { value in
                VStack(alignment: .leading, spacing: Tokens.Space.tight) {
                    HStack {
                        Text(value.label)
                        Spacer()
                        Text(tuning[value.id], format: .number.precision(.fractionLength(0...3)))
                            .monospacedDigit()
                            .foregroundStyle(Tokens.Ink.secondary)
                    }
                    Slider(
                        value: Binding(get: { tuning[value.id] }, set: { tuning[value.id] = $0 }),
                        in: value.range, step: value.step
                    )
                }
            }
            Button("Reset motion") { tuning.reset() }
            Button("Copy changed values") { UIPasteboard.general.string = tuning.swiftSnippet }
        } header: {
            Text("Motion")
        } footer: {
            Text("Live, in this build only. Copy what you like into Tokens.swift.")
        }
    }
}
#endif
