import XCTest
@testable import MakeYourIOS

@MainActor
final class AISettingsStoreTests: XCTestCase {
    func testResponsesModelsAreLimitedToCuratedChoices() {
        XCTAssertEqual(
            OpenAIResponsesModel.allCases.map(\.rawValue),
            ["gpt-5.6", "gpt-5.6-sol", "gpt-5.6-terra", "gpt-5.6-luna"]
        )
    }

    func testUnknownStoredModelMigratesToLuna() throws {
        let suiteName = "AISettingsStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let keychain = KeychainStore(service: "AISettingsStoreTests.\(UUID().uuidString)")
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? keychain.delete(account: "openai.apiKey")
        }
        defaults.set("custom-model-name", forKey: "ai.openai.model")

        let settings = AISettingsStore(defaults: defaults, keychain: keychain)

        XCTAssertEqual(settings.selectedModel, .luna)
        XCTAssertEqual(settings.model, "gpt-5.6-luna")
        XCTAssertEqual(defaults.string(forKey: "ai.openai.model"), "gpt-5.6-luna")
    }

    func testSelectedModelPersistsAndIsUsedByRequests() throws {
        let suiteName = "AISettingsStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let keychain = KeychainStore(service: "AISettingsStoreTests.\(UUID().uuidString)")
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? keychain.delete(account: "openai.apiKey")
        }
        let settings = AISettingsStore(defaults: defaults, keychain: keychain)
        try settings.saveAPIKey("test-key")
        settings.disclosureAccepted = true

        settings.selectedModel = .terra

        XCTAssertEqual(defaults.string(forKey: "ai.openai.model"), "gpt-5.6-terra")
        XCTAssertEqual(try settings.connectionConfig().model, "gpt-5.6-terra")
    }

    func testRuntimeAIRequiresItsOwnVersionedDisclosure() throws {
        let suiteName = "AISettingsStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let keychain = KeychainStore(service: "AISettingsStoreTests.\(UUID().uuidString)")
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? keychain.delete(account: "openai.apiKey")
        }

        let settings = AISettingsStore(defaults: defaults, keychain: keychain)
        try settings.saveAPIKey("test-key")
        XCTAssertTrue(settings.canStartRuntimeAI)
        XCTAssertFalse(settings.runtimeDisclosureAccepted)

        XCTAssertThrowsError(try settings.runtimeConnectionConfig()) { error in
            XCTAssertEqual(error as? AIConfigurationError, .runtimeDisclosureRequired)
        }

        settings.acceptRuntimeDisclosure()
        let config = try settings.runtimeConnectionConfig()
        XCTAssertEqual(config.apiKey, "test-key")
        XCTAssertTrue(settings.runtimeDisclosureAccepted)
    }
}
