import SwiftUI

/// Voltage / Power / Impedance (spec §5.2).
struct VoltagePowerImpedanceView: View {
    private static let descriptor = CalculatorID.voltagePowerImpedance.descriptor
    private static let powerUnitKey = "voltagePower.power"
    private static let voltageUnitKey = "voltagePower.voltage"

    @Environment(PreferencesStore.self) private var store

    @State private var solveFrom: VoltagePowerQuantity = .power
    @State private var power = MeasuredInput<PowerUnit>(text: "0", unit: .dBm)
    @State private var voltage = MeasuredInput<VoltageUnit>(text: "223.6", unit: .millivolt)
    @State private var impedanceText = "50"
    @State private var hasRestored = false
    @State private var edited: Set<String> = []
    @FocusState private var focusedField: String?

    // MARK: - Inputs

    private var impedance: Double? { DecimalTextParser.parse(impedanceText) }

    private var activeIsEmpty: Bool {
        switch solveFrom {
        case .power: return power.isEmpty
        case .voltage: return voltage.isEmpty
        }
    }

    private var activeBaseValue: Double? {
        switch solveFrom {
        case .power: return power.baseValue
        case .voltage: return voltage.baseValue
        }
    }

    // MARK: - Calculation

    private var outcome: Result<VoltagePowerSolution, CalculationError>? {
        guard !activeIsEmpty else { return nil }
        guard let value = activeBaseValue else {
            return .failure(.notANumber(quantity: solveFrom.title))
        }
        guard let impedance else {
            return .failure(.notANumber(quantity: "Impedance"))
        }
        do {
            return .success(try VoltagePowerCalculator.solve(
                from: solveFrom, value: value, impedanceOhms: impedance
            ))
        } catch let error as CalculationError {
            return .failure(error)
        } catch {
            return .failure(.notANumber(quantity: solveFrom.title))
        }
    }

    private var solution: VoltagePowerSolution? {
        if case let .success(value)? = outcome { return value }
        return nil
    }

    private var failure: CalculationError? {
        if case let .failure(error)? = outcome { return error }
        return nil
    }

    private var valueIssue: ValidationIssue? {
        guard edited.contains("value"), let failure else { return nil }
        if case .notANumber(let quantity) = failure, quantity == "Impedance" { return nil }
        if case .mustBePositive(let quantity) = failure, quantity == "Impedance" { return nil }
        return ValidationIssue(failure)
    }

    private var impedanceIssue: ValidationIssue? {
        guard edited.contains("impedance") else { return nil }
        if impedance == nil, !DecibelField.isEmpty(impedanceText) {
            return .error("Impedance is not a valid number.")
        }
        if let impedance, impedance <= 0 {
            return .error(CalculationError.mustBePositive(quantity: "Impedance").message)
        }
        return nil
    }

    // MARK: - Results

    private var results: (primary: ResultValue, secondary: [ResultValue])? {
        guard let solution else { return nil }

        let voltageUnit = UnitScaling.preferredUnit(for: solution.rmsVolts, fallback: VoltageUnit.volt)
        let peakUnit = UnitScaling.preferredUnit(for: solution.peakToPeakVolts, fallback: VoltageUnit.volt)
        let powerUnit = UnitScaling.preferredUnit(for: solution.watts, fallback: PowerUnit.watt)

        let rmsResult = ResultValue.make(
            id: "rms",
            label: "RMS voltage",
            value: voltageUnit.fromBase(solution.rmsVolts),
            unit: voltageUnit
        )
        let dBmResult = ResultValue.scalar(
            id: "dbm",
            label: "Power",
            value: solution.dBm,
            unitSuffix: "dBm",
            spokenUnit: "dBm",
            note: solution.dBm == nil ? "Zero power has no decibel equivalent." : nil
        )
        let linearPower = ResultValue.make(
            id: "watts",
            label: "Power",
            value: powerUnit.fromBase(solution.watts),
            unit: powerUnit
        )
        let peakToPeak = ResultValue.make(
            id: "pp",
            label: "Peak-to-peak (sine)",
            value: peakUnit.fromBase(solution.peakToPeakVolts),
            unit: peakUnit
        )
        let dBmicrovolt = ResultValue.scalar(
            id: "dbuv",
            label: "Level",
            value: solution.dBµV,
            unitSuffix: "dBµV",
            spokenUnit: "dB microvolts"
        )

        switch solveFrom {
        case .power:
            return (rmsResult, [peakToPeak, dBmResult, dBmicrovolt])
        case .voltage:
            return (dBmResult, [linearPower, peakToPeak, dBmicrovolt])
        }
    }

    // MARK: - View

    var body: some View {
        CalculatorPage(descriptor: Self.descriptor) {
            InputCard {
                Picker("Solve from", selection: $solveFrom) {
                    ForEach(VoltagePowerQuantity.allCases) { quantity in
                        Text(quantity.title).tag(quantity)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Solve from")
                .padding(.bottom, 4)

                valueRow

                Divider()

                DecibelInputRow(
                    title: "Impedance",
                    fieldID: "impedance",
                    text: $impedanceText,
                    suffix: "Ω",
                    allowsNegative: false,
                    placeholder: "50",
                    issue: impedanceIssue,
                    focusedField: $focusedField
                )
                .onChange(of: impedanceText) { _, _ in edited.insert("impedance") }

                HStack(spacing: 8) {
                    ForEach(VoltagePowerCalculator.commonImpedances, id: \.self) { value in
                        Button("\(Int(value)) Ω") {
                            impedanceText = String(Int(value))
                            edited.insert("impedance")
                        }
                        .buttonStyle(.bordered)
                        .font(.footnote)
                        .frame(minHeight: AppMetrics.minimumTapTarget)
                    }
                    Spacer()
                }
                .accessibilityLabel("Impedance presets")
            }

            if let results {
                ResultCard(
                    primary: results.primary,
                    secondary: results.secondary,
                    footnote: "Peak figures assume a sine wave. A modulated signal has a higher crest factor."
                )
            } else {
                EmptyResultCard(message: "Enter a \(solveFrom.title.lowercased()) to convert.")
            }
        }
        .keyboardDoneButton(focusedField: $focusedField)
        .onAppear(perform: restoreIfNeeded)
        .onChange(of: power.unit) { _, unit in store.setLastUsedUnit(unit, for: Self.powerUnitKey) }
        .onChange(of: voltage.unit) { _, unit in store.setLastUsedUnit(unit, for: Self.voltageUnitKey) }
    }

    @ViewBuilder
    private var valueRow: some View {
        switch solveFrom {
        case .power:
            NumericInputRow(
                title: "Power",
                fieldID: "value",
                input: $power,
                issue: valueIssue,
                focusedField: $focusedField
            )
            .onChange(of: power.text) { _, _ in edited.insert("value") }
        case .voltage:
            NumericInputRow(
                title: "RMS voltage",
                fieldID: "value",
                input: $voltage,
                issue: valueIssue,
                focusedField: $focusedField
            )
            .onChange(of: voltage.text) { _, _ in edited.insert("value") }
        }
    }

    private func restoreIfNeeded() {
        guard !hasRestored else { return }
        hasRestored = true
        power.setUnit(store.lastUsedUnit(for: Self.powerUnitKey, default: store.preferredPowerUnit))
        voltage.setUnit(store.lastUsedUnit(for: Self.voltageUnitKey, default: VoltageUnit.millivolt))
        impedanceText = ValueFormatter.display(store.defaultImpedanceOhms)
    }
}

#Preview {
    NavigationStack {
        VoltagePowerImpedanceView()
    }
    .environment(PreferencesStore.preview)
}
