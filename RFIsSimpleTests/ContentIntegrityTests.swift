import Testing
@testable import RFIsSimple

/// Guards the content rules from spec §6 and §7. Content is easy to add and
/// easy to let drift, so the shape of it is checked rather than reviewed.
struct ContentIntegrityTests {

    // MARK: - Calculators

    @Test func everyCalculatorHasContent() {
        for descriptor in CalculatorCatalog.all {
            #expect(!descriptor.title.isEmpty)
            #expect(!descriptor.purpose.isEmpty)
            #expect(!descriptor.practicalNote.isEmpty)
            #expect(!descriptor.systemImage.isEmpty)
            #expect(!descriptor.aliases.isEmpty, "\(descriptor.title) has no aliases")
        }
    }

    /// "One sentence, maximum two lines" — 120 characters is about two lines on
    /// an iPhone at the default text size.
    @Test func purposesStayShort() {
        for descriptor in CalculatorCatalog.all {
            #expect(descriptor.purpose.count <= 120, "\(descriptor.title): purpose is \(descriptor.purpose.count) characters")
        }
    }

    @Test func implementedCalculatorsDocumentTheirFormula() {
        for descriptor in CalculatorCatalog.available {
            let formula = descriptor.formula
            #expect(formula != nil, "\(descriptor.title) is implemented but has no formula")
            #expect(formula?.variables.isEmpty == false, "\(descriptor.title) has no variable definitions")
            #expect(formula?.spokenDescription.isEmpty == false, "\(descriptor.title) has no spoken formula")
        }
    }

    @Test func thePhaseOneCalculatorsAreTheImplementedOnes() {
        #expect(Set(CalculatorCatalog.available.map(\.id)) == [.powerConverter, .wavelength, .reflectionConverter])
    }

    @Test func quickCalculationsAreRealCalculators() {
        for id in CalculatorCatalog.quickCalculations {
            #expect(CalculatorCatalog.all.contains { $0.id == id })
        }
        #expect(CalculatorCatalog.quickCalculations.count == 4)
    }

    @Test func calculatorTitlesAreUnique() {
        let titles = CalculatorCatalog.all.map(\.title)
        #expect(Set(titles).count == titles.count)
    }

    // MARK: - Reference pages

    /// Target is 80–180 words; the bounds here leave room without letting a
    /// page turn into an essay.
    @Test func articlesStayWithinTheLengthTarget() {
        for article in ReferenceLibrary.all {
            let words = article.approximateWordCount
            #expect(words >= 40, "\(article.title) is only \(words) words")
            #expect(words <= 220, "\(article.title) is \(words) words")
        }
    }

    @Test func articlesFollowTheTemplate() {
        for article in ReferenceLibrary.all {
            #expect(!article.definition.isEmpty, "\(article.title) has no definition")
            #expect(!article.descriptor.isEmpty, "\(article.title) has no descriptor")
            #expect(!article.inPractice.isEmpty, "\(article.title) has no practical points")
            #expect(article.inPractice.count <= 3, "\(article.title) has more than three practical points")
            #expect(!article.aliases.isEmpty, "\(article.title) has no aliases")
        }
    }

    @Test func articleTitlesAreUnique() {
        let titles = ReferenceLibrary.all.map(\.title)
        #expect(Set(titles).count == titles.count)
    }

    @Test func articlesDoNotLinkToThemselves() {
        for article in ReferenceLibrary.all {
            #expect(!article.relatedArticles.contains(article.id), "\(article.title) links to itself")
        }
    }

    @Test func everyArticleOffersSomewhereToGoNext() {
        for article in ReferenceLibrary.all {
            let onward = article.relatedCalculators.count + article.relatedArticles.count
            #expect(onward > 0, "\(article.title) is a dead end")
        }
    }

    // MARK: - Categories

    /// Calculators and Reference share one set of categories (spec §4), and
    /// every category has to carry something.
    @Test func everyCategoryHasContent() {
        for category in RFCategory.allCases {
            let calculators = CalculatorCatalog.inCategory(category).count
            let articles = ReferenceLibrary.inCategory(category).count
            #expect(articles > 0, "\(category.title) has no reference pages")
            #expect(calculators + articles > 0, "\(category.title) is empty")
            #expect(!category.summary.isEmpty)
            #expect(!category.systemImage.isEmpty)
        }
    }

    // MARK: - Aliases

    @Test func aliasesAreLowercasedAndUnique() {
        for descriptor in CalculatorCatalog.all {
            #expect(descriptor.aliases.allSatisfy { $0 == $0.lowercased() }, "\(descriptor.title) has an uppercased alias")
            #expect(Set(descriptor.aliases).count == descriptor.aliases.count, "\(descriptor.title) repeats an alias")
        }
        for article in ReferenceLibrary.all {
            #expect(article.aliases.allSatisfy { $0 == $0.lowercased() }, "\(article.title) has an uppercased alias")
            #expect(Set(article.aliases).count == article.aliases.count, "\(article.title) repeats an alias")
        }
    }

    /// Every alias must actually find its own page — an alias that does not
    /// search is just a comment.
    @Test func everyAliasFindsItsOwnItem() {
        let index = SearchIndex.shared

        for descriptor in CalculatorCatalog.all {
            for alias in descriptor.aliases {
                let found = index.search(alias, limit: 100).map(\.item)
                #expect(found.contains(.calculator(descriptor.id)), "\(descriptor.title) is not found by \"\(alias)\"")
            }
        }

        for article in ReferenceLibrary.all {
            for alias in article.aliases {
                let found = index.search(alias, limit: 100).map(\.item)
                #expect(found.contains(.reference(article.id)), "\(article.title) is not found by \"\(alias)\"")
            }
        }
    }

    /// Titles have to be searchable too, not only aliases.
    @Test func everyTitleFindsItsOwnItem() {
        let index = SearchIndex.shared

        for descriptor in CalculatorCatalog.all {
            let found = index.search(descriptor.title, limit: 100).map(\.item)
            #expect(found.contains(.calculator(descriptor.id)), "\(descriptor.title) is not found by its own title")
        }
        for article in ReferenceLibrary.all {
            let found = index.search(article.title, limit: 100).map(\.item)
            #expect(found.contains(.reference(article.id)), "\(article.title) is not found by its own title")
        }
    }
}
