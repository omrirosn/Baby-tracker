import SwiftUI

/// Toolbar button that adds or removes an item from Saved.
struct FavouriteButton: View {
    let item: CatalogItemID

    @Environment(PreferencesStore.self) private var store

    private var isFavourite: Bool { store.isFavourite(item) }

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                store.toggleFavourite(item)
            }
        } label: {
            Image(systemName: isFavourite ? "star.fill" : "star")
                .frame(minWidth: AppMetrics.minimumTapTarget, minHeight: AppMetrics.minimumTapTarget)
        }
        .accessibilityLabel(isFavourite ? "Remove from saved" : "Save")
        .accessibilityValue(isFavourite ? "Saved" : "Not saved")
    }
}

/// Links to related calculators and reference pages, closing every calculator
/// page and every article (spec §6, §7).
struct RelatedLinks: View {
    var calculators: [CalculatorID] = []
    var articles: [ReferenceArticleID] = []

    private var hasContent: Bool { !calculators.isEmpty || !articles.isEmpty }

    var body: some View {
        if hasContent {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "Related")

                ForEach(calculators) { id in
                    NavigationLink(value: Route.calculator(id)) {
                        linkLabel(
                            title: id.descriptor.title,
                            systemImage: id.descriptor.systemImage,
                            kind: "Calculator"
                        )
                    }
                    .buttonStyle(.plain)
                }

                ForEach(articles) { id in
                    NavigationLink(value: Route.reference(id)) {
                        linkLabel(
                            title: id.article.title,
                            systemImage: "text.book.closed",
                            kind: "Reference"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .rfCard()
        }
    }

    private func linkLabel(title: String, systemImage: String, kind: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.footnote)
                .foregroundStyle(Color.accentColor)
                .frame(width: 22)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline)
                Text(kind)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .frame(minHeight: AppMetrics.minimumTapTarget)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(kind)")
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            RelatedLinks(
                calculators: [.reflectionConverter, .wavelength],
                articles: [.vswr, .returnLoss]
            )
            .padding()
        }
        .rfPageBackground()
        .navigationTitle("Related")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FavouriteButton(item: .calculator(.powerConverter))
            }
        }
    }
    .environment(PreferencesStore.preview)
}
