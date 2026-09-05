import SwiftUI

/// Power Converter (spec §5.1).
///
/// One value in, every other unit out. The result updates as the value is
/// typed — there is no Calculate button.
struct PowerConverterView: View {
    private static let descriptor = CalculatorID.powerConverter.descriptor
    private static let unitKey = "powerConverter.power"
    /// 1 W, expressed as dBm — the starting point when nothing is stored.
    private static let defaultInput = MeasuredInput<PowerUnit>(text: "30", unit: .dBm)

    @Environment(PreferencesStore.self) private var store

    @State private var input = PowerConverterView.defaultInput
    @State private var hasRestoredUnit = false
    @FocusState private var focusedField: String?

    // MARK: - Calculation

    private var outcome: Result<PowerConversion, CalculationError>? {
        guard !input.isEmpty else { return nil }
        guard let value = input.value else {
            return .failure(.notANumber(quantity: "Power"))
        }
        do {
            return .success(try PowerConversion.from(value: value, unit: input.unit))
        } catch let error as CalculationError {
            return .failure(error)
        } catch {
            return .failure(.notANumber(quantity: "Power"))
        }
    }

    /// Errors stay hidden until the field has been touched (spec §6).
    private var issue: ValidationIssue? {
        guard input.hasBeenEdited else { return nil }
        if case let .failure(error)? = outcome { return ValidationIssue(error) }
        return nil
    }

    private var conversion: PowerConversion? {
        if case let .success(value)? = outcome { return value }
        return nil
    }

    /// A logarithmic entry is most useful shown in watts, and a linear entry in
    /// dBm — so the prominent result is always the one the user did not type.
    private var primaryUnit: PowerUnit {
        guard let conversion else { return .watt }
        return input.unit.isLogarithmic ? conversion.preferredLinearUnit : .dBm
    }

    private var undefinedNote: String? {
        guard let conversion, conversion.watts <= 0 else { return nil }
        return "Zero power has no decibel equivalent."
    }

    private var primaryResult: ResultValue? {
        guard let conversion else { return nil }
        let unit = primaryUnit
        let value = conversion.value(in: unit)
        return .make(
            id: "primary",
            label: "Power",
            value: value,
            unit: unit,
            note: value == nil ? undefinedNote : nil
        )
    }

    private var secondaryResults: [ResultValue] {
        guard let conversion else { return [] }
        return PowerUnit.allCases
            .filter { $0 != input.unit && $0 != primaryUnit }
            .map { unit in
                let value = conversion.value(in: unit)
                return .make(
                    id: unit.rawValue,
                    label: unit.symbol,
                    value: value,
                    unit: unit,
                    note: value == nil ? undefinedNote : nil
                )
            }
    }

    // MARK: - View

    var body: some View {
        CalculatorPage(descriptor: Self.descriptor) {
            InputCard {
                NumericInputRow(
                    title: "Power",
                    fieldID: "power",
                    input: $input,
                    help: input.unit.isLogarithmic ? nil : "Linear power cannot be negative.",
                    issue: issue,
                    focusedField: $focusedField
                )
            }

            if let primaryResult {
                ResultCard(
                    primary: primaryResult,
                    secondary: secondaryResults,
                    footnote: "Shown to four significant digits; copying keeps full precision."
                )
            } else {
                EmptyResultCard(message: "Enter a power level to see the conversion.")
            }
        }
        .keyboardDoneButton(focusedField: $focusedField)
        .onAppear(perform: restoreUnitIfNeeded)
        .onChange(of: input.unit) { _, newUnit in
            store.setLastUsedUnit(newUnit, for: Self.unitKey)
        }
    }

    /// Restores the unit last used here, converting the default so the physical
    /// value stays the same whichever unit comes back.
    private func restoreUnitIfNeeded() {
        guard !hasRestoredUnit else { return }
        hasRestoredUnit = true
        let stored = store.lastUsedUnit(for: Self.unitKey, default: store.preferredPowerUnit)
        input.setUnit(stored)
    }
}

/// Placeholder shown where a result would be, before there is anything to show.
struct EmptyResultCard: View {
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Result")
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .rfCard()
    }
}

#Preview {
    NavigationStack {
        PowerConverterView()
    }
    .environment(PreferencesStore.preview)
}
