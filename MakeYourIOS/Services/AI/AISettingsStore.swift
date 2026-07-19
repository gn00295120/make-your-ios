import Foundation
import Observation

struct AIConnectionConfig: Sendable {
    let apiKey: String
    let model: String
    let safetyIdentifier: String
}

enum OpenAIResponsesModel: String, CaseIterable, Identifiable, Sendable {
    case gpt56 = "gpt-5.6"
    case sol = "gpt-5.6-sol"
    case terra = "gpt-5.6-terra"
    case luna = "gpt-5.6-luna"

    static let defaultSelection: Self = .luna

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gpt56: "GPT-5.6 (Recommended)"
        case .sol: "GPT-5.6 Sol"
        case .terra: "GPT-5.6 Terra"
        case .luna: "GPT-5.6 Luna"
        }
    }

    var detail: String {
        switch self {
        case .gpt56: "Flagship alias for the latest GPT-5.6 Sol model."
        case .sol: "Pinned flagship model for the highest capability."
        case .terra: "Strong capability with balanced cost and latency."
        case .luna: "Efficient model for frequent app generation."
        }
    }
}

@MainActor
@Observable
final class AISettingsStore {
    static let currentRuntimeDisclosureVersion = 1

    private enum Keys {
        static let model = "ai.openai.model"
        static let disclosureAccepted = "ai.openai.disclosureAccepted"
        static let runtimeDisclosureVersion = "ai.openai.runtimeDisclosureVersion"
        static let safetyIdentifier = "ai.openai.safetyIdentifier"
        static let keychainAccount = "openai.apiKey"
    }

    var selectedModel: OpenAIResponsesModel {
        didSet { defaults.set(selectedModel.rawValue, forKey: Keys.model) }
    }

    var model: String { selectedModel.rawValue }

    var disclosureAccepted: Bool {
        didSet { defaults.set(disclosureAccepted, forKey: Keys.disclosureAccepted) }
    }

    private(set) var apiKey = ""
    private(set) var keyStatusMessage: String?
    private(set) var runtimeDisclosureVersion: Int

    private let defaults: UserDefaults
    private let keychain: KeychainStore
    private let safetyIdentifier: String

    init(
        defaults: UserDefaults = .standard,
        keychain: KeychainStore = KeychainStore(service: "com.longweiwang.makeyourios")
    ) {
        self.defaults = defaults
        self.keychain = keychain
        let storedModel = defaults.string(forKey: Keys.model)
        selectedModel = storedModel
            .flatMap(OpenAIResponsesModel.init(rawValue:)) ?? .defaultSelection
        disclosureAccepted = defaults.bool(forKey: Keys.disclosureAccepted)
        runtimeDisclosureVersion = defaults.integer(forKey: Keys.runtimeDisclosureVersion)

        if let existing = defaults.string(forKey: Keys.safetyIdentifier) {
            safetyIdentifier = existing
        } else {
            let newIdentifier = "makeyour_\(UUID().uuidString.lowercased())"
            defaults.set(newIdentifier, forKey: Keys.safetyIdentifier)
            safetyIdentifier = newIdentifier
        }

        if storedModel != selectedModel.rawValue {
            defaults.set(selectedModel.rawValue, forKey: Keys.model)
        }

        do {
            apiKey = try keychain.read(account: Keys.keychainAccount) ?? ""
        } catch {
            keyStatusMessage = error.localizedDescription
        }
    }

    var hasAPIKey: Bool {
        !apiKey.isEmpty
    }

    var isReady: Bool {
        hasAPIKey && disclosureAccepted
    }

    var canStartRuntimeAI: Bool {
        hasAPIKey
    }

    var runtimeDisclosureAccepted: Bool {
        runtimeDisclosureVersion >= Self.currentRuntimeDisclosureVersion
    }

    func saveAPIKey(_ newValue: String) throws {
        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            try removeAPIKey()
            return
        }
        try keychain.save(trimmed, account: Keys.keychainAccount)
        apiKey = trimmed
        keyStatusMessage = "Saved securely on this device."
    }

    func removeAPIKey() throws {
        try keychain.delete(account: Keys.keychainAccount)
        apiKey = ""
        keyStatusMessage = "API key removed."
    }

    func connectionConfig() throws -> AIConnectionConfig {
        guard hasAPIKey else { throw AIConfigurationError.missingKey }
        guard disclosureAccepted else { throw AIConfigurationError.disclosureRequired }
        return AIConnectionConfig(
            apiKey: apiKey,
            model: selectedModel.rawValue,
            safetyIdentifier: safetyIdentifier
        )
    }

    func acceptRuntimeDisclosure() {
        runtimeDisclosureVersion = Self.currentRuntimeDisclosureVersion
        defaults.set(runtimeDisclosureVersion, forKey: Keys.runtimeDisclosureVersion)
    }

    func runtimeConnectionConfig() throws -> AIConnectionConfig {
        guard hasAPIKey else { throw AIConfigurationError.missingKey }
        guard runtimeDisclosureAccepted else { throw AIConfigurationError.runtimeDisclosureRequired }
        return AIConnectionConfig(
            apiKey: apiKey,
            model: selectedModel.rawValue,
            safetyIdentifier: safetyIdentifier
        )
    }
}

enum AIConfigurationError: LocalizedError, Equatable {
    case missingKey
    case disclosureRequired
    case runtimeDisclosureRequired
    case missingModel

    var errorDescription: String? {
        switch self {
        case .missingKey: "Add an OpenAI API key in AI Key first."
        case .disclosureRequired: "Review and accept the AI data disclosure first."
        case .runtimeDisclosureRequired: "Review the in-app AI disclosure before sending text."
        case .missingModel: "Choose an OpenAI model."
        }
    }
}
