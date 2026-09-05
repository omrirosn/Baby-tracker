import SwiftUI

/// Effective Antenna Aperture (spec §5.11).
struct EffectiveApertureView: View {
    private static let descriptor = CalculatorID.effectiveAperture.descriptor
    private static let frequencyUnitKey = "aperture.frequency"

    @Environment(PreferencesStore.self) private var store

    @State private var frequency = MeasuredInput<FrequencyUnit>(text: "2400", unit: .megahertz)
    @State private var gainText = "12"
    @State private var hasRestored = false
    @State private var edited: Set<String> = []
    @FocusState private var focusedField: String?

    private var outcome: Result<ApertureSolution, CalculationError>? {
        guard !frequency.isEmpty, !DecibelField.isEmpty(gainText) else { return nil }
        guard let frequencyHz = frequency.baseValue else {
            return .failure(.notANumber(quantity: "Frequency"))
        }
        guard let gain = DecimalTextParser.parse(gainText) else {
            return .failure(.notANumber(quantity: "Antenna gain"))
        }
        do {
            return .success(try AntennaCalculator.effectiveAperture(frequencyHz: frequencyHz, gainDBi: gain))
        } catch let error as CalculationError {
            return .failure(error)
        } catch {
            return .failure(.notANumber(quantity: "Frequency"))
        }
    }

    private var solution: ApertureSolution? {
        if case let .success(value)? = outcome { return value }
        return nil
    }

    private func issue(for quantity: String, edited isEdited: Bool) -> ValidationIssue? {
        guard isEdited, case let .failure(error)? = outcome else { return nil }
        switch error {
        case let .notANumber(name), let .mustBePositive(name), let .mustBeNonNegative(name):
            return name == quantity ? ValidationIssue(error) : nil
        default:
            return nil
        }
    }

    private var results: (primary: ResultValue, secondary: [ResultValue])? {
        guard let solution else { return nil }

        let wavelengthUnit = UnitScaling.preferredUnit(for: solution.wavelengthMetres, fallback: LengthUnit.metre)
        let diameterUnit = UnitScaling.preferredUnit(
            for: solution.equivalentCircleDiameterMetres, fallback: LengthUnit.metre
        )

        let primary = ResultValue.scalar(
            id: "aperture",
            label: "Effective aperture",
            value: solution.apertureSquareMetres,
            unitSuffix: "m²",
            spokenUnit: "square metres"
        )
        let secondary: [ResultValue] = [
            .scalar(id: "cm2", label: "Effective aperture",
                    value: solution.apertureSquareCentimetres,
                    unitSuffix: "cm²", spokenUnit: "square centimetres"),
            .make(id: "wavelength", label: "Wavelength",
                  value: wavelengthUnit.fromBase(solution.wavelengthMetres), unit: wavelengthUnit),
            .make(id: "diameter", label: "Equivalent circle diameter",
                  value: diameterUnit.fromBase(solution.equivalentCircleDiameterMetres),
                  unit: diameterUnit,
                  note: "A dish this size at 100% efficiency.")
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
                DecibelInputRow(
                    title: "Antenna gain",
                    fieldID: "gain",
                    text: $gainText,
                    suffix: "dBi",
                    issue: issue(for: "Antenna gain", edited: edited.contains("gain")),
                    focusedField: $focusedField
                )
                .onChange(of: gainText) { _, _ in edited.insert("gain") }
            }

            if let results {
                ResultCard(
                    primary: results.primary,
                    secondary: results.secondary,
                    footnote: "Real dishes reach 50–70% of their physical area, so compare the equivalent diameter with the real one."
                )
            } else {
                EmptyResultCard(message: "Enter a frequency and an antenna gain.")
            }
        }
        .keyboardDoneButton(focusedField: $focusedField)
        .onAppear(perform: restoreIfNeeded)
        .onChange(of: frequency.unit) { _, unit in store.setLastUsedUnit(unit, for: Self.frequencyUnitKey) }
    }

    private func restoreIfNeeded() {
        guard !hasRestored else { return }
        hasRestored = true
        frequency.setUnit(store.lastUsedUnit(for: Self.frequencyUnitKey, default: store.preferredFrequencyUnit))
    }
}

/// Far-Field Distance (spec §5.12).
struct FarFieldDistanceView: View {
    private static let descriptor = CalculatorID.farFieldDistance.descriptor
    private static let frequencyUnitKey = "farField.frequency"
    private static let dimensionUnitKey = "farField.dimension"

    @Environment(PreferencesStore.self) private var store

