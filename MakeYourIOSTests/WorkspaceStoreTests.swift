import UIKit
import XCTest
@testable import MakeYourIOS

@MainActor
final class WorkspaceStoreTests: XCTestCase {
    func testFreshWorkspaceSeedsReviewableCapabilityExamples() {
        let (testDirectory, archiveURL) = makeArchiveURL()
        defer { try? FileManager.default.removeItem(at: testDirectory) }

        let store = WorkspaceStore(fileURL: archiveURL, seedSamples: true)

        XCTAssertEqual(store.projects.map(\.document.name), [
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
