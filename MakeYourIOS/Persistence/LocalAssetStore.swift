import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class LocalAssetStore {
    private struct Manifest: Codable {
        var assetsByBinding: [String: String] = [:]
    }

    private static let maximumImageDimension: CGFloat = 2_048
    private static let jpegCompressionQuality: CGFloat = 0.86

    private let rootURL: URL
    private let fileManager: FileManager
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(rootURL: URL? = nil) {
        fileManager = .default
        self.rootURL = rootURL ?? Self.defaultRootURL
        encoder.outputFormatting = [.sortedKeys]
    }

    func saveImageData(_ data: Data, projectID: UUID, binding: String) throws {
        let binding = try validatedBinding(binding)
        guard let sourceImage = UIImage(data: data),
              let normalizedData = Self.normalizedJPEGData(from: sourceImage) else {
            throw LocalAssetStoreError.invalidImageData
        }

        let directory = projectDirectory(for: projectID)
        try createProtectedDirectoryIfNeeded(at: directory)

        var manifest = try loadManifest(projectID: projectID)
        let previousAssetID = manifest.assetsByBinding[binding]
        let assetID = UUID().uuidString.lowercased()
        let destination = assetURL(assetID: assetID, in: directory)

        do {
            try normalizedData.write(to: destination, options: .atomic)
            applyBestEffortProtection(to: destination)
            manifest.assetsByBinding[binding] = assetID
            try saveManifest(manifest, in: directory)
        } catch {
            try? fileManager.removeItem(at: destination)
            throw error
        }

        if let previousAssetID,
           previousAssetID != assetID,
           Self.isValidAssetID(previousAssetID) {
            try? fileManager.removeItem(at: assetURL(assetID: previousAssetID, in: directory))
        }
    }

    func image(projectID: UUID, binding: String) -> UIImage? {
        guard let binding = try? validatedBinding(binding),
              let manifest = try? loadManifest(projectID: projectID),
              let assetID = manifest.assetsByBinding[binding],
              Self.isValidAssetID(assetID) else {
            return nil
        }

        return UIImage(contentsOfFile: assetURL(
            assetID: assetID,
            in: projectDirectory(for: projectID)
        ).path)
    }

    func hasImage(projectID: UUID, binding: String) -> Bool {
        guard let binding = try? validatedBinding(binding),
              let manifest = try? loadManifest(projectID: projectID),
              let assetID = manifest.assetsByBinding[binding],
              Self.isValidAssetID(assetID) else {
            return false
        }

        return fileManager.fileExists(atPath: assetURL(
            assetID: assetID,
            in: projectDirectory(for: projectID)
        ).path)
    }

    func deleteImage(projectID: UUID, binding: String) throws {
        let binding = try validatedBinding(binding)
        let directory = projectDirectory(for: projectID)
        var manifest = try loadManifest(projectID: projectID)
        guard let assetID = manifest.assetsByBinding.removeValue(forKey: binding) else { return }

        guard Self.isValidAssetID(assetID) else {
            throw LocalAssetStoreError.invalidManifest
        }

        if manifest.assetsByBinding.isEmpty {
            try deleteAssets(projectID: projectID)
            return
        }

        try saveManifest(manifest, in: directory)
        let url = assetURL(assetID: assetID, in: directory)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    func duplicateAssets(from sourceProjectID: UUID, to destinationProjectID: UUID) throws {
        guard sourceProjectID != destinationProjectID else { return }

        let sourceManifest = try loadManifest(projectID: sourceProjectID)
        let destinationDirectory = projectDirectory(for: destinationProjectID)

        guard !sourceManifest.assetsByBinding.isEmpty else {
            try deleteAssets(projectID: destinationProjectID)
            return
        }

        try createProtectedDirectoryIfNeeded(at: rootURL)
        let stagingDirectory = rootURL.appendingPathComponent(
            ".duplicate-\(UUID().uuidString.lowercased())",
            isDirectory: true
        )
        try createProtectedDirectoryIfNeeded(at: stagingDirectory)

        var stagingExists = true
        defer {
            if stagingExists {
                try? fileManager.removeItem(at: stagingDirectory)
            }
        }

        var destinationManifest = Manifest()
        let sourceDirectory = projectDirectory(for: sourceProjectID)

        for (binding, sourceAssetID) in sourceManifest.assetsByBinding {
            guard Self.isValidAssetID(sourceAssetID) else {
                throw LocalAssetStoreError.invalidManifest
            }

            let sourceURL = assetURL(assetID: sourceAssetID, in: sourceDirectory)
            guard fileManager.fileExists(atPath: sourceURL.path) else {
                throw LocalAssetStoreError.missingAsset
            }

            let destinationAssetID = UUID().uuidString.lowercased()
            let destinationURL = assetURL(assetID: destinationAssetID, in: stagingDirectory)
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            applyBestEffortProtection(to: destinationURL)
            destinationManifest.assetsByBinding[binding] = destinationAssetID
        }

        try saveManifest(destinationManifest, in: stagingDirectory)
        if fileManager.fileExists(atPath: destinationDirectory.path) {
            try fileManager.removeItem(at: destinationDirectory)
        }
        try fileManager.moveItem(at: stagingDirectory, to: destinationDirectory)
        stagingExists = false
        applyBestEffortProtection(to: destinationDirectory)
    }

    func deleteAssets(projectID: UUID) throws {
        let directory = projectDirectory(for: projectID)
        guard fileManager.fileExists(atPath: directory.path) else { return }
        try fileManager.removeItem(at: directory)
    }

    private func loadManifest(projectID: UUID) throws -> Manifest {
        let directory = projectDirectory(for: projectID)
        let url = manifestURL(in: directory)
        guard fileManager.fileExists(atPath: url.path) else { return Manifest() }

        do {
            return try decoder.decode(Manifest.self, from: Data(contentsOf: url))
        } catch {
            throw LocalAssetStoreError.invalidManifest
        }
    }

    private func saveManifest(_ manifest: Manifest, in directory: URL) throws {
        let data = try encoder.encode(manifest)
        let url = manifestURL(in: directory)
        try data.write(to: url, options: .atomic)
        applyBestEffortProtection(to: url)
    }

    private func createProtectedDirectoryIfNeeded(at url: URL) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        applyBestEffortProtection(to: url)
    }

    private func applyBestEffortProtection(to url: URL) {
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var mutableURL = url
        try? mutableURL.setResourceValues(resourceValues)
        try? fileManager.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: url.path
        )
    }

    private func validatedBinding(_ binding: String) throws -> String {
        let trimmed = binding.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 120 else {
            throw LocalAssetStoreError.invalidBinding
        }
        return trimmed
    }

    private func projectDirectory(for projectID: UUID) -> URL {
        rootURL.appendingPathComponent(projectID.uuidString.lowercased(), isDirectory: true)
    }

    private func assetURL(assetID: String, in directory: URL) -> URL {
        directory.appendingPathComponent(assetID).appendingPathExtension("jpg")
    }

    private func manifestURL(in directory: URL) -> URL {
        directory.appendingPathComponent("manifest.json")
    }

    private static func normalizedJPEGData(from sourceImage: UIImage) -> Data? {
        let sourceSize = sourceImage.size
        guard sourceSize.width.isFinite,
              sourceSize.height.isFinite,
              sourceSize.width > 0,
              sourceSize.height > 0 else {
            return nil
        }

        let scale = min(1, maximumImageDimension / max(sourceSize.width, sourceSize.height))
        let targetSize = CGSize(
            width: max(1, (sourceSize.width * scale).rounded()),
            height: max(1, (sourceSize.height * scale).rounded())
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let normalizedImage = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))
            sourceImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return normalizedImage.jpegData(compressionQuality: jpegCompressionQuality)
    }

    private static func isValidAssetID(_ value: String) -> Bool {
        UUID(uuidString: value) != nil
    }

    private static var defaultRootURL: URL {
        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return applicationSupport
            .appendingPathComponent("MakeYour", isDirectory: true)
            .appendingPathComponent("assets", isDirectory: true)
    }
}

enum LocalAssetStoreError: LocalizedError, Equatable {
    case invalidBinding
    case invalidImageData
    case invalidManifest
    case missingAsset

    var errorDescription: String? {
        switch self {
        case .invalidBinding:
            "The image binding is empty or too long."
        case .invalidImageData:
            "The selected item is not a supported image."
        case .invalidManifest:
            "The local image manifest is invalid."
        case .missingAsset:
            "A local image file is missing."
        }
    }
}
