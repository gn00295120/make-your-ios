import UIKit
import XCTest
@testable import MakeYourIOS

@MainActor
// swiftlint:disable:next type_body_length
final class WorkspaceStoreTests: XCTestCase {
    func testFreshWorkspaceSeedsReviewableCapabilityExamples() {
        let (testDirectory, archiveURL) = makeArchiveURL()
        defer { try? FileManager.default.removeItem(at: testDirectory) }

        let store = WorkspaceStore(fileURL: archiveURL, seedSamples: true)

        XCTAssertEqual(store.projects.map(\.document.name), [
            "Daily Brief",
            "Market Pocket",
            "Pocket Ledger",
            "Skybound",
            "Neon Snake",
            "Device Lab",
            "Live FX Watch",
            "Use It First",
            "Quick Convert",
            "Gentle Tasks"
        ])
    }

    func testCreatePersistsAndReloadsProject() {
        let (testDirectory, archiveURL) = makeArchiveURL()
        defer { try? FileManager.default.removeItem(at: testDirectory) }
        let store = WorkspaceStore(fileURL: archiveURL, seedSamples: false)
        let id = store.createProject(document: SampleDocuments.quickConvert, prompt: "converter")

        let reloaded = WorkspaceStore(fileURL: archiveURL, seedSamples: false)
        XCTAssertEqual(reloaded.projects.count, 1)
        XCTAssertEqual(reloaded.selectedProjectID, id)
        XCTAssertEqual(reloaded.selectedProject?.document.name, "Quick Convert")
        XCTAssertEqual(reloaded.selectedProject?.lastPrompt, "converter")
    }

    func testReplacementIncrementsVersion() throws {
        let (testDirectory, archiveURL) = makeArchiveURL()
        defer { try? FileManager.default.removeItem(at: testDirectory) }
        let store = WorkspaceStore(fileURL: archiveURL, seedSamples: false)
        let id = store.createProject(document: SampleDocuments.blank)

        try store.replaceDocument(
            projectID: id,
            with: SampleDocuments.gentleTasks,
            prompt: "make a task list"
        )

        XCTAssertEqual(store.selectedProject?.document.version, 2)
        XCTAssertEqual(store.selectedProject?.document.name, "Gentle Tasks")
    }

    func testInvalidArchiveIsNotOverwrittenWhenSampleSeedingIsEnabled() throws {
        let (testDirectory, archiveURL) = makeArchiveURL()
        defer { try? FileManager.default.removeItem(at: testDirectory) }
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        let invalidArchive = Data("not a valid workspace archive".utf8)
        try invalidArchive.write(to: archiveURL)

        let store = WorkspaceStore(fileURL: archiveURL, seedSamples: true)

        XCTAssertTrue(store.projects.isEmpty)
        XCTAssertNil(store.selectedProjectID)
        XCTAssertNotNil(store.lastPersistenceError)
        XCTAssertEqual(try Data(contentsOf: archiveURL), invalidArchive)
    }

    func testDuplicateAndDeleteKeepAssetLifecycleInSync() throws {
        let (testDirectory, archiveURL) = makeArchiveURL()
        defer { try? FileManager.default.removeItem(at: testDirectory) }
        let assetStore = LocalAssetStore(
            rootURL: testDirectory.appendingPathComponent("assets", isDirectory: true)
        )
        let store = WorkspaceStore(
            fileURL: archiveURL,
            seedSamples: false,
            assetStore: assetStore
        )
        let sourceID = store.createProject(document: SampleDocuments.museJournal)
        try assetStore.saveImageData(
            try makeImageData(),
            projectID: sourceID,
            binding: "journal-photo"
        )

        let duplicateID = try XCTUnwrap(store.duplicate(sourceID))
        store.delete(sourceID)

        XCTAssertFalse(assetStore.hasImage(projectID: sourceID, binding: "journal-photo"))
        XCTAssertTrue(assetStore.hasImage(projectID: duplicateID, binding: "journal-photo"))
        XCTAssertEqual(store.projects.count, 1)
        XCTAssertEqual(store.projects[0].id, duplicateID)
    }

