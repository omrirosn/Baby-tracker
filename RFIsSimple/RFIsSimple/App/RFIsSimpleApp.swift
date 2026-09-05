import SwiftUI

/// RF is Simple.
///
/// Everything runs locally: no account, no backend, no analytics, no
/// third-party dependency (spec §2, §13). The app works in airplane mode
/// because it never needs the network.
@main
struct RFIsSimpleApp: App {
    @State private var store = PreferencesStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(store)
                .preferredColorScheme(store.appearance.colorScheme)
        }
    }
}
