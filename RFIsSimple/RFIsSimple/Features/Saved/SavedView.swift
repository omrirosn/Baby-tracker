import SwiftUI

/// Saved (spec §11): favourite calculators, favourite reference pages, and
/// recent items. Whole calculations are deliberately not stored in the MVP.
struct SavedView: View {
    @Environment(PreferencesStore.self) private var store

    private var favouriteCalculators: [CalculatorDescriptor] { store.favouriteCalculators }
    private var favouriteArticles: [ReferenceArticle] { store.favouriteArticles }
    private var recents: [CatalogItemID] { store.recentItems }

    private var isEmpty: Bool {
        favouriteCalculators.isEmpty && favouriteArticles.isEmpty && recents.isEmpty
    }

    var body: some View {
        List {
            if !favouriteCalculators.isEmpty {
                Section("Saved calculators") {
                    ForEach(favouriteCalculators) { descriptor in
                        NavigationLink(value: Route.calculator(descriptor.id)) {
                            CalculatorRow(descriptor: descriptor)
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Remove", role: .destructive) {
                                store.removeFavourite(.calculator(descriptor.id))
                            }
                        }
                    }
                }
            }

            if !favouriteArticles.isEmpty {
                Section("Saved reference") {
                    ForEach(favouriteArticles) { article in
                        NavigationLink(value: Route.reference(article.id)) {
                            ReferenceRow(article: article)
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Remove", role: .destructive) {
                                store.removeFavourite(.reference(article.id))
                            }
                        }
                    }
                }
            }

            if !recents.isEmpty {
                Section {
                    ForEach(recents) { item in
                        NavigationLink(value: Route(item: item)) {
                            CatalogItemRow(item: item)
                        }
                    }
                } header: {
                    Text("Recent")
                } footer: {
                    Button("Clear recent history") {
                        withAnimation { store.clearRecents() }
                    }
                    .font(.footnote)
                    .padding(.top, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Saved")
        .overlay {
            if isEmpty {
                ContentUnavailableView {
                    Label("Nothing saved yet", systemImage: "bookmark")
                } description: {
                    Text("Tap the star on any calculator or reference page to keep it here.")
                }
            }
        }
    }
}

#Preview("With content") {
    NavigationStack {
        SavedView()
            .rfNavigationDestinations()
    }
    .environment(PreferencesStore.preview)
}

#Preview("Empty") {
    NavigationStack {
        SavedView()
            .rfNavigationDestinations()
    }
    .environment(PreferencesStore.inMemory(name: "empty-preview"))
}
