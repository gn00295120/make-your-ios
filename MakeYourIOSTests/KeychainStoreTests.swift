import XCTest
@testable import MakeYourIOS

final class KeychainStoreTests: XCTestCase {
    func testRoundTripAndDelete() throws {
        let service = "com.longweiwang.makeyourios.tests.\(UUID().uuidString)"
        let account = "test-api-key"
        let store = KeychainStore(service: service)

        defer { try? store.delete(account: account) }

        try store.save("not-a-real-secret", account: account)
        XCTAssertEqual(try store.read(account: account), "not-a-real-secret")

        try store.delete(account: account)
        XCTAssertNil(try store.read(account: account))
    }
}
