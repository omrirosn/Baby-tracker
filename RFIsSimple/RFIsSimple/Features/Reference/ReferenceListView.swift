import SwiftUI

/// Reference (spec §10): the same categories as Calculators, each row showing
/// the concept name and a short descriptor.
struct ReferenceListView: View {
    @State private var searchText = ""

    var body: some View {
        List {
            if !searchText.isEmpty {
                SearchResultsList(query: searchText, scope: .reference)
            } else {
                ForEach(RFCategory.allCases) { category in
                    let articles = ReferenceLibrary.inCategory(category)
                    if !articles.isEmpty {
                        Section {
                            ForEach(articles) { article in
                                NavigationLink(value: Route.reference(article.id)) {
                                    ReferenceRow(article: article)
                                }
                            }
                        } header: {
                            CategoryHeader(category: category)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Reference")
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search concepts, formulas and abbreviations"
        )
    }
}

#Preview {
    NavigationStack {
        ReferenceListView()
            .rfNavigationDestinations()
    }
    .environment(PreferencesStore.preview)
}
