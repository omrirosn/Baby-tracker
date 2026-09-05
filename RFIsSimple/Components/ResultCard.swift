import SwiftUI
import UIKit

/// One line of output.
///
/// The value is formatted twice: `displayValue` is rounded for reading, and
/// `copyText` keeps full precision so copying never loses digits (spec §12).
struct ResultValue: Identifiable, Hashable {
    let id: String
    let label: String
    let displayValue: String
    let unit: String?
    let copyText: String
    /// Short explanation shown under the value, e.g. why it is undefined.
    let note: String?
    let spokenValue: String

    var isDefined: Bool { displayValue != ValueFormatter.undefinedPlaceholder }

    var accessibilityDescription: String {
        var text = "\(label): \(spokenValue)"
        if let note { text += ". \(note)" }
        return text
    }
}

extension ResultValue {
    /// A result carried in a physical unit.
    static func make(
        id: String,
        label: String,
        value: Double?,
        unit: some PhysicalUnit,
        note: String? = nil
    ) -> ResultValue {
        guard let value, value.isFinite else {
            return ResultValue(
                id: id,
                label: label,
                displayValue: ValueFormatter.undefinedPlaceholder,
                unit: unit.symbol,
                copyText: "",
                note: note,
                spokenValue: "undefined"
            )
        }
        return ResultValue(
            id: id,
            label: label,
            displayValue: ValueFormatter.display(value),
            unit: unit.symbol,
            copyText: "\(ValueFormatter.copyText(value)) \(unit.symbol)",
            note: note,
            spokenValue: ValueFormatter.spoken(value, unit: unit)
        )
    }

    /// A result whose unit is fixed or absent — a ratio, a percentage, a dB figure.
    static func scalar(
        id: String,
        label: String,
        value: Double?,
        unitSuffix: String? = nil,
        spokenUnit: String? = nil,
        note: String? = nil
    ) -> ResultValue {
        guard let value, value.isFinite else {
            return ResultValue(
                id: id,
                label: label,
                displayValue: ValueFormatter.undefinedPlaceholder,
                unit: unitSuffix,
                copyText: "",
                note: note,
                spokenValue: "undefined"
            )
        }
        let display = ValueFormatter.display(value)
        let copy = ValueFormatter.copyText(value)
        let spokenNumber = value < 0 ? "minus \(ValueFormatter.display(abs(value)))" : display
        return ResultValue(
            id: id,
            label: label,
            displayValue: display,
            unit: unitSuffix,
            copyText: unitSuffix.map { "\(copy) \($0)" } ?? copy,
            note: note,
            spokenValue: spokenUnit.map { "\(spokenNumber) \($0)" } ?? spokenNumber
        )
    }
}

/// Puts text on the pasteboard.
enum Pasteboard {
    static func copy(_ text: String) {
        UIPasteboard.general.string = text
    }
}

/// The result section of a calculator page: one prominent value, the rest
/// below it in lower contrast, and a copy action (spec §6).
struct ResultCard: View {
    let primary: ResultValue
    var secondary: [ResultValue] = []
    /// Optional line under everything, e.g. the assumptions used.
    var footnote: String?

    @State private var copiedID: String?

    private var copyAllText: String {
        ([primary] + secondary)
            .filter(\.isDefined)
            .map { "\($0.label): \($0.copyText)" }
            .joined(separator: "\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            primaryValue

            if !secondary.isEmpty {
                Divider()
                VStack(spacing: 10) {
                    ForEach(secondary) { value in
                        secondaryRow(value)
                    }
                }
            }

            if let footnote {
                Text(footnote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .rfCard()
        .task(id: copiedID) {
            guard copiedID != nil else { return }
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            copiedID = nil
        }
    }

    private var header: some View {
        HStack {
            SectionLabel(text: "Result")
            Spacer()
            if copiedID != nil {
                Label("Copied", systemImage: "checkmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
            if !secondary.isEmpty {
                Button {
                    Pasteboard.copy(copyAllText)
                    copiedID = "all"
                } label: {
                    Image(systemName: "doc.on.doc")
                        .frame(minWidth: AppMetrics.minimumTapTarget, minHeight: AppMetrics.minimumTapTarget)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Copy all results")
            }
        }
    }

    private var primaryValue: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(primary.label)
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(primary.displayValue)
                    .font(.system(.largeTitle, design: .monospaced, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if let unit = primary.unit {
                    Text(unit)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                copyButton(for: primary)
            }

            if let note = primary.note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(primary.accessibilityDescription)
    }

    private func secondaryRow(_ value: ResultValue) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(value.label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value.displayValue)
                        .font(.body.monospaced())
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    if let unit = value.unit {
                        Text(unit)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                if let note = value.note {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(value.accessibilityDescription)
        .accessibilityAddTraits(value.isDefined ? .isButton : [])
        .accessibilityHint(value.isDefined ? "Double tap to copy" : "")
        .onTapGesture {
            guard value.isDefined else { return }
            Pasteboard.copy(value.copyText)
            copiedID = value.id
        }
    }

    @ViewBuilder
    private func copyButton(for value: ResultValue) -> some View {
        if value.isDefined {
            Button {
                Pasteboard.copy(value.copyText)
                copiedID = value.id
            } label: {
                Image(systemName: "doc.on.doc")
                    .frame(minWidth: AppMetrics.minimumTapTarget, minHeight: AppMetrics.minimumTapTarget)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Copy \(value.label)")
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            ResultCard(
                primary: .make(id: "w", label: "Power", value: 0.2, unit: PowerUnit.watt),
                secondary: [
                    .make(id: "dbm", label: "dBm", value: 23.01, unit: PowerUnit.dBm),
                    .make(id: "dbw", label: "dBW", value: -6.99, unit: PowerUnit.dBW),
                    .make(id: "mw", label: "Milliwatts", value: 200, unit: PowerUnit.milliwatt)
                ],
                footnote: "Values shown to four significant digits. Copy keeps full precision."
            )

            ResultCard(
                primary: .scalar(id: "rl", label: "Return loss", value: nil, unitSuffix: "dB",
                                 note: "Infinite — a perfect match reflects nothing."),
                secondary: [
                    .scalar(id: "vswr", label: "VSWR", value: 1, unitSuffix: ": 1", spokenUnit: "to one")
                ]
            )
        }
        .padding()
    }
    .rfPageBackground()
}
