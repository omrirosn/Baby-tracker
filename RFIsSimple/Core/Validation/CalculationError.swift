import Foundation

/// Why a calculation could not produce a result.
///
/// Every case carries the name of the quantity involved so the message can be
/// shown next to the field that caused it, and so no calculation ever fails
/// silently or guesses at what the user meant (spec §14).
enum CalculationError: Error, Equatable, Hashable, Sendable {
    /// A required field is empty.
    case missingValue(quantity: String)
    /// The field holds something that is not a usable number.
    case notANumber(quantity: String)
    /// The quantity must be greater than zero (frequency, wavelength, impedance…).
    case mustBePositive(quantity: String)
    /// The quantity may be zero but not negative (linear power, distance…).
    case mustBeNonNegative(quantity: String)
    /// The value falls outside the range the relationship is defined over.
    case outOfRange(quantity: String, requirement: String)
    /// The inputs are valid but the result has no finite value.
    case undefinedResult(explanation: String)

    var message: String {
        switch self {
        case let .missingValue(quantity):
            return "Enter a value for \(quantity)."
        case let .notANumber(quantity):
            return "\(quantity) is not a valid number."
        case let .mustBePositive(quantity):
            return "\(quantity) must be greater than zero."
        case let .mustBeNonNegative(quantity):
            return "\(quantity) cannot be negative."
        case let .outOfRange(quantity, requirement):
            return "\(quantity) must be \(requirement)."
        case let .undefinedResult(explanation):
            return explanation
        }
    }
}
