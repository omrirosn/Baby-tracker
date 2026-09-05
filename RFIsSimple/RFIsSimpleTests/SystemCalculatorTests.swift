import Foundation
import Testing
@testable import RFIsSimple

/// Voltage / Power / Impedance (spec §5.2).
struct VoltagePowerImpedanceTests {

    /// The one every RF engineer knows: 0 dBm in 50 Ω is 223.6 mV RMS,
    /// 632 mV peak-to-peak, and 107 dBµV.
    @Test func zeroDBmInFiftyOhms() throws {
        let solution = try VoltagePowerCalculator.solve(from: .power, value: 1e-3, impedanceOhms: 50)
        #expect(isClose(solution.rmsVolts, 0.22360679774997896, relativeTolerance: 1e-12))
        #expect(isClose(solution.peakToPeakVolts, 0.6324555320336759, relativeTolerance: 1e-12))
        #expect(isClose(solution.dBm, 0, relativeTolerance: 1e-9))
        #expect(isClose(solution.dBµV, 106.98970004336019, relativeTolerance: 1e-9))
    }

    @Test func oneWattInFiftyOhms() throws {
        let solution = try VoltagePowerCalculator.solve(from: .power, value: 1, impedanceOhms: 50)
        #expect(isClose(solution.rmsVolts, 7.0710678118654755, relativeTolerance: 1e-12))
        #expect(isClose(solution.dBm, 30, relativeTolerance: 1e-9))
    }

    @Test func solvingFromVoltage() throws {
        let solution = try VoltagePowerCalculator.solve(from: .voltage, value: 1, impedanceOhms: 50)
        #expect(isClose(solution.watts, 0.02, relativeTolerance: 1e-12))
        #expect(isClose(solution.dBm, 13.010299956639813, relativeTolerance: 1e-9))
    }

    @Test func seventyFiveOhmsGivesADifferentVoltage() throws {
        let fifty = try VoltagePowerCalculator.solve(from: .power, value: 1e-3, impedanceOhms: 50)
        let seventyFive = try VoltagePowerCalculator.solve(from: .power, value: 1e-3, impedanceOhms: 75)
        #expect(seventyFive.rmsVolts > fifty.rmsVolts)
        #expect(isClose(seventyFive.rmsVolts, (1e-3 * 75).squareRoot(), relativeTolerance: 1e-12))
    }

    @Test func roundTripsBetweenPowerAndVoltage() throws {
        let forward = try VoltagePowerCalculator.solve(from: .power, value: 0.25, impedanceOhms: 50)
        let back = try VoltagePowerCalculator.solve(from: .voltage, value: forward.rmsVolts, impedanceOhms: 50)
        #expect(isClose(back.watts, 0.25, relativeTolerance: 1e-12))
    }

    @Test func zeroPowerHasNoDecibelValue() throws {
        let solution = try VoltagePowerCalculator.solve(from: .power, value: 0, impedanceOhms: 50)
        #expect(solution.rmsVolts == 0)
        #expect(solution.dBm == nil)
        #expect(solution.dBµV == nil)
    }

    @Test func invalidInput() {
        #expect(throws: CalculationError.self) {
            _ = try VoltagePowerCalculator.solve(from: .power, value: 1, impedanceOhms: 0)
        }
        #expect(throws: CalculationError.self) {
            _ = try VoltagePowerCalculator.solve(from: .power, value: 1, impedanceOhms: -50)
        }
        #expect(throws: CalculationError.self) {
            _ = try VoltagePowerCalculator.solve(from: .power, value: -1, impedanceOhms: 50)
        }
        #expect(throws: CalculationError.self) {
            _ = try VoltagePowerCalculator.solve(from: .voltage, value: .nan, impedanceOhms: 50)
        }
    }
}

/// Free-space path loss (spec §5.4).
struct PathLossTests {

