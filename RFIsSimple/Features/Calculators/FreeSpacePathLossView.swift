import SwiftUI

/// Free-Space Path Loss (spec §5.4).
struct FreeSpacePathLossView: View {
    private static let descriptor = CalculatorID.freeSpacePathLoss.descriptor
    private static let frequencyUnitKey = "fspl.frequency"
    private static let distanceUnitKey = "fspl.distance"

    @Environment(PreferencesStore.self) private var store

    @State private var frequency = MeasuredInput<FrequencyUnit>(text: "2400", unit: .megahertz)
    @State private var distance = MeasuredInput<LengthUnit>(text: "1", unit: .kilometre)
    @State private var hasRestored = false
    @FocusState private var focusedField: String?

    private var outcome: Result<PathLossSolution, CalculationError>? {
        guard !frequency.isEmpty, !distance.isEmpty else { return nil }
        guard let frequencyHz = frequency.baseValue else {
            return .failure(.notANumber(quantity: "Frequency"))
        }
        guard let distanceMetres = distance.baseValue else {
            return .failure(.notANumber(quantity: "Distance"))
        }
        do {
            return .success(try PathLossCalculator.freeSpace(
                frequencyHz: frequencyHz, distanceMetres: distanceMetres
            ))
        } catch let error as CalculationError {
            return .failure(error)
        } catch {
            return .failure(.notANumber(quantity: "Frequency"))
        }
    }

    private var solution: PathLossSolution? {
        if case let .success(value)? = outcome { return value }
        return nil
    }

    private func issue(for quantity: String, edited: Bool) -> ValidationIssue? {
        guard edited, case let .failure(error)? = outcome else { return nil }
        switch error {
        case let .notANumber(name), let .mustBePositive(name), let .mustBeNonNegative(name):
            return name == quantity ? ValidationIssue(error) : nil
        default:
            return ValidationIssue(error)
        }
    }

    private var results: (primary: ResultValue, secondary: [ResultValue])? {
        guard let solution else { return nil }

        let wavelengthUnit = UnitScaling.preferredUnit(for: solution.wavelengthMetres, fallback: LengthUnit.metre)
        let minimumUnit = UnitScaling.preferredUnit(for: solution.minimumValidDistanceMetres, fallback: LengthUnit.metre)

        let primary = ResultValue.scalar(
            id: "fspl",
            label: "Free-space path loss",
            value: solution.lossDB,
            unitSuffix: "dB",
            spokenUnit: "decibels"
        )
        let secondary: [ResultValue] = [
            .make(
                id: "wavelength",
                label: "Wavelength",
                value: wavelengthUnit.fromBase(solution.wavelengthMetres),
                unit: wavelengthUnit
            ),
            .make(
                id: "minimum",
                label: "Formula valid beyond",
                value: minimumUnit.fromBase(solution.minimumValidDistanceMetres),
                unit: minimumUnit,
                note: "λ / 4π"
            )
        ]
        return (primary, secondary)
    }

    var body: some View {
        CalculatorPage(descriptor: Self.descriptor) {
            InputCard {
                NumericInputRow(
                    title: "Frequency",
                    fieldID: "frequency",
                    input: $frequency,
                    issue: issue(for: "Frequency", edited: frequency.hasBeenEdited),
                    focusedField: $focusedField
                )
                Divider()
                NumericInputRow(
                    title: "Distance",
                    fieldID: "distance",
                    input: $distance,
                    issue: issue(for: "Distance", edited: distance.hasBeenEdited),
                    focusedField: $focusedField
                )
            }

            if let results, let solution {
                VStack(spacing: AppMetrics.sectionSpacing) {
                    ResultCard(
                        primary: results.primary,
                        secondary: results.secondary,
                        footnote: "Isotropic antennas, clear path. Antenna gains belong in the link budget."
                    )
                    if let warning = PathLossCalculator.nearFieldIssue(solution) {
                        ValidationLabel(issue: warning).rfCard()
                    }
                }
            } else {
                EmptyResultCard(message: "Enter a frequency and a distance.")
            }
        }
        .keyboardDoneButton(focusedField: $focusedField)
        .onAppear(perform: restoreIfNeeded)
        .onChange(of: frequency.unit) { _, unit in store.setLastUsedUnit(unit, for: Self.frequencyUnitKey) }
        .onChange(of: distance.unit) { _, unit in store.setLastUsedUnit(unit, for: Self.distanceUnitKey) }
    }

    private func restoreIfNeeded() {
        guard !hasRestored else { return }
        hasRestored = true
        frequency.setUnit(store.lastUsedUnit(for: Self.frequencyUnitKey, default: store.preferredFrequencyUnit))
        distance.setUnit(store.lastUsedUnit(for: Self.distanceUnitKey, default: LengthUnit.kilometre))
    }
}

#Preview {
    NavigationStack {
        FreeSpacePathLossView()
    }
    .environment(PreferencesStore.preview)
}
