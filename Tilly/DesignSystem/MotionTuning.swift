import Foundation
import Observation
import SwiftUI

/// One tunable value: its key, label, default and range. The defaults are the prototype's.
struct MotionValue: Identifiable, Sendable {
    let id: String            // stable key, e.g. "sheetExit"
    let label: String         // "Sheet exit"
    let defaultValue: Double
    let range: ClosedRange<Double>
    let step: Double
}

/// The card motion's values, live. Release builds read the defaults and nothing else; a debug build
/// keeps what's set in Settings across launches, so a value can be tuned on the phone and then copied
/// into `Tokens.swift`.
@MainActor @Observable
final class MotionTuning {
    static let shared = MotionTuning()

    /// The catalogue, in the order the panel lists it.
    static let values: [MotionValue] = [
        MotionValue(id: "sheetExit", label: "Sheet exit", defaultValue: 0.55, range: 0.2...1.2, step: 0.01),
        MotionValue(id: "sheetContentsFade", label: "Sheet contents fade", defaultValue: 0.14, range: 0...0.4, step: 0.01),
        MotionValue(id: "sheetRise", label: "Sheet rise", defaultValue: 0.45, range: 0.2...1, step: 0.01),
        MotionValue(id: "sheetRiseBounce", label: "Sheet rise bounce", defaultValue: 0.1, range: 0...0.5, step: 0.01),
        MotionValue(id: "landingRowOffset", label: "Landing row offset", defaultValue: 120, range: 0...300, step: 1),
        MotionValue(id: "dayDrop", label: "Day drop", defaultValue: 48, range: 0...120, step: 1),
        MotionValue(id: "dayDropDuration", label: "Day drop duration", defaultValue: 0.45, range: 0.2...1, step: 0.01),
        MotionValue(id: "dayDropBounce", label: "Day drop bounce", defaultValue: 0.3, range: 0...0.6, step: 0.01),
        // The drawn look, also tunable here: how far an edge wanders and how far a symbol is moved.
        MotionValue(id: "edgeWobble", label: "Edge wobble", defaultValue: 0.6, range: 0...4, step: 0.1),
        MotionValue(id: "roughAmount", label: "Symbol roughness", defaultValue: 1.8, range: 0...4, step: 0.1),
        // Where pictures boil: 0 nowhere, 1 in the editor and its pickers, 2 everywhere.
        MotionValue(id: "boil", label: "Boil", defaultValue: 2, range: 0...2, step: 1),
    ]

    private let defaults: UserDefaults
    /// What's been changed from its default, by id. Mirrors `UserDefaults` under "motion.<id>".
    private var changed: [String: Double] = [:]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        #if DEBUG
        for value in Self.values {
            if let stored = defaults.object(forKey: Self.key(value.id)) as? Double {
                changed[value.id] = stored
            }
        }
        #endif
    }

    /// The value for `id`: what's been tuned in a debug build, otherwise its default.
    subscript(_ id: String) -> Double {
        get {
            #if DEBUG
            if let tuned = changed[id] { return tuned }
            #endif
            return Self.values.first { $0.id == id }?.defaultValue ?? 0
        }
        set {
            #if DEBUG
            guard let value = Self.values.first(where: { $0.id == id }) else { return }
            let clamped = min(max(newValue, value.range.lowerBound), value.range.upperBound)
            if clamped == value.defaultValue {
                changed[id] = nil
                defaults.removeObject(forKey: Self.key(id))
            } else {
                changed[id] = clamped
                defaults.set(clamped, forKey: Self.key(id))
            }
            #endif
        }
    }

    /// Every value as it stands now, tuned or default, for saving a setup.
    func snapshot() -> [String: Double] {
        Dictionary(uniqueKeysWithValues: Self.values.map { ($0.id, self[$0.id]) })
    }

    /// Takes every value in `setup`, and leaves the rest as they are.
    func apply(_ setup: [String: Double]) {
        for (id, value) in setup { self[id] = value }
    }

    /// Every value back to its default, and what was saved removed.
    func reset() {
        #if DEBUG
        for value in Self.values { defaults.removeObject(forKey: Self.key(value.id)) }
        changed = [:]
        #endif
    }

    /// `static let sheetExit: TimeInterval = 0.55` per changed value, to paste into `Tokens.swift`.
    var swiftSnippet: String {
        Self.values.compactMap { value in
            guard let tuned = changed[value.id] else { return nil }
            return "static let \(value.id): \(Self.swiftType(of: value.id)) = \(Self.literal(tuned))"
        }.joined(separator: "\n")
    }

    private static func key(_ id: String) -> String { "motion.\(id)" }

    private static func swiftType(of id: String) -> String {
        switch id {
        case "sheetExit", "sheetContentsFade", "sheetRise", "dayDropDuration":
            "TimeInterval"
        case "landingRowOffset", "dayDrop":
            "CGFloat"
        default:
            "Double"
        }
    }

    /// 0.4 not 0.40000000000000002, and 120 not 120.0.
    private static func literal(_ value: Double) -> String {
        let text = String(format: "%.4f", value)
        var trimmed = text
        while trimmed.hasSuffix("0") { trimmed.removeLast() }
        if trimmed.hasSuffix(".") { trimmed.removeLast() }
        return trimmed
    }
}

extension Tokens.Motion {
    /// The card's motion. Read in `body`, so a change in the debug panel redraws what uses it.
    @MainActor enum Card {
        static var sheetExit: TimeInterval { MotionTuning.shared["sheetExit"] }
        static var sheetContentsFade: TimeInterval { MotionTuning.shared["sheetContentsFade"] }
        static var sheetRise: TimeInterval { MotionTuning.shared["sheetRise"] }
        static var sheetRiseBounce: Double { MotionTuning.shared["sheetRiseBounce"] }
        /// A jumped-to row's top, under its pinned header.
        static var landingRowOffset: CGFloat { CGFloat(MotionTuning.shared["landingRowOffset"]) }
        /// The calendar month's and the year's drop of a saved charge into its day.
        static var dayDrop: CGFloat { CGFloat(MotionTuning.shared["dayDrop"]) }
        static var dayDropDuration: TimeInterval { MotionTuning.shared["dayDropDuration"] }
        static var dayDropBounce: Double { MotionTuning.shared["dayDropBounce"] }
    }
}
