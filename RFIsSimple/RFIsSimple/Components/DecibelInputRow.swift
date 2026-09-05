import SwiftUI

/// A decibel field — the workhorse of the link-budget and noise calculators.
///
/// Wraps `ScalarInputRow` with the right keyboard, suffix and spoken unit, so
/// the nine calculators that take dB values do not each repeat them.
struct DecibelInputRow: View {
    let title: String
    let fieldID: String
    @Binding var text: String
    /// `dB` for a ratio, `dBm` for an absolute level.
    var suffix: String = "dB"
    /// Losses and noise figures are positive; gains and levels may be negative.
    var allowsNegative: Bool = true
    var placeholder: String = "0"
    var help: String?
    var issue: ValidationIssue?
    @FocusState.Binding var focusedField: String?

    init(
        title: String,
        fieldID: String,
        text: Binding<String>,
        suffix: String = "dB",
        allowsNegative: Bool = true,
        placeholder: String = "0",
        help: String? = nil,
        issue: ValidationIssue? = nil,
        focusedField: FocusState<String?>.Binding
    ) {
        self.title = title
        self.fieldID = fieldID
        self._text = text
        self.suffix = suffix
        self.allowsNegative = allowsNegative
        self.placeholder = placeholder
        self.help = help
        self.issue = issue
        self._focusedField = focusedField
    }

    private var spokenUnit: String {
        switch suffix {
        case "dBm": return "dBm"
        case "dBi": return "dBi"
        case "dBd": return "dBd"
        case "Ω": return "ohms"
        case "%": return "percent"
        default: return "decibels"
        }
    }

    var body: some View {
        ScalarInputRow(
            title: title,
            fieldID: fieldID,
            text: $text,
            unitSuffix: suffix,
            allowsNegative: allowsNegative,
            placeholder: placeholder,
            help: help,
            issue: issue,
            accessibilityUnit: spokenUnit,
            focusedField: $focusedField
        )
    }
}

/// Reads a decibel field, treating an empty field as a supplied zero where the
/// calculator wants one, and as "not supplied" where the term is optional.
enum DecibelField {
    /// Parsed value, or `nil` when the field is empty or unparsable.
    static func value(_ text: String) -> Double? {
        DecimalTextParser.parse(text)
    }

    /// Parsed value, defaulting an empty field to `fallback`.
    static func value(_ text: String, orEmpty fallback: Double) -> Double? {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return fallback }
        return DecimalTextParser.parse(text)
    }

    static func isEmpty(_ text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// An error only once the field has been touched and holds something that
    /// is not a number.
    static func parseIssue(_ text: String, name: String, edited: Bool) -> ValidationIssue? {
        guard edited, !isEmpty(text), DecimalTextParser.parse(text) == nil else { return nil }
        return ValidationIssue(CalculationError.notANumber(quantity: name))
    }
}

private struct DecibelInputRowPreview: View {
    @State private var gain = "20"
    @State private var loss = "1.5"
    @FocusState private var focusedField: String?

    var body: some View {
        VStack(spacing: 8) {
            DecibelInputRow(title: "Antenna gain", fieldID: "gain", text: $gain, suffix: "dBi",
                            focusedField: $focusedField)
            Divider()
            DecibelInputRow(title: "Feedline loss", fieldID: "loss", text: $loss,
                            allowsNegative: false,
                            help: "Enter as a positive number.",
                            focusedField: $focusedField)
        }
        .rfCard()
        .padding()
        .rfPageBackground()
    }
}

#Preview {
    DecibelInputRowPreview()
}
