import Foundation

enum DimensionType {
    case volume, weight, temperature, count
}

enum UnitSystemPref: String, CaseIterable, Identifiable {
    case imperial, metric
    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

enum CookingUnit: String, CaseIterable, Codable {
    // Volume — metric
    case milliliter
    case liter
    // Volume — imperial
    case teaspoon
    case tablespoon
    case fluidOunce = "fluid ounce"
    case cup
    case pint
    case quart
    case gallon
    // Weight — metric
    case gram
    case kilogram
    // Weight — imperial
    case ounce
    case pound
    // Temperature
    case fahrenheit
    case celsius
    // Universal
    case whole
    case pinch
    case dash
    case clove
    case sprig
    case slice
    case unknown

    static func from(string: String?) -> CookingUnit {
        guard let s = string?.lowercased().trimmingCharacters(in: .whitespaces) else { return .unknown }
        let aliases: [String: CookingUnit] = [
            "ml": .milliliter, "milliliters": .milliliter, "milliliter": .milliliter,
            "l": .liter, "liters": .liter, "liter": .liter,
            "tsp": .teaspoon, "teaspoons": .teaspoon, "teaspoon": .teaspoon,
            "tbsp": .tablespoon, "tablespoons": .tablespoon, "tablespoon": .tablespoon,
            "fl oz": .fluidOunce, "fluid ounce": .fluidOunce, "fluid ounces": .fluidOunce,
            "cups": .cup, "cup": .cup,
            "pints": .pint, "pint": .pint,
            "quarts": .quart, "quart": .quart,
            "gallons": .gallon, "gallon": .gallon,
            "g": .gram, "grams": .gram, "gram": .gram,
            "kg": .kilogram, "kilograms": .kilogram, "kilogram": .kilogram,
            "oz": .ounce, "ounces": .ounce, "ounce": .ounce,
            "lb": .pound, "lbs": .pound, "pounds": .pound, "pound": .pound,
            "°f": .fahrenheit, "f": .fahrenheit, "fahrenheit": .fahrenheit,
            "°c": .celsius, "c": .celsius, "celsius": .celsius,
            "cloves": .clove, "clove": .clove,
            "sprigs": .sprig, "sprig": .sprig,
            "slices": .slice, "slice": .slice,
            "pinch": .pinch, "pinches": .pinch,
            "dash": .dash, "dashes": .dash,
        ]
        return aliases[s] ?? .unknown
    }

    var dimensionType: DimensionType {
        switch self {
        case .milliliter, .liter, .teaspoon, .tablespoon, .fluidOunce,
             .cup, .pint, .quart, .gallon: return .volume
        case .gram, .kilogram, .ounce, .pound: return .weight
        case .fahrenheit, .celsius: return .temperature
        default: return .count
        }
    }

    var isMetric: Bool {
        switch self {
        case .milliliter, .liter, .gram, .kilogram, .celsius: return true
        default: return false
        }
    }

    var displayName: String {
        switch self {
        case .milliliter: return "ml"
        case .liter: return "L"
        case .teaspoon: return "tsp"
        case .tablespoon: return "tbsp"
        case .fluidOunce: return "fl oz"
        case .cup: return "cup"
        case .pint: return "pint"
        case .quart: return "qt"
        case .gallon: return "gal"
        case .gram: return "g"
        case .kilogram: return "kg"
        case .ounce: return "oz"
        case .pound: return "lb"
        case .fahrenheit: return "°F"
        case .celsius: return "°C"
        default: return rawValue
        }
    }
}
