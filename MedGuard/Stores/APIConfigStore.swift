import Foundation

/// Persisted API configuration for Doubao / third-party AI models.
/// Stored in UserDefaults so users can plug in their own endpoints / keys.
struct APIConfig: Codable, Equatable {
    var apiKey: String
    var textModel: String
    var visionModel: String
    var baseURL: String

    static let `default` = APIConfig(
        apiKey: "ark-0755e5d2-1471-4926-a6a4-2b1ef5d57452-861e1",
        textModel: "ark-0755e5d2-1471-4926-a6a4-2b1ef5d57452-861e1",
        visionModel: "ep-20260616152526-z5v6t",
        baseURL: "https://ark.cn-beijing.volces.com/api/v3/chat/completions"
    )
}

final class APIConfigStore: ObservableObject {
    static let shared = APIConfigStore()

    @Published var config: APIConfig

    private let key = "medguard_api_config"

    /// Thread-safe access to the current config from any context.
    static var currentConfig: APIConfig {
        if let data = UserDefaults.standard.data(forKey: "medguard_api_config"),
           let saved = try? JSONDecoder().decode(APIConfig.self, from: data) {
            return saved
        }
        return .default
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode(APIConfig.self, from: data) {
            config = saved
        } else {
            config = .default
        }
    }

    @MainActor
    func save(_ newConfig: APIConfig) {
        config = newConfig
        if let data = try? JSONEncoder().encode(newConfig) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    @MainActor
    func resetToDefault() {
        save(.default)
    }

    /// Whether the user has a custom (non-default) configuration
    var isCustom: Bool {
        config != .default
    }
}
