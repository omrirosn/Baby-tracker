import Foundation
import Testing
@testable import RFIsSimple

/// The unit layer every calculator sits on (spec §14 asks for unit-conversion
/// tests alongside the calculation tests).
struct UnitConversionTests {

    // MARK: - Exact factors

    @Test func frequencyFactors() {
        #expect(FrequencyUnit.hertz.toBase(1) == 1)
        #expect(FrequencyUnit.kilohertz.toBase(1) == 1e3)
        #expect(FrequencyUnit.megahertz.toBase(1) == 1e6)
        #expect(FrequencyUnit.gigahertz.toBase(1) == 1e9)
        #expect(FrequencyUnit.terahertz.toBase(1) == 1e12)
    }

    @Test func timeFactors() {
        #expect(TimeUnit.second.toBase(1) == 1)
        #expect(isClose(TimeUnit.millisecond.toBase(1), 1e-3))
        #expect(isClose(TimeUnit.microsecond.toBase(1), 1e-6))
        #expect(isClose(TimeUnit.nanosecond.toBase(1), 1e-9))
        #expect(isClose(TimeUnit.picosecond.toBase(1), 1e-12))
    }

    /// Imperial lengths use the international definitions, which are exact.
    @Test func lengthFactors() {
        #expect(isClose(LengthUnit.millimetre.toBase(1), 1e-3))
        #expect(isClose(LengthUnit.centimetre.toBase(1), 1e-2))
        #expect(LengthUnit.metre.toBase(1) == 1)
        #expect(LengthUnit.kilometre.toBase(1) == 1e3)
        #expect(LengthUnit.inch.toBase(1) == 0.0254)
        #expect(LengthUnit.foot.toBase(1) == 0.3048)
        #expect(LengthUnit.mile.toBase(1) == 1609.344)
    }

    @Test func powerFactors() {
        #expect(PowerUnit.watt.toBase(1) == 1)
        #expect(isClose(PowerUnit.milliwatt.toBase(1), 1e-3))
        #expect(isClose(PowerUnit.microwatt.toBase(1), 1e-6))
        #expect(isClose(PowerUnit.dBm.toBase(0), 1e-3))
        #expect(isClose(PowerUnit.dBW.toBase(0), 1))
    }

    // MARK: - Round trips

    @Test(arguments: [1.0, 0.5, 12_345.678, 1e-9, 6.02e12])
    func everyLinearUnitRoundTrips(_ value: Double) {
        for unit in FrequencyUnit.allCases {
            #expect(isClose(unit.fromBase(unit.toBase(value)), value, relativeTolerance: 1e-12))
        }
        for unit in TimeUnit.allCases {
            #expect(isClose(unit.fromBase(unit.toBase(value)), value, relativeTolerance: 1e-12))
        }
        for unit in LengthUnit.allCases {
            #expect(isClose(unit.fromBase(unit.toBase(value)), value, relativeTolerance: 1e-12))
        }
    }

    @Test(arguments: [-120.0, -30.0, 0.0, 27.0, 60.0])
    func decibelUnitsRoundTrip(_ value: Double) {
        #expect(isClose(PowerUnit.dBm.fromBase(PowerUnit.dBm.toBase(value)), value, relativeTolerance: 1e-12))
        #expect(isClose(PowerUnit.dBW.fromBase(PowerUnit.dBW.toBase(value)), value, relativeTolerance: 1e-12))
    }

    // MARK: - Automatic scaling

    @Test func scalingPicksTheUnitThatReadsBest() {
        #expect(UnitScaling.preferredUnit(for: 0.2, fallback: PowerUnit.watt) == .milliwatt)
        #expect(UnitScaling.preferredUnit(for: 5, fallback: PowerUnit.watt) == .watt)
        #expect(UnitScaling.preferredUnit(for: 1500, fallback: FrequencyUnit.hertz) == .kilohertz)
        #expect(UnitScaling.preferredUnit(for: 2.4e9, fallback: FrequencyUnit.hertz) == .gigahertz)
        #expect(UnitScaling.preferredUnit(for: 0.05, fallback: LengthUnit.metre) == .centimetre)
        #expect(UnitScaling.preferredUnit(for: 1e-9, fallback: TimeUnit.second) == .nanosecond)
    }

    @Test func scalingFallsBackForZeroAndNonFiniteValues() {
        #expect(UnitScaling.preferredUnit(for: 0, fallback: PowerUnit.watt) == .watt)
        #expect(UnitScaling.preferredUnit(for: .nan, fallback: LengthUnit.metre) == .metre)
        #expect(UnitScaling.preferredUnit(for: .infinity, fallback: LengthUnit.metre) == .metre)
    }

    /// Logarithmic units must never be chosen automatically — rescaling a dB
    /// value is meaningless.
    @Test func scalingNeverPicksADecibelUnit() {
        #expect(PowerUnit.autoScaleCandidates.allSatisfy { !$0.isLogarithmic })
        #expect(UnitScaling.preferredUnit(for: 1e-12, fallback: PowerUnit.watt).isLogarithmic == false)
    }

    /// Imperial units stay out of automatic scaling so a metric result never
    /// turns into inches on its own.
    @Test func scalingKeepsToMetricLengths() {
        #expect(LengthUnit.autoScaleCandidates == [.millimetre, .centimetre, .metre, .kilometre])
    }

    // MARK: - Persistence identity

    @Test func rawValuesAreStableAndAscii() {
        for unit in PowerUnit.allCases {
            #expect(unit.rawValue.allSatisfy(\.isASCII))
            #expect(PowerUnit(rawValue: unit.rawValue) == unit)
        }
        for unit in LengthUnit.allCases {
            #expect(unit.rawValue.allSatisfy(\.isASCII))
        }
        // The display symbol may be non-ASCII where the SI symbol is.
        #expect(PowerUnit.microwatt.symbol == "µW")
        #expect(PowerUnit.microwatt.rawValue == "uW")
    }

    @Test func onlyDecibelUnitsAcceptNegativeValues() {
        #expect(PowerUnit.dBm.allowsNegativeValues)
        #expect(PowerUnit.dBW.allowsNegativeValues)
        #expect(PowerUnit.watt.allowsNegativeValues == false)
        #expect(FrequencyUnit.megahertz.allowsNegativeValues == false)
        #expect(LengthUnit.metre.allowsNegativeValues == false)
    }
}
