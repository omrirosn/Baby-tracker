import Foundation

/// Units of frequency. Base unit: hertz.
enum FrequencyUnit: String, PhysicalUnit {
    case hertz = "Hz"
    case kilohertz = "kHz"
    case megahertz = "MHz"
    case gigahertz = "GHz"
    case terahertz = "THz"

    static let dimensionName = "Frequency"

    var symbol: String { rawValue }

    var accessibilityName: String {
        switch self {
        case .hertz: return "hertz"
        case .kilohertz: return "kilohertz"
        case .megahertz: return "megahertz"
        case .gigahertz: return "gigahertz"
        case .terahertz: return "terahertz"
        }
    }

    private var factor: Double {
        switch self {
        case .hertz: return 1
        case .kilohertz: return 1e3
        case .megahertz: return 1e6
        case .gigahertz: return 1e9
        case .terahertz: return 1e12
        }
    }

    func toBase(_ value: Double) -> Double { value * factor }
    func fromBase(_ base: Double) -> Double { base / factor }
}
