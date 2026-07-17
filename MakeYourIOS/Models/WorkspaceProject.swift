import Foundation

struct WorkspaceProject: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var document: AppDocument
    var createdAt: Date
    var updatedAt: Date
    var lastPrompt: String

    init(
        id: UUID = UUID(),
        document: AppDocument,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        lastPrompt: String = ""
    ) {
        self.id = id
        self.document = document
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastPrompt = lastPrompt
    }
}
