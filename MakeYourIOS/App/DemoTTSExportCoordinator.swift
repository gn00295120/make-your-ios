#if DEBUG
import Foundation
import OSLog

struct DemoTTSExportOptions: Equatable, Sendable {
    static let launchFlag = "--demo-export-tts"
    static let textPrefix = "--demo-tts-text-base64="
    static let outputPrefix = "--demo-tts-output="
    static let defaultOutputFilename = "MakeYour-demo-narration.mp3"

    let text: String
    let outputFilename: String

    static func parse(arguments: [String]) throws -> Self? {
        guard arguments.contains(launchFlag) else { return nil }

        guard let encodedText = value(withPrefix: textPrefix, in: arguments),
              let data = Data(base64Encoded: encodedText),
              let text = String(data: data, encoding: .utf8),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DemoTTSExportError.missingOrInvalidText
        }

        let outputFilename = value(withPrefix: outputPrefix, in: arguments)
            ?? defaultOutputFilename
        guard isValidOutputFilename(outputFilename) else {
            throw DemoTTSExportError.invalidOutputFilename
        }

        return Self(text: text, outputFilename: outputFilename)
    }

    private static func value(withPrefix prefix: String, in arguments: [String]) -> String? {
        arguments
            .first(where: { $0.hasPrefix(prefix) })
            .map { String($0.dropFirst(prefix.count)) }
    }

    private static func isValidOutputFilename(_ value: String) -> Bool {
        guard !value.isEmpty,
              value.count <= 128,
              value.lowercased().hasSuffix(".mp3"),
              value != ".mp3",
              URL(fileURLWithPath: value).lastPathComponent == value else {
            return false
        }

        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        return value.unicodeScalars.allSatisfy(allowed.contains)
    }
}

@MainActor
enum DemoTTSExportCoordinator {
    private static let logger = Logger(
        subsystem: "com.longweiwang.makeyourios",
        category: "DemoTTSExport"
    )

    static func exportIfRequested(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        settings: AISettingsStore,
        client: OpenAISpeechClient = OpenAISpeechClient(),
        fileManager: FileManager = .default
    ) async {
        do {
            guard let options = try DemoTTSExportOptions.parse(arguments: arguments) else {
                return
            }

            let config = try settings.connectionConfig()
            let audio = try await client.synthesize(text: options.text, apiKey: config.apiKey)
            guard let documents = fileManager.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first else {
                throw DemoTTSExportError.documentsDirectoryUnavailable
            }

            try fileManager.createDirectory(
                at: documents,
                withIntermediateDirectories: true
            )
            let destination = documents.appendingPathComponent(
                options.outputFilename,
                isDirectory: false
            )
            try audio.write(to: destination, options: .atomic)
            logger.notice("Demo TTS export completed: \(options.outputFilename, privacy: .public)")
        } catch {
            logger.error("Demo TTS export failed; no credentials were logged.")
        }
    }
}

enum DemoTTSExportError: LocalizedError, Equatable {
    case missingOrInvalidText
    case invalidOutputFilename
    case documentsDirectoryUnavailable

    var errorDescription: String? {
        switch self {
        case .missingOrInvalidText:
            "Provide UTF-8 narration with --demo-tts-text-base64."
        case .invalidOutputFilename:
            "The demo TTS output must be a simple .mp3 filename."
        case .documentsDirectoryUnavailable:
            "The app Documents directory is unavailable."
        }
    }
}
#endif
