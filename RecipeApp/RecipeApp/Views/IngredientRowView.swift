import SwiftUI

struct IngredientRowView: View {
    let ingredient: IngredientModel
    let displayedQty: ConvertedQuantity

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Quantity + unit
            Text(quantityText)
                .font(.body.monospacedDigit())
                .foregroundStyle(.primary)
                .frame(minWidth: 60, alignment: .trailing)

            // Name + prep
            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient.name)
                    .font(.body)
                if let prep = ingredient.preparation {
                    Text(prep)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if ingredient.isOptional {
                Spacer()
                Text("optional")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }

    private var quantityText: String {
        guard let v = displayedQty.value else { return "" }
        let formatted = displayedQty.formatted
        return formatted.isEmpty ? "" : formatted
    }
}
