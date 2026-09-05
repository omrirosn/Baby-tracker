import Foundation

/// Free-space path loss and the wavelength it was computed at.
struct PathLossSolution: Equatable, Hashable, Sendable {
    let lossDB: Double
    let wavelengthMetres: Double
    let frequencyHz: Double
    let distanceMetres: Double

    /// Distance at which the far-field spreading formula stops being sensible:
    /// inside λ/4π the "loss" comes out negative.
    var minimumValidDistanceMetres: Double { wavelengthMetres / (4 * .pi) }
}

/// Free-space path loss (spec §5.4).
///
/// Implemented relationship, in SI units so no unit-specific constant is baked
/// into the code:
///
///     FSPL(dB) = 20·log10( 4·π·d·f / c )
///
/// which is the familiar `20·log10(d_km) + 20·log10(f_MHz) + 32.45` with the
/// constant folded in. Unit convention: metres and hertz in, decibels out.
enum PathLossCalculator {
    static func freeSpace(frequencyHz: Double, distanceMetres: Double) throws -> PathLossSolution {
        guard frequencyHz.isFinite else {
            throw CalculationError.notANumber(quantity: "Frequency")
        }
        guard distanceMetres.isFinite else {
            throw CalculationError.notANumber(quantity: "Distance")
        }
        guard frequencyHz > 0 else {
            throw CalculationError.mustBePositive(quantity: "Frequency")
        }
        guard distanceMetres > 0 else {
            throw CalculationError.mustBePositive(quantity: "Distance")
        }

        let wavelength = PhysicalConstants.speedOfLight / frequencyHz
        let loss = 20 * log10(4 * Double.pi * distanceMetres / wavelength)

        guard loss.isFinite, wavelength.isFinite else {
            throw CalculationError.outOfRange(
                quantity: "Path loss",
                requirement: "within the range this relationship can represent"
            )
        }

        return PathLossSolution(
            lossDB: loss,
            wavelengthMetres: wavelength,
            frequencyHz: frequencyHz,
            distanceMetres: distanceMetres
        )
    }

    /// Inside λ/4π the formula returns a negative loss, which is a sign the
    /// two antennas are too close for a free-space model rather than a real
    /// gain. Flagged rather than clamped, so the input is never altered.
    static func nearFieldIssue(_ solution: PathLossSolution) -> ValidationIssue? {
        guard solution.lossDB < 0 else { return nil }
        return .warning("Closer than λ/4π, where free-space spreading does not apply. Treat this as coupling, not path loss.")
    }
}
