import SwiftUI
import UIKit

/// Shared layout for one input: label, field, and a trailing accessory that is
/// either a unit selector or a fixed unit label (spec §6).
///
/// At accessibility text sizes the row becomes two lines so nothing is clipped.
struct InputRowLayout<Accessory: View>: View {
    let title: String
    /// Identity used for focus, unique within a screen.
    let fieldID: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let placeholder: String
    /// One short line under the field.
    let help: String?
    /// Shown only once the caller decides the field has been edited.
    let issue: ValidationIssue?
    /// Spoken after the value, e.g. "megahertz".
    let accessibilityUnit: String?
    @FocusState.Binding var focusedField: String?
    let accessory: () -> Accessory

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        title: String,
        fieldID: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .decimalPad,
        placeholder: String = "0",
        help: String? = nil,
        issue: ValidationIssue? = nil,
        accessibilityUnit: String? = nil,
        focusedField: FocusState<String?>.Binding,
        @ViewBuilder accessory: @escaping () -> Accessory
    ) {
        self.title = title
        self.fieldID = fieldID
        self._text = text
        self.keyboardType = keyboardType
        self.placeholder = placeholder
        self.help = help
        self.issue = issue
        self.accessibilityUnit = accessibilityUnit
        self._focusedField = focusedField
        self.accessory = accessory
    }

    private var field: some View {
        HStack(spacing: 8) {
            TextField(text: $text, prompt: Text(placeholder)) {
                Text(title)
            }
            .keyboardType(keyboardType)
            .textFieldStyle(.plain)
            .multilineTextAlignment(.trailing)
            .font(.body.monospacedDigit())
            .focused($focusedField, equals: fieldID)
            .submitLabel(.done)
            .frame(minWidth: 90, minHeight: AppMetrics.minimumTapTarget)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.rfFieldBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(issue?.severity == .error ? Color.red : Color.clear, lineWidth: 1)
            )
            .accessibilityLabel(title)
            .accessibilityValue(accessibilityValue)

            accessory()
        }
    }

    private var accessibilityValue: String {
        let spokenNumber = text.isEmpty ? "empty" : text
        guard let accessibilityUnit else { return spokenNumber }
        return "\(spokenNumber) \(accessibilityUnit)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.subheadline)
                    field
                }
            } else {
                HStack(spacing: 12) {
                    Text(title)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    field
                }
            }

            if let help {
                Text(help)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let issue {
                ValidationLabel(issue: issue)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Message under a field. Icon plus words, so state never depends on colour.
struct ValidationLabel: View {
    let issue: ValidationIssue

    var body: some View {
        Label {
            Text(issue.message)
        } icon: {
            Image(systemName: issue.systemImage)
        }
        .font(.footnote)
        .foregroundStyle(issue.severity == .error ? Color.red : Color.secondary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(issue.accessibilityPrefix). \(issue.message)")
    }
}

/// A numeric field with a unit selector beside it.
struct NumericInputRow<U: PhysicalUnit>: View {
    let title: String
    let fieldID: String
    @Binding var input: MeasuredInput<U>
    var help: String?
    var issue: ValidationIssue?
    @FocusState.Binding var focusedField: String?

    init(
        title: String,
        fieldID: String,
        input: Binding<MeasuredInput<U>>,
        help: String? = nil,
        issue: ValidationIssue? = nil,
        focusedField: FocusState<String?>.Binding
    ) {
        self.title = title
        self.fieldID = fieldID
        self._input = input
        self.help = help
        self.issue = issue
        self._focusedField = focusedField
    }

    /// A dB field needs a minus sign, which the decimal pad does not offer.
    private var keyboardType: UIKeyboardType {
        input.unit.allowsNegativeValues ? .numbersAndPunctuation : .decimalPad
    }

    private var unitBinding: Binding<U> {
        Binding(
            get: { input.unit },
            set: { input.setUnit($0) }
        )
    }

    var body: some View {
        InputRowLayout(
            title: title,
            fieldID: fieldID,
            text: $input.text,
            keyboardType: keyboardType,
            help: help,
            issue: issue,
            accessibilityUnit: input.unit.accessibilityName,
            focusedField: $focusedField
        ) {
            UnitSelector(selection: unitBinding)
        }
        .onChange(of: input.text) { _, _ in
            input.hasBeenEdited = true
        }
    }
}

/// A numeric field with no unit to choose — a ratio, a percentage, or a
/// quantity whose unit is fixed.
struct ScalarInputRow: View {
    let title: String
    let fieldID: String
    @Binding var text: String
    var unitSuffix: String?
    var allowsNegative: Bool = false
    var placeholder: String = "0"
    var help: String?
    var issue: ValidationIssue?
    var accessibilityUnit: String?
    @FocusState.Binding var focusedField: String?

    init(
        title: String,
        fieldID: String,
        text: Binding<String>,
        unitSuffix: String? = nil,
        allowsNegative: Bool = false,
        placeholder: String = "0",
        help: String? = nil,
        issue: ValidationIssue? = nil,
        accessibilityUnit: String? = nil,
        focusedField: FocusState<String?>.Binding
    ) {
        self.title = title
        self.fieldID = fieldID
        self._text = text
        self.unitSuffix = unitSuffix
        self.allowsNegative = allowsNegative
        self.placeholder = placeholder
        self.help = help
        self.issue = issue
        self.accessibilityUnit = accessibilityUnit
        self._focusedField = focusedField
    }

    var body: some View {
        InputRowLayout(
            title: title,
            fieldID: fieldID,
            text: $text,
            keyboardType: allowsNegative ? .numbersAndPunctuation : .decimalPad,
            placeholder: placeholder,
            help: help,
            issue: issue,
            accessibilityUnit: accessibilityUnit,
            focusedField: $focusedField
        ) {
            if let unitSuffix {
                UnitLabel(text: unitSuffix)
            }
        }
    }
}

private struct InputRowsPreview: View {
    @State private var power = MeasuredInput<PowerUnit>(text: "0", unit: .dBm)
    @State private var frequency = MeasuredInput<FrequencyUnit>(text: "2400", unit: .megahertz)
    @State private var vswr = "1.5"
    @FocusState private var focusedField: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                NumericInputRow(
                    title: "Power",
                    fieldID: "power",
                    input: $power,
                    focusedField: $focusedField
                )
                Divider()
                NumericInputRow(
                    title: "Frequency",
                    fieldID: "frequency",
                    input: $frequency,
                    help: "Centre frequency of the signal.",
                    focusedField: $focusedField
                )
                Divider()
                ScalarInputRow(
                    title: "VSWR",
                    fieldID: "vswr",
                    text: $vswr,
                    unitSuffix: ": 1",
                    issue: .error("VSWR must be at least 1."),
                    accessibilityUnit: "to one",
                    focusedField: $focusedField
                )
            }
            .rfCard()
            .padding()
        }
        .rfPageBackground()
    }
}

#Preview {
    InputRowsPreview()
}
