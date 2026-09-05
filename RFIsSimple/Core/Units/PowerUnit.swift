import Foundation

/// Units of RF power. Base unit: watt.
///
/// Conversions follow the standard definitions:
///
///     P(dBm) = 10 · log10(P / 1 mW)
///     P(dBW) = 10 · log10(P / 1 W)
///
/// so `0 dBm = 1 mW` and `30 dBm = 1 W`.
enum PowerUnit: String, PhysicalUnit {
    case dBm
    case dBW
    case watt = "W"
    case milliwatt = "mW"
    case microwatt = "uW"

    static let dimensionName = "Power"

    /// Only the linear units take part in automatic scaling; a dB value must
    /// never be rescaled behind the user's back.
    static var autoScaleCandidates: [PowerUnit] { [.microwatt, .milliwatt, .watt] }

    var symbol: String {
        switch self {
        case .dBm: return "dBm"
        case .dBW: return "dBW"
        case .watt: return "W"
        case .milliwatt: return "mW"
        case .microwatt: return "µW"
        }
    }

    var accessibilityName: String {
        switch self {
        case .dBm: return "dBm"
        case .dBW: return "dBW"
        case .watt: return "watts"
        case .milliwatt: return "milliwatts"
        case .microwatt: return "microwatts"
        }
    }

    var isLogarithmic: Bool {
        switch self {
        case .dBm, .dBW: return true
        case .watt, .milliwatt, .microwatt: return false
        }
    }

    func toBase(_ value: Double) -> Double {
        switch self {
        case .dBm: return pow(10.0, (value - 30.0) / 10.0)
        case .dBW: return pow(10.0, value / 10.0)
        case .watt: return value
        case .milliwatt: return value * 1e-3
        case .microwatt: return value * 1e-6
        }
    }

    func fromBase(_ base: Double) -> Double {
        switch self {
        case .dBm: return 10.0 * log10(base) + 30.0
        case .dBW: return 10.0 * log10(base)
        case .watt: return base
        case .milliwatt: return base * 1e3
        case .microwatt: return base * 1e6
        }
    }
}