    func testDeleteRemovesOnlyThatProjectsRuntimeState() throws {
        let (testDirectory, archiveURL) = makeArchiveURL()
        defer { try? FileManager.default.removeItem(at: testDirectory) }
        let suiteName = "WorkspaceStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let runtimeStateStore = ProjectRuntimeStateStore(defaults: defaults)
        let store = WorkspaceStore(
            fileURL: archiveURL,
            seedSamples: false,
            runtimeStateStore: runtimeStateStore
        )
        let deletedID = store.createProject(document: SampleDocuments.gentleTasks)
        let retainedID = store.createProject(document: SampleDocuments.gentleTasks)
        try runtimeStateStore.save(
            ["deleted"],
            projectID: deletedID,
            nodeID: "tasks",
            namespace: "tasks"
        )
        try runtimeStateStore.save(
            ["retained"],
            projectID: retainedID,
            nodeID: "tasks",
            namespace: "tasks"
        )

        store.delete(deletedID)

        let deleted: [String]? = try runtimeStateStore.load(
            [String].self,
            projectID: deletedID,
            nodeID: "tasks",
            namespace: "tasks"
        )
        let retained: [String]? = try runtimeStateStore.load(
            [String].self,
            projectID: retainedID,
            nodeID: "tasks",
            namespace: "tasks"
        )
        XCTAssertNil(deleted)
        XCTAssertEqual(retained, ["retained"])
    }

    func testNotificationCleanupSelectsOnlyDeletedProjectIdentifiers() {
        let projectID = UUID()
        let anotherProjectID = UUID()
        let expected = [
            "makeyour.\(projectID.uuidString).task",
            "makeyour.action.\(projectID.uuidString).button"
        ]

        let matching = ProjectNotificationStore.matchingIdentifiers(
            in: expected + [
                "makeyour.\(anotherProjectID.uuidString).task",
                "unrelated"
            ],
            projectID: projectID
        )

        XCTAssertEqual(matching, expected)
    }

    func testDesignControlsApplyThemeAndAddPrivateImageSlot() {
        let (testDirectory, archiveURL) = makeArchiveURL()
        defer { try? FileManager.default.removeItem(at: testDirectory) }
        let store = WorkspaceStore(fileURL: archiveURL, seedSamples: false)
        let projectID = store.createProject(document: SampleDocuments.blank)

        store.applyTheme(.bold, to: projectID)
        store.addImageBlock(to: projectID)

        XCTAssertEqual(store.selectedProject?.document.resolvedTheme.preset, .bold)
        XCTAssertEqual(store.selectedProject?.document.version, 3)
        XCTAssertTrue(store.selectedProject?.document.capabilities.contains(.photoPicker) == true)
        XCTAssertEqual(store.selectedProject?.document.pages[0].nodes.first?.kind, .image)
        XCTAssertEqual(store.selectedProject?.document.pages[0].nodes.first?.binding, "primary-photo")
    }

    func testDesignStudioAppliesAllTokensAsOneVersion() throws {
        let (testDirectory, archiveURL) = makeArchiveURL()
        defer { try? FileManager.default.removeItem(at: testDirectory) }
        let store = WorkspaceStore(fileURL: archiveURL, seedSamples: false)
        let projectID = store.createProject(document: SampleDocuments.gentleTasks)
        var theme = AppVisualTheme.preset(.editorial)
        theme.motion = ThemeMotion.none
        let presentation = PagePresentation(
            layout: .story,
            showsNavigationTitle: false,
            navigationStyle: .chips
        )

        try store.applyDesign(
            theme,
            tint: .amber,
            symbol: "book.fill",
            pagePresentation: presentation,
            canvasBackgroundImageData: nil,
            removesCanvasBackground: false,
            to: projectID
        )

        let document = try XCTUnwrap(store.selectedProject?.document)
        XCTAssertEqual(document.version, 2)
        XCTAssertEqual(document.symbol, "book.fill")
        XCTAssertEqual(document.tint, .amber)
        XCTAssertEqual(document.resolvedTheme.preset, .editorial)
        XCTAssertTrue(document.pages.allSatisfy { $0.presentation == presentation })
    }

