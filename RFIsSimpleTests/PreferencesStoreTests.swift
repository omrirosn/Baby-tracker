import Foundation
import Testing
@testable import RFIsSimple

/// Favourites, recents and preferences — the only state the app keeps, all of
/// it local (spec §11, §13, §15).
struct PreferencesStoreTests {

    /// A `UserDefaults` suite of its own per test, removed afterwards.
    private func withStore(_ body: (PreferencesStore, UserDefaults) throws -> Void) throws {
        let suiteName = "RFIsSimpleTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        try body(PreferencesStore(defaults: defaults), defaults)
    }

    // MARK: - Favourites

    @Test func favouritesToggleAndPersist() throws {
        try withStore { store, defaults in
            #expect(store.isFavourite(.calculator(.powerConverter)) == false)

            store.toggleFavourite(.calculator(.powerConverter))
            #expect(store.isFavourite(.calculator(.powerConverter)))

            let reloaded = PreferencesStore(defaults: defaults)
            #expect(reloaded.isFavourite(.calculator(.powerConverter)))

            store.toggleFavourite(.calculator(.powerConverter))
            #expect(store.isFavourite(.calculator(.powerConverter)) == false)
        }
    }

    @Test func favouritesAreListedInCatalogueOrder() throws {
        try withStore { store, _ in
            store.toggleFavourite(.calculator(.reflectionConverter))
            store.toggleFavourite(.calculator(.powerConverter))
            #expect(store.favouriteCalculators.map(\.id) == [.powerConverter, .reflectionConverter])

            store.toggleFavourite(.reference(.vswr))
            #expect(store.favouriteArticles.map(\.id) == [.vswr])
        }
    }

    @Test func calculatorsAndArticlesWithTheSameNameDoNotCollide() throws {
        try withStore { store, _ in
            store.toggleFavourite(.calculator(.thermalNoise))
            #expect(store.isFavourite(.calculator(.thermalNoise)))
            #expect(store.isFavourite(.reference(.thermalNoise)) == false)
        }
    }

    // MARK: - Recents

    @Test func recentsAreMostRecentFirstAndDeduplicated() throws {
        try withStore { store, _ in
            store.recordVisit(.calculator(.powerConverter))
            store.recordVisit(.reference(.vswr))
            store.recordVisit(.calculator(.powerConverter))

            #expect(store.recentItems == [.calculator(.powerConverter), .reference(.vswr)])
        }
    }

    @Test func recentsAreCapped() throws {
        try withStore { store, _ in
            for id in CalculatorID.allCases {
                store.recordVisit(.calculator(id))
            }
            for id in ReferenceArticleID.allCases.prefix(10) {
                store.recordVisit(.reference(id))
            }
            #expect(store.recentItems.count == PreferencesStore.recentLimit)
        }
    }

    @Test func clearingRecentsKeepsFavourites() throws {
        try withStore { store, _ in
            store.toggleFavourite(.calculator(.wavelength))
            store.recordVisit(.calculator(.wavelength))

            store.clearRecents()
            #expect(store.recentItems.isEmpty)
            #expect(store.isFavourite(.calculator(.wavelength)))
        }
    }

    /// A stored key whose content has since been removed is skipped rather
    /// than crashing or showing an empty row.
    @Test func unknownStoredKeysAreIgnored() throws {
        try withStore { _, defaults in
            defaults.set(["calculator:powerConverter", "calculator:somethingRemoved", "nonsense"],
                         forKey: "recents")
            let store = PreferencesStore(defaults: defaults)
            #expect(store.recentItems == [.calculator(.powerConverter)])
        }
    }

    // MARK: - Units and preferences

    @Test func lastUsedUnitsRoundTrip() throws {
        try withStore { store, defaults in
            #expect(store.lastUsedUnit(for: "power", default: PowerUnit.dBm) == .dBm)

            store.setLastUsedUnit(PowerUnit.milliwatt, for: "power")
            #expect(store.lastUsedUnit(for: "power", default: PowerUnit.dBm) == .milliwatt)

            let reloaded = PreferencesStore(defaults: defaults)
            #expect(reloaded.lastUsedUnit(for: "power", default: PowerUnit.dBm) == .milliwatt)
        }
    }

    @Test func differentDimensionsDoNotShareAKey() throws {
        try withStore { store, _ in
            store.setLastUsedUnit(FrequencyUnit.gigahertz, for: "shared")
            // The stored raw value belongs to another dimension, so the default wins.
            #expect(store.lastUsedUnit(for: "shared", default: PowerUnit.dBm) == .dBm)
        }
    }

    @Test func defaultsMatchTheSpecification() throws {
        try withStore { store, _ in
            #expect(store.defaultImpedanceOhms == 50)
            #expect(store.appearance == .system)
            #expect(store.preferredPowerUnit == .dBm)
        }
    }

    @Test func preferencesPersist() throws {
        try withStore { store, defaults in
            store.defaultImpedanceOhms = 75
            store.appearance = .dark
            store.preferredFrequencyUnit = .gigahertz

            let reloaded = PreferencesStore(defaults: defaults)
            #expect(reloaded.defaultImpedanceOhms == 75)
            #expect(reloaded.appearance == .dark)
            #expect(reloaded.preferredFrequencyUnit == .gigahertz)
        }
    }

    // MARK: - Identifiers

    @Test func storageKeysRoundTrip() {
        for id in CalculatorID.allCases {
            let item = CatalogItemID.calculator(id)
            #expect(CatalogItemID(storageKey: item.storageKey) == item)
        }
        for id in ReferenceArticleID.allCases {
            let item = CatalogItemID.reference(id)
            #expect(CatalogItemID(storageKey: item.storageKey) == item)
        }
        #expect(CatalogItemID(storageKey: "calculator:nope") == nil)
        #expect(CatalogItemID(storageKey: "malformed") == nil)
    }
}
