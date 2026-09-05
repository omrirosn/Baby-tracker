import SwiftUI

/// One editable row in the chain. Holds text rather than numbers so a
/// half-typed value never wipes the stage out.
struct StageDraft: Identifiable, Equatable {
    let id: UUID
    var name: String
    var gainText: String
    var noiseFigureText: String

    init(id: UUID = UUID(), name: String, gainText: String, noiseFigureText: String) {
        self.id = id
        self.name = name
        self.gainText = gainText
        self.noiseFigureText = noiseFigureText
    }

    init(_ stage: CascadeStage) {
        self.id = stage.id
        self.name = stage.name
        self.gainText = ValueFormatter.display(stage.gainDB)
        self.noiseFigureText = ValueFormatter.display(stage.noiseFigureDB)
    }

    var gain: Double? { DecimalTextParser.parse(gainText) }
    var noiseFigure: Double? { DecimalTextParser.parse(noiseFigureText) }

    var stage: CascadeStage? {
        guard let gain, let noiseFigure else { return nil }
        return CascadeStage(id: id, name: name, gainDB: gain, noiseFigureDB: noiseFigure)
    }
}

/// Cascaded Gain & Noise Figure (spec §5.9).
///
/// This is the one calculator with a dynamic list, so it uses a `List` rather
/// than the scrolling card template — that is what gives native reordering and
/// swipe-to-delete. The page still carries the same sections: purpose,
/// results, formula, practical note, common mistake and related pages.
struct CascadeView: View {
    private static let descriptor = CalculatorID.cascadedGainNoiseFigure.descriptor

    @Environment(PreferencesStore.self) private var store

    @State private var drafts: [StageDraft] = CascadeCalculator.defaultStages.map(StageDraft.init)
    @State private var showsContributions = true
    @FocusState private var focusedField: String?

    // MARK: - Calculation

    private var outcome: Result<CascadeSolution, CalculationError>? {
        guard !drafts.isEmpty else { return nil }
        var stages: [CascadeStage] = []
        for (index, draft) in drafts.enumerated() {
            guard let stage = draft.stage else {
                return .failure(.notANumber(quantity: "Stage \(index + 1)"))
            }
            stages.append(stage)
        }
        do {
            return .success(try CascadeCalculator.solve(stages: stages))
        } catch let error as CalculationError {
            return .failure(error)
        } catch {
            return .failure(.notANumber(quantity: "Cascade"))
        }
    }

    private var solution: CascadeSolution? {
        if case let .success(value)? = outcome { return value }
        return nil
    }

    private var failure: CalculationError? {
        if case let .failure(error)? = outcome { return error }
        return nil
    }

    // MARK: - View

