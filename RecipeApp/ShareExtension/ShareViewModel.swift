import Foundation
import Observation
import UniformTypeIdentifiers

@MainActor
@Observable
final class ShareViewModel {
    var state: ShareState = .extracting
    private var extensionContext: NSExtensionContext

    enum ShareState {
        case extracting
        case parsing
        case success(RecipeDTO)
        case error(String)
    }

    init(extensionContext: NSExtensionContext) {
        self.extensionContext = extensionContext
    }

    func start() async {
        let content = await extractSharedContent()
        state = .parsing

        do {
            let dto = try await APIClient.shared.parseRecipe(
                url: content.url,
                text: content.text
            )
            let recipe = PersistenceController.shared.save(dto: dto)

            // Signal main app to deep-link to this recipe
            UserDefaults(suiteName: AppGroup.identifier)?
                .set(recipe.id.uuidString, forKey: UserDefaultsKey.lastParsedRecipeID)

            state = .success(dto)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func completeAndSave() {
        extensionContext.completeRequest(returningItems: nil)
    }

    func completeAndDiscard() {
        if case .success(let dto) = state {
            // Find and remove the just-saved recipe
            let id = UserDefaults(suiteName: AppGroup.identifier)?
                .string(forKey: UserDefaultsKey.lastParsedRecipeID)
                .flatMap { UUID(uuidString: $0) }
            if let id {
                PersistenceController.shared.delete(recipeID: id)
            }
            _ = dto
        }
        extensionContext.completeRequest(returningItems: nil)
    }

    private func extractSharedContent() async -> SharedContent {
        guard let items = extensionContext.inputItems as? [NSExtensionItem] else {
            return SharedContent()
        }
        for item in items {
            for provider in (item.attachments ?? []) {
                // URL first (includes Instagram links copied from the app)
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    if let url = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
                        return SharedContent(url: url.absoluteString)
                    }
                }
                // Plain text fallback
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    if let text = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
                        // If text looks like a URL, treat it as one
                        if text.hasPrefix("http://") || text.hasPrefix("https://") {
                            return SharedContent(url: text)
                        }
                        return SharedContent(text: text)
                    }
                }
            }
        }
        return SharedContent()
    }
}

struct SharedContent {
    var url: String?
    var text: String?
}
