import Testing
@testable import RFIsSimple

/// Global search over calculators, concepts, formulas, abbreviations and
/// aliases (spec §3).
struct SearchIndexTests {
    private let index = SearchIndex.shared

    private func items(_ query: String, scope: SearchScope = .all) -> [CatalogItemID] {
        index.search(query, scope: scope, limit: 100).map(\.item)
    }

    // MARK: - The aliases named in the spec

    /// "Friis" belongs to two different relationships, and both must come back
    /// so the user can tell them apart.
    @Test func friisReturnsBothPathLossAndNoiseFigure() {
        let results = index.search("friis", limit: 100)
        let found = results.map(\.item)

        #expect(found.contains(.calculator(.freeSpacePathLoss)))
        #expect(found.contains(.calculator(.cascadedGainNoiseFigure)))
        #expect(found.contains(.reference(.freeSpacePathLoss)))
        #expect(found.contains(.reference(.noiseFigure)))

        // Each hit carries its own category and kind, which is what tells them apart.
        let categories = Set(results.map(\.category))
        #expect(categories.contains(.propagation))
        #expect(categories.contains(.rfSystems))
    }

    @Test(arguments: ["s11", "return loss", "reflection", "vswr", "swr", "gamma"])
    func reflectionAliasesAllLandOnReflectionContent(_ query: String) {
        let found = items(query)
        let reflectionItems: Set<CatalogItemID> = [
            .calculator(.reflectionConverter),
            .reference(.vswr),
            .reference(.returnLoss),
            .reference(.reflectionCoefficient),
            .reference(.mismatchLoss),
            .reference(.sParameters)
        ]
        #expect(found.contains { reflectionItems.contains($0) }, "No reflection content for \(query)")
    }

    @Test(arguments: ["noise floor", "thermal noise", "ktb", "-174 dBm/Hz", "174", "johnson noise"])
    func thermalNoiseAliases(_ query: String) {
        let found = items(query)
        #expect(
            found.contains(.reference(.thermalNoise)) || found.contains(.calculator(.thermalNoise)),
            "No thermal noise content for \(query)"
        )
    }

    // MARK: - Ranking

    @Test func anExactTitleOutranksAnAliasMatch() throws {
        let results = index.search("vswr")
        let first = try #require(results.first)
        #expect(first.item == .reference(.vswr))
    }

    @Test func prefixesMatchWhileTyping() {
        #expect(items("wavel").contains(.calculator(.wavelength)))
        #expect(items("reflec").contains(.calculator(.reflectionConverter)))
        #expect(items("dbm").contains(.calculator(.powerConverter)))
    }

    @Test func multipleWordsAllHaveToMatch() {
        let found = items("cascaded noise")
        #expect(found.contains(.calculator(.cascadedGainNoiseFigure)) || found.contains(.reference(.noiseFigure)))
        #expect(items("wavelength noise figure").isEmpty)
    }

    // MARK: - Scope

    @Test func scopeLimitsTheKindOfResult() {
        let calculators = index.search("noise", scope: .calculators, limit: 100)
        #expect(!calculators.isEmpty)
        #expect(calculators.allSatisfy { $0.kindLabel == "Calculator" })

        let reference = index.search("noise", scope: .reference, limit: 100)
        #expect(!reference.isEmpty)
        #expect(reference.allSatisfy { $0.kindLabel == "Reference" })
    }

    // MARK: - Edges

    @Test func emptyQueriesReturnNothing() {
        #expect(index.search("").isEmpty)
        #expect(index.search("   ").isEmpty)
    }

    @Test func nonsenseReturnsNothing() {
        #expect(index.search("qwertyuiop").isEmpty)
    }

    @Test func searchIgnoresCaseAndAccents() {
        #expect(items("VSWR") == items("vswr"))
        #expect(items("Polarisation").contains(.reference(.polarisation)))
    }

    @Test func resultsAreUniquePerItem() {
        let results = index.search("power", limit: 100)
        #expect(Set(results.map(\.id)).count == results.count)
    }
}