    /// Independently checked against `20·log10(d_km) + 20·log10(f_MHz) + 32.45`:
    /// 1 km at 1 GHz is 92.45 dB.
    @Test func oneKilometreAtOneGigahertz() throws {
        let solution = try PathLossCalculator.freeSpace(frequencyHz: 1e9, distanceMetres: 1000)
        #expect(isClose(solution.lossDB, 92.44778322188337, relativeTolerance: 1e-9))
        #expect(isClose(solution.wavelengthMetres, 0.299792458, relativeTolerance: 1e-12))
    }

    @Test func hundredMetresAtTwoPointFourGigahertz() throws {
        let solution = try PathLossCalculator.freeSpace(frequencyHz: 2.4e9, distanceMetres: 100)
        #expect(isClose(solution.lossDB, 80.0520080561155, relativeTolerance: 1e-9))
    }

    /// Doubling either term costs 6.02 dB — the property the formula is famous for.
    @Test func doublingDistanceOrFrequencyCostsSixDecibels() throws {
        let base = try PathLossCalculator.freeSpace(frequencyHz: 1e9, distanceMetres: 1000)
        let twiceFar = try PathLossCalculator.freeSpace(frequencyHz: 1e9, distanceMetres: 2000)
        let twiceHigh = try PathLossCalculator.freeSpace(frequencyHz: 2e9, distanceMetres: 1000)

        #expect(isClose(twiceFar.lossDB - base.lossDB, 6.020599913279624, relativeTolerance: 1e-9))
        #expect(isClose(twiceHigh.lossDB - base.lossDB, 6.020599913279624, relativeTolerance: 1e-9))
    }

    @Test func veryCloseRangeIsFlaggedRatherThanReturnedAsGain() throws {
        let solution = try PathLossCalculator.freeSpace(frequencyHz: 1e9, distanceMetres: 0.001)
        #expect(solution.lossDB < 0)
        #expect(PathLossCalculator.nearFieldIssue(solution)?.severity == .warning)

        let normal = try PathLossCalculator.freeSpace(frequencyHz: 1e9, distanceMetres: 1000)
        #expect(PathLossCalculator.nearFieldIssue(normal) == nil)
    }

    @Test func invalidInput() {
        #expect(throws: CalculationError.self) {
            _ = try PathLossCalculator.freeSpace(frequencyHz: 0, distanceMetres: 1000)
        }
        #expect(throws: CalculationError.self) {
            _ = try PathLossCalculator.freeSpace(frequencyHz: 1e9, distanceMetres: 0)
        }
        #expect(throws: CalculationError.self) {
            _ = try PathLossCalculator.freeSpace(frequencyHz: 1e9, distanceMetres: -5)
        }
    }
}

/// Thermal noise and receiver sensitivity (spec §5.6 and §5.7).
struct NoiseCalculatorTests {

    /// −174 dBm/Hz at 290 K, and −114 dBm in 1 MHz (spec §14).
    @Test func thermalNoiseAtRoomTemperature() throws {
        let solution = try NoiseCalculator.thermalNoise(bandwidthHz: 1e6)
        #expect(isClose(solution.densityDBmPerHz, -173.97518719422808, relativeTolerance: 1e-9))
        #expect(isClose(solution.noiseDBm, -113.97518719422811, relativeTolerance: 1e-9))
        #expect(solution.floorDBm == nil)
        #expect(abs(solution.densityDBmPerHz + 174) < 0.03)
    }

    @Test func noiseFigureRaisesTheFloorDecibelForDecibel() throws {
        let solution = try NoiseCalculator.thermalNoise(bandwidthHz: 1e6, noiseFigureDB: 6)
        #expect(isClose(solution.floorDBm, solution.noiseDBm + 6, relativeTolerance: 1e-9))
    }

