import Foundation

/// Which of the three linked wave quantities the user is starting from.
enum WaveQuantity: String, CaseIterable, Identifiable, Sendable {
    case frequency
    case period
    case wavelength

    var id: String { rawValue }

    var title: String {
        switch self {
        case .frequency: return "Frequency"
        case .period: return "Period"
        case .wavelength: return "Wavelength"
        }
    }
}

/// A frequency, its period and its wavelength, together with the propagation
/// velocity they were derived with.
struct WaveSolution: Equatable, Hashable, Sendable {
    let frequencyHz: Double
    let periodSeconds: Double
    let wavelengthMetres: Double
    /// Propagation velocity actually used, m/s.
    let velocity: Double
    /// Velocity factor applied to the speed of light (1 = vacuum).
    let velocityFactor: Double

    /// A quarter of the wavelength — the length that turns up constantly in
    /// stub, whip and matching work.
    var quarterWavelengthMetres: Double { wavelengthMetres / 4 }
}

/// Frequency, period and wavelength.
///
/// Implemented relationships:
///
///     T = 1 / f
///     λ = v / f        with v = VF · c
///
/// Unit convention: all arguments and results are SI base units (Hz, s, m, m/s).
/// The default velocity is the speed of light in vacuum; a velocity factor
/// scales it for propagation in a cable or dielectric.
enum WaveCalculator {
    /// Velocity factor used when the user has not supplied one.
    static let defaultVelocityFactor: Double = 1.0

    /// Solves the other two quantities from whichever one was entered.
    ///
    /// - Parameters:
    ///   - quantity: which quantity `value` represents.
    ///   - value: the entered quantity in its SI base unit (Hz, s or m).
    ///   - velocityFactor: propagation velocity as a fraction of c.
    /// - Throws: `CalculationError.mustBePositive` — none of frequency, period,
    ///   wavelength or velocity factor can be zero or negative.
    static func solve(
        from quantity: WaveQuantity,
        value: Double,
        velocityFactor: Double = defaultVelocityFactor
    ) throws -> WaveSolution {
        guard value.isFinite else {
            throw CalculationError.notANumber(quantity: quantity.title)
        }
        guard velocityFactor.isFinite else {
            throw CalculationError.notANumber(quantity: "Velocity factor")
        }
        guard velocityFactor > 0 else {
            throw CalculationError.mustBePositive(quantity: "Velocity factor")
        }
        guard value > 0 else {
            throw CalculationError.mustBePositive(quantity: quantity.title)
        }

        let velocity = PhysicalConstants.speedOfLight * velocityFactor

        let frequency: Double
        let period: Double
        let wavelength: Double

        switch quantity {
        case .frequency:
            frequency = value
            period = 1 / value
            wavelength = velocity / value
        case .period:
            frequency = 1 / value
            period = value
            wavelength = velocity * value
        case .wavelength:
            frequency = velocity / value
            period = value / velocity
            wavelength = value
        }

        guard frequency.isFinite, period.isFinite, wavelength.isFinite,
              frequency > 0, period > 0, wavelength > 0 else {
            throw CalculationError.outOfRange(
                quantity: quantity.title,
                requirement: "within the range this relationship can represent"
            )
        }

        return WaveSolution(
            frequencyHz: frequency,
            periodSeconds: period,
            wavelengthMetres: wavelength,
            velocity: velocity,
            velocityFactor: velocityFactor
        )
    }

    /// A velocity factor above 1 is legitimate for the phase velocity in a
    /// waveguide, but is far more often a typing error — so it is flagged
    /// rather than rejected or silently corrected (spec §12).
    static func velocityFactorIssue(_ velocityFactor: Double) -> ValidationIssue? {
        guard velocityFactor.isFinite else { return nil }
        guard velocityFactor > 1 else { return nil }
        return .warning("Above 1, so faster than light in vacuum. Correct for waveguide phase velocity, otherwise check the value.")
    }
}
