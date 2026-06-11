import SwiftUI

struct ShareView: View {
    @Bindable var vm: ShareViewModel

    var body: some View {
        NavigationStack {
            Group {
                switch vm.state {
                case .extracting:
                    statusView(icon: "arrow.down.circle", message: "Reading content…")

                case .parsing:
                    statusView(icon: "wand.and.stars", message: "Parsing recipe…")

                case .success(let dto):
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Thumbnail
                            if let imageURL = dto.media.first(where: { $0.type == "image" })?.url,
                               let url = URL(string: imageURL) {
                                AsyncImage(url: url) { img in
                                    img.resizable().scaledToFill()
                                } placeholder: {
                                    Color.secondary.opacity(0.2)
                                }
                                .frame(maxWidth: .infinity, maxHeight: 180)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            Text(dto.title)
                                .font(.title3.bold())

                            HStack(spacing: 12) {
                                if let servings = dto.metadata.servings {
                                    chip(icon: "person.2", text: "\(servings) \(dto.metadata.servingsUnit)")
                                }
                                if let total = totalMinutes(dto) {
                                    chip(icon: "clock", text: "\(total) min")
                                }
                                if let cuisine = dto.metadata.cuisine {
                                    chip(icon: "fork.knife", text: cuisine)
                                }
                            }

                            Divider()

                            Text("**\(dto.ingredients.count)** ingredients · **\(dto.steps.count)** steps")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }

                case .error(let message):
                    ContentUnavailableView(
                        "Could not parse recipe",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message)
                    )
                }
            }
            .navigationTitle("Recipe Found")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { vm.completeAndDiscard() }
                }
                if case .success = vm.state {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { vm.completeAndSave() }
                            .bold()
                    }
                }
            }
        }
        .task { await vm.start() }
    }

    private func totalMinutes(_ dto: RecipeDTO) -> Int? {
        if let total = dto.metadata.totalTimeMinutes { return total }
        let sum = (dto.metadata.prepTimeMinutes ?? 0) + (dto.metadata.cookTimeMinutes ?? 0)
        return sum > 0 ? sum : nil
    }

    private func statusView(icon: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(message)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func chip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).imageScale(.small)
            Text(text)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.quaternary, in: Capsule())
    }
}
