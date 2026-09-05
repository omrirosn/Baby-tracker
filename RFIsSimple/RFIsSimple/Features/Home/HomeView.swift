import SwiftUI

/// Home (spec §8): search, quick calculations, categories, recents, and two
/// small "browse everything" actions. No hero banner, no onboarding carousel,
/// no promotional cards.
struct HomeView: View {
    @Environment(PreferencesStore.self) private var store

    @State private var searchText = ""
    @State private var isShowingSettings = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        List {
            if searchText.isEmpty {
                quickCalculations
                categories
                recents
                browse
            } else {
                SearchResultsList(query: searchText)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("RF is Simple")
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search calculators and reference"
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .frame(minWidth: AppMetrics.minimumTapTarget, minHeight: AppMetrics.minimumTapTarget)
                }
                .accessibilityLabel("Settings and about")
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
    }

    private var quickCalculations: some View {
        Section("Quick calculations") {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(CalculatorCatalog.quickCalculations, id: \.self) { id in
                    NavigationLink(value: Route.calculator(id)) {
                        QuickCalculationTile(descriptor: id.descriptor, label: Self.quickLabel(for: id))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 6)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        }
    }

    private var categories: some View {
        Section("Categories") {
            ForEach(RFCategory.allCases) { category in
                NavigationLink(value: Route.category(category)) {
                    CategoryRow(category: category)
                }
            }
        }
    }

    @ViewBuilder
    private var recents: some View {
        let items = store.recentItems
        if !items.isEmpty {
            Section("Recently used") {
                ForEach(items) { item in
                    NavigationLink(value: Route(item: item)) {
                        CatalogItemRow(item: item)
                    }
                }
            }
        }
    }

    private var browse: some View {
        Section {
            NavigationLink(value: Route.allCalculators) {
                Label("Browse all calculators", systemImage: "function")
            }
            NavigationLink(value: Route.allReference) {
                Label("Browse reference", systemImage: "text.book.closed")
            }
        }
    }

    /// Short labels for the four tiles, which have less room than a list row.
    private static func quickLabel(for id: CalculatorID) -> String {
        switch id {
        case .powerConverter: return "dBm ↔ W"
        case .wavelength: return "Wavelength"
        case .reflectionConverter: return "VSWR ↔ RL"
        case .freeSpacePathLoss: return "FSPL"
        default: return id.descriptor.title
        }
    }
}

/// One tile in the quick calculations grid.
struct QuickCalculationTile: View {
    let descriptor: CalculatorDescriptor
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Image(systemName: descriptor.systemImage)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                Spacer(minLength: 4)
                if !descriptor.isAvailable {
                    PlannedBadge()
                }
            }
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 86, alignment: .topLeading)
        .background(Color.rfFieldBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(descriptor.title)\(descriptor.isAvailable ? "" : ", planned")")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .rfNavigationDestinations()
    }
    .environment(PreferencesStore.preview)
}
