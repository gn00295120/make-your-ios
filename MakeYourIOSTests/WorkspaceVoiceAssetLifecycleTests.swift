import XCTest
@testable import MakeYourIOS

@MainActor
final class WorkspaceVoiceAssetLifecycleTests: XCTestCase {
    func testRegenerationKeepsReferencedVoiceAndDeletesRemovedBinding() throws {
        let rootURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            "MakeYourVoiceWorkspaceTests-\(UUID().uuidString)",
            isDirectory: true
        )
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let assetStore = LocalAssetStore(
            rootURL: rootURL.appendingPathComponent("assets", isDirectory: true)
        )
        let store = WorkspaceStore(
            fileURL: rootURL.appendingPathComponent("projects.json"),
            seedSamples: false,
            assetStore: assetStore
        )
        let projectID = store.createProject(document: voiceDocument(binding: "retained-voice"))
        let recording = try makePlayableVoiceRecordingData()
        try assetStore.saveVoiceRecordingData(
            recording,
            projectID: projectID,
            binding: "retained-voice"
        )
        try assetStore.saveVoiceRecordingData(
            recording,
            projectID: projectID,
            binding: "removed-voice"
        )

        try store.replaceDocument(
            projectID: projectID,
            with: voiceDocument(binding: "retained-voice"),
            prompt: "Keep my current voice block"
        )

        assertRecording(true, store: assetStore, projectID: projectID, binding: "retained-voice")
        assertRecording(false, store: assetStore, projectID: projectID, binding: "removed-voice")

        try store.replaceDocument(
            projectID: projectID,
            with: SampleDocuments.blank,
            prompt: "Remove the voice block"
        )
        assertRecording(false, store: assetStore, projectID: projectID, binding: "retained-voice")

        try store.replaceDocument(
            projectID: projectID,
            with: voiceDocument(binding: "retained-voice"),
            prompt: "Add the voice block again"
        )
        assertRecording(false, store: assetStore, projectID: projectID, binding: "retained-voice")
    }

    func testFailedDocumentPersistenceRollsBackAndPreservesVoiceRecording() throws {
        let rootURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            "MakeYourVoiceWorkspaceTests-\(UUID().uuidString)",
            isDirectory: true
        )
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let archiveURL = rootURL.appendingPathComponent("projects.json")
        let assetStore = LocalAssetStore(
            rootURL: rootURL.appendingPathComponent("assets", isDirectory: true)
        )
        let store = WorkspaceStore(
            fileURL: archiveURL,
            seedSamples: false,
            assetStore: assetStore
        )
        let projectID = store.createProject(document: voiceDocument(binding: "durable-voice"))
        try assetStore.saveVoiceRecordingData(
            try makePlayableVoiceRecordingData(),
            projectID: projectID,
            binding: "durable-voice"
        )
        try FileManager.default.removeItem(at: archiveURL)
        try FileManager.default.createDirectory(at: archiveURL, withIntermediateDirectories: true)

        XCTAssertThrowsError(try store.replaceDocument(
            projectID: projectID,
            with: SampleDocuments.blank,
            prompt: "This write must fail"
        ))

        XCTAssertEqual(store.selectedProject?.document.version, 1)
        XCTAssertEqual(store.selectedProject?.document.name, "Private voice")
        XCTAssertNotNil(store.lastPersistenceError)
        assertRecording(true, store: assetStore, projectID: projectID, binding: "durable-voice")
    }

    private func assertRecording(
        _ expected: Bool,
        store: LocalAssetStore,
        projectID: UUID,
        binding: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            store.hasVoiceRecording(projectID: projectID, binding: binding),
            expected,
            file: file,
            line: line
        )
    }

    private func voiceDocument(binding: String) -> AppDocument {
        AppDocument(
            name: "Private voice",
            summary: "A local voice note",
            symbol: "mic.fill",
            tint: .indigo,
            startPageID: "home",
            capabilities: [.localStorage, .microphoneRecordLocal],
            pages: [
                AppPage(
                    id: "home",
                    title: "Voice",
                    nodes: [
                        ComponentNode(
                            id: "voice",
                            kind: .voiceNote,
                            title: "Voice note",
                            binding: binding,
                            voiceNote: RuntimeVoiceNoteSpec(
                                maximumDurationSeconds: 30,
                                recordButtonLabel: "Record"
                            )
                        )
                    ]
                )
            ]
        )
    }
}
