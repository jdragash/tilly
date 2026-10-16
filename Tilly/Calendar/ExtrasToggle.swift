import SwiftUI

/// "All" / "Extras": a stock segmented `Picker`, under the top row's trailing end at every
/// Calendar level, floating over the pinned header on the timeline. One setting, held across the
/// levels and across launches, so the year, a month and the days always show the same charges.
/// See "The calendar" in `docs/DESIGN.md`.
///
/// Not on glass: the control draws its own track, and inside a glass capsule it read as a pill in
/// a pill, 37pt tall, taller than the title line beside it. Alone it is 32pt and sits within it.
struct ExtrasToggle: View {
    @Binding var extrasOnly: Bool

    var body: some View {
        Picker("Show", selection: $extrasOnly) {
            Text("All").tag(false)
            Text("Extras").tag(true)
        }
        .pickerStyle(.segmented)
        .fixedSize()
        // A fixed-height control beside the title, as the glass pair is a fixed height.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}
