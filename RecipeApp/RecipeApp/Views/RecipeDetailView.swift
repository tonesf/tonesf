import SwiftUI

struct RecipeDetailView: View {
    @State private var vm: RecipeDetailViewModel

    init(recipe: RecipeModel) {
        _vm = State(initialValue: RecipeDetailViewModel(recipe: recipe))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Hero media
                let media = vm.recipe.decodedMedia
                if !media.isEmpty {
                    MediaCarouselView(media: media)
                }

                VStack(alignment: .leading, spacing: 20) {

                    // Title + description
                    VStack(alignment: .leading, spacing: 6) {
                        Text(vm.recipe.title)
                            .font(.title2.bold())
                        if let desc = vm.recipe.recipeDescription {
                            Text(desc)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Metadata chips
                    MetaChipsView(recipe: vm.recipe)

                    Divider()

                    // Servings + unit toggle
                    HStack {
                        if let servings = vm.scaledServings {
                            Stepper(
                                "\(servings) \(vm.recipe.servingsUnit)",
                                value: $vm.scaleFactor,
                                in: 0.25...8,
                                step: 0.25
                            )
                        }
                        Spacer()
                        Picker("Units", selection: $vm.unitSystem) {
                            ForEach(UnitSystemPref.allCases) { sys in
                                Text(sys.displayName).tag(sys)
                            }
                        }
                        .pickerStyle(.segmented)
                        .fixedSize()
                    }

                    Divider()

                    // Ingredients
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ingredients")
                            .font(.headline)
                        ForEach(vm.sortedIngredients, id: \.id) { ing in
                            IngredientRowView(
                                ingredient: ing,
                                displayedQty: vm.displayedQuantity(for: ing)
                            )
                        }
                    }

                    Divider()

                    // Steps
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Instructions")
                            .font(.headline)
                        ForEach(vm.sortedSteps, id: \.id) { step in
                            StepRowView(
                                step: step,
                                displayedTemp: vm.displayedTemperature(for: step)
                            )
                        }
                    }

                    // Source link
                    if let urlString = vm.recipe.sourceURL,
                       let url = URL(string: urlString) {
                        Divider()
                        Link("View original source", destination: url)
                            .font(.footnote)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(vm.recipe.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    vm.recipe.isFavorite.toggle()
                } label: {
                    Image(systemName: vm.recipe.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(vm.recipe.isFavorite ? .red : .primary)
                }
            }
        }
    }
}

private struct MetaChipsView: View {
    let recipe: RecipeModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let time = recipe.totalTimeDisplay {
                    Chip(icon: "clock", text: time)
                }
                if let cuisine = recipe.cuisine {
                    Chip(icon: "fork.knife", text: cuisine)
                }
                if let diff = recipe.difficulty {
                    Chip(icon: "chart.bar", text: diff.capitalized)
                }
                ForEach(recipe.tags, id: \.self) { tag in
                    Chip(icon: nil, text: tag)
                }
            }
        }
    }
}

private struct Chip: View {
    let icon: String?
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            if let icon { Image(systemName: icon).imageScale(.small) }
            Text(text)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.quaternary, in: Capsule())
    }
}
