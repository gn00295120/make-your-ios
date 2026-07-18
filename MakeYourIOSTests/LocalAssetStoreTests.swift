import UIKit
import XCTest
@testable import MakeYourIOS

@MainActor
final class LocalAssetStoreTests: XCTestCase {
    func testSaveAndReadImageDownsamplesToMaximumDimension() throws {
        let rootURL = makeTemporaryRootURL()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let store = LocalAssetStore(rootURL: rootURL)
        let projectID = UUID()

        try store.saveImageData(
            try makeImageData(size: CGSize(width: 3_000, height: 1_500)),
            projectID: projectID,
            binding: "hero-photo"
        )

        XCTAssertTrue(store.hasImage(projectID: projectID, binding: "hero-photo"))
        let image = try XCTUnwrap(store.image(projectID: projectID, binding: "hero-photo"))
        XCTAssertEqual(max(image.size.width, image.size.height), 2_048, accuracy: 1)
    }

    func testDuplicateAssetsCreatesIndependentReadableCopy() throws {
        let rootURL = makeTemporaryRootURL()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let store = LocalAssetStore(rootURL: rootURL)
        let sourceProjectID = UUID()
        let destinationProjectID = UUID()

        try store.saveImageData(
            try makeImageData(size: CGSize(width: 80, height: 60)),
            projectID: sourceProjectID,
            binding: "profile-photo"
        )
        try store.duplicateAssets(from: sourceProjectID, to: destinationProjectID)
        try store.deleteAssets(projectID: sourceProjectID)

        XCTAssertFalse(store.hasImage(projectID: sourceProjectID, binding: "profile-photo"))
        XCTAssertTrue(store.hasImage(projectID: destinationProjectID, binding: "profile-photo"))
        XCTAssertNotNil(store.image(projectID: destinationProjectID, binding: "profile-photo"))
    }

    func testDeleteAssetsRemovesProjectImages() throws {
        let rootURL = makeTemporaryRootURL()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let store = LocalAssetStore(rootURL: rootURL)
        let projectID = UUID()

        try store.saveImageData(
            try makeImageData(size: CGSize(width: 40, height: 40)),
            projectID: projectID,
            binding: "cover"
        )
        try store.deleteAssets(projectID: projectID)

        XCTAssertFalse(store.hasImage(projectID: projectID, binding: "cover"))
        XCTAssertNil(store.image(projectID: projectID, binding: "cover"))
        XCTAssertNoThrow(try store.deleteAssets(projectID: projectID))
    }

    func testDeleteImageRemovesOnlyRequestedBinding() throws {
        let rootURL = makeTemporaryRootURL()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let store = LocalAssetStore(rootURL: rootURL)
        let projectID = UUID()

        try store.saveImageData(
            try makeImageData(size: CGSize(width: 40, height: 40)),
            projectID: projectID,
            binding: "canvas-background"
        )
        try store.saveImageData(
            try makeImageData(size: CGSize(width: 60, height: 40)),
            projectID: projectID,
            binding: "profile-photo"
        )

        try store.deleteImage(projectID: projectID, binding: "canvas-background")

        XCTAssertFalse(store.hasImage(projectID: projectID, binding: "canvas-background"))
        XCTAssertTrue(store.hasImage(projectID: projectID, binding: "profile-photo"))
        XCTAssertNoThrow(
            try store.deleteImage(projectID: projectID, binding: "canvas-background")
        )
    }

    func testInvalidImageDataIsRejectedWithoutCreatingAsset() {
        let rootURL = makeTemporaryRootURL()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let store = LocalAssetStore(rootURL: rootURL)
        let projectID = UUID()

        XCTAssertThrowsError(
            try store.saveImageData(
                Data("not an image".utf8),
                projectID: projectID,
                binding: "broken"
            )
        ) { error in
            XCTAssertEqual(error as? LocalAssetStoreError, .invalidImageData)
        }
        XCTAssertFalse(store.hasImage(projectID: projectID, binding: "broken"))
    }
}