    @Test func tenTimesTheBandwidthCostsTenDecibels() throws {
        let narrow = try NoiseCalculator.thermalNoise(bandwidthHz: 1e5)
        let wide = try NoiseCalculator.thermalNoise(bandwidthHz: 1e6)
        #expect(isClose(wide.noiseDBm - narrow.noiseDBm, 10, relativeTolerance: 1e-9))
    }

    @Test func temperatureChangesTheDensity() throws {
        let cold = try NoiseCalculator.thermalNoise(bandwidthHz: 1e6, temperatureKelvin: 145)
        let warm = try NoiseCalculator.thermalNoise(bandwidthHz: 1e6, temperatureKelvin: 290)
        // Halving the temperature is 3.01 dB less noise.
        #expect(isClose(warm.noiseDBm - cold.noiseDBm, 3.010299956639812, relativeTolerance: 1e-9))
    }

    /// 200 kHz, 6 dB noise figure, 10 dB required SNR: −104.96 dBm.
    @Test func sensitivityOfATypicalNarrowbandReceiver() throws {
        let solution = try NoiseCalculator.sensitivity(
            bandwidthHz: 200e3, noiseFigureDB: 6, requiredSNRDB: 10
        )
        #expect(isClose(solution.sensitivityDBm, -104.9648872375883, relativeTolerance: 1e-9))
        #expect(isClose(solution.noiseFloorDBm, solution.thermalNoiseDBm + 6, relativeTolerance: 1e-9))
        #expect(isClose(solution.sensitivityDBm, solution.noiseFloorDBm + 10, relativeTolerance: 1e-9))
    }

    /// A 1 dB noise figure is about 75 K, the figure quoted in every low-noise
    /// datasheet.
    @Test func equivalentNoiseTemperature() throws {
        let solution = try NoiseCalculator.sensitivity(
            bandwidthHz: 1e6, noiseFigureDB: 1, requiredSNRDB: 0
        )
        #expect(abs(solution.equivalentNoiseTemperature - 75.09) < 0.05)
    }

    @Test func invalidInput() {
        #expect(throws: CalculationError.self) {
            _ = try NoiseCalculator.thermalNoise(bandwidthHz: 0)
        }
        #expect(throws: CalculationError.self) {
            _ = try NoiseCalculator.thermalNoise(bandwidthHz: -1e6)
        }
        #expect(throws: CalculationError.self) {
            _ = try NoiseCalculator.thermalNoise(bandwidthHz: 1e6, temperatureKelvin: 0)
        }
        // A negative noise figure is unphysical.
        #expect(throws: CalculationError.self) {
            _ = try NoiseCalculator.thermalNoise(bandwidthHz: 1e6, noiseFigureDB: -1)
        }
        #expect(throws: CalculationError.self) {
            _ = try NoiseCalculator.sensitivity(bandwidthHz: 1e6, noiseFigureDB: 3, requiredSNRDB: .nan)
        }
    }
}

/// Link budget and radiated power (spec §5.5 and §5.10).
struct LinkBudgetTests {

    @Test func aBudgetThatCloses() throws {
        let solution = try LinkBudgetCalculator.solve(
            LinkBudgetInput(
                transmitPowerDBm: 20,
                transmitLossDB: 1,
                transmitGainDBi: 6,
                pathLossDB: 100,
                receiveGainDBi: 6,
                receiveLossDB: 1,
                sensitivityDBm: -90
            )
        )
        #expect(isClose(solution.eirpDBm, 25))
        #expect(isClose(solution.receivedPowerDBm, -70))
        #expect(isClose(solution.marginDB, 20))
        #expect(solution.closes == true)
    }

    @Test func aBudgetThatDoesNotClose() throws {
        let solution = try LinkBudgetCalculator.solve(
            LinkBudgetInput(transmitPowerDBm: 0, pathLossDB: 120, sensitivityDBm: -100)
        )
        #expect(isClose(solution.receivedPowerDBm, -120))
        #expect(isClose(solution.marginDB, -20))
        #expect(solution.closes == false)
    }

