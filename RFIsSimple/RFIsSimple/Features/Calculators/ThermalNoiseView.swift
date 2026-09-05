import SwiftUI

/// Thermal Noise (spec §5.6).
struct ThermalNoiseView: View {
    private static let descriptor = CalculatorID.thermalNoise.descriptor
    private static let bandwidthUnitKey = "thermalNoise.bandwidth"

    @Environment(PreferencesStore.self) private var store

    @State private var bandwidth = MeasuredInput<FrequencyUnit>(text: "1", unit: .megahertz)
    @State private var temperature = MeasuredInput<TemperatureUnit>(text: "290", unit: .kelvin)
    @State private var noiseFigureText = ""
    @State private var hasRestored = false
    @State private var edited: Set<String> = []
    @FocusState private var focusedField: String?

    private var noiseFigure: Double? {
        DecibelField.isEmpty(noiseFigureText) ? nil : DecimalTextParser.parse(noiseFigureText)
    }

    private var outcome: Result<ThermalNoiseSolution, CalculationError>? {
        guard !bandwidth.isEmpty else { return nil }
        guard let bandwidthHz = bandwidth.baseValue else {
            return .failure(.notANumber(quantity: "Bandwidth"))
        }
        guard let temperatureKelvin = temperature.baseValue else {
            return .failure(.notANumber(quantity: "Temperature"))
        }
        if !DecibelField.isEmpty(noiseFigureText), noiseFigure == nil {
            return .failure(.notANumber(quantity: "Noise figure"))
        }
        do {
            return .success(try NoiseCalculator.thermalNoise(
                bandwidthHz: bandwidthHz,
                temperatureKelvin: temperatureKelvin,
                noiseFigureDB: noiseFigure
            ))
        } catch let error as CalculationError {
            return .failure(error)
        } catch {
            return .failure(.notANumber(quantity: "Bandwidth"))
        }
    }

    private var solution: ThermalNoiseSolution? {
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

        let thermal = ResultValue.scalar(
            id: "noise",
            label: "Thermal noise in bandwidth",
            value: solution.noiseDBm,
            unitSuffix: "dBm",
            spokenUnit: "dBm"
        )
        let density = ResultValue.scalar(
            id: "density",
            label: "Noise density",
            value: solution.densityDBmPerHz,
            unitSuffix: "dBm/Hz",
            spokenUnit: "dBm per hertz"
        )

        if let floor = solution.floorDBm {
            let floorResult = ResultValue.scalar(
                id: "floor",
                label: "Receiver noise floor",
                value: floor,
                unitSuffix: "dBm",
                spokenUnit: "dBm"
            )
            return (floorResult, [thermal, density])
        }
        return (thermal, [density])
    }

    var body: some View {
        CalculatorPage(descriptor: Self.descriptor) {
            InputCard {
                NumericInputRow(
                    title: "Bandwidth",
                    fieldID: "bandwidth",
                    input: $bandwidth,
                    help: "Equivalent noise bandwidth, which may differ from the channel bandwidth.",
                    issue: issue(for: "Bandwidth", edited: bandwidth.hasBeenEdited),
                    focusedField: $focusedField
                )
                Divider()
                NumericInputRow(
                    title: "Temperature",
                    fieldID: "temperature",
                    input: $temperature,
                    help: "290 K is the standard reference temperature.",
                    issue: issue(for: "Temperature", edited: temperature.hasBeenEdited),
                    focusedField: $focusedField
                )
                Divider()
                DecibelInputRow(
                    title: "Noise figure",
                    fieldID: "noiseFigure",
                    text: $noiseFigureText,
                    allowsNegative: false,
                    placeholder: "Optional",
                    help: "Leave empty for the thermal noise alone.",
                    issue: issue(for: "Noise figure", edited: edited.contains("noiseFigure")),
                    focusedField: $focusedField
                )
                .onChange(of: noiseFigureText) { _, _ in edited.insert("noiseFigure") }
            }

            if let results {
                ResultCard(
                    primary: results.primary,
                    secondary: results.secondary,
                    footnote: "Defaults shown explicitly: 290 K reference temperature, no noise figure unless entered."
                )
            } else {
                EmptyResultCard(message: "Enter a bandwidth to see the noise power.")
            }
        }
        .keyboardDoneButton(focusedField: $focusedField)
        .onAppear(perform: restoreIfNeeded)
        .onChange(of: bandwidth.unit) { _, unit in store.setLastUsedUnit(unit, for: Self.bandwidthUnitKey) }
    }

    private func restoreIfNeeded() {
        guard !hasRestored else { return }
        hasRestored = true
        bandwidth.setUnit(store.lastUsedUnit(for: Self.bandwidthUnitKey, default: FrequencyUnit.megahertz))
    }
}

#Preview {
    NavigationStack {
        ThermalNoiseView()
    }
    .environment(PreferencesStore.preview)
}
