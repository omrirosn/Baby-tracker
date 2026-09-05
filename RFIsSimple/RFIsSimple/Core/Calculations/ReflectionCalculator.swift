import Foundation

/// The five interchangeable ways of describing the same mismatch.
enum ReflectionQuantity: String, CaseIterable, Identifiable, Sendable {
    case vswr
    case returnLoss
    case reflectionCoefficient
    case reflectedPower
    case mismatchLoss

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vswr: return "VSWR"
        case .returnLoss: return "Return loss"
        case .reflectionCoefficient: return "|Γ|"
        case .reflectedPower: return "Reflected power"
        case .mismatchLoss: return "Mismatch loss"
        }
    }

    /// Short label used on the segmented picker, where space is tight.
    var shortTitle: String {
        switch self {
        case .vswr: return "VSWR"
        case .returnLoss: return "RL"
        case .reflectionCoefficient: return "|Γ|"
        case .reflectedPower: return "%"
        case .mismatchLoss: return "ML"
        }
    }

    var unitSuffix: String? {
        switch self {
        case .vswr: return ": 1"
        case .returnLoss, .mismatchLoss: return "dB"
        case .reflectionCoefficient: return nil
        case .reflectedPower: return "%"
        }
    }

    var accessibilityName: String {
        switch self {
        case .vswr: return "VSWR"
        case .returnLoss: return "return loss in decibels"
        case .reflectionCoefficient: return "magnitude of the reflection coefficient"
        case .reflectedPower: return "reflected power percentage"
        case .mismatchLoss: return "mismatch loss in decibels"
        }
    }

    /// Spoken after the number by VoiceOver.
    var spokenUnit: String? {
        switch self {
        case .vswr: return "to one"
        case .returnLoss, .mismatchLoss: return "decibels"
        case .reflectionCoefficient: return nil
        case .reflectedPower: return "percent"
        }
    }

    /// A value that gives a sensible starting point for each quantity.
    var defaultValue: String {
        switch self {
        case .vswr: return "1.5"
        case .returnLoss: return "14"
        case .reflectionCoefficient: return "0.2"
        case .reflectedPower: return "4"
        case .mismatchLoss: return "0.18"
        }
    }
}

/// One mismatch, expressed every way at once.
///
/// `nil` marks a quantity that is infinite rather than merely large:
/// a perfect match has infinite return loss, and total reflection gives
/// infinite VSWR and infinite mismatch loss.
struct ReflectionSolution: Equatable, Hashable, Sendable {
    /// Magnitude of the reflection coefficient, 0…1.
    let gamma: Double
    /// `nil` when Γ = 1 (total reflection).
    let vswr: Double?
    /// `nil` when Γ = 0 (perfect match).
    let returnLossDB: Double?
    let reflectedPowerPercent: Double
    let transmittedPowerPercent: Double
    /// `nil` when Γ = 1 (no power is delivered).
    let mismatchLossDB: Double?

    func value(for quantity: ReflectionQuantity) -> Double? {
        switch quantity {
        case .vswr: return vswr
        case .returnLoss: return returnLossDB
        case .reflectionCoefficient: return gamma
        case .reflectedPower: return reflectedPowerPercent
        case .mismatchLoss: return mismatchLossDB
        }
    }

    /// Why a quantity is infinite, for the note under the result.
    func undefinedExplanation(for quantity: ReflectionQuantity) -> String? {
        switch quantity {
        case .returnLoss where returnLossDB == nil:
            return "Infinite — a perfect match reflects nothing."
        case .vswr where vswr == nil:
            return "Infinite — all power is reflected."
        case .mismatchLoss where mismatchLossDB == nil:
            return "Infinite — no power reaches the load."
        default:
            return nil
        }
    }
}

/// Conversions between VSWR, return loss, reflection coefficient, reflected
/// power and mismatch loss.
///
/// Implemented relationships:
///
///     |Γ|  = (VSWR - 1) / (VSWR + 1)
///     VSWR = (1 + |Γ|) / (1 - |Γ|)
///     RL   = -20 · log10|Γ|           (dB, positive by convention)
///     Pr   = |Γ|² · 100               (% of incident power reflected)
///     ML   = -10 · log10(1 - |Γ|²)    (dB)
///
/// Unit convention: return loss and mismatch loss are positive decibel
/// quantities; reflected power is a percentage; Γ is a magnitude with no unit.
/// The phase of Γ is out of scope — these are magnitude-only relationships.
enum ReflectionCalculator {
    /// Γ within this distance of 1 is treated as total reflection, which keeps
    /// floating-point noise from producing a huge but finite VSWR.
    private static let unityTolerance = 1e-12

    /// Solves every quantity from whichever one was entered.
    static func solve(from quantity: ReflectionQuantity, value: Double) throws -> ReflectionSolution {
        guard value.isFinite else {
            throw CalculationError.notANumber(quantity: quantity.title)
        }

        let gamma: Double
        switch quantity {
        case .vswr:
            guard value >= 1 else {
                throw CalculationError.outOfRange(quantity: "VSWR", requirement: "at least 1")
            }
            gamma = (value - 1) / (value + 1)

        case .returnLoss:
            guard value >= 0 else {
                throw CalculationError.outOfRange(
                    quantity: "Return loss",
                    requirement: "zero or positive — an S11 of -20 dB is 20 dB of return loss"
                )
            }
            gamma = pow(10.0, -value / 20.0)

        case .reflectionCoefficient:
            guard value >= 0, value <= 1 else {
                throw CalculationError.outOfRange(quantity: "|Γ|", requirement: "between 0 and 1")
            }
            gamma = value

        case .reflectedPower:
            guard value >= 0, value <= 100 else {
                throw CalculationError.outOfRange(
                    quantity: "Reflected power",
                    requirement: "between 0 and 100%"
                )
            }
            gamma = (value / 100).squareRoot()

        case .mismatchLoss:
            guard value >= 0 else {
                throw CalculationError.outOfRange(
                    quantity: "Mismatch loss",
                    requirement: "zero or positive"
                )
            }
            let transmitted = pow(10.0, -value / 10.0)
            gamma = max(0, 1 - transmitted).squareRoot()
        }

        return solution(gamma: min(max(gamma, 0), 1))
    }

    /// Derives every quantity from a reflection coefficient magnitude.
    static func solution(gamma rawGamma: Double) -> ReflectionSolution {
        let gamma = min(max(rawGamma, 0), 1)
        let isTotalReflection = gamma >= 1 - unityTolerance
        let isPerfectMatch = gamma <= unityTolerance

        let reflectedFraction = gamma * gamma
        let transmittedFraction = 1 - reflectedFraction

        let vswr: Double? = isTotalReflection ? nil : (1 + gamma) / (1 - gamma)
        let returnLoss: Double? = isPerfectMatch ? nil : -20 * log10(gamma)
        let mismatchLoss: Double? = isTotalReflection ? nil : -10 * log10(transmittedFraction)

        return ReflectionSolution(
            gamma: gamma,
            vswr: vswr.flatMap { $0.isFinite ? $0 : nil },
            returnLossDB: returnLoss.flatMap { $0.isFinite ? $0 : nil },
            reflectedPowerPercent: reflectedFraction * 100,
            transmittedPowerPercent: transmittedFraction * 100,
            mismatchLossDB: mismatchLoss.flatMap { $0.isFinite ? $0 : nil }
        )
    }
}
