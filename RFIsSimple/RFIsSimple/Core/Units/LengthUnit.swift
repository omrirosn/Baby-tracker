import Foundation

/// Units of length, used for wavelength, antenna dimensions and link distance.
/// Base unit: metre.
///
/// Imperial units convert by the international definitions
/// (1 in = 25.4 mm exactly), and are excluded from automatic scaling so a
/// metric result never turns into inches on its own.
enum LengthUnit: String, PhysicalUnit {
    case millimetre = "mm"
    case centimetre = "cm"
    case metre = "m"
    case kilometre = "km"
    case inch = "in"
    case foot = "ft"
    case mile = "mi"

    static let dimensionName = "Length"

    static var autoScaleCandidates: [LengthUnit] { [.millimetre, .centimetre, .metre, .kilometre] }

    var symbol: String { rawValue }

    var accessibilityName: String {
        switch self {
        case .millimetre: return "millimetres"
        case .centimetre: return "centimetres"
        case .metre: return "metres"
        case .kilometre: return "kilometres"
        case .inch: return "inches"
        case .foot: return "feet"
        case .mile: return "miles"
        }
    }

    private var factor: Double {
        switch self {
        case .millimetre: return 1e-3
        case .centimetre: return 1e-2
        case .metre: return 1
        case .kilometre: return 1e3
        case .inch: return 0.0254
        case .foot: return 0.3048
        case .mile: return 1609.344
        }
    }

    func toBase(_ value: Double) -> Double { value * factor }
    func fromBase(_ base: Double) -> Double { base / factor }
}
