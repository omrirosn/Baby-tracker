import Foundation

/// Units of voltage. Base unit: volt.
///
/// Used for RMS, peak and peak-to-peak figures alike — which of the three a
/// value is depends on the label beside it, not on the unit.
enum VoltageUnit: String, PhysicalUnit {
    case microvolt = "uV"
    case millivolt = "mV"
    case volt = "V"
    case kilovolt = "kV"

    static let dimensionName = "Voltage"

    var symbol: String {
        switch self {
        case .microvolt: return "µV"
        case .millivolt: return "mV"
        case .volt: return "V"
        case .kilovolt: return "kV"
        }
    }

    var accessibilityName: String {
        switch self {
        case .microvolt: return "microvolts"
        case .millivolt: return "millivolts"
        case .volt: return "volts"
        case .kilovolt: return "kilovolts"
        }
    }

    private var factor: Double {
        switch self {
        case .microvolt: return 1e-6
        case .millivolt: return 1e-3
        case .volt: return 1
        case .kilovolt: return 1e3
        }
    }

    func toBase(_ value: Double) -> Double { value * factor }
    func fromBase(_ base: Double) -> Double { base / factor }
}
