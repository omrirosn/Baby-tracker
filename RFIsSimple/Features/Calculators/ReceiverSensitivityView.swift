import SwiftUI

/// Receiver Sensitivity (spec §5.7).
struct ReceiverSensitivityView: View {
    private static let descriptor = CalculatorID.receiverSensitivity.descriptor
    private static let bandwidthUnitKey = "sensitivity.bandwidth"

    @Environment(PreferencesStore.self) private var store

    @State private var bandwidth = MeasuredInput<FrequencyUnit>(text: "200", unit: .kilohertz)
    @State private var temperature = MeasuredInput<TemperatureUnit>(text: "290", unit: .kelvin)
    @State private var noiseFigureText = "6"
    @State private var snrText = "10"
    @State private var hasRestored = false
    @State private var edited: Set<String> = []
    @FocusState private var focusedField: String?

    private var noiseFigure: Double? { DecimalTextParser.parse(noiseFigureText) }
    private var requiredSNR: Double? { DecimalTextParser.parse(snrText) }

    private var outcome: Result<SensitivitySolution, CalculationError>? {
        guard !bandwidth.isEmpty, !DecibelField.isEmpty(noiseFigureText), !DecibelField.isEmpty(snrText) else {
            return nil
        }
        guard let bandwidthHz = bandwidth.baseValue else {
            return .failure(.notANumber(quantity: "Bandwidth"))
        }
        guard let temperatureKelvin = temperature.baseValue else {
            return .failure(.notANumber(quantity: "Temperature"))
        }
        guard let noiseFigure else {
            return .failure(.notANumber(quantity: "Noise figure"))
        }
        guard let requiredSNR else {
            return .failure(.notANumber(quantity: "Required SNR"))
        }
        do {
            return .success(try NoiseCalculator.sensitivity(
                bandwidthHz: bandwidthHz,
                noiseFigureDB: noiseFigure,
                requiredSNRDB: requiredSNR,
                temperatureKelvin: temperatureKelvin
            ))
        } catch let error as CalculationError {
            return .failure(error)
        } catch {
            return .failure(.notANumber(quantity: "Bandwidth"))
        }
    }

    private var solution: SensitivitySolution? {
        if case let .success(value)? = outcome { return value }
        return nil
    }

    private func issue(for quantity: String, edited isEdited: Bool) -> ValidationIssue? {
        guard isEdited, case let .failure(error)? = outcome else { return nil }
        switch error {
        case let .notANumber(name), let .mustBePositive(name), let .mustBeNonNegative(name):
            return name == quantity ? ValidationIssue(error) : nil
        default:
            return quantity == "Bandwidth" ? ValidationIssue(error) : nil
        }
    }

    private var results: (primary: ResultValue, secondary: [ResultValue])? {
        guard let solution else { return nil }
        let primary = ResultValue.scalar(
            id: "sensitivity",
            label: "Estimated sensitivity",
            value: solution.sensitivityDBm,
            unitSuffix: "dBm",
            spokenUnit: "dBm"
        )
        let secondary: [ResultValue] = [
            .scalar(id: "floor", label: "Receiver noise floor", value: solution.noiseFloorDBm,
                    unitSuffix: "dBm", spokenUnit: "dBm"),
            .scalar(id: "thermal", label: "Thermal noise in bandwidth", value: solution.thermalNoiseDBm,
                    unitSuffix: "dBm", spokenUnit: "dBm"),
            .scalar(id: "temperature", label: "Equivalent noise temperature",
                    value: solution.equivalentNoiseTemperature,
                    unitSuffix: "K", spokenUnit: "kelvin")
        ]
        return (primary, secondary)
    }

    var body: some View {
        CalculatorPage(descriptor: Self.descriptor) {
            InputCard {
                NumericInputRow(
                    title: "Bandwidth",
                    fieldID: "bandwidth",
                    input: $bandwidth,
                    help: "Equivalent noise bandwidth.",
                    issue: issue(for: "Bandwidth", edited: bandwidth.hasBeenEdited),
                    focusedField: $focusedField
                )
                Divider()
                DecibelInputRow(
                    title: "Noise figure",
                    fieldID: "noiseFigure",
                    text: $noiseFigureText,
                    allowsNegative: false,
                    issue: issue(for: "Noise figure", edited: edited.contains("noiseFigure")),
                    focusedField: $focusedField
                )
                .onChange(of: noiseFigureText) { _, _ in edited.insert("noiseFigure") }
                Divider()
                DecibelInputRow(
                    title: "Required SNR",
                    fieldID: "snr",
                    text: $snrText,
                    help: "Set by the modulation and coding, not by the radio.",
                    issue: issue(for: "Required SNR", edited: edited.contains("snr")),
                    focusedField: $focusedField
                )
                .onChange(of: snrText) { _, _ in edited.insert("snr") }
                Divider()
                NumericInputRow(
                    title: "Temperature",
                    fieldID: "temperature",
                    input: $temperature,
                    help: "290 K is the standard reference temperature.",
                    issue: issue(for: "Temperature", edited: temperature.hasBeenEdited),
                    focusedField: $focusedField
                )
            }

            if let results {
                ResultCard(
                    primary: results.primary,
                    secondary: results.secondary,
                    footnote: "An estimate from the noise budget alone — implementation loss is not included."
                )
            } else {
                EmptyResultCard(message: "Enter a bandwidth, noise figure and required SNR.")
            }
        }
        .keyboardDoneButton(focusedField: $focusedField)
        .onAppear(perform: restoreIfNeeded)
        .onChange(of: bandwidth.unit) { _, unit in store.setLastUsedUnit(unit, for: Self.bandwidthUnitKey) }
    }

    private func restoreIfNeeded() {
        guard !hasRestored else { return }
        hasRestored = true
        bandwidth.setUnit(store.lastUsedUnit(for: Self.bandwidthUnitKey, default: FrequencyUnit.kilohertz))
    }
}

#Preview {
    NavigationStack {
        ReceiverSensitivityView()
    }
    .environment(PreferencesStore.preview)
}
