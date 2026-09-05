import Foundation

/// One stage in a chain: its gain (negative for a loss) and its noise figure.
struct CascadeStage: Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    var name: String
    var gainDB: Double
    var noiseFigureDB: Double

    init(id: UUID = UUID(), name: String = "", gainDB: Double, noiseFigureDB: Double) {
        self.id = id
        self.name = name
        self.gainDB = gainDB
        self.noiseFigureDB = noiseFigureDB
    }

    var linearGain: Double { pow(10.0, gainDB / 10) }
    var linearNoiseFactor: Double { pow(10.0, noiseFigureDB / 10) }
}

/// What one stage contributes to the total noise figure.
struct StageContribution: Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    let name: String
    /// The stage's term in the Friis sum, in linear noise factor.
    let noiseFactorTerm: Double
    /// That term as a share of the total, 0–100%.
    let sharePercent: Double
    /// Cumulative gain ahead of this stage, dB.
    let precedingGainDB: Double
}

struct CascadeSolution: Equatable, Hashable, Sendable {
    let totalGainDB: Double
    let totalNoiseFigureDB: Double
    let contributions: [StageContribution]

    /// Equivalent input noise temperature of the whole chain, K.
    var equivalentNoiseTemperature: Double {
        PhysicalConstants.standardNoiseTemperature * (pow(10.0, totalNoiseFigureDB / 10) - 1)
    }
}

/// Cascaded gain and noise figure (spec §5.9).
///
/// Implemented relationships — the Friis cascade, which works in *linear*
/// noise factor, not in decibels:
///
///     G_total(dB) = Σ Gₙ(dB)
///     F_total     = F₁ + (F₂−1)/G₁ + (F₃−1)/(G₁·G₂) + …
///     NF_total    = 10·log10(F_total)
///
/// Unit convention: every stage takes gain and noise figure in dB; a passive
/// loss is entered as a negative gain. Stage order matters for noise figure
/// and is preserved exactly as given.
enum CascadeCalculator {
    static func solve(stages: [CascadeStage]) throws -> CascadeSolution {
        guard !stages.isEmpty else {
            throw CalculationError.missingValue(quantity: "At least one stage")
        }

        for (index, stage) in stages.enumerated() {
            let position = index + 1
            guard stage.gainDB.isFinite else {
                throw CalculationError.notANumber(quantity: "Gain of stage \(position)")
            }
            guard stage.noiseFigureDB.isFinite else {
                throw CalculationError.notANumber(quantity: "Noise figure of stage \(position)")
            }
            guard stage.noiseFigureDB >= 0 else {
                throw CalculationError.mustBeNonNegative(quantity: "Noise figure of stage \(position)")
            }
        }

        var totalGainDB: Double = 0
        var cumulativeLinearGain: Double = 1
        var totalNoiseFactor: Double = 0
        var terms: [(stage: CascadeStage, term: Double, precedingGainDB: Double)] = []

        for stage in stages {
            let term = (stage.linearNoiseFactor - 1) / cumulativeLinearGain
            terms.append((stage, term, totalGainDB))

            totalNoiseFactor += term
            totalGainDB += stage.gainDB
            cumulativeLinearGain *= stage.linearGain

            guard cumulativeLinearGain > 0, cumulativeLinearGain.isFinite else {
                throw CalculationError.outOfRange(
                    quantity: "Cascade gain",
                    requirement: "within the range this relationship can represent"
                )
            }
        }

        // Friis gives F − 1 as the sum of the terms; the first stage's own
        // noise factor supplies the leading 1.
        totalNoiseFactor += 1
        let totalNoiseFigure = 10 * log10(totalNoiseFactor)

        guard totalGainDB.isFinite, totalNoiseFigure.isFinite else {
            throw CalculationError.outOfRange(
                quantity: "Cascade",
                requirement: "within the range this relationship can represent"
            )
        }

        let excess = max(totalNoiseFactor - 1, .leastNormalMagnitude)
        let contributions = terms.map { entry in
            StageContribution(
                id: entry.stage.id,
                name: entry.stage.name,
                noiseFactorTerm: entry.term,
                sharePercent: entry.term / excess * 100,
                precedingGainDB: entry.precedingGainDB
            )
        }

        return CascadeSolution(
            totalGainDB: totalGainDB,
            totalNoiseFigureDB: totalNoiseFigure,
            contributions: contributions
        )
    }

    /// A lossy passive stage has a noise figure equal to its loss. Offered as a
    /// convenience when a stage is entered with negative gain and no noise
    /// figure — never applied silently.
    static func passiveNoiseFigure(forGainDB gainDB: Double) -> Double? {
        guard gainDB < 0 else { return nil }
        return -gainDB
    }

    /// The chain a new sheet starts with: an amplifier after a little cable loss.
    static var defaultStages: [CascadeStage] {
        [
            CascadeStage(name: "Feedline", gainDB: -1.5, noiseFigureDB: 1.5),
            CascadeStage(name: "LNA", gainDB: 20, noiseFigureDB: 1),
            CascadeStage(name: "Mixer", gainDB: -7, noiseFigureDB: 7)
        ]
    }
}
