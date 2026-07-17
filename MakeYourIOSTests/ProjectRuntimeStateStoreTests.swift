import XCTest
@testable import MakeYourIOS

final class ProjectRuntimeStateStoreTests: XCTestCase {
    private struct Fixture: Codable, Equatable {
        var name: String
        var values: [Double]
    }

    func testStateIsScopedByProjectAndNode() throws {
        let suite = "ProjectRuntimeStateStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = ProjectRuntimeStateStore(defaults: defaults)
        let firstProject = UUID()
        let secondProject = UUID()
        let value = Fixture(name: "Rates", values: [1.0, 2.0])

        try store.save(value, projectID: firstProject, nodeID: "watch", namespace: "fixture")

        XCTAssertEqual(
            try store.load(
                Fixture.self,
                projectID: firstProject,
                nodeID: "watch",
                namespace: "fixture"
            ),
            value
        )
        XCTAssertNil(
            try store.load(
                Fixture.self,
                projectID: secondProject,
                nodeID: "watch",
                namespace: "fixture"
            )
        )
    }
}
