#if DEBUG
import SwiftUI

/// The last section of Settings in debug builds: switch between your own data and sample
/// scenarios, reset the one you're in, or forget the saved place. Each rebuilds the timeline,
/// which closes Settings.
struct DeveloperSection: View {
    let session: DeveloperSession

    var body: some View {
        Group {
            developer
            landing
            MotionTuningSection()
        }
    }

    /// Until a landing jumps for itself (step 6 of the card-motion plan removes these).
    private var landing: some View {
        Section {
            Button("Jump to a charge this month") { jump(monthsBack: 0) }
            Button("Jump to a charge two years back") { jump(monthsBack: 24) }
            Button("Let the held row go") { jump(monthsBack: nil) }
        } header: {
            Text("Landing")
        } footer: {
            Text("Holds a charge's row closed and empty, and puts it under its month's header.")
        }
    }

    private func jump(monthsBack: Int?) {
        NotificationCenter.default.post(
            name: .debugLandingJump, object: nil,
            userInfo: monthsBack.map { ["monthsBack": $0] }
        )
    }

    private var developer: some View {
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
extension Notification.Name {
    /// The Developer section's landing jump; `userInfo["monthsBack"]` is an `Int`, or absent to let go.
    static let debugLandingJump = Notification.Name("tillyDebugLandingJump")
}
#endif
