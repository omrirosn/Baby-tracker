import SwiftUI

/// Marks a calculator that is listed but not yet calculating.
struct PlannedBadge: View {
    var body: some View {
        Text("Planned")
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.rfFieldBackground, in: Capsule())
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
    }
}

/// A calculator in a list: icon, name, one line of purpose (spec §9).
///
/// Favourite and planned state are shown with a symbol and a word, never with
/// colour alone.
struct CalculatorRow: View {
    let descriptor: CalculatorDescriptor
    /// Shows the category instead of the purpose, for mixed lists.
    var showsCategory: Bool = false

    @Environment(PreferencesStore.self) private var store

    private var isFavourite: Bool { store.isFavourite(.calculator(descriptor.id)) }

    private var subtitle: String {
        showsCategory ? descriptor.category.title : descriptor.purpose
    }

    private var accessibilityDescription: String {
        var parts = [descriptor.title, subtitle]
        if isFavourite { parts.append("Favourite") }
        if !descriptor.isAvailable { parts.append("Planned, not yet available") }
        return parts.joined(separator: ". ")
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: descriptor.systemImage)
                .font(.body)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)
                .padding(.top, 2)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(descriptor.title)
                    if isFavourite {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                }
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            if !descriptor.isAvailable {
                PlannedBadge()
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }
}

/// A reference page in a list: name and a short descriptor (spec §10).
struct ReferenceRow: View {
    let article: ReferenceArticle
    var showsCategory: Bool = false

    @Environment(PreferencesStore.self) private var store

    private var isFavourite: Bool { store.isFavourite(.reference(article.id)) }

    private var subtitle: String {
        showsCategory ? article.category.title : article.descriptor
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "text.book.closed")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(width: 28)
                .padding(.top, 3)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(article.title)
                    if isFavourite {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                }
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(article.title). \(subtitle).\(isFavourite ? " Favourite." : "")")
    }
}

/// A row for anything in the catalogue, used by Saved and by search.
struct CatalogItemRow: View {
    let item: CatalogItemID
    var showsKind: Bool = true

    var body: some View {
        switch item {
        case let .calculator(id):
            CalculatorRow(descriptor: id.descriptor, showsCategory: showsKind)
        case let .reference(id):
            ReferenceRow(article: id.article, showsCategory: showsKind)
        }
    }
}

#Preview("Calculator rows") {
    List {
        CalculatorRow(descriptor: CalculatorID.powerConverter.descriptor)
        CalculatorRow(descriptor: CalculatorID.reflectionConverter.descriptor)
        CalculatorRow(descriptor: CalculatorID.linkBudget.descriptor)
    }
    .environment(PreferencesStore.preview)
}

#Preview("Reference rows") {
    List {
        ReferenceRow(article: ReferenceArticleID.vswr.article)
        ReferenceRow(article: ReferenceArticleID.thermalNoise.article)
        ReferenceRow(article: ReferenceArticleID.decibels.article, showsCategory: true)
    }
    .environment(PreferencesStore.preview)
}
