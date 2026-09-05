import Testing
@testable import RFIsSimple

/// Frequency / Period / Wavelength.
///
/// Reference values follow from c = 299 792 458 m/s exactly, which makes the
/// free-space wavelength at 1 GHz 0.299 792 458 m (spec §14).
struct WaveCalculatorTests {

    // MARK: - Normal cases

    @Test func oneGigahertzInFreeSpace() throws {
        let solution = try WaveCalculator.solve(from: .frequency, value: 1e9)
        #expect(isClose(solution.wavelengthMetres, 0.299792458, relativeTolerance: 1e-12))
        #expect(isClose(solution.periodSeconds, 1e-9, relativeTolerance: 1e-12))
        #expect(isClose(solution.velocity, 299_792_458))
        #expect(isClose(solution.quarterWavelengthMetres, 0.0749481145, relativeTolerance: 1e-12))
    }

    /// 2.4 GHz: 299 792 458 / 2.4e9 = 0.124 913 524 m, the familiar 12.5 cm.
    @Test func twoPointFourGigahertz() throws {
        let solution = try WaveCalculator.solve(from: .frequency, value: 2.4e9)
        #expect(isClose(solution.wavelengthMetres, 0.12491352416666667, relativeTolerance: 1e-12))
    }

    @Test func solvingFromPeriod() throws {
        let solution = try WaveCalculator.solve(from: .period, value: 1e-6)
        #expect(isClose(solution.frequencyHz, 1e6, relativeTolerance: 1e-12))
        #expect(isClose(solution.wavelengthMetres, 299.792458, relativeTolerance: 1e-12))
    }

    @Test func solvingFromWavelength() throws {
        let solution = try WaveCalculator.solve(from: .wavelength, value: 0.125)
        #expect(isClose(solution.frequencyHz, 2_398_339_664, relativeTolerance: 1e-12))
        #expect(isClose(solution.periodSeconds, 0.125 / 299_792_458, relativeTolerance: 1e-12))
    }

    /// A velocity factor of 0.66 is typical of solid polyethylene coax:
    /// 0.66 · 299 792 458 / 100 MHz = 1.978 630 m.
    @Test func velocityFactorShortensTheWavelength() throws {
        let solution = try WaveCalculator.solve(from: .frequency, value: 100e6, velocityFactor: 0.66)
        #expect(isClose(solution.wavelengthMetres, 1.9786302228, relativeTolerance: 1e-12))
        #expect(isClose(solution.velocity, 197_863_022.28, relativeTolerance: 1e-12))
        // The period does not depend on the medium.
        #expect(isClose(solution.periodSeconds, 1e-8, relativeTolerance: 1e-12))
    }

    @Test(arguments: [1.0, 1e3, 13.56e6, 433.92e6, 2.4e9, 77e9])
    func frequencyToWavelengthAndBackIsStable(_ frequency: Double) throws {
        let forward = try WaveCalculator.solve(from: .frequency, value: frequency)
        let backward = try WaveCalculator.solve(from: .wavelength, value: forward.wavelengthMetres)
        #expect(isClose(backward.frequencyHz, frequency, relativeTolerance: 1e-12))
    }

    // MARK: - Unit handling

    @Test func unitsConvertBeforeTheCalculationSeesThem() throws {
        var input = MeasuredInput<FrequencyUnit>(text: "2.4", unit: .gigahertz, locale: testLocale)
        #expect(isClose(input.baseValue, 2.4e9))

        input.setUnit(.megahertz)
        #expect(input.text == "2400")
        #expect(isClose(input.baseValue, 2.4e9))

        let solution = try WaveCalculator.solve(from: .frequency, value: try #require(input.baseValue))
        #expect(isClose(solution.wavelengthMetres, 0.12491352416666667, relativeTolerance: 1e-12))
    }

    // MARK: - Invalid input

    @Test(arguments: [0.0, -1.0, -1e9])
    func nonPositiveFrequencyIsRejected(_ frequency: Double) {
        #expect(throws: CalculationError.self) {
            _ = try WaveCalculator.solve(from: .frequency, value: frequency)
        }
    }

    @Test func nonPositiveWavelengthAndPeriodAreRejected() {
        #expect(throws: CalculationError.self) {
            _ = try WaveCalculator.solve(from: .wavelength, value: 0)
        }
        #expect(throws: CalculationError.self) {
            _ = try WaveCalculator.solve(from: .period, value: -1)
        }
    }

    @Test(arguments: [0.0, -0.5])
    func nonPositiveVelocityFactorIsRejected(_ factor: Double) {
        #expect(throws: CalculationError.self) {
            _ = try WaveCalculator.solve(from: .frequency, value: 1e9, velocityFactor: factor)
        }
    }

    @Test func notANumberIsRejected() {
        #expect(throws: CalculationError.self) {
            _ = try WaveCalculator.solve(from: .frequency, value: .nan)
        }
        #expect(throws: CalculationError.self) {
            _ = try WaveCalculator.solve(from: .frequency, value: 1e9, velocityFactor: .infinity)
        }
    }

    /// Faster than light is legitimate for waveguide phase velocity, so it is
    /// flagged rather than rejected — the input is never silently changed.
    @Test func velocityFactorAboveOneWarnsButStillCalculates() throws {
        let solution = try WaveCalculator.solve(from: .frequency, value: 1e9, velocityFactor: 1.4)
        #expect(isClose(solution.wavelengthMetres, 0.299792458 * 1.4, relativeTolerance: 1e-12))
        #expect(WaveCalculator.velocityFactorIssue(1.4)?.severity == .warning)
        #expect(WaveCalculator.velocityFactorIssue(1.0) == nil)
        #expect(WaveCalculator.velocityFactorIssue(0.66) == nil)
    }
}