    @Test func withoutSensitivityThereIsNoMargin() throws {
        let solution = try LinkBudgetCalculator.solve(
            LinkBudgetInput(transmitPowerDBm: 30, pathLossDB: 90)
        )
        #expect(isClose(solution.receivedPowerDBm, -60))
        #expect(solution.marginDB == nil)
        #expect(solution.closes == nil)
    }

    @Test func lossesMustBeEnteredPositive() {
        #expect(throws: CalculationError.self) {
            _ = try LinkBudgetCalculator.solve(
                LinkBudgetInput(transmitPowerDBm: 20, transmitLossDB: -1, pathLossDB: 100)
            )
        }
        #expect(throws: CalculationError.self) {
            _ = try LinkBudgetCalculator.solve(
                LinkBudgetInput(transmitPowerDBm: 20, pathLossDB: -100)
            )
        }
    }

    // MARK: - EIRP / ERP

    @Test func eirpAndErp() throws {
        let solution = try RadiatedPowerCalculator.solve(
            transmitPowerDBm: 30, feedLossDB: 2, antennaGain: 12, reference: .dBi
        )
        #expect(isClose(solution.eirpDBm, 40))
        #expect(isClose(solution.erpDBm, 37.85))
        #expect(isClose(solution.eirpWatts, 10, relativeTolerance: 1e-9))
    }

    /// The 2.15 dB that separates dBi from dBd, applied in the right direction.
    @Test func dBdGainIsConvertedToDBi() throws {
        let asDBd = try RadiatedPowerCalculator.solve(
            transmitPowerDBm: 30, feedLossDB: 0, antennaGain: 12, reference: .dBd
        )
        let asDBi = try RadiatedPowerCalculator.solve(
            transmitPowerDBm: 30, feedLossDB: 0, antennaGain: 12, reference: .dBi
        )
        #expect(isClose(asDBd.antennaGainDBi, 14.15))
        #expect(isClose(asDBd.eirpDBm - asDBi.eirpDBm, 2.15, relativeTolerance: 1e-9))
    }

    @Test func feedLossMustBePositive() {
        #expect(throws: CalculationError.self) {
            _ = try RadiatedPowerCalculator.solve(
                transmitPowerDBm: 30, feedLossDB: -2, antennaGain: 0, reference: .dBi
            )
        }
    }
}

/// Cascaded gain and noise figure (spec §5.9).
struct CascadeCalculatorTests {

    /// A loss ahead of an amplifier adds to the noise figure decibel for
    /// decibel: 1.5 dB of cable before a 1 dB LNA gives exactly 2.5 dB. That
    /// identity is independent of the Friis arithmetic, so it is a genuine
    /// cross-check rather than a restatement of the code.
    @Test func lossAheadOfAnAmplifierAddsDecibelForDecibel() throws {
        let solution = try CascadeCalculator.solve(stages: [
            CascadeStage(name: "Cable", gainDB: -1.5, noiseFigureDB: 1.5),
            CascadeStage(name: "LNA", gainDB: 20, noiseFigureDB: 1)
        ])
        #expect(isClose(solution.totalNoiseFigureDB, 2.5, relativeTolerance: 1e-9))
        #expect(isClose(solution.totalGainDB, 18.5, relativeTolerance: 1e-9))
    }

    @Test func aSingleStageIsItsOwnNoiseFigure() throws {
        let solution = try CascadeCalculator.solve(stages: [
            CascadeStage(name: "Amp", gainDB: 20, noiseFigureDB: 3)
        ])
        #expect(isClose(solution.totalNoiseFigureDB, 3, relativeTolerance: 1e-9))
        #expect(isClose(solution.totalGainDB, 20))
    }

