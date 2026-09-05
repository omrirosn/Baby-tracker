import Testing
@testable import RFIsSimple

/// Power Converter.
///
/// Reference values are the definitions themselves: 0 dBm = 1 mW and
/// 30 dBm = 1 W (spec §14), plus decade steps that follow from them.
struct PowerConversionTests {

    // MARK: - Normal cases

    @Test func zeroDBmIsOneMilliwatt() throws {
        let conversion = try PowerConversion.from(value: 0, unit: .dBm)
        #expect(isClose(conversion.watts, 1e-3))
        #expect(isClose(conversion.milliwatts, 1))
        #expect(isClose(conversion.microwatts, 1000))
        #expect(isClose(conversion.dBW, -30))
    }

    @Test func thirtyDBmIsOneWatt() throws {
        let conversion = try PowerConversion.from(value: 30, unit: .dBm)
        #expect(isClose(conversion.watts, 1))
        #expect(isClose(conversion.dBW, 0))
    }

    @Test func minusThirtyDBmIsOneMicrowatt() throws {
        let conversion = try PowerConversion.from(value: -30, unit: .dBm)
        #expect(isClose(conversion.watts, 1e-6))
        #expect(isClose(conversion.microwatts, 1))
    }

    /// Independently checked: 100 W is 20 dBW, and dBm is always 30 dB above dBW.
    @Test func hundredWattsIsFiftyDBm() throws {
        let conversion = try PowerConversion.from(value: 100, unit: .watt)
        #expect(isClose(conversion.dBm, 50))
        #expect(isClose(conversion.dBW, 20))
    }

    /// 200 mW: 10·log10(0.2) + 30 = 23.0103 dBm.
    @Test func twoHundredMilliwattsInDBm() throws {
        let conversion = try PowerConversion.from(value: 200, unit: .milliwatt)
        #expect(isClose(conversion.dBm, 23.010299956639813, relativeTolerance: 1e-12))
        #expect(isClose(conversion.watts, 0.2))
    }

    @Test(arguments: [-120.0, -30.0, 0.0, 13.0, 30.0, 60.0])
    func dBmSurvivesARoundTripThroughWatts(_ dBm: Double) throws {
        let conversion = try PowerConversion.from(value: dBm, unit: .dBm)
        let back = try PowerConversion.fromWatts(conversion.watts)
        #expect(isClose(back.dBm, dBm, relativeTolerance: 1e-12))
    }

    @Test func everyUnitAgreesOnTheSamePower() throws {
        let conversion = try PowerConversion.from(value: 1, unit: .watt)
        #expect(isClose(conversion.value(in: .dBm), 30))
        #expect(isClose(conversion.value(in: .dBW), 0))
        #expect(isClose(conversion.value(in: .watt), 1))
        #expect(isClose(conversion.value(in: .milliwatt), 1000))
        #expect(isClose(conversion.value(in: .microwatt), 1e6))
    }

    // MARK: - Boundaries

    /// Zero power is a real input, and its decibel value genuinely does not
    /// exist — the calculator reports that rather than showing -inf.
    @Test func zeroWattsHasNoDecibelValue() throws {
        let conversion = try PowerConversion.from(value: 0, unit: .watt)
        #expect(conversion.watts == 0)
        #expect(conversion.dBm == nil)
        #expect(conversion.dBW == nil)
        #expect(conversion.value(in: .milliwatt) == 0)
    }

    @Test func linearPowerPicksAReadableUnit() throws {
        #expect(try PowerConversion.from(value: 0.2, unit: .watt).preferredLinearUnit == .milliwatt)
        #expect(try PowerConversion.from(value: 5, unit: .watt).preferredLinearUnit == .watt)
        #expect(try PowerConversion.from(value: 2e-7, unit: .watt).preferredLinearUnit == .microwatt)
    }

    // MARK: - Invalid input

    @Test func negativeLinearPowerIsRejected() {
        #expect(throws: CalculationError.self) {
            _ = try PowerConversion.from(value: -1, unit: .watt)
        }
        #expect(throws: CalculationError.self) {
            _ = try PowerConversion.from(value: -0.001, unit: .milliwatt)
        }
    }

    @Test func negativeDecibelPowerIsAccepted() throws {
        let conversion = try PowerConversion.from(value: -174, unit: .dBm)
        #expect(conversion.watts > 0)
        #expect(isClose(conversion.dBm, -174, relativeTolerance: 1e-12))
    }

    @Test func absurdlyLargeDecibelValueIsRejectedRatherThanOverflowing() {
        #expect(throws: CalculationError.self) {
            _ = try PowerConversion.from(value: 4000, unit: .dBm)
        }
    }

    @Test func notANumberIsRejected() {
        #expect(throws: CalculationError.self) {
            _ = try PowerConversion.from(value: .nan, unit: .dBm)
        }
    }
}
