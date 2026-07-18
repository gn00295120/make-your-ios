import XCTest
@testable import MakeYourIOS

@MainActor
final class RuntimeSessionStateTests: XCTestCase {
    func testProjectStateMergesOverInitialValuesAndSessionStateResets() throws {
        let suiteName = "RuntimeSessionStateTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = ProjectRuntimeStateStore(defaults: defaults)
        let projectID = UUID()

        let first = RuntimeSessionState(
            initialValues: ["score": "0", "draft": "initial"],
            projectID: projectID,
            persistentKeys: ["score"],
            stateStore: store
        )
        first.set("25", for: "score")
        first.set("edited", for: "draft")

        let reopened = RuntimeSessionState(
            initialValues: ["score": "0", "draft": "initial"],
            projectID: projectID,
            persistentKeys: ["score"],
            stateStore: store
        )

        XCTAssertEqual(reopened.binding(for: "score"), "25")
        XCTAssertEqual(reopened.binding(for: "draft"), "initial")
    }

    func testProjectStateRemainsIsolatedByProject() throws {
        let suiteName = "RuntimeSessionStateTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = ProjectRuntimeStateStore(defaults: defaults)
        let firstProjectID = UUID()

        let first = RuntimeSessionState(
            initialValues: ["score": "0"],
            projectID: firstProjectID,
            persistentKeys: ["score"],
            stateStore: store
        )
        first.set("50", for: "score")

        let second = RuntimeSessionState(
            initialValues: ["score": "0"],
            projectID: UUID(),
            persistentKeys: ["score"],
            stateStore: store
        )

        XCTAssertEqual(second.binding(for: "score"), "0")
    }

    func testTemplateResolutionIsSinglePassAndBounded() {
        let state = RuntimeSessionState(initialValues: [
            "name": "Mina",
            "nested": "{{name}}"
        ])

        XCTAssertEqual(
            state.resolveTemplate("Hello {{ name }} · {{missing}}"),
            "Hello Mina · "
        )
        XCTAssertEqual(state.resolveTemplate("{{nested}}"), "{{name}}")
        XCTAssertEqual(state.resolveTemplate("abcdef", maximumLength: 4), "abcd")
    }

    func testOversizedCommitRollsBackState() {
        let state = RuntimeSessionState(initialValues: ["note": "kept"])

        XCTAssertThrowsError(try state.commit([
            "note": String(repeating: "a", count: RuntimeLogicEngine.maximumValueLength + 1)
        ])) { error in
            XCTAssertEqual(error as? RuntimeSessionStateError, .stateLimitExceeded)
        }
        XCTAssertEqual(state.binding(for: "note"), "kept")
    }
}
