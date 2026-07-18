@preconcurrency import Speech
import Foundation
import Observation

private struct RuntimeSpeechRequest: Equatable {
    let id = UUID()
    let ownerID: String
}

@MainActor
@Observable
final class RuntimeSpeechHost {
    enum Activity: Equatable {
        case idle
        case authorizing(ownerID: String)
        case recognizing(ownerID: String)
        case completed(ownerID: String, transcript: String)
        case failed(ownerID: String, message: String)
    }

    nonisolated static let maximumTranscriptLength = 2_000
    nonisolated static let maximumTranscriptBytes = 8_192
    private(set) var activity: Activity = .idle

    private var activeRequest: RuntimeSpeechRequest?
    private var recognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var timeoutTask: Task<Void, Never>?
    private var sceneIsActive = true

    var isProcessing: Bool {
        switch activity {
        case .authorizing, .recognizing: true
        case .idle, .completed, .failed: false
        }
    }

    func requestAndTranscribe(
        ownerID: String,
        fileURL: URL,
        localeIdentifier: String
    ) async {
        guard activity == .idle else { return }
        let request = RuntimeSpeechRequest(ownerID: ownerID)
        activeRequest = request
        activity = .authorizing(ownerID: ownerID)

        do {
            let authorization = await authorizationStatus()
            try Task.checkCancellation()
            guard activeRequest?.id == request.id else { return }
            guard authorization == .authorized else {
                throw RuntimeSpeechError.permissionDenied
            }
            try await waitForActiveScene(requestID: request.id)
            guard activeRequest?.id == request.id else { return }
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                throw RuntimeSpeechError.missingRecording
            }

            let recognizer = try makeRecognizer(localeIdentifier: localeIdentifier)
            guard recognizer.isAvailable else {
                throw RuntimeSpeechError.recognizerUnavailable
            }
            guard recognizer.supportsOnDeviceRecognition else {
                throw RuntimeSpeechError.onDeviceRecognitionUnavailable
            }
            self.recognizer = recognizer

            startRecognition(
                request: request,
                ownerID: ownerID,
                fileURL: fileURL,
                recognizer: recognizer
            )
        } catch is CancellationError {
            cancel(ownerID: ownerID)
        } catch {
            fail(requestID: request.id, error: error)
        }
    }

    func consumeResult(ownerID: String) {
        switch activity {
        case .completed(let activeOwnerID, _) where activeOwnerID == ownerID:
            activity = .idle
        case .failed(let activeOwnerID, _) where activeOwnerID == ownerID:
            activity = .idle
        default:
            break
        }
    }

    func cancel(ownerID: String) {
        let ownsActivity: Bool
        switch activity {
        case .authorizing(let activeOwnerID), .recognizing(let activeOwnerID),
             .completed(let activeOwnerID, _), .failed(let activeOwnerID, _):
            ownsActivity = activeOwnerID == ownerID
        case .idle:
            ownsActivity = false
        }
        guard ownsActivity else { return }
        clearResources(cancelRecognition: true)
        activity = .idle
    }

    func sceneDidBecomeActive() {
        sceneIsActive = true
    }

    func sceneDidBecomeInactive() {
        sceneIsActive = false
        if case .recognizing = activity, let requestID = activeRequest?.id {
            fail(requestID: requestID, error: RuntimeSpeechError.leftForeground)
        }
    }

    func sceneDidEnterBackground() {
        sceneIsActive = false
        switch activity {
        case .authorizing, .recognizing:
            if let requestID = activeRequest?.id {
                fail(requestID: requestID, error: RuntimeSpeechError.leftForeground)
            }
        case .completed(let ownerID, _):
            cancel(ownerID: ownerID)
        case .idle, .failed:
            break
        }
    }
}

