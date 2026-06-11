import Foundation
import Observation

@Observable
final class RecipeListViewModel {
    var searchText: String = ""
    var sortOrder: SortOrder = .newest
    var pendingRecipeID: UUID?

    enum SortOrder: String, CaseIterable, Identifiable {
        case newest = "Newest"
        case oldest = "Oldest"
        case titleAZ = "A–Z"
        var id: String { rawValue }
    }

    func filtered(_ recipes: [RecipeModel]) -> [RecipeModel] {
        let base = searchText.isEmpty
            ? recipes
            : recipes.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        return base.sorted(by: comparator)
    }

    private var comparator: (RecipeModel, RecipeModel) -> Bool {
        switch sortOrder {
        case .newest: return { $0.createdAt > $1.createdAt }
        case .oldest: return { $0.createdAt < $1.createdAt }
        case .titleAZ: return { $0.title < $1.title }
        }
    }
}
