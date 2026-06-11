import SwiftData
import SwiftUI

struct RecipeListView: View {
    @Environment(\.modelContext) private var ctx
    @Query private var allRecipes: [RecipeModel]
    @State private var vm = RecipeListViewModel()
    @State private var path = NavigationPath()
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if allRecipes.isEmpty {
                    ContentUnavailableView(
                        "No recipes yet",
                        systemImage: "fork.knife.circle",
                        description: Text("Share a recipe URL or Instagram post to get started.")
                    )
                } else {
                    List(vm.filtered(allRecipes)) { recipe in
                        NavigationLink(value: recipe) {
                            RecipeRowView(recipe: recipe)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                ctx.delete(recipe)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                recipe.isFavorite.toggle()
                            } label: {
                                Label(
                                    recipe.isFavorite ? "Unfave" : "Favorite",
                                    systemImage: recipe.isFavorite ? "heart.slash" : "heart"
                                )
                            }
                            .tint(.pink)
                        }
                    }
                    .searchable(text: $vm.searchText, prompt: "Search recipes")
                }
            }
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sort", selection: $vm.sortOrder) {
                            ForEach(RecipeListViewModel.SortOrder.allCases) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(for: RecipeModel.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .sheet(isPresented: $showAddSheet) {
                AddRecipeView()
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
        ) { _ in
            checkForPendingRecipe()
        }
        .onAppear { checkForPendingRecipe() }
    }

    private func checkForPendingRecipe() {
        let defaults = UserDefaults(suiteName: AppGroup.identifier)
        guard let idString = defaults?.string(forKey: UserDefaultsKey.lastParsedRecipeID),
              let id = UUID(uuidString: idString) else { return }
        defaults?.removeObject(forKey: UserDefaultsKey.lastParsedRecipeID)

        let descriptor = FetchDescriptor<RecipeModel>(predicate: #Predicate { $0.id == id })
        if let recipe = try? ctx.fetch(descriptor).first {
            path.append(recipe)
        }
    }
}

private struct RecipeRowView: View {
    let recipe: RecipeModel

    var body: some View {
        HStack(spacing: 12) {
            if let media = recipe.decodedMedia.first, let url = URL(string: media.url) {
                AsyncImage(url: url) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Color.secondary.opacity(0.2)
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.secondary.opacity(0.2))
                    .frame(width: 56, height: 56)
                    .overlay { Image(systemName: "fork.knife").foregroundStyle(.secondary) }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(recipe.title).font(.headline).lineLimit(1)
                HStack(spacing: 6) {
                    if let time = recipe.totalTimeDisplay {
                        Text(time).font(.caption).foregroundStyle(.secondary)
                    }
                    if let cuisine = recipe.cuisine {
                        Text("·").foregroundStyle(.tertiary)
                        Text(cuisine).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if recipe.isFavorite {
                Image(systemName: "heart.fill").foregroundStyle(.pink).imageScale(.small)
            }
        }
        .padding(.vertical, 2)
    }
}
