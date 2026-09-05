import SwiftUI

/// The formula behind a calculator or article.
///
/// Collapsed by default on a calculator page so the result stays the focus
/// (spec §6), and expanded where the formula is the point of the page.
/// The expression scrolls sideways rather than wrapping, which keeps it
/// readable at large text sizes.
struct FormulaCard: View {
    let formula: Formula
    var startsExpanded: Bool = false

    @State private var isExpanded: Bool

    init(formula: Formula, startsExpanded: Bool = false) {
        self.formula = formula
        self.startsExpanded = startsExpanded
        self._isExpanded = State(initialValue: startsExpanded)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: 12) {
                    expression

                    if !formula.variables.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(formula.variables) { variable in
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text(variable.symbol)
                                        .font(.footnote.monospaced())
                                        .frame(minWidth: 44, alignment: .leading)
                                    Text(variable.meaning)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("\(variable.symbol): \(variable.meaning)")
                            }
                        }
                    }
                }
                .padding(.top, 12)
            } label: {
                SectionLabel(text: "Formula")
                    .frame(minHeight: AppMetrics.minimumTapTarget, alignment: .leading)
            }
            .accessibilityHint(isExpanded ? "Collapses the formula" : "Expands the formula")
        }
        .rfCard()
    }

    private var expression: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(formula.expression)
                .font(.callout.monospaced())
                .fixedSize(horizontal: true, vertical: true)
                .padding(.vertical, 2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(formula.spokenDescription)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            FormulaCard(formula: CalculatorID.reflectionConverter.descriptor.formula!)
            FormulaCard(formula: CalculatorID.wavelength.descriptor.formula!, startsExpanded: true)
        }
        .padding()
    }
    .rfPageBackground()
}