    @State private var frequency = MeasuredInput<FrequencyUnit>(text: "2400", unit: .megahertz)
    @State private var dimension = MeasuredInput<LengthUnit>(text: "300", unit: .millimetre)
    @State private var hasRestored = false
    @FocusState private var focusedField: String?

    private var outcome: Result<FieldRegionSolution, CalculationError>? {
        guard !frequency.isEmpty, !dimension.isEmpty else { return nil }
        guard let frequencyHz = frequency.baseValue else {
            return .failure(.notANumber(quantity: "Frequency"))
        }
        guard let dimensionMetres = dimension.baseValue else {
            return .failure(.notANumber(quantity: "Antenna dimension"))
        }
        do {
            return .success(try AntennaCalculator.fieldRegions(
                frequencyHz: frequencyHz, largestDimensionMetres: dimensionMetres
            ))
        } catch let error as CalculationError {
            return .failure(error)
        } catch {
            return .failure(.notANumber(quantity: "Frequency"))
        }
    }

    private var solution: FieldRegionSolution? {
        if case let .success(value)? = outcome { return value }
        return nil
    }

    private func issue(for quantity: String, edited isEdited: Bool) -> ValidationIssue? {
        guard isEdited, case let .failure(error)? = outcome else { return nil }
        switch error {
        case let .notANumber(name), let .mustBePositive(name), let .mustBeNonNegative(name):
            return name == quantity ? ValidationIssue(error) : nil
        default:
            return nil
        }
    }

    private func lengthResult(_ id: String, _ label: String, _ metres: Double, note: String? = nil) -> ResultValue {
        let unit = UnitScaling.preferredUnit(for: metres, fallback: LengthUnit.metre)
        return .make(id: id, label: label, value: unit.fromBase(metres), unit: unit, note: note)
    }

    private var results: (primary: ResultValue, secondary: [ResultValue])? {
        guard let solution else { return nil }

        let primary = lengthResult(
            "practical",
            "Measure beyond",
            solution.practicalFarFieldMetres,
            note: "The most demanding of the criteria below."
        )
        let secondary: [ResultValue] = [
            lengthResult("fraunhofer", "Far field, 2D²/λ", solution.fraunhoferBoundaryMetres),
            lengthResult("reactive", "Reactive near field ends", solution.reactiveBoundaryMetres,
                         note: "0.62·√(D³/λ)"),
            lengthResult("small", "λ/2π", solution.smallAntennaBoundaryMetres,
                         note: "Binding for antennas smaller than a wavelength."),
            lengthResult("wavelength", "Wavelength", solution.wavelengthMetres)
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
                    title: "Largest antenna dimension",
                    fieldID: "dimension",
                    input: $dimension,
                    help: "The biggest straight-line size of the radiating structure.",
                    issue: issue(for: "Antenna dimension", edited: dimension.hasBeenEdited),
                    focusedField: $focusedField
                )
            }

            if let results, let solution {
                VStack(spacing: AppMetrics.sectionSpacing) {
                    ResultCard(
                        primary: results.primary,
                        secondary: results.secondary,
                        footnote: "Antenna geometry and the criterion chosen both move the practical boundary — these are the standard rules of thumb, not a specification."
                    )
                    if let warning = AntennaCalculator.fieldRegionIssue(solution) {
                        ValidationLabel(issue: warning).rfCard()
                    }
                }
            } else {
                EmptyResultCard(message: "Enter a frequency and the antenna's largest dimension.")
            }
        }
        .keyboardDoneButton(focusedField: $focusedField)
        .onAppear(perform: restoreIfNeeded)
        .onChange(of: frequency.unit) { _, unit in store.setLastUsedUnit(unit, for: Self.frequencyUnitKey) }
        .onChange(of: dimension.unit) { _, unit in store.setLastUsedUnit(unit, for: Self.dimensionUnitKey) }
    }

    private func restoreIfNeeded() {
        guard !hasRestored else { return }
        hasRestored = true
        frequency.setUnit(store.lastUsedUnit(for: Self.frequencyUnitKey, default: store.preferredFrequencyUnit))
        dimension.setUnit(store.lastUsedUnit(for: Self.dimensionUnitKey, default: LengthUnit.millimetre))
    }
}

#Preview("Aperture") {
    NavigationStack {
        EffectiveApertureView()
    }
    .environment(PreferencesStore.preview)
}

#Preview("Far field") {
    NavigationStack {
        FarFieldDistanceView()
    }
    .environment(PreferencesStore.preview)
}
