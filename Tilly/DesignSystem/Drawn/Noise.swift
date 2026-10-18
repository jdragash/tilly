import Foundation

/// A small seeded generator (mulberry32) so a drawn edge is the same on every launch.
nonisolated struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt32

    init(seed: UInt64) { state = UInt32(truncatingIfNeeded: seed ^ (seed >> 32)) }

    /// 0..<1, as the prototype's `prng`.
    mutating func unit() -> Double {
        state = state &+ 0x6D2B_79F5
        var t = (state ^ (state >> 15)) &* (1 | state)
        t = (t &+ ((t ^ (t >> 7)) &* (61 | t))) ^ t
        return Double((t ^ (t >> 14))) / 4_294_967_296
    }

    mutating func next() -> UInt64 {
        (UInt64(unit() * 4_294_967_296) << 32) | UInt64(unit() * 4_294_967_296)
    }
}

/// Smooth one-dimensional noise in -1...1: three sines of random phase and frequency, as the
/// prototype's `smooth`. Along a card's edge it makes the line wander rather than shake.
nonisolated struct SmoothNoise {
    private let terms: [(frequency: Double, phase: Double, amplitude: Double)]

    init(seed: UInt64, frequency: Double) {
        var generator = SeededGenerator(seed: seed)
        terms = (0..<3).map { index in
            (
                frequency * (0.55 + generator.unit() * 0.9) * Double(index + 1) * 0.8,
                generator.unit() * 6.283,
                1 / Double(index + 1)
            )
        }
    }

    func callAsFunction(_ t: Double) -> Double {
        terms.reduce(0) { $0 + $1.amplitude * sin(t * $1.frequency + $1.phase) } / 1.83
    }
}

/// A seed that is the same on every launch, from text such as an occurrence's id. `hashValue`
/// is not: it changes per process.
nonisolated func stableSeed(_ text: String) -> UInt64 {
    var hash: UInt64 = 0xcbf2_9ce4_8422_2325
    for byte in text.utf8 {
        hash ^= UInt64(byte)
        hash = hash &* 0x100_0000_01b3
    }
    return hash
}
