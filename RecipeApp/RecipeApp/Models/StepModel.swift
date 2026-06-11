import Foundation
import SwiftData

@Model
final class StepModel {
    var id: UUID
    var index: Int
    var instruction: String
    var durationMinutes: Int?
    var temperatureF: Double?
    var recipe: RecipeModel?

    init(from dto: StepDTO) {
        self.id = UUID()
        self.index = dto.index
        self.instruction = dto.instruction
        self.durationMinutes = dto.durationMinutes
        self.temperatureF = dto.temperatureF
    }
}