    /// Gain in the first stage suppresses everything behind it.
    @Test func gainAheadSuppressesLaterNoise() throws {
        let solution = try CascadeCalculator.solve(stages: [
            CascadeStage(name: "LNA", gainDB: 20, noiseFigureDB: 1),
            CascadeStage(name: "Receiver", gainDB: 20, noiseFigureDB: 10)
        ])
        #expect(isClose(solution.totalNoiseFigureDB, 1.2998793622358962, relativeTolerance: 1e-9))
        #expect(isClose(solution.totalGainDB, 40))
    }

    /// The same two stages the other way round are far worse — the reason
    /// stage order is preserved rather than sorted.
    @Test func orderChangesTheNoiseFigure() throws {
        let good = try CascadeCalculator.solve(stages: [
            CascadeStage(gainDB: 20, noiseFigureDB: 1),
            CascadeStage(gainDB: 20, noiseFigureDB: 10)
        ])
        let bad = try CascadeCalculator.solve(stages: [
            CascadeStage(gainDB: 20, noiseFigureDB: 10),
            CascadeStage(gainDB: 20, noiseFigureDB: 1)
        ])
        #expect(isClose(bad.totalNoiseFigureDB, 10.001124353220137, relativeTolerance: 1e-9))
        #expect(bad.totalNoiseFigureDB > good.totalNoiseFigureDB + 8)
        // Total gain is unaffected by order.
        #expect(isClose(good.totalGainDB, bad.totalGainDB))
    }

    @Test func contributionsSumToTheWholeExcessNoise() throws {
        let solution = try CascadeCalculator.solve(stages: CascadeCalculator.defaultStages)
        let total = solution.contributions.reduce(0) { $0 + $1.sharePercent }
        #expect(isClose(total, 100, relativeTolerance: 1e-9))
        #expect(solution.contributions.count == CascadeCalculator.defaultStages.count)
        // The first stage dominates a chain that starts with a loss.
        #expect(solution.contributions[0].sharePercent > 40)
    }

    @Test func aPassiveStageNoiseFigureMatchesItsLoss() {
        #expect(CascadeCalculator.passiveNoiseFigure(forGainDB: -3) == 3)
        #expect(CascadeCalculator.passiveNoiseFigure(forGainDB: 10) == nil)
    }

    @Test func invalidInput() {
        #expect(throws: CalculationError.self) {
            _ = try CascadeCalculator.solve(stages: [])
        }
        #expect(throws: CalculationError.self) {
            _ = try CascadeCalculator.solve(stages: [CascadeStage(gainDB: 10, noiseFigureDB: -1)])
        }
        #expect(throws: CalculationError.self) {
            _ = try CascadeCalculator.solve(stages: [CascadeStage(gainDB: .nan, noiseFigureDB: 3)])
        }
    }
}

/// Effective aperture and field regions (spec §5.11 and §5.12).
struct AntennaCalculatorTests {

    /// An isotropic antenna's aperture is λ²/4π — 0.00715 m² at 1 GHz.
    @Test func isotropicAperture() throws {
        let solution = try AntennaCalculator.effectiveAperture(frequencyHz: 1e9, gainDBi: 0)
        #expect(isClose(solution.apertureSquareMetres, 0.007152066466270221, relativeTolerance: 1e-9))
        #expect(isClose(solution.apertureSquareCentimetres, 71.52066466270221, relativeTolerance: 1e-9))
    }

    @Test func gainScalesTheAperture() throws {
        let low = try AntennaCalculator.effectiveAperture(frequencyHz: 2.4e9, gainDBi: 0)
        let high = try AntennaCalculator.effectiveAperture(frequencyHz: 2.4e9, gainDBi: 10)
        #expect(isClose(high.apertureSquareMetres / low.apertureSquareMetres, 10, relativeTolerance: 1e-9))
    }

