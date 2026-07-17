import Foundation

struct ProjectRuntimeStateStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load<Value: Decodable>(
        _ type: Value.Type,
        projectID: UUID,
        nodeID: String,
        namespace: String
    ) throws -> Value? {
        guard let data = defaults.data(forKey: key(
            projectID: projectID,
            nodeID: nodeID,
            namespace: namespace
        )) else {
            return nil
        }
        return try JSONDecoder().decode(type, from: data)
    }

    func save<Value: Encodable>(
        _ value: Value,
        projectID: UUID,
        nodeID: String,
        namespace: String
    ) throws {
        let data = try JSONEncoder().encode(value)
        defaults.set(
            data,
            forKey: key(projectID: projectID, nodeID: nodeID, namespace: namespace)
        )
    }

    private func key(projectID: UUID, nodeID: String, namespace: String) -> String {
        "runtime.\(namespace).\(projectID.uuidString).\(nodeID)"
    }
}
