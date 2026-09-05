import Foundation

/// Anything the app can favourite, list as recent, or return from a search.
enum CatalogItemID: Hashable, Sendable, Identifiable {
    case calculator(CalculatorID)
    case reference(ReferenceArticleID)

    var id: String { storageKey }

    /// Stable string used in `UserDefaults`. Readable on purpose, so stored
    /// state can be inspected while debugging.
    var storageKey: String {
        switch self {
        case let .calculator(id): return "calculator:\(id.rawValue)"
        case let .reference(id): return "reference:\(id.rawValue)"
        }
    }

    /// Returns `nil` for a key written by an older build whose item no longer
    /// exists, which is how stored favourites and recents survive content changes.
    init?(storageKey: String) {
        let parts = storageKey.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2 else { return nil }
        let value = String(parts[1])
        switch parts[0] {
        case "calculator":
            guard let id = CalculatorID(rawValue: value) else { return nil }
            self = .calculator(id)
        case "reference":
            guard let id = ReferenceArticleID(rawValue: value) else { return nil }
            self = .reference(id)
        default:
            return nil
        }
    }

    var kindLabel: String {
        switch self {
        case .calculator: return "Calculator"
        case .reference: return "Reference"
        }
    }

    var title: String {
        switch self {
        case let .calculator(id): return id.descriptor.title
        case let .reference(id): return id.article.title
        }
    }

    var subtitle: String {
        switch self {
        case let .calculator(id): return id.descriptor.purpose
        case let .reference(id): return id.article.descriptor
        }
    }

    var category: RFCategory {
        switch self {
        case let .calculator(id): return id.descriptor.category
        case let .reference(id): return id.article.category
        }
    }

    var systemImage: String {
        switch self {
        case let .calculator(id): return id.descriptor.systemImage
        case let .reference(id): return id.article.category.systemImage
        }
    }
}