    /// For a fixed gain the aperture falls with the square of frequency.
    @Test func apertureShrinksWithFrequency() throws {
        let lowBand = try AntennaCalculator.effectiveAperture(frequencyHz: 900e6, gainDBi: 6)
        let highBand = try AntennaCalculator.effectiveAperture(frequencyHz: 1800e6, gainDBi: 6)
        #expect(isClose(lowBand.apertureSquareMetres / highBand.apertureSquareMetres, 4, relativeTolerance: 1e-9))
    }

    @Test func twelveDBiAtTwoPointFourGigahertz() throws {
        let solution = try AntennaCalculator.effectiveAperture(frequencyHz: 2.4e9, gainDBi: 12)
        #expect(isClose(solution.apertureSquareMetres, 0.01967927335836994, relativeTolerance: 1e-9))
    }

    /// A 1 m antenna at 1 GHz: far field beyond 6.67 m, reactive near field
    /// ending at 1.13 m.
    @Test func fieldRegionsOfAOneMetreAntenna() throws {
        let solution = try AntennaCalculator.fieldRegions(frequencyHz: 1e9, largestDimensionMetres: 1)
        #expect(isClose(solution.fraunhoferBoundaryMetres, 6.671281903963042, relativeTolerance: 1e-9))
        #expect(isClose(solution.reactiveBoundaryMetres, 1.1323517041722049, relativeTolerance: 1e-9))
        #expect(isClose(solution.smallAntennaBoundaryMetres, 0.04771345159236942, relativeTolerance: 1e-9))
        #expect(solution.isElectricallySmall == false)
        #expect(isClose(solution.practicalFarFieldMetres, 6.671281903963042, relativeTolerance: 1e-9))
    }

    /// An antenna smaller than a wavelength is flagged, because 2D²/λ then
    /// gives a distance far too short to measure at.
    @Test func electricallySmallAntennaIsFlagged() throws {
        let solution = try AntennaCalculator.fieldRegions(frequencyHz: 100e6, largestDimensionMetres: 0.05)
        #expect(solution.isElectricallySmall)
        #expect(AntennaCalculator.fieldRegionIssue(solution)?.severity == .warning)
        // Three wavelengths dominates 2D²/λ here.
        #expect(isClose(solution.practicalFarFieldMetres, 3 * solution.wavelengthMetres, relativeTolerance: 1e-9))
    }

    @Test func invalidInput() {
        #expect(throws: CalculationError.self) {
            _ = try AntennaCalculator.effectiveAperture(frequencyHz: 0, gainDBi: 6)
        }
        #expect(throws: CalculationError.self) {
            _ = try AntennaCalculator.fieldRegions(frequencyHz: 1e9, largestDimensionMetres: 0)
        }
        #expect(throws: CalculationError.self) {
            _ = try AntennaCalculator.fieldRegions(frequencyHz: -1e9, largestDimensionMetres: 1)
        }
    }
}

/// Temperature units, which convert by an offset rather than a factor.
struct TemperatureUnitTests {

    @Test func celsiusToKelvin() {
        #expect(isClose(TemperatureUnit.celsius.toBase(0), 273.15))
        #expect(isClose(TemperatureUnit.celsius.toBase(16.85), 290, relativeTolerance: 1e-9))
        #expect(isClose(TemperatureUnit.kelvin.toBase(290), 290))
    }

    @Test func roundTrip() {
        for value in [-40.0, 0.0, 25.0, 1000.0] {
            #expect(isClose(TemperatureUnit.celsius.fromBase(TemperatureUnit.celsius.toBase(value)), value,
                            relativeTolerance: 1e-9))
        }
    }

    @Test func temperatureIsNeverAutoScaled() {
        #expect(TemperatureUnit.autoScaleCandidates.isEmpty)
        #expect(UnitScaling.preferredUnit(for: 290, fallback: TemperatureUnit.kelvin) == .kelvin)
    }

    @Test func onlyCelsiusTakesNegativeValues() {
        #expect(TemperatureUnit.celsius.allowsNegativeValues)
        #expect(TemperatureUnit.kelvin.allowsNegativeValues == false)
    }
}
