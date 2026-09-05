import SwiftUI

/// Everything that can be pushed onto a navigation stack.
///
/// Routes are values, so any screen can link anywhere without holding a
/// reference to another view.
enum Route: Hashable {
    case calculator(CalculatorID)
    case reference(ReferenceArticleID)
    case category(RFCategory)
    case allCalculators
    case allReference

    init(item: CatalogItemID) {
        switch item {
        case let .calculator(id): self = .calculator(id)
        case let .reference(id): self = .reference(id)
        }
    }
}

/// Resolves a route to its screen.
struct RouteView: View {
    let route: Route

    var body: some View {
        switch route {
        case let .calculator(id):
            CalculatorDetailView(descriptor: id.descriptor)
        case let .reference(id):
            ReferenceArticleView(article: id.article)
        case let .category(category):
            CategoryView(category: category)
        case .allCalculators:
            CalculatorsListView()
        case .allReference:
            ReferenceListView()
        }
    }
}

extension View {
    /// Registers every destination once per navigation stack.
    func rfNavigationDestinations() -> some View {
        navigationDestination(for: Route.self) { route in
            RouteView(route: route)
        }
    }
}
