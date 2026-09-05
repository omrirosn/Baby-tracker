import SwiftUI

/// Frequency / Period / Wavelength (spec §5.3).
///
/// Enter any one of the three and the other two follow. The propagation
/// velocity defaults to the speed of light in vacuum and is shown explicitly,
/// so the assumption is never hidden.
struct WavelengthCalculatorView: View {
    private static let descriptor = CalculatorID.wavelength.descriptor
    private static let frequencyUnitKey = "wavelength.frequency"
    private static let periodUnitKey = "wavelength.period"
    private static let wavelengthUnitKey = "wavelength.wavelength"

    @Environment(PreferencesStore.self) private var store

    @State private var solveFrom: WaveQuantity = .frequency
    @State private var frequency = MeasuredInput<FrequencyUnit>(text: "2400", unit: .megahertz)
    @State private var period = MeasuredInput<TimeUnit>(text: "1", unit: .nanosecond)
    @State private var wavelength = MeasuredInput<LengthUnit>(text: "125", unit: .millimetre)
    @State private var velocityFactorText = "1"
    @State private var hasRestoredUnits = false
    @FocusState private var focusedField: String?

    // MARK: - Inputs

    private var velocityFactor: Double? {
        if velocityFactorText.trimmingCharacters(in: .whitespaces).isEmpty {
            return WaveCalculator.defaultVelocityFactor
        }
        return DecimalTextParser.parse(velocityFactorText)
    }

    private var activeBaseValue: Double? {
        switch solveFrom {
        case .frequency: return frequency.baseValue
        case .period: return period.baseValue
        case .wavelength: return wavelength.baseValue
        }
    }

    private var activeInputIsEmpty: Bool {
        switch solveFrom {
        case .frequency: return frequency.isEmpty
        case .period: return period.isEmpty
        case .wavelength: return wavelength.isEmpty
        }
    }

    private var activeInputHasBeenEdited: Bool {
        switch solveFrom {
        case .frequency: return frequency.hasBeenEdited
        case .period: return period.hasBeenEdited
        case .wavelength: return wavelength.hasBeenEdited
        }
    }

    // MARK: - Calculation

    private var outcome: Result<WaveSolution, CalculationError>? {
        guard !activeInputIsEmpty else { return nil }
        guard let value = activeBaseValue else {
            return .failure(.notANumber(quantity: solveFrom.title))
        }
        guard let velocityFactor else {
            return .failure(.notANumber(quantity: "Velocity factor"))
        }
        do {
            return .success(try WaveCalculator.solve(from: solveFrom, value: value, velocityFactor: velocityFactor))
        } catch let error as CalculationError {
            return .failure(error)
        } catch {
            return .failure(.notANumber(quantity: solveFrom.title))
        }
    }

    private var solution: WaveSolution? {
        if case let .success(value)? = outcome { return value }
        return nil
    }

    private var inputIssue: ValidationIssue? {
        guard activeInputHasBeenEdited else { return nil }
        guard case let .failure(error)? = outcome else { return nil }
        // Only show the failure on the value field when it is that field's fault.
        if case .notANumber(let quantity) = error, quantity == "Velocity factor" { return nil }
        if case .mustBePositive(let quantity) = error, quantity == "Velocity factor" { return nil }
        return ValidationIssue(error)
    }

    private var velocityIssue: ValidationIssue? {
        guard let velocityFactor else {
            return velocityFactorText.isEmpty ? nil : .error("Velocity factor is not a valid number.")
        }
        if velocityFactor <= 0 {
            return .error(CalculationError.mustBePositive(quantity: "Velocity factor").message)
        }
        return WaveCalculator.velocityFactorIssue(velocityFactor)
    }

    // MARK: - Results

