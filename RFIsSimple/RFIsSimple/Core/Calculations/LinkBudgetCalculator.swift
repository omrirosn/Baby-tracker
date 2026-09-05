import Foundation

/// The terms of a link budget, all in decibels except the transmit power.
struct LinkBudgetInput: Equatable, Hashable, Sendable {
    var transmitPowerDBm: Double
    var transmitLossDB: Double
    var transmitGainDBi: Double
    var pathLossDB: Double
    var receiveGainDBi: Double
    var receiveLossDB: Double
    /// Optional: without it there is a received power but no margin.
    var sensitivityDBm: Double?

    init(
        transmitPowerDBm: Double,
        transmitLossDB: Double = 0,
        transmitGainDBi: Double = 0,
        pathLossDB: Double,
        receiveGainDBi: Double = 0,
        receiveLossDB: Double = 0,
        sensitivityDBm: Double? = nil
    ) {
        self.transmitPowerDBm = transmitPowerDBm
        self.transmitLossDB = transmitLossDB
        self.transmitGainDBi = transmitGainDBi
        self.pathLossDB = pathLossDB
        self.receiveGainDBi = receiveGainDBi
        self.receiveLossDB = receiveLossDB
        self.sensitivityDBm = sensitivityDBm
    }
}

struct LinkBudgetSolution: Equatable, Hashable, Sendable {
    let receivedPowerDBm: Double
    /// EIRP at the transmit antenna, dBm.
    let eirpDBm: Double
    /// `nil` when no sensitivity was supplied.
    let marginDB: Double?

    /// Whether the link closes at all, when a sensitivity is known.
    var closes: Bool? {
        guard let marginDB else { return nil }
        return marginDB >= 0
    }
}

/// Link budget (spec §5.5).
///
/// Implemented relationship — a running sum in decibels:
///
///     P_rx = P_tx − L_tx + G_tx − L_path + G_rx − L_rx
///     Margin = P_rx − Sensitivity
///
/// Unit convention: transmit power and sensitivity in dBm, everything else in
/// dB. Losses are entered as positive numbers and subtracted, which is how
/// datasheets quote them.
enum LinkBudgetCalculator {
    static func solve(_ input: LinkBudgetInput) throws -> LinkBudgetSolution {
        let terms: [(String, Double)] = [
            ("Transmit power", input.transmitPowerDBm),
            ("Transmit loss", input.transmitLossDB),
            ("Transmit antenna gain", input.transmitGainDBi),
            ("Path loss", input.pathLossDB),
            ("Receive antenna gain", input.receiveGainDBi),
            ("Receive loss", input.receiveLossDB)
        ]
        for (name, value) in terms where !value.isFinite {
            throw CalculationError.notANumber(quantity: name)
        }
        if let sensitivity = input.sensitivityDBm, !sensitivity.isFinite {
            throw CalculationError.notANumber(quantity: "Receiver sensitivity")
        }
        guard input.transmitLossDB >= 0 else {
            throw CalculationError.mustBeNonNegative(quantity: "Transmit loss")
        }
        guard input.receiveLossDB >= 0 else {
            throw CalculationError.mustBeNonNegative(quantity: "Receive loss")
        }
        guard input.pathLossDB >= 0 else {
            throw CalculationError.mustBeNonNegative(quantity: "Path loss")
        }

        let eirp = input.transmitPowerDBm - input.transmitLossDB + input.transmitGainDBi
        let received = eirp - input.pathLossDB + input.receiveGainDBi - input.receiveLossDB

        guard received.isFinite else {
            throw CalculationError.outOfRange(
                quantity: "Link budget",
                requirement: "within the range this relationship can represent"
            )
        }

        return LinkBudgetSolution(
            receivedPowerDBm: received,
            eirpDBm: eirp,
            marginDB: input.sensitivityDBm.map { received - $0 }
        )
    }
}

// MARK: - EIRP and ERP

/// How an antenna gain figure is referenced.
enum GainReference: String, CaseIterable, Identifiable, Sendable {
    /// Relative to an isotropic radiator.
    case dBi
    /// Relative to a half-wave dipole.
    case dBd

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .dBi: return "dBi"
        case .dBd: return "dBd"
        }
    }

    /// A dipole has 2.15 dB of gain over an isotropic radiator.
    static let dipoleGainDBi: Double = 2.15

    /// Converts a gain in this reference to dBi.
    func toDBi(_ gain: Double) -> Double {
        switch self {
        case .dBi: return gain
        case .dBd: return gain + Self.dipoleGainDBi
        }
    }
}

struct RadiatedPowerSolution: Equatable, Hashable, Sendable {
    let eirpDBm: Double
    let erpDBm: Double
    let antennaGainDBi: Double

    var eirpWatts: Double { pow(10.0, (eirpDBm - 30) / 10) }
    var erpWatts: Double { pow(10.0, (erpDBm - 30) / 10) }
}

/// EIRP and ERP (spec §5.10).
///
/// Implemented relationships:
///
///     EIRP(dBm) = P_tx − L_feed + G(dBi)
///     ERP       = EIRP − 2.15 dB
///     G(dBi)    = G(dBd) + 2.15 dB
///
/// Unit convention: transmit power in dBm, losses and gains in dB.
enum RadiatedPowerCalculator {
    static func solve(
        transmitPowerDBm: Double,
        feedLossDB: Double,
        antennaGain: Double,
        reference: GainReference
    ) throws -> RadiatedPowerSolution {
        guard transmitPowerDBm.isFinite else {
            throw CalculationError.notANumber(quantity: "Transmitter power")
        }
        guard feedLossDB.isFinite else {
            throw CalculationError.notANumber(quantity: "Feed loss")
        }
        guard antennaGain.isFinite else {
            throw CalculationError.notANumber(quantity: "Antenna gain")
        }
        guard feedLossDB >= 0 else {
            throw CalculationError.mustBeNonNegative(quantity: "Feed loss")
        }

        let gainDBi = reference.toDBi(antennaGain)
        let eirp = transmitPowerDBm - feedLossDB + gainDBi
        let erp = eirp - GainReference.dipoleGainDBi

        guard eirp.isFinite, erp.isFinite else {
            throw CalculationError.outOfRange(
                quantity: "EIRP",
                requirement: "within the range this relationship can represent"
            )
        }

        return RadiatedPowerSolution(eirpDBm: eirp, erpDBm: erp, antennaGainDBi: gainDBi)
    }
}
