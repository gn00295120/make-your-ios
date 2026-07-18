import Foundation
import UserNotifications

enum ProjectNotificationStore {
    static func removeAll(projectID: UUID, center: UNUserNotificationCenter = .current()) {
        center.getPendingNotificationRequests { requests in
            let identifiers = matchingIdentifiers(
                in: requests.map(\.identifier),
                projectID: projectID
            )
            center.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
        center.getDeliveredNotifications { notifications in
            let identifiers = matchingIdentifiers(
                in: notifications.map(\.request.identifier),
                projectID: projectID
            )
            center.removeDeliveredNotifications(withIdentifiers: identifiers)
        }
    }

    static func matchingIdentifiers(in identifiers: [String], projectID: UUID) -> [String] {
        let projectSegment = ".\(projectID.uuidString)."
        return identifiers.filter { $0.contains(projectSegment) }
    }
}
