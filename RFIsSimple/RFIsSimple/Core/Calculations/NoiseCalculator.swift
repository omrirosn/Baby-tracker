import Foundation

/// Thermal noise in a bandwidth, and the receiver floor above it.
struct ThermalNoiseSolution: Equatable, Hashable, Sendable {
    /// Noise power in the stated bandwidth, dBm.
    let noiseDBm: Double
    /// Noise power density, dBm/Hz — the −174 figure at 290 K.
    let densityDBmPerHz: Double
    /// Noise floor including the receiver's own noise figure, dBm.
    /// `nil` when no noise figure was supplied.
    let floorDBm: Double?
    let bandwidthHz: Double
    let temperatureKelvin: Double
    let noiseFigureDB: Double?

    var noiseWatts: Double {
        pow(10.0, (noiseDBm - 30) / 10)
    }
}

/// Receiver sensitivity: the floor plus the SNR the demodulator needs.
struct SensitivitySolution: Equatable, Hashable, Sendable {
    let sensitivityDBm: Double
    /// Noise floor before the required SNR is added, dBm.
    let noiseFloorDBm: Double
    let thermalNoiseDBm: Double
    let bandwidthHz: Double
    let noiseFigureDB: Double
    let requiredSNRDB: Double
    let temperatureKelvin: Double

    /// The equivalent input noise temperature of the receiver, K.
    var equivalentNoiseTemperature: Double {
        PhysicalConstants.standardNoiseTemperature * (pow(10.0, noiseFigureDB / 10) - 1)
    }
}

/// Thermal noise and receiver sensitivity (spec §5.6 and §5.7).
///
/// Implemented relationships:
///
///     N     = k·T·B                              (watts)
///     N(dBm) = 10·log10(k·T·B / 1 mW)
///     Floor  = N(dBm) + NF
///     S      = N(dBm) + NF + SNR
///
/// Unit convention: hertz, kelvin and decibels in; dBm out. At T = 290 K the
/// density comes to −173.98 dBm/Hz, the −174 every noise budget starts from.
enum NoiseCalculator {
    /// Bandwidth here is the equivalent *noise* bandwidth, which is not always
    /// the channel bandwidth — the interface says so next to the field.
    static func thermalNoise(
        bandwidthHz: Double,
        temperatureKelvin: Double = PhysicalConstants.standardNoiseTemperature,
        noiseFigureDB: Double? = nil
    ) throws -> ThermalNoiseSolution {
        guard bandwidthHz.isFinite else {
            throw CalculationError.notANumber(quantity: "Bandwidth")
        }
        guard temperatureKelvin.isFinite else {
            throw CalculationError.notANumber(quantity: "Temperature")
        }
        guard bandwidthHz > 0 else {
            throw CalculationError.mustBePositive(quantity: "Bandwidth")
        }
        guard temperatureKelvin > 0 else {
            throw CalculationError.mustBePositive(quantity: "Temperature")
        }
        if let noiseFigureDB {
            guard noiseFigureDB.isFinite else {
                throw CalculationError.notANumber(quantity: "Noise figure")
            }
            guard noiseFigureDB >= 0 else {
                throw CalculationError.mustBeNonNegative(quantity: "Noise figure")
            }
        }

        let density = 10 * log10(PhysicalConstants.boltzmann * temperatureKelvin / 1e-3)
        let noise = density + 10 * log10(bandwidthHz)

        guard density.isFinite, noise.isFinite else {
            throw CalculationError.outOfRange(
                quantity: "Bandwidth",
                requirement: "within the range this relationship can represent"
            )
        }

        return ThermalNoiseSolution(
            noiseDBm: noise,
            densityDBmPerHz: density,
            floorDBm: noiseFigureDB.map { noise + $0 },
            bandwidthHz: bandwidthHz,
            temperatureKelvin: temperatureKelvin,
            noiseFigureDB: noiseFigureDB
        )
    }

    static func sensitivity(
        bandwidthHz: Double,
        noiseFigureDB: Double,
        requiredSNRDB: Double,
        temperatureKelvin: Double = PhysicalConstants.standardNoiseTemperature
    ) throws -> SensitivitySolution {
        guard requiredSNRDB.isFinite else {
            throw CalculationError.notANumber(quantity: "Required SNR")
        }

        let noise = try thermalNoise(
            bandwidthHz: bandwidthHz,
            temperatureKelvin: temperatureKelvin,
            noiseFigureDB: noiseFigureDB
        )
        // `floorDBm` is non-nil because a noise figure was supplied.
        let floor = noise.floorDBm ?? noise.noiseDBm
        let sensitivity = floor + requiredSNRDB

        guard sensitivity.isFinite else {
            throw CalculationError.outOfRange(
                quantity: "Required SNR",
                requirement: "within the range this relationship can represent"
            )
        }

        return SensitivitySolution(
            sensitivityDBm: sensitivity,
            noiseFloorDBm: floor,
            thermalNoiseDBm: noise.noiseDBm,
            bandwidthHz: bandwidthHz,
            noiseFigureDB: noiseFigureDB,
            requiredSNRDB: requiredSNRDB,
            temperatureKelvin: temperatureKelvin
        )
    }
}
