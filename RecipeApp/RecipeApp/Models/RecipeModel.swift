import Foundation
import SwiftData

@Model
final class RecipeModel {
    var id: UUID
    var title: String
    var recipeDescription: String?
    var sourceURL: String?
    var sourcePlatform: String?
    var servings: Int?
    var servingsUnit: String
    var prepTimeMinutes: Int?
    var cookTimeMinutes: Int?
    var totalTimeMinutes: Int?
    var cuisine: String?
    var mealType: String?
    var difficulty: String?
    var tags: [String]
    var createdAt: Date
    var isFavorite: Bool

    // Stored as JSON-encoded [MediaItemDTO] to keep the schema flat
    var mediaJSON: Data?

    @Relationship(deleteRule: .cascade, inverse: \IngredientModel.recipe)
    var ingredients: [IngredientModel]

    @Relationship(deleteRule: .cascade, inverse: \StepModel.recipe)
    var steps: [StepModel]

    init(from dto: RecipeDTO) {
        self.id = UUID()
        self.title = dto.title
        self.recipeDescription = dto.description
        self.sourceURL = dto.metadata.sourceUrl
        self.sourcePlatform = dto.metadata.sourcePlatform
        self.servings = dto.metadata.servings
        self.servingsUnit = dto.metadata.servingsUnit
        self.prepTimeMinutes = dto.metadata.prepTimeMinutes
        self.cookTimeMinutes = dto.metadata.cookTimeMinutes
        self.totalTimeMinutes = dto.metadata.totalTimeMinutes
        self.cuisine = dto.metadata.cuisine
        self.mealType = dto.metadata.mealType
        self.difficulty = dto.metadata.difficulty
        self.tags = dto.metadata.tags
        self.createdAt = Date()
        self.isFavorite = false
        self.ingredients = dto.ingredients.enumerated().map { idx, ing in
            IngredientModel(from: ing, sortOrder: idx)
        }
        self.steps = dto.steps.map { StepModel(from: $0) }
        self.mediaJSON = try? JSONEncoder().encode(dto.media)
    }

    var decodedMedia: [MediaItemDTO] {
        guard let data = mediaJSON else { return [] }
        return (try? JSONDecoder().decode([MediaItemDTO].self, from: data)) ?? []
    }

    var totalTimeDisplay: String? {
        let minutes = totalTimeMinutes ?? (prepTimeMinutes.map { $0 } ?? 0) + (cookTimeMinutes.map { $0 } ?? 0)
        guard minutes > 0 else { return nil }
        if minutes < 60 { return "\(minutes) min" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h) hr" : "\(h) hr \(m) min"
    }
}
