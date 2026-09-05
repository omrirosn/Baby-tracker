import SwiftUI

/// One search hit. The kind and category are always visible, which is what
/// keeps two hits on the same term apart — searching "Friis" returns both
/// free-space path loss and cascaded noise figure (spec §3).
struct SearchResultRow: View {
    let result: SearchResult

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: result.systemImage)
                .font(.body)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)
                .padding(.top, 2)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(result.title)
                Text(result.subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(result.kindLabel)
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.rfFieldBackground, in: Capsule())
                    Text(result.category.shortTitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(result.title). \(result.kindLabel) in \(result.category.title). \(result.subtitle)")
    }
}

/// Rows for a query, ready to drop into a `List`.
struct SearchResultsList: View {
    let query: String
    var scope: SearchScope = .all

    private var results: [SearchResult] {
        SearchIndex.shared.search(query, scope: scope)
    }

    var body: some View {
        if results.isEmpty {
            ContentUnavailableView.search(text: query)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        } else {
            Section {
                ForEach(results) { result in
                    NavigationLink(value: Route(item: result.item)) {
                        SearchResultRow(result: result)
                    }
                }
            } header: {
                Text(results.count == 1 ? "1 result" : "\(results.count) results")
            }
        }
    }
}

#Preview("Results") {
    NavigationStack {
        List {
            SearchResultsList(query: "friis")
        }
        .navigationTitle("Search")
    }
    .environment(PreferencesStore.preview)
}

#Preview("No results") {
    NavigationStack {
        List {
            SearchResultsList(query: "zzzz")
        }
        .navigationTitle("Search")
    }
    .environment(PreferencesStore.preview)
}
