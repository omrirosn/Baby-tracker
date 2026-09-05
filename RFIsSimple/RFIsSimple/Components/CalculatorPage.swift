import SwiftUI

/// The page template every calculator uses (spec §6): purpose, inputs,
/// results, formula, practical note, common mistake, related pages.
///
/// A calculator screen supplies only its inputs and results; everything else
/// comes from the descriptor, so the pages cannot drift apart.
struct CalculatorPage<Content: View>: View {
    let descriptor: CalculatorDescriptor
    let content: () -> Content

    @Environment(PreferencesStore.self) private var store

    init(descriptor: CalculatorDescriptor, @ViewBuilder content: @escaping () -> Content) {
        self.descriptor = descriptor
        self.content = content
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppMetrics.sectionSpacing) {
                Text(descriptor.purpose)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                content()

                if let formula = descriptor.formula {
                    FormulaCard(formula: formula)
                }

                NoteCard(kind: .practical, text: descriptor.practicalNote)

                if let mistake = descriptor.commonMistake {
                    NoteCard(kind: .mistake, text: mistake)
                }

                RelatedLinks(articles: descriptor.relatedArticles)
            }
            .padding(AppMetrics.cardPadding)
        }
        .rfPageBackground()
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(descriptor.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FavouriteButton(item: .calculator(descriptor.id))
            }
        }
        .onAppear {
            store.recordVisit(.calculator(descriptor.id))
        }
    }
}

/// Card holding a calculator's input rows.
struct InputCard<Content: View>: View {
    var title: String = "Inputs"
    let content: () -> Content

    init(title: String = "Inputs", @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: title)
            content()
        }
        .rfCard()
    }
}

extension View {
    /// Keyboard accessory shared by the calculator screens: one Done button
    /// that dismisses the numeric keypad, which otherwise has no return key.
    func keyboardDoneButton(focusedField: FocusState<String?>.Binding) -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField.wrappedValue = nil
                }
                .accessibilityLabel("Dismiss keyboard")
            }
        }
    }
}
