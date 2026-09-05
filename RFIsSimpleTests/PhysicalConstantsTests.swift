import Foundation
import Testing
@testable import RFIsSimple

/// The constants the calculators are built on.
///
/// Thermal noise has no calculator yet, but spec §14 names -174 dBm/Hz as a
/// global reference value — so the constants that produce it are checked here.
/// If `boltzmann` or `standardNoiseTemperature` ever drifts, this fails before
/// the noise calculators are written against them.
struct PhysicalConstantsTests {

    @Test func speedOfLightIsTheExactSIValue() {
        #expect(PhysicalConstants.speedOfLight == 299_792_458)
    }

    @Test func boltzmannIsTheExactSIValue() {
        #expect(PhysicalConstants.boltzmann == 1.380_649e-23)
    }

    /// N = k·T·B at T = 290 K and B = 1 Hz, expressed in dBm:
    /// 10·log10(1.380649e-23 · 290 / 1e-3) = -173.9751872 dBm, the familiar -174.
    @Test func thermalNoiseDensityIsMinus174dBmPerHertz() {
        let noiseWatts = PhysicalConstants.boltzmann * PhysicalConstants.standardNoiseTemperature * 1.0
        let dBmPerHertz = 10 * log10(noiseWatts / 1e-3)

        #expect(isClose(dBmPerHertz, -173.97518719422808, relativeTolerance: 1e-9))
        #expect(abs(dBmPerHertz + 174) < 0.03)
    }

    /// The same figure through the unit layer, which is how a future thermal
    /// noise calculator will reach it.
    @Test func thermalNoiseDensityThroughThePowerUnits() throws {
        let noiseWatts = PhysicalConstants.boltzmann * PhysicalConstants.standardNoiseTemperature
        let conversion = try PowerConversion.fromWatts(noiseWatts)
        #expect(isClose(conversion.dBm, -173.97518719422808, relativeTolerance: 1e-9))
    }

    /// In 1 MHz of bandwidth the floor is 60 dB higher: -114 dBm.
    @Test func thermalNoiseInOneMegahertz() {
        let noiseWatts = PhysicalConstants.boltzmann * PhysicalConstants.standardNoiseTemperature * 1e6
        let dBm = 10 * log10(noiseWatts / 1e-3)
        #expect(abs(dBm + 113.975) < 0.03)
    }

    @Test func freeSpaceImpedanceAndSystemImpedance() {
        #expect(abs(PhysicalConstants.freeSpaceImpedance - 376.730) < 0.001)
        #expect(PhysicalConstants.defaultSystemImpedance == 50)
    }
}
