import XCTest
@testable import MakeYourIOS

@MainActor
final class RuntimeSessionStateTests: XCTestCase {
    private struct StoredFixture: Codable {
        var version: Int?
        var fingerprints: [String: String]?
        var values: [String: String]
    }

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

    func testLegacyStateMigratesOnlyWhenItMatchesTheDeclaredType() throws {
        let suiteName = "RuntimeSessionStateTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = ProjectRuntimeStateStore(defaults: defaults)
        let projectID = UUID()
        try store.save(
            StoredFixture(version: nil, fingerprints: nil, values: ["score": "25"]),
            projectID: projectID,
            nodeID: "$app",
            namespace: "automation-state-v1"
        )

        let reopened = RuntimeSessionState(
            initialValues: ["score": "0"],
            projectID: projectID,
            persistentKeys: ["score"],
            stateDefinitions: [RuntimeStateDefinition(
                key: "score",
                type: .number,
                persistence: .project,
                initialValue: "0"
            )],
            stateStore: store
        )

        XCTAssertEqual(reopened.binding(for: "score"), "25")
    }

    func testFingerprintMismatchResetsOnlyTheChangedKey() throws {
        let suiteName = "RuntimeSessionStateTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = ProjectRuntimeStateStore(defaults: defaults)
        let projectID = UUID()
        let numberDefinition = RuntimeStateDefinition(
            key: "shared",
            type: .number,
            persistence: .project,
            initialValue: "0"
        )
        let first = RuntimeSessionState(
            initialValues: ["shared": "0"],
            projectID: projectID,
            persistentKeys: ["shared"],
            stateDefinitions: [numberDefinition],
            stateStore: store
        )
        first.set("25", for: "shared")

        let reopened = RuntimeSessionState(
            initialValues: ["shared": "2026-07-19T00:00:00Z"],
            projectID: projectID,
            persistentKeys: ["shared"],
            stateDefinitions: [RuntimeStateDefinition(
                key: "shared",
                type: .date,
                persistence: .project,
                initialValue: "2026-07-19"
            )],
            stateStore: store
        )

        XCTAssertEqual(reopened.binding(for: "shared"), "2026-07-19T00:00:00Z")
    }

    func testTemplatesSummarizeStructuredValuesInsteadOfLeakingJSON() {
        let state = RuntimeSessionState(
            initialValues: [
                "items": #"["Milk","Eggs"]"#,
                "profile": #"{"name":"Mina"}"#
            ],
            stateDefinitions: [
                RuntimeStateDefinition(
                    key: "items",
                    type: .list,
                    persistence: .session,
                    initialValue: "[]"
                ),
                RuntimeStateDefinition(
                    key: "profile",
                    type: .object,
                    persistence: .session,
                    initialValue: "{}"
                )
            ]
        )

        XCTAssertEqual(state.resolveTemplate("{{items}} · {{profile}}"), "2 items · 1 field")
        XCTAssertEqual(state.resolveExportTemplate("{{items}}"), #"["Milk","Eggs"]"#)
        XCTAssertEqual(state.resolveExportTemplate("{{profile}}"), #"{"name":"Mina"}"#)
    }
}
