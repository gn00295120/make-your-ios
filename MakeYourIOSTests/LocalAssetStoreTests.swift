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

    private func makeTemporaryRootURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(
            "MakeYourAssetTests-\(UUID().uuidString)",
            isDirectory: true
        )
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
}
