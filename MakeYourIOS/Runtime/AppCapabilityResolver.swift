import Foundation

enum AppCapabilityResolver {
    static func requiredCapabilities(for document: AppDocument) -> Set<AppCapability> {
        var capabilities = requiredCapabilities(for: document.pages)
        if document.resolvedTheme.backgroundAssetBinding?.isEmpty == false {
            capabilities.insert(.photoPicker)
        }
        return capabilities
    }

    static func requiredCapabilities(for pages: [AppPage]) -> Set<AppCapability> {
        let nodes = pages.flatMap(\.nodes)
        var capabilities: Set<AppCapability> = [.localStorage]
        let capabilitiesByKind: [ComponentKind: AppCapability] = [
            .currencyConverter: .safeCalculation,
            .taskList: .localNotifications,
            .aiAssistant: .aiRequests,
            .map: .mapSearch,
            .calendarEvent: .calendarWrite,
            .documentExport: .documentExport,
            .voiceNote: .microphoneRecordLocal,
            .speechTranscript: .speechTranscribeOnDevice,
            .liveDataList: .network,
            .newsFeed: .network,
            .marketWatch: .network
        ]
        capabilities.formUnion(nodes.compactMap { capabilitiesByKind[$0.kind] })

        if nodes.contains(where: {
            $0.action.type == .scheduleNotification
                || ($0.kind == .recordCollection && $0.collection?.allowsReminders == true)
        }) {
            capabilities.insert(.localNotifications)
        }
        if nodes.contains(where: {
            [.hero, .image].contains($0.kind) && $0.image?.allowsUserSelection == true
        }) {
            capabilities.insert(.photoPicker)
        }
        if nodes.contains(where: { $0.kind == .game && $0.game?.haptics == true }) {
            capabilities.insert(.haptics)
        }
        capabilities.formUnion(runtimeStepCapabilities(for: nodes))
        for node in nodes where node.kind == .deviceInput {
            if let kind = node.deviceInput?.kind {
                capabilities.insert(kind.requiredCapability)
            }
        }
        return capabilities
    }

    private static func runtimeStepCapabilities(for nodes: [ComponentNode]) -> Set<AppCapability> {
        let steps = nodes.flatMap { $0.events ?? [] }.flatMap(\.steps)
        let arithmeticOperations: Set<RuntimeExpressionOperation> = [
            .add, .subtract, .multiply, .divide, .min, .max,
            .listAppend, .listRemove, .listCount, .listContains, .listJoin,
            .objectSet, .objectRemove, .objectGet, .objectCount,
            .dateAddDays, .dateDaysBetween
        ]
        let numericComparisons: Set<RuntimeComparison> = [
            .less, .lessOrEqual, .greater, .greaterOrEqual
        ]
        var capabilities = Set<AppCapability>()
        if steps.contains(where: { $0.kind == .scheduleNotification }) {
            capabilities.insert(.localNotifications)
        }
        if steps.contains(where: { $0.kind == .playHaptic }) {
            capabilities.insert(.haptics)
        }
        if steps.contains(where: {
            arithmeticOperations.contains($0.expression.operation)
                || $0.condition.map { numericComparisons.contains($0.comparison) } == true
        }) {
            capabilities.insert(.safeCalculation)
        }
        return capabilities
    }
}
