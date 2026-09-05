import Testing
@testable import RFIsSimple

/// Reflection Converter.
///
/// The reference values are the ones printed in every VSWR table:
/// VSWR 1.5 → 13.98 dB return loss, 4% reflected, 0.18 dB mismatch loss;
/// VSWR 2 → 9.54 dB, 11.1%, 0.51 dB.
struct ReflectionCalculatorTests {

    // MARK: - Normal cases

    /// Spec §14: VSWR 1 is Γ = 0 with infinite return loss.
    @Test func perfectMatch() throws {
        let solution = try ReflectionCalculator.solve(from: .vswr, value: 1)
        #expect(isClose(solution.gamma, 0))
        #expect(solution.returnLossDB == nil)
        #expect(isClose(solution.vswr, 1))
        #expect(isClose(solution.reflectedPowerPercent, 0))
        #expect(isClose(solution.transmittedPowerPercent, 100))
        #expect(isClose(solution.mismatchLossDB, 0))
        #expect(solution.undefinedExplanation(for: .returnLoss) != nil)
    }

    @Test func vswrOfTwo() throws {
        let solution = try ReflectionCalculator.solve(from: .vswr, value: 2)
        #expect(isClose(solution.gamma, 1.0 / 3.0))
        #expect(isClose(solution.returnLossDB, 9.542425094393249, relativeTolerance: 1e-9))
        #expect(isClose(solution.reflectedPowerPercent, 11.111111111111111, relativeTolerance: 1e-9))
        #expect(isClose(solution.mismatchLossDB, 0.5115252244738129, relativeTolerance: 1e-9))
        #expect(isClose(solution.transmittedPowerPercent, 88.888888888888889, relativeTolerance: 1e-9))
    }

    @Test func vswrOfOnePointFive() throws {
        let solution = try ReflectionCalculator.solve(from: .vswr, value: 1.5)
        #expect(isClose(solution.gamma, 0.2))
        #expect(isClose(solution.returnLossDB, 13.979400086720375, relativeTolerance: 1e-9))
        #expect(isClose(solution.reflectedPowerPercent, 4))
        #expect(isClose(solution.mismatchLossDB, 0.17728766960431604, relativeTolerance: 1e-9))
    }

    /// 20 dB of return loss is Γ = 0.1, VSWR 1.2222, 1% reflected.
    @Test func twentyDBReturnLoss() throws {
        let solution = try ReflectionCalculator.solve(from: .returnLoss, value: 20)
        #expect(isClose(solution.gamma, 0.1, relativeTolerance: 1e-12))
        #expect(isClose(solution.vswr, 1.2222222222222223, relativeTolerance: 1e-9))
        #expect(isClose(solution.reflectedPowerPercent, 1, relativeTolerance: 1e-9))
        #expect(isClose(solution.mismatchLossDB, 0.04364805402450088, relativeTolerance: 1e-9))
    }

    /// 10 dB of return loss is the textbook VSWR 1.925.
    @Test func tenDBReturnLoss() throws {
        let solution = try ReflectionCalculator.solve(from: .returnLoss, value: 10)
        #expect(isClose(solution.gamma, 0.31622776601683794, relativeTolerance: 1e-12))
        #expect(isClose(solution.vswr, 1.9249505911485288, relativeTolerance: 1e-9))
        #expect(isClose(solution.reflectedPowerPercent, 10, relativeTolerance: 1e-9))
        #expect(isClose(solution.mismatchLossDB, 0.45757490560675115, relativeTolerance: 1e-9))
    }

    /// Half the power reflected: Γ = 1/√2, and return loss equals mismatch
    /// loss at 3.0103 dB — a useful independent cross-check.
    @Test func halfThePowerReflected() throws {
        let solution = try ReflectionCalculator.solve(from: .reflectedPower, value: 50)
        #expect(isClose(solution.gamma, 0.7071067811865476, relativeTolerance: 1e-12))
        #expect(isClose(solution.vswr, 5.8284271247461903, relativeTolerance: 1e-9))
        #expect(isClose(solution.returnLossDB, 3.0102999566398116, relativeTolerance: 1e-9))
        #expect(isClose(solution.mismatchLossDB, 3.0102999566398116, relativeTolerance: 1e-9))
        #expect(isClose(solution.transmittedPowerPercent, 50, relativeTolerance: 1e-9))
    }

