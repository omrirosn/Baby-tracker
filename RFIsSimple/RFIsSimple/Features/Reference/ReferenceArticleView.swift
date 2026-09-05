import SwiftUI

/// A reference page, laid out to the template in spec §7: definition, key
/// relationship, what it means in practice, one common mistake, related tools.
struct ReferenceArticleView: View {
    let article: ReferenceArticle

    @Environment(PreferencesStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppMetrics.sectionSpacing) {
                Text(article.definition)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .rfCard()

                if let formula = article.keyRelationship {
                    FormulaCard(formula: formula, startsExpanded: true)
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel(text: "In practice")
                    BulletList(items: article.inPractice)
                }
                .rfCard()

                if let mistake = article.commonMistake {
                    NoteCard(kind: .mistake, text: mistake)
                }

                RelatedLinks(
                    calculators: article.relatedCalculators,
                    articles: article.relatedArticles
                )
            }
            .padding(AppMetrics.cardPadding)
        }
        .rfPageBackground()
        .navigationTitle(article.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FavouriteButton(item: .reference(article.id))
            }
        }
        .onAppear {
            store.recordVisit(.reference(article.id))
        }
    }
}

#Preview("VSWR") {
    NavigationStack {
        ReferenceArticleView(article: ReferenceArticleID.vswr.article)
            .rfNavigationDestinations()
    }
    .environment(PreferencesStore.preview)
}

#Preview("Thermal noise") {
    NavigationStack {
        ReferenceArticleView(article: ReferenceArticleID.thermalNoise.article)
            .rfNavigationDestinations()
    }
    .environment(PreferencesStore.preview)
}
