import Foundation

struct ApertureSolution: Equatable, Hashable, Sendable {
    /// Effective aperture, m².
    let apertureSquareMetres: Double
    let wavelengthMetres: Double
    let gainDBi: Double

    var apertureSquareCentimetres: Double { apertureSquareMetres * 1e4 }
    var linearGain: Double { pow(10.0, gainDBi / 10) }

    /// Diameter of a circular aperture with this area — a rough sanity check
    /// against the physical size of a dish.
    var equivalentCircleDiameterMetres: Double {
        (4 * apertureSquareMetres / .pi).squareRoot()
    }
}

/// The boundaries between an antenna's field regions.
struct FieldRegionSolution: Equatable, Hashable, Sendable {
    /// End of the reactive near field, 0.62·√(D³/λ).
    let reactiveBoundaryMetres: Double
    /// Start of the far field by the Fraunhofer criterion, 2D²/λ.
    let fraunhoferBoundaryMetres: Double
    /// λ/2π — the boundary that dominates for electrically small antennas.
    let smallAntennaBoundaryMetres: Double
    let wavelengthMetres: Double
    let largestDimensionMetres: Double

    /// True when the antenna is smaller than a wavelength, where 2D²/λ stops
    /// being the binding criterion.
    var isElectricallySmall: Bool { largestDimensionMetres < wavelengthMetres }

    /// A conservative distance to measure at: the largest of the Fraunhofer
    /// distance, three wavelengths, and the reactive boundary.
    var practicalFarFieldMetres: Double {
        max(fraunhoferBoundaryMetres, 3 * wavelengthMetres, reactiveBoundaryMetres)
    }
}

/// Effective aperture and field regions (spec §5.11 and §5.12).
///
/// Implemented relationships:
///
///     A_e = G · λ² / (4π)              G linear, from dBi
///     R_reactive   = 0.62·√(D³/λ)
///     R_fraunhofer = 2·D² / λ
///
/// Unit convention: metres and hertz in; square metres and metres out. Gain is
/// entered in dBi and converted to a linear ratio internally.
enum AntennaCalculator {
    static func effectiveAperture(frequencyHz: Double, gainDBi: Double) throws -> ApertureSolution {
        guard frequencyHz.isFinite else {
            throw CalculationError.notANumber(quantity: "Frequency")
        }
        guard gainDBi.isFinite else {
            throw CalculationError.notANumber(quantity: "Antenna gain")
        }
        guard frequencyHz > 0 else {
            throw CalculationError.mustBePositive(quantity: "Frequency")
        }

        let wavelength = PhysicalConstants.speedOfLight / frequencyHz
        let linearGain = pow(10.0, gainDBi / 10)
        let aperture = linearGain * wavelength * wavelength / (4 * .pi)

        guard aperture.isFinite, wavelength.isFinite else {
            throw CalculationError.outOfRange(
                quantity: "Effective aperture",
                requirement: "within the range this relationship can represent"
            )
        }

        return ApertureSolution(
            apertureSquareMetres: aperture,
            wavelengthMetres: wavelength,
            gainDBi: gainDBi
        )
    }

    static func fieldRegions(
        frequencyHz: Double,
        largestDimensionMetres: Double
    ) throws -> FieldRegionSolution {
        guard frequencyHz.isFinite else {
            throw CalculationError.notANumber(quantity: "Frequency")
        }
        guard largestDimensionMetres.isFinite else {
            throw CalculationError.notANumber(quantity: "Antenna dimension")
        }
        guard frequencyHz > 0 else {
            throw CalculationError.mustBePositive(quantity: "Frequency")
        }
        guard largestDimensionMetres > 0 else {
            throw CalculationError.mustBePositive(quantity: "Antenna dimension")
        }

        let wavelength = PhysicalConstants.speedOfLight / frequencyHz
        let dimension = largestDimensionMetres
        let reactive = 0.62 * (dimension * dimension * dimension / wavelength).squareRoot()
        let fraunhofer = 2 * dimension * dimension / wavelength
        let small = wavelength / (2 * .pi)

        guard reactive.isFinite, fraunhofer.isFinite, small.isFinite else {
            throw CalculationError.outOfRange(
                quantity: "Antenna dimension",
                requirement: "within the range this relationship can represent"
            )
        }

        return FieldRegionSolution(
            reactiveBoundaryMetres: reactive,
            fraunhoferBoundaryMetres: fraunhofer,
            smallAntennaBoundaryMetres: small,
            wavelengthMetres: wavelength,
            largestDimensionMetres: dimension
        )
    }

    /// Spec §5.12 asks for a note that geometry and the chosen criterion move
    /// the practical boundary. It is a warning rather than body text because it
    /// only applies when the antenna is small relative to a wavelength.
    static func fieldRegionIssue(_ solution: FieldRegionSolution) -> ValidationIssue? {
        guard solution.isElectricallySmall else { return nil }
        return .warning("Antenna is smaller than a wavelength, where 2D²/λ is not the binding criterion. Use the practical distance below.")
    }
}