    @Test func reflectionCoefficientEnteredDirectly() throws {
        let solution = try ReflectionCalculator.solve(from: .reflectionCoefficient, value: 0.5)
        #expect(isClose(solution.vswr, 3))
        #expect(isClose(solution.reflectedPowerPercent, 25))
        #expect(isClose(solution.returnLossDB, 6.020599913279624, relativeTolerance: 1e-9))
        #expect(isClose(solution.mismatchLossDB, 1.2493873660829993, relativeTolerance: 1e-9))
    }

    // MARK: - Boundaries

    @Test func totalReflection() throws {
        let solution = try ReflectionCalculator.solve(from: .reflectionCoefficient, value: 1)
        #expect(solution.vswr == nil)
        #expect(isClose(solution.returnLossDB, 0))
        #expect(isClose(solution.reflectedPowerPercent, 100))
        #expect(isClose(solution.transmittedPowerPercent, 0))
        #expect(solution.mismatchLossDB == nil)
        #expect(solution.undefinedExplanation(for: .vswr) != nil)
        #expect(solution.undefinedExplanation(for: .mismatchLoss) != nil)
    }

    @Test func zeroMismatchLossIsAPerfectMatch() throws {
        let solution = try ReflectionCalculator.solve(from: .mismatchLoss, value: 0)
        #expect(isClose(solution.gamma, 0))
        #expect(isClose(solution.vswr, 1))
        #expect(solution.returnLossDB == nil)
    }

    @Test func zeroReturnLossIsTotalReflection() throws {
        let solution = try ReflectionCalculator.solve(from: .returnLoss, value: 0)
        #expect(isClose(solution.gamma, 1))
        #expect(solution.vswr == nil)
        #expect(isClose(solution.reflectedPowerPercent, 100))
    }

    // MARK: - Every quantity agrees with every other

    @Test(arguments: [1.05, 1.5, 2.0, 3.0, 10.0])
    func solvingFromAnyQuantityGivesTheSameAnswer(_ vswr: Double) throws {
        let reference = try ReflectionCalculator.solve(from: .vswr, value: vswr)

        for quantity in ReflectionQuantity.allCases {
            let value = try #require(reference.value(for: quantity))
            let solution = try ReflectionCalculator.solve(from: quantity, value: value)
            #expect(
                isClose(solution.gamma, reference.gamma, relativeTolerance: 1e-9),
                "Solving from \(quantity.title) disagreed with VSWR \(vswr)"
            )
        }
    }

    // MARK: - Invalid input

    @Test func vswrBelowOneIsRejected() {
        #expect(throws: CalculationError.self) {
            _ = try ReflectionCalculator.solve(from: .vswr, value: 0.5)
        }
    }

    /// A negative return loss is almost always an S11 figure entered as-is, so
    /// it is rejected with a message that says so rather than being flipped.
    @Test func negativeReturnLossIsRejected() {
        #expect(throws: CalculationError.self) {
            _ = try ReflectionCalculator.solve(from: .returnLoss, value: -20)
        }
    }

    @Test func reflectionCoefficientOutsideZeroToOneIsRejected() {
        #expect(throws: CalculationError.self) {
            _ = try ReflectionCalculator.solve(from: .reflectionCoefficient, value: 1.5)
        }
        #expect(throws: CalculationError.self) {
            _ = try ReflectionCalculator.solve(from: .reflectionCoefficient, value: -0.1)
        }
    }

    @Test func reflectedPowerOutsideZeroToHundredIsRejected() {
        #expect(throws: CalculationError.self) {
            _ = try ReflectionCalculator.solve(from: .reflectedPower, value: 101)
        }
        #expect(throws: CalculationError.self) {
            _ = try ReflectionCalculator.solve(from: .reflectedPower, value: -1)
        }
    }

    @Test func negativeMismatchLossIsRejected() {
        #expect(throws: CalculationError.self) {
            _ = try ReflectionCalculator.solve(from: .mismatchLoss, value: -0.1)
        }
    }

    @Test func notANumberIsRejected() {
        #expect(throws: CalculationError.self) {
            _ = try ReflectionCalculator.solve(from: .vswr, value: .nan)
        }
    }
}
