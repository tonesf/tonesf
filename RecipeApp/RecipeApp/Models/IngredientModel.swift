import Foundation
import SwiftData

@Model
final class IngredientModel {
    var id: UUID
    var quantity: Double?
    var quantityMax: Double?
    var unit: String?
    var unitSystem: String
    var name: String
    var preparation: String?
    var isOptional: Bool
    var sortOrder: Int
    var recipe: RecipeModel?

    init(from dto: IngredientDTO, sortOrder: Int) {
        self.id = UUID()
        self.quantity = dto.quantity
        self.quantityMax = dto.quantityMax
        self.unit = dto.unit
        self.unitSystem = dto.unitSystem
        self.name = dto.name
        self.preparation = dto.preparation
        self.isOptional = dto.optional
        self.sortOrder = sortOrder
    }
}
