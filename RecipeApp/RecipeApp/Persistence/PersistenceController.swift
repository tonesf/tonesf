import Foundation
import SwiftData

enum AppGroup {
    // Replace with your actual App Group identifier
    static let identifier = "group.com.yourname.recipeapp"
}

enum UserDefaultsKey {
    static let backendURL = "backendURL"
    static let lastParsedRecipeID = "lastParsedRecipeID"
    static let preferredUnitSystem = "preferredUnitSystem"
}

@MainActor
final class PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer

    private init() {
        let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppGroup.identifier)?
            .appendingPathComponent("recipe.store")

        let config: ModelConfiguration
        if let url = groupURL {
            config = ModelConfiguration(url: url)
        } else {
            // Fallback for Simulator when App Group isn't configured
            config = ModelConfiguration()
        }

        container = try! ModelContainer(
            for: RecipeModel.self, IngredientModel.self, StepModel.self,
            configurations: config
        )
    }

    func save(dto: RecipeDTO) -> RecipeModel {
        let recipe = RecipeModel(from: dto)
        container.mainContext.insert(recipe)
        try? container.mainContext.save()
        return recipe
    }

    func delete(recipeID: UUID) {
        let ctx = container.mainContext
        let descriptor = FetchDescriptor<RecipeModel>(
            predicate: #Predicate { $0.id == recipeID }
        )
        if let recipe = try? ctx.fetch(descriptor).first {
            ctx.delete(recipe)
            try? ctx.save()
        }
    }
}
