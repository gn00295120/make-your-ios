import Foundation

struct WorkspaceArchive: Codable, Sendable {
    var projects: [WorkspaceProject]
    var selectedProjectID: UUID?
}
