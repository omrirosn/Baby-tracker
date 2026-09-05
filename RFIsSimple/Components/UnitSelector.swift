import SwiftUI

/// The unit control that sits beside a numeric field.
///
/// Changing the selection preserves the physical quantity rather than
/// reinterpreting the typed number — that behaviour lives in `MeasuredInput`,
/// so every field gets it for free.
struct UnitSelector<U: PhysicalUnit>: View {
    @Binding var selection: U

    var body: some View {
        Picker(selection: $selection) {
            ForEach(Array(U.allCases), id: \.self) { unit in
                Text(unit.symbol).tag(unit)
            }
        } label: {
            Text("\(U.dimensionName) unit")
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .frame(minWidth: 72, minHeight: AppMetrics.minimumTapTarget)
        .accessibilityLabel("\(U.dimensionName) unit")
        .accessibilityValue(selection.accessibilityName)
    }
}

/// A fixed unit shown where there is nothing to choose, e.g. `%` or `dB`.
struct UnitLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(minWidth: 40, minHeight: AppMetrics.minimumTapTarget, alignment: .leading)
            .accessibilityHidden(true)
    }
}

private struct UnitSelectorPreview: View {
    @State private var power: PowerUnit = .dBm
    @State private var frequency: FrequencyUnit = .megahertz

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Power")
                Spacer()
                UnitSelector(selection: $power)
            }
            HStack {
                Text("Frequency")
                Spacer()
                UnitSelector(selection: $frequency)
            }
            HStack {
                Text("Reflected power")
                Spacer()
                UnitLabel(text: "%")
            }
        }
        .padding()
    }
}

#Preview {
    UnitSelectorPreview()
}
