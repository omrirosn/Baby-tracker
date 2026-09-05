import SwiftUI

/// Reflection Converter (spec §5.8).
///
/// Any one of the five ways of describing a mismatch produces the other four,
/// plus the transmitted power. Quantities that are infinite rather than large —
/// the return loss of a perfect match — are shown as a dash with a reason.
struct ReflectionConverterView: View {
    private static let descriptor = CalculatorID.reflectionConverter.descriptor

    @State private var solveFrom: ReflectionQuantity = .vswr
    @State private var vswrText = ReflectionQuantity.vswr.defaultValue
    @State private var returnLossText = ReflectionQuantity.returnLoss.defaultValue
    @State private var gammaText = ReflectionQuantity.reflectionCoefficient.defaultValue
    @State private var reflectedPowerText = ReflectionQuantity.reflectedPower.defaultValue
    @State private var mismatchLossText = ReflectionQuantity.mismatchLoss.defaultValue
    @State private var editedQuantities: Set<ReflectionQuantity> = []
    @FocusState private var focusedField: String?

    // MARK: - Inputs

    private var activeText: Binding<String> {
        switch solveFrom {
        case .vswr: return $vswrText
        case .returnLoss: return $returnLossText
        case .reflectionCoefficient: return $gammaText
        case .reflectedPower: return $reflectedPowerText
        case .mismatchLoss: return $mismatchLossText
        }
    }

    private var activeValue: Double? {
        DecimalTextParser.parse(activeText.wrappedValue)
    }

    private var help: String? {
        switch solveFrom {
        case .vswr: return "1 is a perfect match. Values below 1 do not exist."
        case .returnLoss: return "Positive by convention: an S11 of −20 dB is 20 dB here."
        case .reflectionCoefficient: return "Magnitude only, between 0 and 1."
        case .reflectedPower: return "Percentage of incident power reflected, 0 to 100."
        case .mismatchLoss: return "Power lost to reflection, in dB. 0 is a perfect match."
        }
    }

    // MARK: - Calculation

    private var outcome: Result<ReflectionSolution, CalculationError>? {
        guard !activeText.wrappedValue.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        guard let value = activeValue else {
            return .failure(.notANumber(quantity: solveFrom.title))
        }
        do {
            return .success(try ReflectionCalculator.solve(from: solveFrom, value: value))
        } catch let error as CalculationError {
            return .failure(error)
        } catch {
            return .failure(.notANumber(quantity: solveFrom.title))
        }
    }

    private var solution: ReflectionSolution? {
        if case let .success(value)? = outcome { return value }
        return nil
    }

    private var issue: ValidationIssue? {
        guard editedQuantities.contains(solveFrom) else { return nil }
        guard case let .failure(error)? = outcome else { return nil }
        return ValidationIssue(error)
    }

    // MARK: - Results

    /// The prominent result is VSWR, unless VSWR is what was entered.
    private var primaryQuantity: ReflectionQuantity {
        solveFrom == .vswr ? .returnLoss : .vswr
    }

    private func resultValue(for quantity: ReflectionQuantity, in solution: ReflectionSolution) -> ResultValue {
        .scalar(
            id: quantity.rawValue,
            label: quantity.title,
            value: solution.value(for: quantity),
            unitSuffix: quantity.unitSuffix,
            spokenUnit: quantity.spokenUnit,
            note: solution.undefinedExplanation(for: quantity)
        )
    }

    private var results: (primary: ResultValue, secondary: [ResultValue])? {
        guard let solution else { return nil }

        let primary = resultValue(for: primaryQuantity, in: solution)
        var secondary = ReflectionQuantity.allCases
            .filter { $0 != solveFrom && $0 != primaryQuantity }
            .map { resultValue(for: $0, in: solution) }

        secondary.append(
            .scalar(
                id: "transmitted",
                label: "Transmitted power",
                value: solution.transmittedPowerPercent,
                unitSuffix: "%",
                spokenUnit: "percent"
            )
        )
        return (primary, secondary)
    }

    // MARK: - View

    var body: some View {
        CalculatorPage(descriptor: Self.descriptor) {
            InputCard {
                Picker("Solve from", selection: $solveFrom) {
                    ForEach(ReflectionQuantity.allCases) { quantity in
                        Text(quantity.shortTitle).tag(quantity)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Solve from")
                .padding(.bottom, 4)

                ScalarInputRow(
                    title: solveFrom.title,
                    fieldID: solveFrom.rawValue,
                    text: activeText,
                    unitSuffix: solveFrom.unitSuffix,
                    placeholder: solveFrom.defaultValue,
                    help: help,
                    issue: issue,
                    accessibilityUnit: solveFrom.spokenUnit,
                    focusedField: $focusedField
                )
                .onChange(of: activeText.wrappedValue) { _, _ in
                    editedQuantities.insert(solveFrom)
                }
            }

            if let results {
                ResultCard(
                    primary: results.primary,
                    secondary: results.secondary,
                    footnote: "Magnitudes only — the phase of Γ is not part of these relationships."
                )
            } else {
                EmptyResultCard(message: "Enter a value to convert between all five.")
            }
        }
        .keyboardDoneButton(focusedField: $focusedField)
    }
}

#Preview {
    NavigationStack {
        ReflectionConverterView()
    }
    .environment(PreferencesStore.preview)
}