    func testCanvasBackgroundAddsAndRemovesOnlyRequiredPhotoCapability() throws {
        let (testDirectory, archiveURL) = makeArchiveURL()
        defer { try? FileManager.default.removeItem(at: testDirectory) }
        let assetStore = LocalAssetStore(
            rootURL: testDirectory.appendingPathComponent("assets", isDirectory: true)
        )
        let store = WorkspaceStore(
            fileURL: archiveURL,
            seedSamples: false,
            assetStore: assetStore
        )
        let projectID = store.createProject(document: SampleDocuments.blank)

        try store.applyDesign(
            .preset(.soft),
            tint: .indigo,
            symbol: "sparkles",
            pagePresentation: .flow,
            canvasBackgroundImageData: try makeImageData(),
            removesCanvasBackground: false,
            to: projectID
        )

        XCTAssertEqual(
            store.selectedProject?.document.theme?.backgroundAssetBinding,
            WorkspaceStore.designCanvasBackgroundBinding
        )
        XCTAssertTrue(store.selectedProject?.document.capabilities.contains(.photoPicker) == true)
        XCTAssertTrue(assetStore.hasImage(
            projectID: projectID,
            binding: WorkspaceStore.designCanvasBackgroundBinding
        ))

        try store.applyDesign(
            store.selectedProject?.document.resolvedTheme ?? .legacy,
            tint: .indigo,
            symbol: "sparkles",
            pagePresentation: .flow,
            canvasBackgroundImageData: nil,
            removesCanvasBackground: true,
            to: projectID
        )

        XCTAssertNil(store.selectedProject?.document.theme?.backgroundAssetBinding)
        XCTAssertTrue(store.selectedProject?.document.capabilities.contains(.photoPicker) == false)
        XCTAssertFalse(assetStore.hasImage(
            projectID: projectID,
            binding: WorkspaceStore.designCanvasBackgroundBinding
        ))
        XCTAssertEqual(store.selectedProject?.document.version, 3)
    }

    func testClearingCanvasBackgroundKeepsPhotoCapabilityForImageNode() throws {
        let (testDirectory, archiveURL) = makeArchiveURL()
        defer { try? FileManager.default.removeItem(at: testDirectory) }
        let assetStore = LocalAssetStore(
            rootURL: testDirectory.appendingPathComponent("assets", isDirectory: true)
        )
        let store = WorkspaceStore(
            fileURL: archiveURL,
            seedSamples: false,
            assetStore: assetStore
        )
        let projectID = store.createProject(document: SampleDocuments.museJournal)

        try store.applyDesign(
            .preset(.soft),
            tint: .plum,
            symbol: "photo.fill",
            pagePresentation: .flow,
            canvasBackgroundImageData: try makeImageData(),
            removesCanvasBackground: false,
            to: projectID
        )
        try store.applyDesign(
            store.selectedProject?.document.resolvedTheme ?? .legacy,
            tint: .plum,
            symbol: "photo.fill",
            pagePresentation: .flow,
            canvasBackgroundImageData: nil,
            removesCanvasBackground: true,
            to: projectID
        )

        XCTAssertTrue(store.selectedProject?.document.capabilities.contains(.photoPicker) == true)
    }

    func testDesignApplyKeepsPhotoCapabilityForSelectableHeroMedia() throws {
        let (testDirectory, archiveURL) = makeArchiveURL()
        defer { try? FileManager.default.removeItem(at: testDirectory) }
        var document = SampleDocuments.blank
        document.pages[0].nodes[0].image = .editableLandscape
        document.pages[0].nodes[0].binding = "hero-photo"
        document.capabilities.append(.photoPicker)
        let store = WorkspaceStore(fileURL: archiveURL, seedSamples: false)
        let projectID = store.createProject(document: document)

        try store.applyDesign(
            .preset(.editorial),
            tint: .amber,
            symbol: "photo.fill",
            pagePresentation: .flow,
            canvasBackgroundImageData: nil,
            removesCanvasBackground: true,
            to: projectID
        )

        XCTAssertTrue(store.selectedProject?.document.capabilities.contains(.photoPicker) == true)
        XCTAssertNoThrow(try AppDocumentValidator().validate(
            XCTUnwrap(store.selectedProject?.document)
        ))
    }

    func testInvalidCanvasImageDoesNotCreateDesignVersion() throws {
        let (testDirectory, archiveURL) = makeArchiveURL()
        defer { try? FileManager.default.removeItem(at: testDirectory) }
        let store = WorkspaceStore(fileURL: archiveURL, seedSamples: false)
        let projectID = store.createProject(document: SampleDocuments.blank)

        XCTAssertThrowsError(try store.applyDesign(
            .preset(.playful),
            tint: .coral,
            symbol: "party.popper.fill",
            pagePresentation: .flow,
            canvasBackgroundImageData: Data("invalid image".utf8),
            removesCanvasBackground: false,
            to: projectID
        ))

        XCTAssertEqual(store.selectedProject?.document.version, 1)
        XCTAssertEqual(store.selectedProject?.document.resolvedTheme.preset, .minimal)
    }

    private func makeArchiveURL() -> (directory: URL, archive: URL) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MakeYourTests-\(UUID().uuidString)", isDirectory: true)
        return (directory, directory.appendingPathComponent("projects.json"))
    }

    private func makeImageData() throws -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 30))
        let image = renderer.image { context in
            UIColor.systemPurple.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 40, height: 30))
        }
        return try XCTUnwrap(image.pngData())
    }
}
