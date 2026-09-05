import Foundation

/// The engineering categories used by both Calculators and Reference (spec §4).
///
/// Declaration order is display order.
enum RFCategory: String, CaseIterable, Identifiable, Hashable, Sendable {
    case fundamentals
    case signalsAndPower
    case reflectionAndLines
    case antennas
    case propagation
    case rfSystems
    case measurements

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fundamentals: return "Fundamentals"
        case .signalsAndPower: return "Signals & Power"
        case .reflectionAndLines: return "Reflection & Transmission Lines"
        case .antennas: return "Antennas"
        case .propagation: return "Propagation"
        case .rfSystems: return "RF Systems"
        case .measurements: return "Measurements"
        }
    }

    /// Fits in a navigation bar and on a compact row.
    var shortTitle: String {
        switch self {
        case .reflectionAndLines: return "Reflection & Lines"
        default: return title
        }
    }

    var summary: String {
        switch self {
        case .fundamentals:
            return "Units, decibels and the wave relationships everything else builds on."
        case .signalsAndPower:
            return "Power levels, gain, noise and how low a receiver can hear."
        case .reflectionAndLines:
            return "Mismatch, VSWR and what a transmission line does to a signal."
        case .antennas:
            return "Gain, aperture, polarisation and where the far field starts."
        case .propagation:
            return "Path loss, link budgets and clearance between two antennas."
        case .rfSystems:
            return "Cascades, noise figure, compression and dynamic range."
        case .measurements:
            return "Reading a spectrum or network analyser without being fooled."
        }
    }

    /// A single accent colour is used throughout, so categories are told apart
    /// by symbol and name rather than by colour (spec §12).
    var systemImage: String {
        switch self {
        case .fundamentals: return "function"
        case .signalsAndPower: return "bolt.horizontal.fill"
        case .reflectionAndLines: return "arrow.uturn.backward"
        case .antennas: return "antenna.radiowaves.left.and.right"
        case .propagation: return "dot.radiowaves.right"
        case .rfSystems: return "square.stack.3d.up"
        case .measurements: return "waveform"
        }
    }
}
