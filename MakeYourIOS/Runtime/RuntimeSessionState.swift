import Foundation
import Observation

@MainActor
@Observable
final class RuntimeSessionState {
    private struct LegacyPersistedState: Codable {
        var values: [String: String]
    }

    private struct PersistedState: Codable {
        var version: Int
        var fingerprints: [String: String]
        var values: [String: String]
    }

    private static let appStateNodeID = "$app"
    private static let appStateNamespace = "automation-state-v2"
    private static let legacyAppStateNamespace = "automation-state-v1"
    private static let maximumTemplateLength = 2_000
    private static let maximumTemplateReferences = 32
    private static let maximumStoredValues = 256
    private static let maximumStoredValueBytes = 8_192
    private static let maximumStateBytes = 131_072

    var values: [String: String]
    var checkedItemIDs: Set<String> = []
    var alertMessage: String?

    private let projectID: UUID?
    private let persistentKeys: Set<String>
    private let stateStore: ProjectRuntimeStateStore
    private let logicEngine: RuntimeLogicEngine
    private let stateFingerprints: [String: String]
    private let stateTypes: [String: RuntimeValueType]

    init(
        initialValues: [String: String],
        projectID: UUID? = nil,
        persistentKeys: Set<String> = [],
        stateDefinitions: [RuntimeStateDefinition] = [],
        stateStore: ProjectRuntimeStateStore = ProjectRuntimeStateStore()
    ) {
        self.projectID = projectID
        self.persistentKeys = persistentKeys
        self.stateStore = stateStore
        let logicEngine = RuntimeLogicEngine(logic: RuntimeLogic(state: stateDefinitions))
        self.logicEngine = logicEngine
        self.stateTypes = Dictionary(uniqueKeysWithValues: stateDefinitions.map { ($0.key, $0.type) })
        self.stateFingerprints = persistentKeys.reduce(into: [:]) { fingerprints, key in
            fingerprints[key] = logicEngine.stateFingerprints[key] ?? "runtime-value-v1:untyped"
        }
        self.values = initialValues

        var mergedValues = initialValues
        if let projectID, !persistentKeys.isEmpty {
            let persisted = try? stateStore.load(
                PersistedState.self,
                projectID: projectID,
                nodeID: Self.appStateNodeID,
                namespace: Self.appStateNamespace
            )
            if let persisted, persisted.version == 2 {
                merge(
                    persisted.values,
                    fingerprints: persisted.fingerprints,
                    into: &mergedValues
                )
            } else if let legacy = try? stateStore.load(
                LegacyPersistedState.self,
                projectID: projectID,
                nodeID: Self.appStateNodeID,
                namespace: Self.legacyAppStateNamespace
            ) {
                merge(legacy.values, fingerprints: nil, into: &mergedValues)
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
                      && $0.utf8.count <= Self.maximumStoredValueBytes
              }),
              proposedValues.reduce(0, { $0 + $1.key.utf8.count + $1.value.utf8.count })
                <= Self.maximumStateBytes else {
            throw RuntimeSessionStateError.stateLimitExceeded
        }
        if let projectID, !persistentKeys.isEmpty {
            let persisted = PersistedState(
                version: 2,
                fingerprints: stateFingerprints,
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
        resolveTemplate(
            template,
            maximumLength: maximumLength,
            exposesStructuredValues: false
        )
    }

    func resolveExportTemplate(_ template: String, maximumLength: Int = 2_000) -> String {
        resolveTemplate(
            template,
            maximumLength: maximumLength,
            exposesStructuredValues: true
        )
    }

    private func resolveTemplate(
        _ template: String,
        maximumLength: Int,
        exposesStructuredValues: Bool
    ) -> String {
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
            appendBounded(
                templateValue(for: key, exposesStructuredValues: exposesStructuredValues),
                to: &output,
                limit: outputLimit
            )
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

    private func merge(
        _ persistedValues: [String: String],
        fingerprints persistedFingerprints: [String: String]?,
        into mergedValues: inout [String: String]
    ) {
        for key in persistentKeys {
            guard let value = persistedValues[key],
                  value.count <= RuntimeLogicEngine.maximumValueLength,
                  value.utf8.count <= Self.maximumStoredValueBytes else { continue }
            if let persistedFingerprints,
               persistedFingerprints[key] != stateFingerprints[key] {
                continue
            }
            if stateTypes[key] != nil {
                guard let normalized = logicEngine.normalizedPersistedValue(value, for: key) else {
                    continue
                }
                mergedValues[key] = normalized
            } else {
                mergedValues[key] = value
            }
        }
    }

    private func templateValue(for key: String, exposesStructuredValues: Bool) -> String {
        guard let value = values[key] else { return "" }
        switch stateTypes[key] {
        case .list:
            if exposesStructuredValues { return value }
            let count = (try? RuntimeValueCodec.decodedList(value).count) ?? 0
            return count == 1 ? "1 item" : "\(count) items"
        case .object:
            if exposesStructuredValues { return value }
            let count = (try? RuntimeValueCodec.decodedObject(value).count) ?? 0
            return count == 1 ? "1 field" : "\(count) fields"
        case .date:
            return RuntimeValueCodec.date(from: value)?.formatted(
                date: .abbreviated,
                time: .shortened
            ) ?? ""
        default:
            return value
        }
    }
}

enum RuntimeSessionStateError: LocalizedError, Equatable {
    case stateLimitExceeded

    var errorDescription: String? {
        "This tiny app value exceeds the local state limit."
    }
}
