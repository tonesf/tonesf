import Foundation
import Observation

@Observable
final class RecipeDetailViewModel {
    var recipe: RecipeModel
    var unitSystem: UnitSystemPref {
        didSet {
            UserDefaults(suiteName: AppGroup.identifier)?
                .set(unitSystem.rawValue, forKey: UserDefaultsKey.preferredUnitSystem)
        }
    }
    var scaleFactor: Double = 1.0

    init(recipe: RecipeModel) {
        self.recipe = recipe
        let stored = UserDefaults(suiteName: AppGroup.identifier)?
            .string(forKey: UserDefaultsKey.preferredUnitSystem) ?? "imperial"
        self.unitSystem = UnitSystemPref(rawValue: stored) ?? .imperial
    }

    var sortedIngredients: [IngredientModel] {
        recipe.ingredients.sorted { $0.sortOrder < $1.sortOrder }
    }

    var sortedSteps: [StepModel] {
        recipe.steps.sorted { $0.index < $1.index }
    }

    func displayedQuantity(for ingredient: IngredientModel) -> ConvertedQuantity {
        let scaled = ingredient.quantity.map { $0 * scaleFactor }
        return UnitConverter.convert(quantity: scaled, unit: ingredient.unit, to: unitSystem)
    }

    func displayedTemperature(for step: StepModel) -> String? {
        guard let tempF = step.temperatureF else { return nil }
        let converted = UnitConverter.convert(quantity: tempF, unit: "fahrenheit", to: unitSystem)
        return converted.formatted
    }

    var scaledServings: Int? {
        guard let s = recipe.servings else { return nil }
        return max(1, Int((Double(s) * scaleFactor).rounded()))
    }
}