    private var results: (primary: ResultValue, secondary: [ResultValue])? {
        guard let solution else { return nil }

        let frequencyUnit = UnitScaling.preferredUnit(for: solution.frequencyHz, fallback: FrequencyUnit.hertz)
        let periodUnit = UnitScaling.preferredUnit(for: solution.periodSeconds, fallback: TimeUnit.second)
        let wavelengthUnit = UnitScaling.preferredUnit(for: solution.wavelengthMetres, fallback: LengthUnit.metre)
        let quarterUnit = UnitScaling.preferredUnit(for: solution.quarterWavelengthMetres, fallback: LengthUnit.metre)

        let frequencyResult = ResultValue.make(
            id: "frequency",
            label: "Frequency",
            value: frequencyUnit.fromBase(solution.frequencyHz),
            unit: frequencyUnit
        )
        let periodResult = ResultValue.make(
            id: "period",
            label: "Period",
            value: periodUnit.fromBase(solution.periodSeconds),
            unit: periodUnit
        )
        let wavelengthResult = ResultValue.make(
            id: "wavelength",
            label: "Wavelength",
            value: wavelengthUnit.fromBase(solution.wavelengthMetres),
            unit: wavelengthUnit
        )
        let quarterResult = ResultValue.make(
            id: "quarter",
            label: "Quarter wavelength",
            value: quarterUnit.fromBase(solution.quarterWavelengthMetres),
            unit: quarterUnit
        )

        switch solveFrom {
        case .frequency:
            return (wavelengthResult, [periodResult, quarterResult])
        case .period:
            return (frequencyResult, [wavelengthResult, quarterResult])
        case .wavelength:
            return (frequencyResult, [periodResult, quarterResult])
        }
    }

    private var footnote: String? {
        guard let solution else { return nil }
        let velocity = ValueFormatter.display(solution.velocity)
        let factor = ValueFormatter.display(solution.velocityFactor)
        return "Propagation velocity \(velocity) m/s at velocity factor \(factor)."
    }

    // MARK: - View

    var body: some View {
        CalculatorPage(descriptor: Self.descriptor) {
            InputCard {
                Picker("Solve from", selection: $solveFrom) {
                    ForEach(WaveQuantity.allCases) { quantity in
                        Text(quantity.title).tag(quantity)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Solve from")
                .padding(.bottom, 4)

                inputRow

                Divider()

                ScalarInputRow(
                    title: "Velocity factor",
                    fieldID: "velocityFactor",
                    text: $velocityFactorText,
                    placeholder: "1",
                    help: "1 in vacuum or air. Around 0.66 for solid polyethylene coax.",
                    issue: velocityIssue,
                    focusedField: $focusedField
                )
            }

            if let results {
                ResultCard(primary: results.primary, secondary: results.secondary, footnote: footnote)
            } else {
                EmptyResultCard(message: "Enter a \(solveFrom.title.lowercased()) to see the other two.")
            }
        }
        .keyboardDoneButton(focusedField: $focusedField)
        .onAppear(perform: restoreUnitsIfNeeded)
        .onChange(of: frequency.unit) { _, unit in store.setLastUsedUnit(unit, for: Self.frequencyUnitKey) }
        .onChange(of: period.unit) { _, unit in store.setLastUsedUnit(unit, for: Self.periodUnitKey) }
        .onChange(of: wavelength.unit) { _, unit in store.setLastUsedUnit(unit, for: Self.wavelengthUnitKey) }
    }

    @ViewBuilder
    private var inputRow: some View {
        switch solveFrom {
        case .frequency:
            NumericInputRow(
                title: "Frequency",
                fieldID: "frequency",
                input: $frequency,
                issue: inputIssue,
                focusedField: $focusedField
            )
        case .period:
            NumericInputRow(
                title: "Period",
                fieldID: "period",
                input: $period,
                issue: inputIssue,
                focusedField: $focusedField
            )
        case .wavelength:
            NumericInputRow(
                title: "Wavelength",
                fieldID: "wavelength",
                input: $wavelength,
                issue: inputIssue,
                focusedField: $focusedField
            )
        }
    }

    private func restoreUnitsIfNeeded() {
        guard !hasRestoredUnits else { return }
        hasRestoredUnits = true
        frequency.setUnit(store.lastUsedUnit(for: Self.frequencyUnitKey, default: store.preferredFrequencyUnit))
        period.setUnit(store.lastUsedUnit(for: Self.periodUnitKey, default: TimeUnit.nanosecond))
        wavelength.setUnit(store.lastUsedUnit(for: Self.wavelengthUnitKey, default: store.preferredLengthUnit))
    }
}

#Preview {
    NavigationStack {
        WavelengthCalculatorView()
    }
    .environment(PreferencesStore.preview)
}
