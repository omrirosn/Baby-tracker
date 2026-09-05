import Foundation

/// What a search should look through.
enum SearchScope: Hashable, Sendable {
    case all
    case calculators
    case reference

    func includes(_ item: CatalogItemID) -> Bool {
        switch (self, item) {
        case (.all, _): return true
        case (.calculators, .calculator): return true
        case (.reference, .reference): return true
        default: return false
        }
    }
}

/// One hit, carrying enough context to tell two similar hits apart — which is
/// the point of "Friis" returning both free-space path loss and cascaded noise
/// figure, clearly differentiated (spec §3).
struct SearchResult: Identifiable, Hashable, Sendable {
    let item: CatalogItemID
    let title: String
    let subtitle: String
    let category: RFCategory
    let systemImage: String
    let score: Int

    var id: String { item.storageKey }
    var kindLabel: String { item.kindLabel }
}

/// Global search over calculators, concepts, formulas, abbreviations and
/// aliases (spec §3).
///
/// The index is built once from the content catalogue. Matching runs over a
/// few dozen entries, so a linear scan is both fast enough and easy to reason
/// about — no third-party search dependency.
struct SearchIndex: Sendable {
    private struct Entry: Sendable {
        let item: CatalogItemID
        let title: String
        let subtitle: String
        let category: RFCategory
        let systemImage: String
        /// Title, aliases, category, formula and body text, normalised.
        let haystack: String
        let normalisedTitle: String
        let aliases: [String]
        let tokens: Set<String>
    }

    static let shared = SearchIndex()

    private let entries: [Entry]

    init(
        calculators: [CalculatorDescriptor] = CalculatorCatalog.all,
        articles: [ReferenceArticle] = ReferenceLibrary.all
    ) {
        var entries: [Entry] = []

        for calculator in calculators {
            let parts = [calculator.title, calculator.purpose, calculator.category.title]
                + calculator.aliases
                + [calculator.formula?.expression ?? "", calculator.practicalNote]
            entries.append(
                Entry(
                    item: .calculator(calculator.id),
                    title: calculator.title,
                    subtitle: calculator.purpose,
                    category: calculator.category,
                    systemImage: calculator.systemImage,
                    haystack: SearchText.normalise(parts.joined(separator: " ")),
                    normalisedTitle: SearchText.normalise(calculator.title),
                    aliases: calculator.aliases.map(SearchText.normalise),
                    tokens: SearchText.tokens(parts.joined(separator: " "))
                )
            )
        }

        for article in articles {
            let parts = [article.title, article.descriptor, article.category.title, article.definition]
                + article.aliases
                + article.inPractice
                + [article.keyRelationship?.expression ?? ""]
            entries.append(
                Entry(
                    item: .reference(article.id),
                    title: article.title,
                    subtitle: article.descriptor,
                    category: article.category,
                    systemImage: article.category.systemImage,
                    haystack: SearchText.normalise(parts.joined(separator: " ")),
                    normalisedTitle: SearchText.normalise(article.title),
                    aliases: article.aliases.map(SearchText.normalise),
                    tokens: SearchText.tokens(parts.joined(separator: " "))
                )
            )
        }

        self.entries = entries
    }

    func search(_ query: String, scope: SearchScope = .all, limit: Int = 40) -> [SearchResult] {
        let normalised = SearchText.normalise(query)
        guard !normalised.isEmpty else { return [] }
        let queryTokens = SearchText.tokens(query)

        var results: [SearchResult] = []
        for entry in entries where scope.includes(entry.item) {
            guard let score = score(entry: entry, query: normalised, queryTokens: queryTokens) else { continue }
            results.append(
                SearchResult(
                    item: entry.item,
                    title: entry.title,
                    subtitle: entry.subtitle,
                    category: entry.category,
                    systemImage: entry.systemImage,
                    score: score
                )
            )
        }

        results.sort { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
        return Array(results.prefix(limit))
    }

    /// Ranking, highest first: exact title, title prefix, exact alias, alias
    /// prefix, title substring, anything else in the entry, then a token match
    /// so multi-word queries such as "noise floor analyser" still land.
    private func score(entry: Entry, query: String, queryTokens: Set<String>) -> Int? {
        if entry.normalisedTitle == query { return 1000 }
        if entry.normalisedTitle.hasPrefix(query) { return 850 }
        if entry.aliases.contains(query) { return 800 }
        if entry.aliases.contains(where: { $0.hasPrefix(query) }) { return 650 }
        if entry.normalisedTitle.contains(query) { return 500 }
        if entry.haystack.contains(query) { return 350 }

        guard !queryTokens.isEmpty else { return nil }
        let everyTokenMatches = queryTokens.allSatisfy { token in
            entry.tokens.contains { $0.hasPrefix(token) }
        }
        return everyTokenMatches ? 200 : nil
    }
}

/// Normalisation shared by the index and the query.
enum SearchText {
    /// Lowercased, diacritic-folded, whitespace-collapsed. Punctuation is kept
    /// so an alias like `-174 dBm/Hz` can still be matched literally.
    static func normalise(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive], locale: nil)
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
    }

    /// Word-ish pieces, with punctuation dropped: `-174 dBm/Hz` becomes
    /// `["174", "dbm", "hz"]`.
    static func tokens(_ text: String) -> Set<String> {
        let normalised = normalise(text)
        let pieces = normalised.split { character in
            !(character.isLetter || character.isNumber)
        }
        return Set(pieces.map(String.init).filter { !$0.isEmpty })
    }
}
