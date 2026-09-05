import SwiftUI

/// One category, showing its calculators and its reference pages together —
/// the two lists use the same categories, so they belong on the same screen
/// (spec §4).
struct CategoryView: View {
    let category: RFCategory

    private var calculators: [CalculatorDescriptor] { CalculatorCatalog.inCategory(category) }
    private var articles: [ReferenceArticle] { ReferenceLibrary.inCategory(category) }

    var body: some View {
        List {
            Section {
                Text(category.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !calculators.isEmpty {
                Section("Calculators") {
                    ForEach(calculators) { descriptor in
                        NavigationLink(value: Route.calculator(descriptor.id)) {
                            CalculatorRow(descriptor: descriptor)
                        }
                    }
                }
            }

            if !articles.isEmpty {
                Section("Reference") {
                    ForEach(articles) { article in
                        NavigationLink(value: Route.reference(article.id)) {
                            ReferenceRow(article: article)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(category.shortTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CategoryView(category: .reflectionAndLines)
            .rfNavigationDestinations()
    }
    .environment(PreferencesStore.preview)
}
