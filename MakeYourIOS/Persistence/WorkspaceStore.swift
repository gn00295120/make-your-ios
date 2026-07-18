import Foundation
import Observation

@MainActor
@Observable
// swiftlint:disable:next type_body_length
final class WorkspaceStore {
    static let designCanvasBackgroundBinding = "design-canvas-background"

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
    private let runtimeStateStore: ProjectRuntimeStateStore

    init(
        fileURL: URL? = nil,
        seedSamples: Bool = true,
        assetStore: LocalAssetStore? = nil,
        runtimeStateStore: ProjectRuntimeStateStore = ProjectRuntimeStateStore()
    ) {
        self.fileURL = fileURL ?? Self.defaultFileURL
        self.assetStore = assetStore ?? LocalAssetStore()
        self.runtimeStateStore = runtimeStateStore

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
        var theme = AppVisualTheme.preset(preset)
        theme.backgroundAssetBinding = projects[index].document.theme?.backgroundAssetBinding
        projects[index].document.theme = theme
        reconcilePhotoPickerCapability(in: &projects[index].document)
        projects[index].document.version += 1
        projects[index].document.updatedAt = .now
        projects[index].updatedAt = .now
        persist()
    }

    // swiftlint:disable:next function_parameter_count
    func applyDesign(
        _ theme: AppVisualTheme,
        tint: AppTint,
        symbol: String,
        pagePresentation: PagePresentation,
        canvasBackgroundImageData: Data?,
        removesCanvasBackground: Bool,
        to projectID: UUID
    ) throws {
        guard let index = projects.firstIndex(where: { $0.id == projectID }) else { return }

        let previousBackgroundBinding = projects[index].document.theme?.backgroundAssetBinding
        var nextDocument = projects[index].document
        var nextTheme = theme
        if canvasBackgroundImageData != nil {
            nextTheme.backgroundAssetBinding = Self.designCanvasBackgroundBinding
        } else if removesCanvasBackground {
            nextTheme.backgroundAssetBinding = nil
        }
        nextDocument.theme = nextTheme
        nextDocument.tint = tint
        if GeneratedAppPayload.allowedSymbols.contains(symbol) {
            nextDocument.symbol = symbol
        }
        for pageIndex in nextDocument.pages.indices {
            nextDocument.pages[pageIndex].presentation = pagePresentation
        }
        reconcilePhotoPickerCapability(in: &nextDocument)
        try AppDocumentValidator().validate(nextDocument)

        if let canvasBackgroundImageData {
            try assetStore.saveImageData(
                canvasBackgroundImageData,
                projectID: projectID,
                binding: Self.designCanvasBackgroundBinding
            )
            if let previousBackgroundBinding,
               previousBackgroundBinding != Self.designCanvasBackgroundBinding {
                try assetStore.deleteImage(
                    projectID: projectID,
                    binding: previousBackgroundBinding
                )
            }
        } else if removesCanvasBackground {
            if let previousBackgroundBinding {
                try assetStore.deleteImage(
                    projectID: projectID,
                    binding: previousBackgroundBinding
                )
            }
        }

        nextDocument.version += 1
        nextDocument.updatedAt = .now
        projects[index].document = nextDocument
        projects[index].updatedAt = .now
        selectedProjectID = projectID
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
        runtimeStateStore.delete(projectID: projectID)
        ProjectNotificationStore.removeAll(projectID: projectID)
        projects.removeAll(where: { $0.id == projectID })
        if selectedProjectID == projectID {
            selectedProjectID = projects.first?.id
        }
        persist()
    }

    func resetSamples() {
        for project in projects {
            try? assetStore.deleteAssets(projectID: project.id)
            runtimeStateStore.delete(projectID: project.id)
            ProjectNotificationStore.removeAll(projectID: project.id)
        }
        projects = [
            WorkspaceProject(document: SampleDocuments.dailyBrief),
            WorkspaceProject(document: SampleDocuments.marketPocket),
            WorkspaceProject(document: SampleDocuments.pocketLedger),
            WorkspaceProject(document: SampleDocuments.skybound),
            WorkspaceProject(document: SampleDocuments.neonSnake),
            WorkspaceProject(document: SampleDocuments.captureKit),
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

    private func reconcilePhotoPickerCapability(in document: inout AppDocument) {
        let hasSelectableImage = document.pages
            .flatMap(\.nodes)
            .contains(where: {
                [.hero, .image].contains($0.kind) && $0.image?.allowsUserSelection == true
            })
        let hasDesignBackground = document.theme?.backgroundAssetBinding != nil
        let needsPhotoPicker = hasSelectableImage || hasDesignBackground

        document.capabilities.removeAll(where: { $0 == .photoPicker })
        if needsPhotoPicker {
            document.capabilities.append(.photoPicker)
        }
    }

    private static var defaultFileURL: URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return root.appendingPathComponent("MakeYour", isDirectory: true)
            .appendingPathComponent("projects.json")
    }

    private static let sampleDocuments = [
        SampleDocuments.dailyBrief,
        SampleDocuments.marketPocket,
        SampleDocuments.pocketLedger,
        SampleDocuments.skybound,
        SampleDocuments.neonSnake,
        SampleDocuments.captureKit,
        SampleDocuments.liveFXWatch,
        SampleDocuments.useItFirst,
        SampleDocuments.quickConvert,
        SampleDocuments.gentleTasks
    ]
}
