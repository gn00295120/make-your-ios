import Foundation
import Observation

@MainActor
@Observable
final class RuntimeSessionState {
    var values: [String: String]
    var checkedItemIDs: Set<String> = []
    var alertMessage: String?

    init(initialValues: [String: String]) {
        values = initialValues
    }

    func binding(for key: String, fallback: String = "") -> String {
        values[key] ?? fallback
    }

    func set(_ value: String, for key: String) {
        guard !key.isEmpty else { return }
        values[key] = value
    }
}
