import Foundation
import Observation

@MainActor
@Observable
final class RuntimeSessionState {
    private struct PersistedState: Codable {
        var values: [String: String]
    }

    private static let appStateNodeID = "$app"
    private static let appStateNamespace = "automation-state-v1"
    private static let maximumTemplateLength = 2_000
    private static let maximumTemplateReferences = 32
    private static let maximumStoredValues = 256

    var values: [String: String]
    var checkedItemIDs: Set<String> = []
    var alertMessage: String?

    private let projectID: UUID?
    private let persistentKeys: Set<String>
    private let stateStore: ProjectRuntimeStateStore

    init(
        initialValues: [String: String],
        projectID: UUID? = nil,
        persistentKeys: Set<String> = [],
        stateStore: ProjectRuntimeStateStore = ProjectRuntimeStateStore()
    ) {
        self.projectID = projectID
        self.persistentKeys = persistentKeys
        self.stateStore = stateStore

        var mergedValues = initialValues
        if let projectID,
           !persistentKeys.isEmpty,
           let persisted = try? stateStore.load(
               PersistedState.self,
               projectID: projectID,
               nodeID: Self.appStateNodeID,
               namespace: Self.appStateNamespace
            ) {
            for key in persistentKeys {
                if let value = persisted.values[key],
                   value.count <= RuntimeLogicEngine.maximumValueLength {
                    mergedValues[key] = value
                }
            }
        }
        values = mergedValues
    }

    func binding(for key: String, fallback: String = "") -> String {
        values[key] ?? fallback
    }

    func set(_ value: String, for key: String) {
        guard !key.isEmpty else { return }
        var proposed = values
        proposed[key] = value
        do {
            try commit(proposed)
        } catch {
            alertMessage = "Changes could not be saved."
        }
    }

    func commit(_ proposedValues: [String: String]) throws {
        guard proposedValues.count <= Self.maximumStoredValues,
              proposedValues.values.allSatisfy({
                  $0.count <= RuntimeLogicEngine.maximumValueLength
              }) else {
            throw RuntimeSessionStateError.stateLimitExceeded
        }
        if let projectID, !persistentKeys.isEmpty {
            let persisted = PersistedState(
                values: proposedValues.filter { persistentKeys.contains($0.key) }
            )
            try stateStore.save(
                persisted,
                projectID: projectID,
                nodeID: Self.appStateNodeID,
                namespace: Self.appStateNamespace
            )
        }
        values = proposedValues
    }

    func resolveTemplate(_ template: String, maximumLength: Int = 2_000) -> String {
        let outputLimit = min(max(maximumLength, 0), Self.maximumTemplateLength)
        guard outputLimit > 0, !template.isEmpty else { return "" }

        var output = ""
        var remainder = template[...]
        var referenceCount = 0

        while referenceCount < Self.maximumTemplateReferences,
              let opening = remainder.range(of: "{{") {
            appendBounded(String(remainder[..<opening.lowerBound]), to: &output, limit: outputLimit)
            guard output.count < outputLimit else { return output }

            let afterOpening = remainder[opening.upperBound...]
            guard let closing = afterOpening.range(of: "}}") else {
                appendBounded(String(remainder[opening.lowerBound...]), to: &output, limit: outputLimit)
                return output
            }

            let key = afterOpening[..<closing.lowerBound]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            appendBounded(values[key] ?? "", to: &output, limit: outputLimit)
            remainder = afterOpening[closing.upperBound...]
            referenceCount += 1
        }

        appendBounded(String(remainder), to: &output, limit: outputLimit)
        return output
    }

    private func appendBounded(_ value: String, to output: inout String, limit: Int) {
        guard output.count < limit else { return }
        output.append(contentsOf: value.prefix(limit - output.count))
    }
}

enum RuntimeSessionStateError: LocalizedError, Equatable {
    case stateLimitExceeded

    var errorDescription: String? {
        "This tiny app value exceeds the local state limit."
    }
}
