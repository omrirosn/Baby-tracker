import SwiftUI

/// The four-tab structure (spec §3). Settings sits behind a toolbar button on
/// Home rather than taking a fifth tab.
struct RootTabView: View {
    enum Tab: Hashable {
        case home, calculators, reference, saved
    }

    @State private var selection: Tab = .home
    @State private var homePath: [Route] = []
    @State private var calculatorsPath: [Route] = []
    @State private var referencePath: [Route] = []
    @State private var savedPath: [Route] = []

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack(path: $homePath) {
                HomeView()
                    .rfNavigationDestinations()
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(Tab.home)

            NavigationStack(path: $calculatorsPath) {
                CalculatorsListView()
                    .rfNavigationDestinations()
            }
            .tabItem { Label("Calculators", systemImage: "function") }
            .tag(Tab.calculators)

            NavigationStack(path: $referencePath) {
                ReferenceListView()
                    .rfNavigationDestinations()
            }
            .tabItem { Label("Reference", systemImage: "text.book.closed") }
            .tag(Tab.reference)

            NavigationStack(path: $savedPath) {
                SavedView()
                    .rfNavigationDestinations()
            }
            .tabItem { Label("Saved", systemImage: "bookmark") }
            .tag(Tab.saved)
        }
    }
}

#Preview {
    RootTabView()
        .environment(PreferencesStore.preview)
}
