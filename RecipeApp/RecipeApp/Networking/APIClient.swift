import Foundation

enum APIError: LocalizedError {
    case serverError(Int, String)
    case decodingError(Error)
    case networkError(Error)
    case notARecipe

    var errorDescription: String? {
        switch self {
        case .serverError(let code, let message): return "Server error \(code): \(message)"
        case .decodingError(let err): return "Could not read response: \(err.localizedDescription)"
        case .networkError(let err): return "Network error: \(err.localizedDescription)"
        case .notARecipe: return "That doesn't look like a recipe."
        }
    }
}

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        return URLSession(configuration: config)
    }()

    private var baseURL: URL {
        let stored = UserDefaults(suiteName: AppGroup.identifier)?
            .string(forKey: UserDefaultsKey.backendURL) ?? "http://localhost:8000"
        return URL(string: stored)!
    }

    func parseRecipe(url: String? = nil, text: String? = nil, imageBase64: String? = nil) async throws -> RecipeDTO {
        var request = URLRequest(url: baseURL.appendingPathComponent("parse"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ParseRequestBody(url: url, text: text, imageBase64: imageBase64)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        if http.statusCode == 422 {
            if let body = try? JSONDecoder().decode([String: String].self, from: data),
               body["detail"] == "not_a_recipe" {
                throw APIError.notARecipe
            }
        }

        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(http.statusCode, message)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(RecipeDTO.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