@MainActor
final class LocalAssetStoreVoiceTests: XCTestCase {
    func testLegacyImageOnlyManifestDefaultsAudioBindingsAndRemainsWritable() throws {
        let rootURL = makeTemporaryRootURL()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let projectID = UUID()
        let projectDirectory = projectDirectory(rootURL: rootURL, projectID: projectID)
        try FileManager.default.createDirectory(
            at: projectDirectory,
            withIntermediateDirectories: true
        )
        let imageAssetID = UUID().uuidString.lowercased()
        try makeImageData(size: CGSize(width: 24, height: 24)).write(
            to: projectDirectory
                .appendingPathComponent(imageAssetID)
                .appendingPathExtension("jpg")
        )
        let legacyManifest = try JSONSerialization.data(withJSONObject: [
            "assetsByBinding": ["legacy-image": imageAssetID]
        ])
        try legacyManifest.write(to: projectDirectory.appendingPathComponent("manifest.json"))
        let store = LocalAssetStore(rootURL: rootURL)

        XCTAssertTrue(store.hasImage(projectID: projectID, binding: "legacy-image"))
        XCTAssertFalse(store.hasVoiceRecording(projectID: projectID, binding: "voice-note"))

        try store.saveVoiceRecordingData(
            try makePlayableVoiceRecordingData(),
            projectID: projectID,
            binding: "voice-note"
        )

        XCTAssertTrue(store.hasImage(projectID: projectID, binding: "legacy-image"))
        XCTAssertTrue(store.hasVoiceRecording(projectID: projectID, binding: "voice-note"))
        let savedManifestData = try Data(
            contentsOf: projectDirectory.appendingPathComponent("manifest.json")
        )
        let savedManifest = try XCTUnwrap(
            JSONSerialization.jsonObject(with: savedManifestData) as? [String: Any]
        )
        XCTAssertNotNil(savedManifest["assetsByBinding"])
        XCTAssertNotNil(savedManifest["audioByBinding"])
    }

    func testVoiceRecordingRejectsInvalidAndOversizedDataAtOneMiBBoundary() throws {
        let rootURL = makeTemporaryRootURL()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let store = LocalAssetStore(rootURL: rootURL)
        let projectID = UUID()

        var forgedM4A = Data(repeating: 0, count: 32)
        forgedM4A.replaceSubrange(4..<8, with: Data("ftyp".utf8))
        for invalidData in [Data(repeating: 0, count: 32), forgedM4A] {
            XCTAssertThrowsError(
                try store.saveVoiceRecordingData(
                    invalidData,
                    projectID: projectID,
                    binding: "invalid"
                )
            ) { error in
                XCTAssertEqual(error as? LocalAssetStoreError, .invalidVoiceRecordingData)
            }
        }

        let maximumData = try makePlayableVoiceRecordingData(minimumByteCount: 1_048_576)
        try store.saveVoiceRecordingData(
            maximumData,
            projectID: projectID,
            binding: "maximum"
        )
        XCTAssertTrue(store.hasVoiceRecording(projectID: projectID, binding: "maximum"))

        XCTAssertThrowsError(
            try store.saveVoiceRecordingData(
                makePlayableVoiceRecordingData(minimumByteCount: 1_048_577),
                projectID: projectID,
                binding: "too-large"
            )
        ) { error in
            XCTAssertEqual(error as? LocalAssetStoreError, .voiceRecordingTooLarge)
        }
        XCTAssertFalse(store.hasVoiceRecording(projectID: projectID, binding: "too-large"))
    }

    func testSaveReadAndDeleteVoiceRecordingUsesOpaqueM4AFilename() throws {
        let rootURL = makeTemporaryRootURL()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let store = LocalAssetStore(rootURL: rootURL)
        let projectID = UUID()
        let recordingData = try makePlayableVoiceRecordingData()

        try store.saveVoiceRecordingData(
            recordingData,
            projectID: projectID,
            binding: "daily-note"
        )

        let recordingURL = try XCTUnwrap(
            store.voiceRecordingURL(projectID: projectID, binding: "daily-note")
        )
        XCTAssertTrue(store.hasVoiceRecording(projectID: projectID, binding: "daily-note"))
        XCTAssertEqual(recordingURL.pathExtension, "m4a")
        XCTAssertNotNil(UUID(uuidString: recordingURL.deletingPathExtension().lastPathComponent))
        XCTAssertEqual(try Data(contentsOf: recordingURL), recordingData)
        XCTAssertEqual(
            try recordingURL.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup,
            true
        )
        #if !targetEnvironment(simulator)
        let attributes = try FileManager.default.attributesOfItem(atPath: recordingURL.path)
        XCTAssertEqual(attributes[.protectionKey] as? FileProtectionType, .complete)
        #endif

        try store.deleteVoiceRecording(projectID: projectID, binding: "daily-note")

        XCTAssertFalse(store.hasVoiceRecording(projectID: projectID, binding: "daily-note"))
        XCTAssertNil(store.voiceRecordingURL(projectID: projectID, binding: "daily-note"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: recordingURL.path))
        XCTAssertNoThrow(
            try store.deleteVoiceRecording(projectID: projectID, binding: "daily-note")
        )
    }

