import Foundation

/// One variable in a formula, held to a single short line (spec §6).
struct VariableDefinition: Hashable, Identifiable, Sendable {
    let symbol: String
    let meaning: String

    var id: String { symbol }
}

/// A formula as it is shown and as it is spoken.
///
/// Formulas are plain text rendered in a monospaced font rather than typeset
/// maths: it keeps the app dependency-free, and it copies cleanly (spec §19
/// records this as a decision that can be revisited).
struct Formula: Hashable, Sendable {
    /// The expression, e.g. `λ = v / f`.
    let expression: String
    let variables: [VariableDefinition]
    /// Read aloud instead of the symbols, which VoiceOver cannot pronounce.
    let spokenDescription: String

    init(expression: String, variables: [VariableDefinition] = [], spokenDescription: String) {
        self.expression = expression
        self.variables = variables
        self.spokenDescription = spokenDescription
    }
}
