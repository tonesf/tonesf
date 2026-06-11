import Foundation

struct ConvertedQuantity {
    let value: Double?
    let unit: CookingUnit

    var formatted: String {
        guard let v = value else { return "" }
        return formatValue(v) + " " + unit.displayName
    }

    private func formatValue(_ d: Double) -> String {
        // Try common cooking fractions
        let fractions: [(Double, String)] = [
            (1.0/8, "⅛"), (1.0/4, "¼"), (1.0/3, "⅓"),
            (1.0/2, "½"), (2.0/3, "⅔"), (3.0/4, "¾"),
        ]
        let whole = Int(d)
        let rem = d - Double(whole)

        for (fraction, symbol) in fractions {
            if abs(rem - fraction) < 0.04 {
                return whole > 0 ? "\(whole) \(symbol)" : symbol
            }
        }

        if rem < 0.05 { return "\(whole)" }

        // Use 1 decimal for metric, keep to sensible precision otherwise
        if d >= 100 {
            return String(format: "%.0f", d)
        } else if d >= 10 {
            return String(format: "%.1f", d)
        } else {
            return String(format: "%.2g", d)
        }
    }
}

enum UnitConverter {
    // Volume: how many ml per unit
    private static let toML: [CookingUnit: Double] = [
        .milliliter: 1, .liter: 1000,
        .teaspoon: 4.92892, .tablespoon: 14.7868,
        .fluidOunce: 29.5735, .cup: 236.588,
        .pint: 473.176, .quart: 946.353, .gallon: 3785.41,
    ]
    // Weight: how many grams per unit
    private static let toGrams: [CookingUnit: Double] = [
        .gram: 1, .kilogram: 1000,
        .ounce: 28.3495, .pound: 453.592,
    ]

    static func convert(
        quantity: Double?,
        unit unitString: String?,
        to target: UnitSystemPref
    ) -> ConvertedQuantity {
        let source = CookingUnit.from(string: unitString)
        guard let qty = quantity else {
            return ConvertedQuantity(value: nil, unit: source)
        }

        // Universal/countable — never convert
        if source.dimensionType == .count || source == .unknown {
            return ConvertedQuantity(value: qty, unit: source)
        }

        let sourceIsMetric = source.isMetric
        let targetIsMetric = target == .metric

        // Already in correct system
        if sourceIsMetric == targetIsMetric {
            return ConvertedQuantity(value: qty, unit: source)
        }

        switch source.dimensionType {
        case .volume: return convertVolume(qty, from: source, toMetric: targetIsMetric)
        case .weight: return convertWeight(qty, from: source, toMetric: targetIsMetric)
        case .temperature: return convertTemperature(qty, from: source, toMetric: targetIsMetric)
        case .count: return ConvertedQuantity(value: qty, unit: source)
        }
    }

    private static func convertVolume(_ qty: Double, from: CookingUnit, toMetric: Bool) -> ConvertedQuantity {
        let ml = qty * (toML[from] ?? 1.0)
        if toMetric {
            return ml >= 950
                ? ConvertedQuantity(value: ml / 1000, unit: .liter)
                : ConvertedQuantity(value: ml, unit: .milliliter)
        } else {
            return bestImperialVolume(ml: ml)
        }
    }

    private static func bestImperialVolume(ml: Double) -> ConvertedQuantity {
        let tsp = ml / toML[.teaspoon]!
        if tsp <= 3.1 { return ConvertedQuantity(value: tsp, unit: .teaspoon) }
        let tbsp = ml / toML[.tablespoon]!
        if tbsp <= 4.1 { return ConvertedQuantity(value: tbsp, unit: .tablespoon) }
        let cups = ml / toML[.cup]!
        if cups <= 4.1 { return ConvertedQuantity(value: cups, unit: .cup) }
        let qt = ml / toML[.quart]!
        return ConvertedQuantity(value: qt, unit: .quart)
    }

    private static func convertWeight(_ qty: Double, from: CookingUnit, toMetric: Bool) -> ConvertedQuantity {
        let grams = qty * (toGrams[from] ?? 1.0)
        if toMetric {
            return grams >= 950
                ? ConvertedQuantity(value: grams / 1000, unit: .kilogram)
                : ConvertedQuantity(value: grams, unit: .gram)
        } else {
            let oz = grams / toGrams[.ounce]!
            return oz >= 16
                ? ConvertedQuantity(value: oz / 16, unit: .pound)
                : ConvertedQuantity(value: oz, unit: .ounce)
        }
    }

    private static func convertTemperature(_ qty: Double, from: CookingUnit, toMetric: Bool) -> ConvertedQuantity {
        if from == .fahrenheit && toMetric {
            return ConvertedQuantity(value: (qty - 32) * 5 / 9, unit: .celsius)
        } else if from == .celsius && !toMetric {
            return ConvertedQuantity(value: qty * 9 / 5 + 32, unit: .fahrenheit)
        }
        return ConvertedQuantity(value: qty, unit: from)
    }
}