private extension RuntimeSpeechHost {
    func authorizationStatus() async -> SFSpeechRecognizerAuthorizationStatus {
        let status = SFSpeechRecognizer.authorizationStatus()
        guard status == .notDetermined else { return status }
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { newStatus in
                continuation.resume(returning: newStatus)
            }
        }
    }

    func waitForActiveScene(requestID: UUID) async throws {
        while !sceneIsActive {
            guard activeRequest?.id == requestID else { throw CancellationError() }
            try await Task.sleep(for: .milliseconds(50))
        }
    }

    func startRecognition(
        request: RuntimeSpeechRequest,
        ownerID: String,
        fileURL: URL,
        recognizer: SFSpeechRecognizer
    ) {
        let speechRequest = RuntimeSpeechRequestFactory.make(fileURL: fileURL)
        activity = .recognizing(ownerID: ownerID)
        let task = recognizer.recognitionTask(with: speechRequest) { [weak self] result, error in
            let transcript = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal == true
            let hasError = error != nil
            Task { @MainActor [weak self] in
                self?.receiveResult(
                    requestID: request.id,
                    transcript: transcript,
                    isFinal: isFinal,
                    hasError: hasError
                )
            }
        }
        if activeRequest?.id == request.id {
            recognitionTask = task
            startTimeout(requestID: request.id)
        } else {
            task.cancel()
        }
    }

    func makeRecognizer(localeIdentifier: String) throws -> SFSpeechRecognizer {
        let supportedLocales = SFSpeechRecognizer.supportedLocales()
        let recognizer: SFSpeechRecognizer?
        if localeIdentifier.isEmpty {
            recognizer = SFSpeechRecognizer()
        } else {
            let requestedLocale = Locale(identifier: localeIdentifier)
            guard RuntimeSpeechLocaleResolver.isSupported(
                requestedLocale,
                among: supportedLocales
            ) else {
                throw RuntimeSpeechError.unsupportedLocale
            }
            recognizer = SFSpeechRecognizer(locale: requestedLocale)
        }
        guard let recognizer,
              RuntimeSpeechLocaleResolver.accepts(
                requestedIdentifier: localeIdentifier,
                actual: recognizer.locale,
                supportedLocales: supportedLocales
              ) else {
            throw RuntimeSpeechError.unsupportedLocale
        }
        return recognizer
    }

    func startTimeout(requestID: UUID) {
        timeoutTask?.cancel()
        timeoutTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .seconds(75))
            } catch {
                return
            }
            self?.fail(requestID: requestID, error: RuntimeSpeechError.timedOut)
        }
    }

    func receiveResult(
        requestID: UUID,
        transcript: String?,
        isFinal: Bool,
        hasError: Bool
    ) {
        guard activeRequest?.id == requestID else { return }
        if isFinal {
            let normalized = RuntimeSpeechTranscriptNormalizer.normalize(transcript ?? "")
            guard !normalized.isEmpty else {
                fail(requestID: requestID, error: RuntimeSpeechError.emptyTranscript)
                return
            }
            let ownerID = activeRequest?.ownerID ?? ""
            clearResources(cancelRecognition: true)
            activity = .completed(ownerID: ownerID, transcript: normalized)
        } else if hasError {
            fail(requestID: requestID, error: RuntimeSpeechError.recognitionFailed)
        }
    }

    func fail(requestID: UUID, error: Error) {
        guard activeRequest?.id == requestID else { return }
        let ownerID = activeRequest?.ownerID ?? ""
        clearResources(cancelRecognition: true)
        let message = (error as? LocalizedError)?.errorDescription
            ?? RuntimeSpeechError.recognitionFailed.localizedDescription
        activity = .failed(ownerID: ownerID, message: message)
    }

    func clearResources(cancelRecognition: Bool) {
        activeRequest = nil
        timeoutTask?.cancel()
        timeoutTask = nil
        let task = recognitionTask
        recognitionTask = nil
        recognizer = nil
        if cancelRecognition { task?.cancel() }
    }

}

enum RuntimeSpeechTranscriptNormalizer {
    static func normalize(_ value: String) -> String {
        let characters = value.trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(RuntimeSpeechHost.maximumTranscriptLength)
        var result = ""
        var byteCount = 0
        result.reserveCapacity(characters.count)
        for character in characters {
            let text = String(character)
            guard byteCount + text.utf8.count <= RuntimeSpeechHost.maximumTranscriptBytes else { break }
            result.append(character)
            byteCount += text.utf8.count
        }
        return result
    }
}

enum RuntimeSpeechLocaleResolver {
    static func accepts(
        requestedIdentifier: String,
        actual: Locale,
        supportedLocales: Set<Locale>
    ) -> Bool {
        guard isSupported(actual, among: supportedLocales) else { return false }
        if requestedIdentifier.isEmpty { return true }
        return key(actual) == key(Locale(identifier: requestedIdentifier))
    }

    static func isSupported(_ locale: Locale, among supportedLocales: Set<Locale>) -> Bool {
        let supportedKeys = Set(supportedLocales.map(key))
        return supportedKeys.contains(key(locale))
    }

    private static func key(_ locale: Locale) -> String {
        locale.identifier.replacingOccurrences(of: "_", with: "-").lowercased()
    }
}

enum RuntimeSpeechRequestFactory {
    static func make(fileURL: URL) -> SFSpeechURLRecognitionRequest {
        let request = SFSpeechURLRecognitionRequest(url: fileURL)
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = false
        request.addsPunctuation = true
        request.taskHint = .dictation
        return request
    }
}

enum RuntimeSpeechError: LocalizedError, Equatable {
    case permissionDenied
    case missingRecording
    case unsupportedLocale
    case recognizerUnavailable
    case onDeviceRecognitionUnavailable
    case emptyTranscript
    case recognitionFailed
    case timedOut
    case leftForeground

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "Speech Recognition access was not granted. You can change it in Settings."
        case .missingRecording:
            "Record a voice note before creating a transcript."
        case .unsupportedLocale:
            "This speech language is not supported on this device."
        case .recognizerUnavailable:
            "Speech recognition is temporarily unavailable."
        case .onDeviceRecognitionUnavailable:
            "On-device recognition is unavailable for this language. No network fallback was used."
        case .emptyTranscript:
            "No speech was recognized in this voice note."
        case .recognitionFailed:
            "This voice note could not be transcribed on this device."
        case .timedOut:
            "On-device transcription took too long and was cancelled."
        case .leftForeground:
            "On-device transcription stopped when MakeYour left the foreground."
        }
    }
}
