import Foundation

/// Units of temperature. Base unit: kelvin.
///
/// Celsius converts by an offset rather than a factor, which is why the unit
/// layer takes conversion functions rather than a multiplier. Temperature is
/// never auto-scaled — "290 K" must not turn into "0.29 kK".
enum TemperatureUnit: String, PhysicalUnit {
    case kelvin = "K"
    case celsius = "C"

    static let dimensionName = "Temperature"

    /// Nothing to scale between: both units are read at human scale.
    static var autoScaleCandidates: [TemperatureUnit] { [] }

    var symbol: String {
        switch self {
        case .kelvin: return "K"
        case .celsius: return "°C"
        }
    }

    var accessibilityName: String {
        switch self {
        case .kelvin: return "kelvin"
        case .celsius: return "degrees Celsius"
        }
    }

    /// Below −273.15 °C is unphysical, but the field has to accept a leading
    /// minus for ordinary Celsius values.
    var allowsNegativeValues: Bool {
        self == .celsius
    }

    func toBase(_ value: Double) -> Double {
        switch self {
        case .kelvin: return value
        case .celsius: return value + 273.15
        }
    }

    func fromBase(_ base: Double) -> Double {
        switch self {
        case .kelvin: return base
        case .celsius: return base - 273.15
        }
    }
}
