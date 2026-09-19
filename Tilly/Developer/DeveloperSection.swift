#if DEBUG
import SwiftUI

/// The last section of Settings in debug builds: switch between your own data and sample
/// scenarios, reset the one you're in, or forget the saved place. Loading rebuilds the
/// timeline, which closes Settings.
struct DeveloperSection: View {
    let session: DeveloperSession

    var body: some View {
        Section {
            Picker("Data", selection: Binding(get: { session.scenario }, set: { session.load($0) })) {
                ForEach(DeveloperScenario.allCases) { scenario in
                    Text(scenario.title).tag(scenario)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
            if session.scenario.isSample {
                Button("Reset scenario") { session.load(session.scenario) }
            }
            Button("Forget my place") { session.forgetPlace() }
        } header: {
            Text("Developer")
        } footer: {
            Text("Only in builds run from Xcode. Sample data lives in its own store; your data is never touched.")
        }
    }
}
#endif
