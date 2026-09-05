import Foundation

/// A unit belonging to one physical dimension.
///
/// Every dimension has a canonical SI base unit that all conversions pass
/// through. Calculations only ever see base units, so the maths is independent
/// of whatever the user happened to type into a field.
///
///     Dimension   Base unit
///     Power       watt (W)
///     Frequency   hertz (Hz)
///     Time        second (s)
///     Length      metre (m)
///
/// `rawValue` is the persistence key (ASCII, stable across releases) and is
/// deliberately kept separate from `symbol`, which is the display form and may
/// contain characters such as `µ`.
protocol PhysicalUnit: CaseIterable, Hashable, Identifiable, Sendable, RawRepresentable where RawValue == String {
    /// Human readable dimension name, used in accessibility labels.
    static var dimensionName: String { get }

    /// Units the app may choose between when it scales a result automatically.
    static var autoScaleCandidates: [Self] { get }

    /// Symbol shown next to a value, e.g. `MHz`.
    var symbol: String { get }

    /// Spoken form for VoiceOver, e.g. "megahertz".
    var accessibilityName: String { get }

    /// `true` for logarithmic units such as dBm. These are never auto-scaled
    /// and they accept negative values.
    var isLogarithmic: Bool { get }

    /// `true` when a negative number is physically meaningful in this unit.
    var allowsNegativeValues: Bool { get }

    /// Converts a value expressed in this unit into the dimension's base unit.
    func toBase(_ value: Double) -> Double

    /// Converts a value expressed in the dimension's base unit into this unit.
    func fromBase(_ base: Double) -> Double
}

extension PhysicalUnit {
    var id: String { rawValue }

    var isLogarithmic: Bool { false }

    /// Only a logarithmic scale gives meaning to a negative number: -10 dBm is
    /// a real power level, -10 mW is not.
    var allowsNegativeValues: Bool { isLogarithmic }

    static var autoScaleCandidates: [Self] { allCases.filter { !$0.isLogarithmic } }

    /// Multiplier that turns 1 of this unit into the base unit. Only meaningful
    /// for linear units, where `toBase` is a pure scaling.
    var linearFactor: Double { toBase(1) }
}

/// Picks display units so results read as "500 mW" rather than "0.0005 W".
enum UnitScaling {
    /// Returns the largest candidate unit that still displays `base` as a
    /// magnitude of at least 1, which is the usual engineering-notation rule.
    ///
    /// - Parameters:
    ///   - base: value in the dimension's base unit.
    ///   - fallback: unit used when `base` is zero, non-finite, or smaller than
    ///     every candidate can express with a magnitude of 1.
    static func preferredUnit<U: PhysicalUnit>(for base: Double, fallback: U) -> U {
        let candidates = U.autoScaleCandidates.filter { !$0.isLogarithmic }
        guard base.isFinite, base != 0 else { return fallback }

        let ascending = candidates.sorted { $0.linearFactor < $1.linearFactor }
        guard let smallest = ascending.first else { return fallback }

        var chosen = smallest
        for unit in ascending {
            if abs(unit.fromBase(base)) >= 1 {
                chosen = unit
            } else {
                break
            }
        }
        return chosen
    }
}
