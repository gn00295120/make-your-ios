import Foundation
import Observation

@MainActor
@Observable
final class WorkspaceStore {
    private enum LoadResult {
        case missing
        case loaded
        case failed
    }

    private struct Archive: Codable {
        var projects: [WorkspaceProject]
        var selectedProjectID: UUID?
    }

    private(set) var projects: [WorkspaceProject] = []
    private(set) var selectedProjectID: UUID?
    private(set) var lastPersistenceError: String?

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let assetStore: LocalAssetStore

    init(
        fileURL: URL? = nil,
        seedSamples: Bool = true,
        assetStore: LocalAssetStore? = nil
    ) {
        self.fileURL = fileURL ?? Self.defaultFileURL
        self.assetStore = assetStore ?? LocalAssetStore()

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        switch load() {
        case .missing where seedSamples:
            let samples = Self.sampleDocuments
            projects = samples.map { WorkspaceProject(document: $0) }
            selectedProjectID = projects.first?.id
            persist()
        case .missing, .loaded, .failed:
            break
        }
    }

    var selectedProject: WorkspaceProject? {
        guard let selectedProjectID else { return projects.first }
        return projects.first(where: { $0.id == selectedProjectID }) ?? projects.first
    }

    @discardableResult
    func createProject(document: AppDocument = SampleDocuments.blank, prompt: String = "") -> UUID {
        let project = WorkspaceProject(document: document, lastPrompt: prompt)
        projects.insert(project, at: 0)
        selectedProjectID = project.id
        persist()
        return project.id
    }

    func select(_ projectID: UUID) {
        guard projects.contains(where: { $0.id == projectID }) else { return }
        selectedProjectID = projectID
        persist()
    }

    func replaceDocument(projectID: UUID, with document: AppDocument, prompt: String) throws {
        try AppDocumentValidator().validate(document)
        guard let index = projects.firstIndex(where: { $0.id == projectID }) else { return }

        var nextDocument = document
        nextDocument.id = projects[index].document.id
        nextDocument.version = projects[index].document.version + 1
        nextDocument.updatedAt = .now

        projects[index].document = nextDocument
        projects[index].lastPrompt = prompt
        projects[index].updatedAt = .now
        selectedProjectID = projectID
        persist()
    }

    func applyTheme(_ preset: VisualThemePreset, to projectID: UUID) {
        guard let index = projects.firstIndex(where: { $0.id == projectID }) else { return }
        projects[index].document.theme = .preset(preset)
        projects[index].document.version += 1
        projects[index].document.updatedAt = .now
        projects[index].updatedAt = .now
        persist()
    }

    func addImageBlock(to projectID: UUID) {
        guard let index = projects.firstIndex(where: { $0.id == projectID }),
              !projects[index].document.pages.isEmpty else { return }

        let binding = "primary-photo"
        let imageNode = ComponentNode(
            id: "image-\(UUID().uuidString.lowercased())",
            kind: .image,
            title: "Your image",
            subtitle: "Choose a photo to make this app yours.",
            symbol: "photo.fill",
            binding: binding,
            presentation: ComponentPresentation(
                surface: .plain,
                span: .full,
                alignment: .center,
                emphasis: .strong,
                variant: .photoOverlay
            ),
            image: .editableLandscape
        )

        if let existingIndex = projects[index].document.pages[0].nodes.firstIndex(
            where: { $0.kind == .image && $0.binding == binding }
        ) {
            projects[index].document.pages[0].nodes[existingIndex] = imageNode
        } else {
            projects[index].document.pages[0].nodes.insert(imageNode, at: 0)
        }

        if !projects[index].document.capabilities.contains(.photoPicker) {
            projects[index].document.capabilities.append(.photoPicker)
        }
        projects[index].document.version += 1
        projects[index].document.updatedAt = .now
        projects[index].updatedAt = .now
        persist()
    }

    @discardableResult
    func duplicate(_ projectID: UUID) -> UUID? {
        guard let source = projects.first(where: { $0.id == projectID }) else { return nil }
        var document = source.document
        document.id = UUID()
        document.name += " Copy"
        document.version = 1
        document.updatedAt = .now
        let duplicateID = createProject(document: document, prompt: source.lastPrompt)
        do {
            try assetStore.duplicateAssets(from: source.id, to: duplicateID)
        } catch {
            lastPersistenceError = error.localizedDescription
        }
        return duplicateID
    }

    func delete(_ projectID: UUID) {
        do {
            try assetStore.deleteAssets(projectID: projectID)
        } catch {
            lastPersistenceError = error.localizedDescription
            return
        }
        projects.removeAll(where: { $0.id == projectID })
        if selectedProjectID == projectID {
            selectedProjectID = projects.first?.id
        }
        persist()
    }

    func resetSamples() {
        for project in projects {
            try? assetStore.deleteAssets(projectID: project.id)
        }
        projects = [
            WorkspaceProject(document: SampleDocuments.liveFXWatch),
            WorkspaceProject(document: SampleDocuments.useItFirst),
            WorkspaceProject(document: SampleDocuments.quickConvert),
            WorkspaceProject(document: SampleDocuments.gentleTasks)
        ]
        selectedProjectID = projects.first?.id
        persist()
    }

    private func load() -> LoadResult {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return .missing }

        do {
            let data = try Data(contentsOf: fileURL)
            let archive = try decoder.decode(Archive.self, from: data)
            projects = archive.projects
            selectedProjectID = archive.selectedProjectID
            lastPersistenceError = nil
            return .loaded
        } catch {
            lastPersistenceError = error.localizedDescription
            return .failed
        }
    }

    private func persist() {
        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try encoder.encode(Archive(projects: projects, selectedProjectID: selectedProjectID))
            try data.write(to: fileURL, options: .atomic)
            lastPersistenceError = nil
        } catch {
            lastPersistenceError = error.localizedDescription
        }
    }

    private static var defaultFileURL: URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return root.appendingPathComponent("MakeYour", isDirectory: true)
            .appendingPathComponent("projects.json")
    }

    private static let sampleDocuments = [
        SampleDocuments.liveFXWatch,
        SampleDocuments.useItFirst,
        SampleDocuments.quickConvert,
        SampleDocuments.gentleTasks
    ]
}
