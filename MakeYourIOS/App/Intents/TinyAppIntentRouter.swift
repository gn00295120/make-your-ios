import Foundation
import Observation

@MainActor
@Observable
final class TinyAppIntentRouter {
    struct Request: Equatable, Identifiable, Sendable {
        let id: UUID
        let projectID: UUID

        init(id: UUID = UUID(), projectID: UUID) {
            self.id = id
            self.projectID = projectID
        }
    }

    static let shared = TinyAppIntentRouter()

    private(set) var pendingRequest: Request?

    func requestOpen(projectID: UUID) {
        pendingRequest = Request(projectID: projectID)
    }

    func consume(requestID: UUID) {
        guard pendingRequest?.id == requestID else { return }
        pendingRequest = nil
    }
}
