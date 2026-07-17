import Foundation
import Observation

struct AIConnectionConfig: Sendable {
    let apiKey: String
    let model: String
    let safetyIdentifier: String
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

    var model: String {
        didSet { defaults.set(model, forKey: Keys.model) }
    }

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
        model = defaults.string(forKey: Keys.model) ?? "gpt-5.6-luna"
        disclosureAccepted = defaults.bool(forKey: Keys.disclosureAccepted)
        runtimeDisclosureVersion = defaults.integer(forKey: Keys.runtimeDisclosureVersion)

        if let existing = defaults.string(forKey: Keys.safetyIdentifier) {
            safetyIdentifier = existing
        } else {
            let newIdentifier = "makeyour_\(UUID().uuidString.lowercased())"
            defaults.set(newIdentifier, forKey: Keys.safetyIdentifier)
            safetyIdentifier = newIdentifier
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
        hasAPIKey && disclosureAccepted && !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canStartRuntimeAI: Bool {
        hasAPIKey && !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        guard !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIConfigurationError.missingModel
        }
        return AIConnectionConfig(
            apiKey: apiKey,
            model: model.trimmingCharacters(in: .whitespacesAndNewlines),
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
        guard !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIConfigurationError.missingModel
        }
        return AIConnectionConfig(
            apiKey: apiKey,
            model: model.trimmingCharacters(in: .whitespacesAndNewlines),
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
