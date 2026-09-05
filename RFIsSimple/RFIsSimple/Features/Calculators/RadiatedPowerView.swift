import SwiftUI

/// EIRP / ERP (spec §5.10).
struct RadiatedPowerView: View {
    private static let descriptor = CalculatorID.eirp.descriptor

    @State private var transmitPowerText = "30"
    @State private var feedLossText = "2"
    @State private var gainText = "12"
    @State private var reference: GainReference = .dBi
    @State private var edited: Set<String> = []
    @FocusState private var focusedField: String?

    private var outcome: Result<RadiatedPowerSolution, CalculationError>? {
        guard !DecibelField.isEmpty(transmitPowerText) else { return nil }
        guard let transmitPower = DecimalTextParser.parse(transmitPowerText) else {
            return .failure(.notANumber(quantity: "Transmitter power"))
        }
        guard let feedLoss = DecibelField.value(feedLossText, orEmpty: 0) else {
            return .failure(.notANumber(quantity: "Feed loss"))
        }
        guard let gain = DecibelField.value(gainText, orEmpty: 0) else {
            return .failure(.notANumber(quantity: "Antenna gain"))
        }
        do {
            return .success(try RadiatedPowerCalculator.solve(
                transmitPowerDBm: transmitPower,
                feedLossDB: feedLoss,
                antennaGain: gain,
                reference: reference
            ))
        } catch let error as CalculationError {
            return .failure(error)
        } catch {
            return .failure(.notANumber(quantity: "Transmitter power"))
        }
    }

    private var solution: RadiatedPowerSolution? {
        if case let .success(value)? = outcome { return value }
        return nil
    }

    private func issue(for quantity: String, fieldID: String) -> ValidationIssue? {
        guard edited.contains(fieldID), case let .failure(error)? = outcome else { return nil }
        switch error {
        case let .notANumber(name), let .mustBePositive(name), let .mustBeNonNegative(name):
            return name == quantity ? ValidationIssue(error) : nil
        default:
            return nil
        }
    }

    private var results: (primary: ResultValue, secondary: [ResultValue])? {
        guard let solution else { return nil }

        let eirpWattUnit = UnitScaling.preferredUnit(for: solution.eirpWatts, fallback: PowerUnit.watt)
        let primary = ResultValue.scalar(
            id: "eirp",
            label: "EIRP",
            value: solution.eirpDBm,
            unitSuffix: "dBm",
            spokenUnit: "dBm"
        )
        let secondary: [ResultValue] = [
            .make(id: "eirpWatts", label: "EIRP", value: eirpWattUnit.fromBase(solution.eirpWatts),
                  unit: eirpWattUnit),
            .scalar(id: "erp", label: "ERP", value: solution.erpDBm,
                    unitSuffix: "dBm", spokenUnit: "dBm"),
            .scalar(id: "gain", label: "Antenna gain", value: solution.antennaGainDBi,
                    unitSuffix: "dBi", spokenUnit: "dBi",
                    note: reference == .dBd ? "Converted from dBd by adding 2.15 dB." : nil)
        ]
        return (primary, secondary)
    }

    var body: some View {
        CalculatorPage(descriptor: Self.descriptor) {
            InputCard {
                DecibelInputRow(
                    title: "Transmitter power",
                    fieldID: "power",
                    text: $transmitPowerText,
                    suffix: "dBm",
                    issue: issue(for: "Transmitter power", fieldID: "power"),
                    focusedField: $focusedField
                )
                .onChange(of: transmitPowerText) { _, _ in edited.insert("power") }

                Divider()

                DecibelInputRow(
                    title: "Feedline and connector loss",
                    fieldID: "loss",
                    text: $feedLossText,
                    allowsNegative: false,
                    issue: issue(for: "Feed loss", fieldID: "loss"),
                    focusedField: $focusedField
                )
                .onChange(of: feedLossText) { _, _ in edited.insert("loss") }

                Divider()

                DecibelInputRow(
                    title: "Antenna gain",
                    fieldID: "gain",
                    text: $gainText,
                    suffix: reference.symbol,
                    issue: issue(for: "Antenna gain", fieldID: "gain"),
                    focusedField: $focusedField
                )
                .onChange(of: gainText) { _, _ in edited.insert("gain") }

                Picker("Gain reference", selection: $reference) {
                    ForEach(GainReference.allCases) { option in
                        Text(option.symbol).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Gain reference")
                .padding(.top, 4)
            }

            if let results {
                ResultCard(
                    primary: results.primary,
                    secondary: results.secondary,
                    footnote: "A dipole has 2.15 dB of gain over an isotropic radiator, which is the whole difference between EIRP and ERP."
                )
            } else {
                EmptyResultCard(message: "Enter a transmitter power.")
            }
        }
        .keyboardDoneButton(focusedField: $focusedField)
    }
}

#Preview {
    NavigationStack {
        RadiatedPowerView()
    }
    .environment(PreferencesStore.preview)
}
