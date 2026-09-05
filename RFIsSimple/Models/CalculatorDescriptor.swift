import Foundation

/// Every calculator in the MVP list (spec §5).
///
/// Declaration order is display order within a category. The identifier is the
/// persistence key for favourites and recents, so cases must not be renamed
/// without a migration.
enum CalculatorID: String, CaseIterable, Identifiable, Hashable, Sendable {
    case powerConverter
    case voltagePowerImpedance
    case wavelength
    case freeSpacePathLoss
    case linkBudget
    case thermalNoise
    case receiverSensitivity
    case reflectionConverter
    case cascadedGainNoiseFigure
    case eirp
    case effectiveAperture
    case farFieldDistance

    var id: String { rawValue }
}

/// Whether a calculator is usable yet.
enum ImplementationStatus: Hashable, Sendable {
    case available
    /// Listed so the shape of the product is visible, but not yet calculating.
    case planned
}

/// Everything the interface needs to show a calculator, apart from its inputs.
///
/// Holding this as data keeps the calculator page template identical across
/// calculators (spec §6) and lets search index calculators without touching
/// their views.
struct CalculatorDescriptor: Identifiable, Hashable, Sendable {
    let id: CalculatorID
    let title: String
    /// One sentence, two lines at most.
    let purpose: String
    let systemImage: String
    let category: RFCategory
    /// Alternative names, abbreviations and misspellings that should find this.
    let aliases: [String]
    let status: ImplementationStatus
    let formula: Formula?
    /// Two or three sentences on reading the result.
    let practicalNote: String
    /// One short warning, where there is one worth making.
    let commonMistake: String?
    let relatedArticles: [ReferenceArticleID]

    var isAvailable: Bool { status == .available }
}
