import SwiftUI

/// Calculators (spec §9): search, category sections, and an alphabetical view
/// for people who already know the name they want.
struct CalculatorsListView: View {
    private enum SortMode: String, CaseIterable, Identifiable {
        case category
        case alphabetical

        var id: String { rawValue }

        var title: String {
            switch self {
            case .category: return "By category"
            case .alphabetical: return "A–Z"
            }
        }
    }

    @State private var searchText = ""
    @State private var sortMode: SortMode = .category

    var body: some View {
        List {
            if !searchText.isEmpty {
                SearchResultsList(query: searchText, scope: .calculators)
            } else if sortMode == .category {
                categorySections
            } else {
                alphabeticalSection
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Calculators")
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search calculators"
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("View", selection: $sortMode) {
                        ForEach(SortMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .frame(minWidth: AppMetrics.minimumTapTarget, minHeight: AppMetrics.minimumTapTarget)
                }
                .accessibilityLabel("Change ordering")
            }
        }
    }

    private var categorySections: some View {
        ForEach(RFCategory.allCases) { category in
            let calculators = CalculatorCatalog.inCategory(category)
            if !calculators.isEmpty {
                Section {
                    ForEach(calculators) { descriptor in
                        NavigationLink(value: Route.calculator(descriptor.id)) {
                            CalculatorRow(descriptor: descriptor)
                        }
                    }
                } header: {
                    CategoryHeader(category: category)
                }
            }
        }
    }

    private var alphabeticalSection: some View {
        Section {
            ForEach(CalculatorCatalog.alphabetical) { descriptor in
                NavigationLink(value: Route.calculator(descriptor.id)) {
                    CalculatorRow(descriptor: descriptor, showsCategory: true)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CalculatorsListView()
            .rfNavigationDestinations()
    }
    .environment(PreferencesStore.preview)
}
