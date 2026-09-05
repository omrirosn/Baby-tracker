import Foundation

/// A single power level, held in watts, that can be read back in any power unit.
///
/// Implemented relationships (all standard definitions):
///
///     P(dBm) = 10 · log10( P(W) / 1 mW )
///     P(dBW) = 10 · log10( P(W) / 1 W )
///     P(W)   = 10 ^ ( P(dBm) / 10 ) · 1 mW
///
/// Unit convention: the stored value is always watts. Reference points that
/// follow from the definitions: 0 dBm = 1 mW, 30 dBm = 1 W, -30 dBm = 1 µW.
struct PowerConversion: Equatable, Hashable, Sendable {
    /// The power level in watts. Zero is allowed and means "no power", for
    /// which the logarithmic units have no value.
    let watts: Double

    private init(watts: Double) {
        self.watts = watts
    }

    /// Builds a conversion from a value the user entered in `unit`.
    ///
    /// - Throws: `CalculationError.mustBeNonNegative` for a negative linear
    ///   power, and `.outOfRange` when a dB value is so large that the linear
    ///   equivalent overflows a `Double` (roughly above +3085 dBm).
    static func from(value: Double, unit: PowerUnit) throws -> PowerConversion {
        guard value.isFinite else {
            throw CalculationError.notANumber(quantity: "Power")
        }
        if !unit.allowsNegativeValues && value < 0 {
            throw CalculationError.mustBeNonNegative(quantity: "Power in \(unit.symbol)")
        }

        let watts = unit.toBase(value)
        guard watts.isFinite else {
            throw CalculationError.outOfRange(
                quantity: "Power",
                requirement: "small enough to express in watts"
            )
        }
        return PowerConversion(watts: watts)
    }

    /// Builds a conversion from a power already expressed in watts.
    static func fromWatts(_ watts: Double) throws -> PowerConversion {
        try from(value: watts, unit: .watt)
    }

    /// The power expressed in `unit`.
    ///
    /// Returns `nil` where the value does not exist: the logarithm of zero
    /// power is undefined, so 0 W has no dBm or dBW equivalent. Callers show
    /// this as "—" rather than as `-inf`.
    func value(in unit: PowerUnit) -> Double? {
        if unit.isLogarithmic && watts <= 0 { return nil }
        let converted = unit.fromBase(watts)
        return converted.isFinite ? converted : nil
    }

    var dBm: Double? { value(in: .dBm) }
    var dBW: Double? { value(in: .dBW) }
    var milliwatts: Double { watts * 1e3 }
    var microwatts: Double { watts * 1e6 }

    /// The linear unit that displays this power most readably.
    var preferredLinearUnit: PowerUnit {
        UnitScaling.preferredUnit(for: watts, fallback: .watt)
    }

    /// Every unit except the one the value was entered in, in a stable order.
    static func complementaryUnits(excluding unit: PowerUnit) -> [PowerUnit] {
        PowerUnit.allCases.filter { $0 != unit }
    }
}
