import XCTest
@testable import MakeYourIOS

final class RuntimeVoiceRecordingFilesTests: XCTestCase {
    func testCleanupRemovesOnlyOwnedM4AStagingFiles() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            "MakeYourVoiceStagingTests-\(UUID().uuidString)",
            isDirectory: true
        )
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let ownedFile = directory.appendingPathComponent("makeyour-voice-stale.m4a")
        let unrelatedAudio = directory.appendingPathComponent("other.m4a")
        let unrelatedExtension = directory.appendingPathComponent("makeyour-voice-note.txt")
        try Data("owned".utf8).write(to: ownedFile)
        try Data("other".utf8).write(to: unrelatedAudio)
        try Data("text".utf8).write(to: unrelatedExtension)

        RuntimeVoiceRecordingFiles.removeAllStagedRecordings(in: directory)

        XCTAssertFalse(FileManager.default.fileExists(atPath: ownedFile.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: unrelatedAudio.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: unrelatedExtension.path))
    }

    func testStagingURLIsOpaqueAndDirectoryIsExcludedFromBackup() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            "MakeYourVoiceStagingTests-\(UUID().uuidString)",
            isDirectory: true
        )
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = try RuntimeVoiceRecordingFiles.makeFileURL(in: directory)

        XCTAssertTrue(fileURL.lastPathComponent.hasPrefix("makeyour-voice-"))
        XCTAssertEqual(fileURL.pathExtension, "m4a")
        XCTAssertNotNil(
            UUID(uuidString: fileURL.deletingPathExtension().lastPathComponent
                .replacingOccurrences(of: "makeyour-voice-", with: ""))
        )
        XCTAssertEqual(
            try directory.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup,
            true
        )
    }
}