    func testDuplicateAssetsCopiesMixedImagesAndAudioIndependently() throws {
        let rootURL = makeTemporaryRootURL()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let store = LocalAssetStore(rootURL: rootURL)
        let sourceProjectID = UUID()
        let destinationProjectID = UUID()
        let recordingData = try makePlayableVoiceRecordingData()

        try store.saveImageData(
            try makeImageData(size: CGSize(width: 64, height: 48)),
            projectID: sourceProjectID,
            binding: "photo"
        )
        try store.saveVoiceRecordingData(
            recordingData,
            projectID: sourceProjectID,
            binding: "voice"
        )
        let sourceRecordingURL = try XCTUnwrap(
            store.voiceRecordingURL(projectID: sourceProjectID, binding: "voice")
        )

        try store.duplicateAssets(from: sourceProjectID, to: destinationProjectID)

        let destinationRecordingURL = try XCTUnwrap(
            store.voiceRecordingURL(projectID: destinationProjectID, binding: "voice")
        )
        XCTAssertTrue(store.hasImage(projectID: destinationProjectID, binding: "photo"))
        XCTAssertNotEqual(sourceRecordingURL.lastPathComponent, destinationRecordingURL.lastPathComponent)
        XCTAssertEqual(try Data(contentsOf: destinationRecordingURL), recordingData)

        try store.deleteAssets(projectID: sourceProjectID)

        XCTAssertTrue(store.hasImage(projectID: destinationProjectID, binding: "photo"))
        XCTAssertTrue(store.hasVoiceRecording(projectID: destinationProjectID, binding: "voice"))
    }

    func testDuplicateAssetsSupportsAudioOnlySourceAndReplacesDestination() throws {
        let rootURL = makeTemporaryRootURL()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let store = LocalAssetStore(rootURL: rootURL)
        let sourceProjectID = UUID()
        let destinationProjectID = UUID()

        try store.saveVoiceRecordingData(
            try makePlayableVoiceRecordingData(),
            projectID: sourceProjectID,
            binding: "voice"
        )
        try store.saveImageData(
            try makeImageData(size: CGSize(width: 20, height: 20)),
            projectID: destinationProjectID,
            binding: "old-photo"
        )

        try store.duplicateAssets(from: sourceProjectID, to: destinationProjectID)

        XCTAssertTrue(store.hasVoiceRecording(projectID: destinationProjectID, binding: "voice"))
        XCTAssertFalse(store.hasImage(projectID: destinationProjectID, binding: "old-photo"))
        try store.deleteAssets(projectID: sourceProjectID)
        XCTAssertTrue(store.hasVoiceRecording(projectID: destinationProjectID, binding: "voice"))
    }

    func testDeletingLastImagePreservesAudioOnlyProject() throws {
        let rootURL = makeTemporaryRootURL()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let store = LocalAssetStore(rootURL: rootURL)
        let projectID = UUID()
        let recordingData = try makePlayableVoiceRecordingData()

        try store.saveImageData(
            try makeImageData(size: CGSize(width: 30, height: 30)),
            projectID: projectID,
            binding: "photo"
        )
        try store.saveVoiceRecordingData(
            recordingData,
            projectID: projectID,
            binding: "voice"
        )

        try store.deleteImage(projectID: projectID, binding: "photo")

        XCTAssertFalse(store.hasImage(projectID: projectID, binding: "photo"))
        let recordingURL = try XCTUnwrap(
            store.voiceRecordingURL(projectID: projectID, binding: "voice")
        )
        XCTAssertEqual(try Data(contentsOf: recordingURL), recordingData)
    }

}

private func makeTemporaryRootURL() -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent(
        "MakeYourAssetTests-\(UUID().uuidString)",
        isDirectory: true
    )
}

private func projectDirectory(rootURL: URL, projectID: UUID) -> URL {
    rootURL.appendingPathComponent(projectID.uuidString.lowercased(), isDirectory: true)
}

private func makeImageData(size: CGSize) throws -> Data {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.opaque = true
    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    let image = renderer.image { context in
        UIColor.systemTeal.setFill()
        context.fill(CGRect(origin: .zero, size: size))
    }
    return try XCTUnwrap(image.pngData())
}
