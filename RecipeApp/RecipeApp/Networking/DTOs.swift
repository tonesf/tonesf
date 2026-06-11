import Foundation

struct RecipeDTO: Codable {
    let title: String
    let description: String?
    let ingredients: [IngredientDTO]
    let steps: [StepDTO]
    let media: [MediaItemDTO]
    let metadata: RecipeMetadataDTO
}

struct IngredientDTO: Codable {
    let quantity: Double?
    let quantityMax: Double?
    let unit: String?
    let unitSystem: String
    let name: String
    let preparation: String?
    let optional: Bool
}

struct StepDTO: Codable {
    let index: Int
    let instruction: String
    let durationMinutes: Int?
    let temperatureF: Double?
    let mediaUrls: [String]
}

struct MediaItemDTO: Codable {
    let url: String
    let type: String  // "image" | "video"
    let caption: String?
    let width: Int?
    let height: Int?
}

struct RecipeMetadataDTO: Codable {
    let sourceUrl: String?
    let sourcePlatform: String?
    let servings: Int?
    let servingsUnit: String
    let prepTimeMinutes: Int?
    let cookTimeMinutes: Int?
    let totalTimeMinutes: Int?
    let cuisine: String?
    let mealType: String?
    let difficulty: String?
    let tags: [String]
}

struct ParseRequestBody: Codable {
    var url: String?
    var text: String?
    var imageBase64: String?
}
