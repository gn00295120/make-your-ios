import XCTest
@testable import MakeYourIOS

@MainActor
final class AISettingsStoreTests: XCTestCase {
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
