import Foundation

enum AppCapabilityResolver {
    static func requiredCapabilities(for pages: [AppPage]) -> Set<AppCapability> {
        let nodes = pages.flatMap(\.nodes)
        var capabilities: Set<AppCapability> = [.localStorage]

        if nodes.contains(where: { $0.kind == .currencyConverter }) {
            capabilities.insert(.safeCalculation)
        }
        if nodes.contains(where: {
            $0.kind == .taskList
                || $0.action.type == .scheduleNotification
                || ($0.kind == .recordCollection && $0.collection?.allowsReminders == true)
        }) {
            capabilities.insert(.localNotifications)
        }
        if nodes.contains(where: { $0.kind == .image && $0.image?.allowsUserSelection == true }) {
            capabilities.insert(.photoPicker)
        }
        if nodes.contains(where: { $0.kind == .aiAssistant }) {
            capabilities.insert(.aiRequests)
        }
        if nodes.contains(where: { $0.kind == .game && $0.game?.haptics == true }) {
            capabilities.insert(.haptics)
        }
        if nodes.contains(where: {
            $0.kind == .liveDataList || $0.kind == .newsFeed || $0.kind == .marketWatch
        }) {
            capabilities.insert(.network)
        }
        for node in nodes where node.kind == .deviceInput {
            if let kind = node.deviceInput?.kind {
                capabilities.insert(kind.requiredCapability)
            }
        }
        return capabilities
    }
}
