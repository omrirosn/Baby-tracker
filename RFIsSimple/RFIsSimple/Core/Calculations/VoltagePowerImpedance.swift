import Foundation

/// Which quantity the user is starting from.
enum VoltagePowerQuantity: String, CaseIterable, Identifiable, Sendable {
    case power
    case voltage

    var id: String { rawValue }

    var title: String {
        switch self {
        case .power: return "Power"
        case .voltage: return "RMS voltage"
        }
    }
}

/// A signal level expressed as power and as voltage, for one impedance.
struct VoltagePowerSolution: Equatable, Hashable, Sendable {
    let watts: Double
    /// RMS voltage across the impedance, V.
    let rmsVolts: Double
    let impedanceOhms: Double

    /// Peak of a sine wave with this RMS value.
    var peakVolts: Double { rmsVolts * 2.0.squareRoot() }
    /// Peak-to-peak of a sine wave, which is what a scope shows.
    var peakToPeakVolts: Double { 2 * peakVolts }

    /// `nil` at zero power, where the logarithm is undefined.
    var dBm: Double? {
        guard watts > 0 else { return nil }
        return 10 * log10(watts) + 30
    }

    /// Voltage referred to 1 mV, the convention used on cable and video gear.
    var dBmV: Double? {
        guard rmsVolts > 0 else { return nil }
        return 20 * log10(rmsVolts / 1e-3)
    }

    /// Voltage referred to 1 µV, the convention used for receiver sensitivity.
    var dBµV: Double? {
        guard rmsVolts > 0 else { return nil }
        return 20 * log10(rmsVolts / 1e-6)
    }
}

/// RMS voltage, power and impedance.
///
/// Implemented relationships:
///
///     P = V² / Z
///     V = √(P · Z)
///     V_peak = √2 · V_rms          (sine wave)
///     V_pp   = 2·√2 · V_rms
///
/// Unit convention: watts, volts RMS and ohms. The peak relationships assume a
/// sine wave — which is exactly why they are labelled as such in the interface
/// rather than presented as universal.
enum VoltagePowerCalculator {
    static func solve(
        from quantity: VoltagePowerQuantity,
        value: Double,
        impedanceOhms: Double
    ) throws -> VoltagePowerSolution {
        guard value.isFinite else {
            throw CalculationError.notANumber(quantity: quantity.title)
        }
        guard impedanceOhms.isFinite else {
            throw CalculationError.notANumber(quantity: "Impedance")
        }
        guard impedanceOhms > 0 else {
            throw CalculationError.mustBePositive(quantity: "Impedance")
        }
        guard value >= 0 else {
            throw CalculationError.mustBeNonNegative(quantity: quantity.title)
        }

        let watts: Double
        let volts: Double
        switch quantity {
        case .power:
            watts = value
            volts = (value * impedanceOhms).squareRoot()
        case .voltage:
            volts = value
            watts = (value * value) / impedanceOhms
        }

        guard watts.isFinite, volts.isFinite else {
            throw CalculationError.outOfRange(
                quantity: quantity.title,
                requirement: "within the range this relationship can represent"
            )
        }

        return VoltagePowerSolution(watts: watts, rmsVolts: volts, impedanceOhms: impedanceOhms)
    }

    /// Impedances offered as presets. Any other positive value can be typed.
    static let commonImpedances: [Double] = [50, 75]
}
