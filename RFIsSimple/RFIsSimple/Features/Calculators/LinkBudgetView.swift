import SwiftUI

/// Link Budget (spec §5.5).
struct LinkBudgetView: View {
    private static let descriptor = CalculatorID.linkBudget.descriptor

    @State private var transmitPowerText = "20"
    @State private var transmitLossText = "1"
    @State private var transmitGainText = "6"
    @State private var pathLossText = "100"
    @State private var receiveGainText = "6"
    @State private var receiveLossText = "1"
    @State private var sensitivityText = ""
    @State private var edited: Set<String> = []
    @FocusState private var focusedField: String?

    private var input: LinkBudgetInput? {
        guard let transmitPower = DecimalTextParser.parse(transmitPowerText),
              let transmitLoss = DecibelField.value(transmitLossText, orEmpty: 0),
              let transmitGain = DecibelField.value(transmitGainText, orEmpty: 0),
              let pathLoss = DecimalTextParser.parse(pathLossText),
              let receiveGain = DecibelField.value(receiveGainText, orEmpty: 0),
              let receiveLoss = DecibelField.value(receiveLossText, orEmpty: 0) else {
            return nil
        }
        let sensitivity = DecibelField.isEmpty(sensitivityText)
            ? nil
            : DecimalTextParser.parse(sensitivityText)
        if !DecibelField.isEmpty(sensitivityText), sensitivity == nil { return nil }

        return LinkBudgetInput(
            transmitPowerDBm: transmitPower,
            transmitLossDB: transmitLoss,
            transmitGainDBi: transmitGain,
            pathLossDB: pathLoss,
            receiveGainDBi: receiveGain,
            receiveLossDB: receiveLoss,
            sensitivityDBm: sensitivity
        )
    }

    private var outcome: Result<LinkBudgetSolution, CalculationError>? {
        guard !DecibelField.isEmpty(transmitPowerText), !DecibelField.isEmpty(pathLossText) else {
            return nil
        }
        guard let input else {
            return .failure(.notANumber(quantity: "One of the terms"))
        }
        do {
            return .success(try LinkBudgetCalculator.solve(input))
        } catch let error as CalculationError {
            return .failure(error)
        } catch {
            return .failure(.notANumber(quantity: "Link budget"))
        }
    }

    private var solution: LinkBudgetSolution? {
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

        let received = ResultValue.scalar(
            id: "received",
            label: "Received power",
            value: solution.receivedPowerDBm,
            unitSuffix: "dBm",
            spokenUnit: "dBm"
        )
        var secondary: [ResultValue] = [
            .scalar(id: "eirp", label: "EIRP", value: solution.eirpDBm,
                    unitSuffix: "dBm", spokenUnit: "dBm")
        ]

        if let margin = solution.marginDB {
            let closes = margin >= 0
            let marginResult = ResultValue.scalar(
                id: "margin",
                label: "Link margin",
                value: margin,
                unitSuffix: "dB",
                spokenUnit: "decibels",
                note: closes ? "Link closes with this much to spare." : "Short of sensitivity — the link does not close."
            )
            secondary.insert(received, at: 0)
            return (marginResult, secondary)
        }
        return (received, secondary)
    }

    var body: some View {
        CalculatorPage(descriptor: Self.descriptor) {
            InputCard(title: "Transmit side") {
                field("Transmit power", "transmitPower", $transmitPowerText, suffix: "dBm",
                      quantity: "Transmit power")
                Divider()
                field("Transmit losses", "transmitLoss", $transmitLossText,
                      allowsNegative: false, quantity: "Transmit loss",
                      help: "Feedline, connectors and duplexer, as a positive number.")
                Divider()
                field("Transmit antenna gain", "transmitGain", $transmitGainText, suffix: "dBi",
                      quantity: "Transmit antenna gain")
            }

            InputCard(title: "Path") {
                field("Path loss", "pathLoss", $pathLossText, allowsNegative: false,
                      quantity: "Path loss",
                      help: "From the free-space path loss calculator, plus any margin for obstruction.")
            }

            InputCard(title: "Receive side") {
                field("Receive antenna gain", "receiveGain", $receiveGainText, suffix: "dBi",
                      quantity: "Receive antenna gain")
                Divider()
                field("Receive losses", "receiveLoss", $receiveLossText,
                      allowsNegative: false, quantity: "Receive loss")
                Divider()
                field("Receiver sensitivity", "sensitivity", $sensitivityText, suffix: "dBm",
                      quantity: "Receiver sensitivity", placeholder: "Optional",
                      help: "Leave empty to see received power without a margin.")
            }

            if let results {
                ResultCard(
                    primary: results.primary,
                    secondary: results.secondary,
                    footnote: "Losses are entered positive and subtracted, the way datasheets quote them."
                )
            } else {
                EmptyResultCard(message: "Enter at least a transmit power and a path loss.")
            }
        }
        .keyboardDoneButton(focusedField: $focusedField)
    }

    private func field(
        _ title: String,
        _ fieldID: String,
        _ text: Binding<String>,
        suffix: String = "dB",
        allowsNegative: Bool = true,
        quantity: String,
        placeholder: String = "0",
        help: String? = nil
    ) -> some View {
        DecibelInputRow(
            title: title,
            fieldID: fieldID,
            text: text,
            suffix: suffix,
            allowsNegative: allowsNegative,
            placeholder: placeholder,
            help: help,
            issue: issue(for: quantity, fieldID: fieldID),
            focusedField: $focusedField
        )
        .onChange(of: text.wrappedValue) { _, _ in edited.insert(fieldID) }
    }
}

#Preview {
    NavigationStack {
        LinkBudgetView()
    }
    .environment(PreferencesStore.preview)
}
