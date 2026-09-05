import Foundation

/// Units of time, used for signal period and propagation delay. Base unit: second.
enum TimeUnit: String, PhysicalUnit {
    case second = "s"
    case millisecond = "ms"
    case microsecond = "us"
    case nanosecond = "ns"
    case picosecond = "ps"

    static let dimensionName = "Time"

    var symbol: String {
        switch self {
        case .second: return "s"
        case .millisecond: return "ms"
        case .microsecond: return "µs"
        case .nanosecond: return "ns"
        case .picosecond: return "ps"
        }
    }

    var accessibilityName: String {
        switch self {
        case .second: return "seconds"
        case .millisecond: return "milliseconds"
        case .microsecond: return "microseconds"
        case .nanosecond: return "nanoseconds"
        case .picosecond: return "picoseconds"
        }
    }

    private var factor: Double {
        switch self {
        case .second: return 1
        case .millisecond: return 1e-3
        case .microsecond: return 1e-6
        case .nanosecond: return 1e-9
        case .picosecond: return 1e-12
        }
    }

    func toBase(_ value: Double) -> Double { value * factor }
    func fromBase(_ base: Double) -> Double { base / factor }
}
