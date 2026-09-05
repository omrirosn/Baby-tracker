import Foundation
import Observation
import SwiftUI

/// Appearance override offered in Settings (spec §15).
enum AppearanceOption: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Everything the app remembers between launches.
///
/// `UserDefaults` is enough for favourites, recents and preferences, and it
/// keeps the MVP free of a persistence framework (spec §13). Nothing here ever
/// leaves the device.
@Observable
final class PreferencesStore {
    /// How many recently opened items are kept.
    static let recentLimit = 12

    @ObservationIgnored private let defaults: UserDefaults

    /// Storage keys of favourited items.
    private(set) var favourites: [String] {
        didSet { defaults.set(favourites, forKey: Keys.favourites) }
    }

    /// Storage keys of recently opened items, most recent first.
    private(set) var recents: [String] {
        didSet { defaults.set(recents, forKey: Keys.recents) }
    }

    var defaultImpedanceOhms: Double {
        didSet { defaults.set(defaultImpedanceOhms, forKey: Keys.impedance) }
    }

    var preferredPowerUnit: PowerUnit {
        didSet { defaults.set(preferredPowerUnit.rawValue, forKey: Keys.powerUnit) }
    }

    var preferredFrequencyUnit: FrequencyUnit {
        didSet { defaults.set(preferredFrequencyUnit.rawValue, forKey: Keys.frequencyUnit) }
    }

    var preferredLengthUnit: LengthUnit {
        didSet { defaults.set(preferredLengthUnit.rawValue, forKey: Keys.lengthUnit) }
    }

    var appearance: AppearanceOption {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    /// Last unit chosen per calculator field, keyed `calculatorID.fieldName`.
    private var lastUsedUnits: [String: String] {
        didSet { defaults.set(lastUsedUnits, forKey: Keys.lastUnits) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.favourites = defaults.stringArray(forKey: Keys.favourites) ?? []
        self.recents = defaults.stringArray(forKey: Keys.recents) ?? []
        let storedImpedance = defaults.double(forKey: Keys.impedance)
        self.defaultImpedanceOhms = storedImpedance > 0 ? storedImpedance : PhysicalConstants.defaultSystemImpedance
        self.preferredPowerUnit = PowerUnit(rawValue: defaults.string(forKey: Keys.powerUnit) ?? "") ?? .dBm
        self.preferredFrequencyUnit = FrequencyUnit(rawValue: defaults.string(forKey: Keys.frequencyUnit) ?? "") ?? .megahertz
        self.preferredLengthUnit = LengthUnit(rawValue: defaults.string(forKey: Keys.lengthUnit) ?? "") ?? .metre
        self.appearance = AppearanceOption(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        self.lastUsedUnits = defaults.dictionary(forKey: Keys.lastUnits) as? [String: String] ?? [:]
    }

    // MARK: - Favourites

    func isFavourite(_ item: CatalogItemID) -> Bool {
        favourites.contains(item.storageKey)
    }

    func toggleFavourite(_ item: CatalogItemID) {
        if let index = favourites.firstIndex(of: item.storageKey) {
            favourites.remove(at: index)
        } else {
            favourites.append(item.storageKey)
        }
    }

    func removeFavourite(_ item: CatalogItemID) {
        favourites.removeAll { $0 == item.storageKey }
    }

    /// Favourited calculators, in the order they appear in the catalogue.
    var favouriteCalculators: [CalculatorDescriptor] {
        CalculatorCatalog.all.filter { isFavourite(.calculator($0.id)) }
    }

    /// Favourited reference pages, in catalogue order.
    var favouriteArticles: [ReferenceArticle] {
        ReferenceLibrary.all.filter { isFavourite(.reference($0.id)) }
    }

    // MARK: - Recents

    /// Records that an item was opened. Most recent first, no duplicates.
    func recordVisit(_ item: CatalogItemID) {
        var updated = recents.filter { $0 != item.storageKey }
        updated.insert(item.storageKey, at: 0)
        recents = Array(updated.prefix(Self.recentLimit))
    }

    /// Recently opened items, skipping any whose content has since been removed.
    var recentItems: [CatalogItemID] {
        recents.compactMap(CatalogItemID.init(storageKey:))
    }

    func clearRecents() {
        recents = []
    }

    // MARK: - Last used units

    func lastUsedUnit<U: PhysicalUnit>(for key: String, default fallback: U) -> U {
        guard let raw = lastUsedUnits[key], let unit = U(rawValue: raw) else { return fallback }
        return unit
    }

    func setLastUsedUnit(_ unit: some PhysicalUnit, for key: String) {
        lastUsedUnits[key] = unit.rawValue
    }

    // MARK: - Keys

    private enum Keys {
        static let favourites = "favourites"
        static let recents = "recents"
        static let impedance = "defaultImpedanceOhms"
        static let powerUnit = "preferredPowerUnit"
        static let frequencyUnit = "preferredFrequencyUnit"
        static let lengthUnit = "preferredLengthUnit"
        static let appearance = "appearance"
        static let lastUnits = "lastUsedUnits"
    }
}

extension PreferencesStore {
    /// An empty store backed by a throwaway suite, for previews and tests.
    static func inMemory(name: String = UUID().uuidString) -> PreferencesStore {
        guard let defaults = UserDefaults(suiteName: "RFIsSimple.transient.\(name)") else {
            return PreferencesStore()
        }
        defaults.removePersistentDomain(forName: "RFIsSimple.transient.\(name)")
        return PreferencesStore(defaults: defaults)
    }

    /// A store with a little content in it, so previews show real rows.
    static var preview: PreferencesStore {
        let store = inMemory(name: "preview")
        store.toggleFavourite(.calculator(.powerConverter))
        store.toggleFavourite(.reference(.vswr))
        store.recordVisit(.calculator(.reflectionConverter))
        store.recordVisit(.calculator(.wavelength))
        return store
    }
}
