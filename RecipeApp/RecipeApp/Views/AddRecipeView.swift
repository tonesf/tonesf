import SwiftUI

struct AddRecipeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx

    @State private var inputText: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $inputText)
                        .frame(minHeight: 120)
                } header: {
                    Text("Paste a recipe URL or text")
                } footer: {
                    Text("Tip: paste an Instagram post URL, a recipe website URL, or raw recipe text.")
                }

                if let err = errorMessage {
                    Section {
                        Text(err)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Add Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Parse") {
                        Task { await parse() }
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
            }
            .overlay {
                if isLoading {
                    ProgressView("Parsing recipe…")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    @MainActor
    private func parse() async {
        isLoading = true
        errorMessage = nil
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let isURL = trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://")

        do {
            let dto = try await APIClient.shared.parseRecipe(
                url: isURL ? trimmed : nil,
                text: isURL ? nil : trimmed
            )
            let recipe = PersistenceController.shared.save(dto: dto)
            _ = recipe  // saved to context
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