    var body: some View {
        List {
            Section {
                Text(Self.descriptor.purpose)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            stagesSection
            resultsSection

            if showsContributions, let solution, solution.contributions.count > 1 {
                contributionsSection(solution)
            }

            Section {
                if let formula = Self.descriptor.formula {
                    FormulaCard(formula: formula)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                NoteCard(kind: .practical, text: Self.descriptor.practicalNote)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                if let mistake = Self.descriptor.commonMistake {
                    NoteCard(kind: .mistake, text: mistake)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                RelatedLinks(articles: Self.descriptor.relatedArticles)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(Self.descriptor.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FavouriteButton(item: .calculator(Self.descriptor.id))
            }
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
        .keyboardDoneButton(focusedField: $focusedField)
        .onAppear {
            store.recordVisit(.calculator(Self.descriptor.id))
        }
    }

    private var stagesSection: some View {
        Section {
            ForEach($drafts) { $draft in
                StageRow(draft: $draft, focusedField: $focusedField)
            }
            .onDelete { offsets in
                // Keep at least one stage so the chain never becomes meaningless.
                guard drafts.count > offsets.count else { return }
                drafts.remove(atOffsets: offsets)
            }
            .onMove { source, destination in
                drafts.move(fromOffsets: source, toOffset: destination)
            }

            Button {
                withAnimation {
                    drafts.append(StageDraft(name: "Stage \(drafts.count + 1)", gainText: "10", noiseFigureText: "3"))
                }
            } label: {
                Label("Add stage", systemImage: "plus.circle")
            }
            .frame(minHeight: AppMetrics.minimumTapTarget)
        } header: {
            Text("Stages, input first")
        } footer: {
            Text("Enter a loss as a negative gain. Swipe to delete; use Edit to reorder — order changes the noise figure.")
        }
    }

    @ViewBuilder
    private var resultsSection: some View {
        Section("Results") {
            if let solution {
                ResultCard(
                    primary: .scalar(
                        id: "nf",
                        label: "Cascaded noise figure",
                        value: solution.totalNoiseFigureDB,
                        unitSuffix: "dB",
                        spokenUnit: "decibels"
                    ),
                    secondary: [
                        .scalar(id: "gain", label: "Total gain", value: solution.totalGainDB,
                                unitSuffix: "dB", spokenUnit: "decibels"),
                        .scalar(id: "temperature", label: "Equivalent noise temperature",
                                value: solution.equivalentNoiseTemperature,
                                unitSuffix: "K", spokenUnit: "kelvin")
                    ],
                    footnote: "Noise figure is computed in linear noise factor and converted back, which is why stage order matters."
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } else if let failure {
                ValidationLabel(issue: ValidationIssue(failure))
            } else {
                Text("Add a stage to see the totals.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func contributionsSection(_ solution: CascadeSolution) -> some View {
        Section {
            ForEach(solution.contributions) { contribution in
                HStack(alignment: .firstTextBaseline) {
                    Text(contribution.name.isEmpty ? "Unnamed stage" : contribution.name)
                        .font(.subheadline)
                    Spacer(minLength: 8)
                    Text("\(ValueFormatter.display(contribution.sharePercent))%")
                        .font(.body.monospaced())
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(contribution.name) contributes \(ValueFormatter.display(contribution.sharePercent)) percent of the excess noise")
            }
        } header: {
            Text("Noise contribution")
        } footer: {
            Text("Share of the chain's excess noise each stage is responsible for.")
        }
    }
}

/// One editable stage row.
private struct StageRow: View {
    @Binding var draft: StageDraft
    @FocusState.Binding var focusedField: String?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var gainIssue: ValidationIssue? {
        guard !DecibelField.isEmpty(draft.gainText), draft.gain == nil else { return nil }
        return .error("Not a valid number.")
    }

    private var noiseFigureIssue: ValidationIssue? {
        if !DecibelField.isEmpty(draft.noiseFigureText), draft.noiseFigure == nil {
            return .error("Not a valid number.")
        }
        if let value = draft.noiseFigure, value < 0 {
            return .error("Noise figure cannot be negative.")
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(text: $draft.name, prompt: Text("Stage name")) {
                Text("Stage name")
            }
            .font(.subheadline.weight(.medium))
            .focused($focusedField, equals: "\(draft.id)-name")
            .accessibilityLabel("Stage name")

            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    numberField(title: "Gain", suffix: "dB", text: $draft.gainText,
                                fieldID: "\(draft.id)-gain", issue: gainIssue)
                    numberField(title: "NF", suffix: "dB", text: $draft.noiseFigureText,
                                fieldID: "\(draft.id)-nf", issue: noiseFigureIssue)
                }
            } else {
                HStack(spacing: 12) {
                    numberField(title: "Gain", suffix: "dB", text: $draft.gainText,
                                fieldID: "\(draft.id)-gain", issue: gainIssue)
                    numberField(title: "NF", suffix: "dB", text: $draft.noiseFigureText,
                                fieldID: "\(draft.id)-nf", issue: noiseFigureIssue)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func numberField(
        title: String,
        suffix: String,
        text: Binding<String>,
        fieldID: String,
        issue: ValidationIssue?
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField(text: text, prompt: Text("0")) {
                    Text(title)
                }
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.trailing)
                .font(.body.monospacedDigit())
                .focused($focusedField, equals: fieldID)
                .frame(minWidth: 56, minHeight: AppMetrics.minimumTapTarget)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.rfFieldBackground)
                )
                .accessibilityLabel(title)
                Text(suffix)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            if let issue {
                ValidationLabel(issue: issue)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CascadeView()
    }
    .environment(PreferencesStore.preview)
}
