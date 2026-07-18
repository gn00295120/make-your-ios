import Foundation
import Observation
import UIKit

private struct LocalAssetManifest: Codable {
    var assetsByBinding: [String: String] = [:]
    var audioByBinding: [String: String] = [:]

    private enum CodingKeys: String, CodingKey {
        case assetsByBinding
        case audioByBinding
    }

    init(assetsByBinding: [String: String] = [:], audioByBinding: [String: String] = [:]) {
        self.assetsByBinding = assetsByBinding
        self.audioByBinding = audioByBinding
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dictionary = [String: String].self
        assetsByBinding = try container.decodeIfPresent(dictionary, forKey: .assetsByBinding) ?? [:]
        audioByBinding = try container.decodeIfPresent(dictionary, forKey: .audioByBinding) ?? [:]
    }
}

@MainActor
@Observable
final class LocalAssetStore {
    private static let maximumImageDimension: CGFloat = 2_048
    private static let jpegCompressionQuality: CGFloat = 0.86
    private static let maximumVoiceRecordingBytes = 1_048_576
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
        try saveAssetData(
            normalizedData, projectID: projectID, binding: binding,
            manifestKeyPath: \.assetsByBinding,
            fileExtension: "jpg"
        )
    }
    func image(projectID: UUID, binding: String) -> UIImage? {
        guard let url = storedAssetURL(
            projectID: projectID, binding: binding,
            manifestKeyPath: \.assetsByBinding,
            fileExtension: "jpg"
        ) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    func hasImage(projectID: UUID, binding: String) -> Bool {
        storedAssetURL(
            projectID: projectID, binding: binding,
            manifestKeyPath: \.assetsByBinding,
            fileExtension: "jpg"
        ) != nil
    }

    func saveVoiceRecordingData(_ data: Data, projectID: UUID, binding: String) throws {
        let binding = try validatedBinding(binding)
        guard data.count <= Self.maximumVoiceRecordingBytes else {
            throw LocalAssetStoreError.voiceRecordingTooLarge
        }
        guard LocalVoiceRecordingValidator.isPlayableM4A(data) else {
            throw LocalAssetStoreError.invalidVoiceRecordingData
        }
        try saveAssetData(
            data, projectID: projectID, binding: binding,
            manifestKeyPath: \.audioByBinding,
            fileExtension: "m4a"
        )
    }
    func voiceRecordingURL(projectID: UUID, binding: String) -> URL? {
        storedAssetURL(
            projectID: projectID, binding: binding,
            manifestKeyPath: \.audioByBinding,
            fileExtension: "m4a"
        )
    }

    func hasVoiceRecording(projectID: UUID, binding: String) -> Bool {
        voiceRecordingURL(projectID: projectID, binding: binding) != nil
    }

    func deleteImage(projectID: UUID, binding: String) throws {
        try deleteAsset(
            projectID: projectID, binding: binding,
            manifestKeyPath: \.assetsByBinding,
            fileExtension: "jpg"
        )
    }

    func deleteVoiceRecording(projectID: UUID, binding: String) throws {
        try deleteAsset(
            projectID: projectID, binding: binding,
            manifestKeyPath: \.audioByBinding,
            fileExtension: "m4a"
        )
    }

    func retainVoiceRecordings(projectID: UUID, bindings: Set<String>) throws {
        let retainedBindings = try Set(bindings.map(validatedBinding))
        let directory = projectDirectory(for: projectID)
        var manifest = try loadManifest(projectID: projectID)
        let removedAssets = manifest.audioByBinding.filter {
            !retainedBindings.contains($0.key)
        }
        guard !removedAssets.isEmpty else { return }
        guard removedAssets.values.allSatisfy(Self.isValidAssetID) else {
            throw LocalAssetStoreError.invalidManifest
        }
        manifest.audioByBinding = manifest.audioByBinding.filter {
            retainedBindings.contains($0.key)
        }
        if manifest.assetsByBinding.isEmpty, manifest.audioByBinding.isEmpty {
            try deleteAssets(projectID: projectID)
            return
        }
        try saveManifest(manifest, in: directory)
        for assetID in removedAssets.values {
            try? fileManager.removeItem(at: storedAssetURL(
                assetID: assetID,
                fileExtension: "m4a",
                in: directory
            ))
        }
    }

    func duplicateAssets(from sourceProjectID: UUID, to destinationProjectID: UUID) throws {
        guard sourceProjectID != destinationProjectID else { return }
        let sourceManifest = try loadManifest(projectID: sourceProjectID)
        let destinationDirectory = projectDirectory(for: destinationProjectID)
        guard !sourceManifest.assetsByBinding.isEmpty || !sourceManifest.audioByBinding.isEmpty else {
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
        let sourceDirectory = projectDirectory(for: sourceProjectID)
        let destinationManifest = LocalAssetManifest(
            assetsByBinding: try duplicateAssetMap(
                sourceManifest.assetsByBinding,
                from: sourceDirectory,
                to: stagingDirectory,
                fileExtension: "jpg"
            ),
            audioByBinding: try duplicateAssetMap(
                sourceManifest.audioByBinding,
                from: sourceDirectory,
                to: stagingDirectory,
                fileExtension: "m4a"
            )
        )
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
}

private extension LocalAssetStore {
    func saveAssetData(
        _ data: Data,
        projectID: UUID,
        binding: String,
        manifestKeyPath: WritableKeyPath<LocalAssetManifest, [String: String]>,
        fileExtension: String
    ) throws {
        let binding = try validatedBinding(binding)
        let directory = projectDirectory(for: projectID)
        try createProtectedDirectoryIfNeeded(at: directory)
        var manifest = try loadManifest(projectID: projectID)
        let previousAssetID = manifest[keyPath: manifestKeyPath][binding]
        let assetID = UUID().uuidString.lowercased()
        let destination = storedAssetURL(
            assetID: assetID,
            fileExtension: fileExtension,
            in: directory
        )
        do {
            try data.write(to: destination, options: .atomic)
            applyBestEffortProtection(to: destination)
            manifest[keyPath: manifestKeyPath][binding] = assetID
            try saveManifest(manifest, in: directory)
        } catch {
            try? fileManager.removeItem(at: destination)
            throw error
        }
        if let previousAssetID,
           previousAssetID != assetID,
           Self.isValidAssetID(previousAssetID) {
            try? fileManager.removeItem(at: storedAssetURL(
                assetID: previousAssetID,
                fileExtension: fileExtension,
                in: directory
            ))
        }
    }
    func storedAssetURL(
        projectID: UUID,
        binding: String,
        manifestKeyPath: KeyPath<LocalAssetManifest, [String: String]>,
        fileExtension: String
    ) -> URL? {
        guard let binding = try? validatedBinding(binding),
              let manifest = try? loadManifest(projectID: projectID),
              let assetID = manifest[keyPath: manifestKeyPath][binding],
              Self.isValidAssetID(assetID) else {
            return nil
        }
        let url = storedAssetURL(
            assetID: assetID,
            fileExtension: fileExtension,
            in: projectDirectory(for: projectID)
        )
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }
    func deleteAsset(
        projectID: UUID,
        binding: String,
        manifestKeyPath: WritableKeyPath<LocalAssetManifest, [String: String]>,
        fileExtension: String
    ) throws {
        let binding = try validatedBinding(binding)
        let directory = projectDirectory(for: projectID)
        var manifest = try loadManifest(projectID: projectID)
        guard let assetID = manifest[keyPath: manifestKeyPath].removeValue(
            forKey: binding
        ) else { return }
        guard Self.isValidAssetID(assetID) else {
            throw LocalAssetStoreError.invalidManifest
        }
        if manifest.assetsByBinding.isEmpty, manifest.audioByBinding.isEmpty {
            try deleteAssets(projectID: projectID)
            return
        }
        try saveManifest(manifest, in: directory)
        let url = storedAssetURL(
            assetID: assetID,
            fileExtension: fileExtension,
            in: directory
        )
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
    func loadManifest(projectID: UUID) throws -> LocalAssetManifest {
        let directory = projectDirectory(for: projectID)
        let url = manifestURL(in: directory)
        guard fileManager.fileExists(atPath: url.path) else { return LocalAssetManifest() }
        do {
            return try decoder.decode(LocalAssetManifest.self, from: Data(contentsOf: url))
        } catch {
            throw LocalAssetStoreError.invalidManifest
        }
    }
    func saveManifest(_ manifest: LocalAssetManifest, in directory: URL) throws {
        let data = try encoder.encode(manifest)
        let url = manifestURL(in: directory)
        try data.write(to: url, options: .atomic)
        applyBestEffortProtection(to: url)
    }
    func createProtectedDirectoryIfNeeded(at url: URL) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        applyBestEffortProtection(to: url)
    }
    func applyBestEffortProtection(to url: URL) {
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var mutableURL = url
        try? mutableURL.setResourceValues(resourceValues)
        try? fileManager.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: url.path
        )
    }
    func duplicateAssetMap(
        _ sourceMap: [String: String],
        from sourceDirectory: URL,
        to destinationDirectory: URL,
        fileExtension: String
    ) throws -> [String: String] {
        var destinationMap: [String: String] = [:]
        for (binding, sourceAssetID) in sourceMap {
            guard Self.isValidAssetID(sourceAssetID) else {
                throw LocalAssetStoreError.invalidManifest
            }
            let sourceURL = storedAssetURL(
                assetID: sourceAssetID,
                fileExtension: fileExtension,
                in: sourceDirectory
            )
            guard fileManager.fileExists(atPath: sourceURL.path) else {
                throw LocalAssetStoreError.missingAsset
            }
            let destinationAssetID = UUID().uuidString.lowercased()
            let destinationURL = storedAssetURL(
                assetID: destinationAssetID,
                fileExtension: fileExtension,
                in: destinationDirectory
            )
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            applyBestEffortProtection(to: destinationURL)
            destinationMap[binding] = destinationAssetID
        }
        return destinationMap
    }
    func validatedBinding(_ binding: String) throws -> String {
        let trimmed = binding.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 120 else {
            throw LocalAssetStoreError.invalidBinding
        }
        return trimmed
    }
    func projectDirectory(for projectID: UUID) -> URL {
        rootURL.appendingPathComponent(projectID.uuidString.lowercased(), isDirectory: true)
    }
    func storedAssetURL(
        assetID: String,
        fileExtension: String,
        in directory: URL
    ) -> URL {
        directory.appendingPathComponent(assetID).appendingPathExtension(fileExtension)
    }
    func manifestURL(in directory: URL) -> URL {
        directory.appendingPathComponent("manifest.json")
    }
    static func normalizedJPEGData(from sourceImage: UIImage) -> Data? {
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
    static func isValidAssetID(_ value: String) -> Bool {
        UUID(uuidString: value) != nil
    }
    static var defaultRootURL: URL {
        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return applicationSupport
            .appendingPathComponent("MakeYour", isDirectory: true)
            .appendingPathComponent("assets", isDirectory: true)
    }
}
