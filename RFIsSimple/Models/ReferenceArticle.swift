import Foundation

/// Every reference page. Declaration order is display order within a category.
///
/// The identifier is the persistence key for favourites and recents, so cases
/// must not be renamed without a migration.
enum ReferenceArticleID: String, CaseIterable, Identifiable, Hashable, Sendable {
    // Fundamentals
    case decibels
    case dbmAndDbw
    case frequencyPeriodWavelength
    case impedanceBasics
    case spectrumBands

    // Signals & Power
    case powerConversion
    case voltagePowerImpedance
    case gainAndLoss
    case eirpAndErp
    case thermalNoise
    case receiverSensitivity

    // Reflection & Transmission Lines
    case reflectionCoefficient
    case returnLoss
    case vswr
    case mismatchLoss
    case characteristicImpedance
    case electricalLength

    // Antennas
    case antennaGain
    case radiationEfficiency
    case effectiveAperture
    case polarisation
    case nearAndFarField

    // Propagation
    case freeSpacePathLoss
    case linkBudget
    case fresnelZone
    case dopplerShift
    case propagationDelay

    // RF Systems
    case cascadedGain
    case noiseFigure
    case noiseTemperature
    case p1dB
    case thirdOrderIntercept
    case dynamicRange

    // Measurements
    case resolutionBandwidth
    case displayedAverageNoiseLevel
    case sParameters
    case cableAndConnectorLoss

    var id: String { rawValue }
}

/// A reference page, held to the template in spec §7.
///
/// Everything here is short on purpose: a definition, the relationship, at most
/// three practical points, one mistake worth avoiding, and where to go next.
struct ReferenceArticle: Identifiable, Hashable, Sendable {
    let id: ReferenceArticleID
    let title: String
    /// One line under the title in a list.
    let descriptor: String
    let category: RFCategory
    /// One or two sentences.
    let definition: String
    let keyRelationship: Formula?
    /// At most three bullets.
    let inPractice: [String]
    /// At most one sentence.
    let commonMistake: String?
    let relatedCalculators: [CalculatorID]
    let relatedArticles: [ReferenceArticleID]
    let aliases: [String]

    /// Rough length check used by the content tests to keep pages within the
    /// 80–180 word target.
    var approximateWordCount: Int {
        let body = ([definition] + inPractice + [commonMistake ?? ""]).joined(separator: " ")
        return body.split { $0 == " " || $0 == "\n" }.count
    }
}
