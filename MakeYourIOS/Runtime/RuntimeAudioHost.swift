@preconcurrency import AVFAudio
import Foundation
import Observation

private struct PendingRecordingRequest: Equatable {
    let id = UUID()
    let ownerID: String
}

@MainActor
@Observable
final class RuntimeAudioHost {
    struct RecordingCompletion: Identifiable, Equatable {
        let id = UUID()
        let ownerID: String
        let fileURL: URL
    }

    enum Activity: Equatable {
        case idle
        case recording(ownerID: String)
        case playing(ownerID: String)
        case paused(ownerID: String)
    }

    private(set) var activity: Activity = .idle
    private(set) var elapsedSeconds: TimeInterval = 0
    private(set) var durationSeconds: TimeInterval = 0
    private(set) var completedRecording: RecordingCompletion?

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var temporaryRecordingURL: URL?
    private var monitorTask: Task<Void, Never>?
    private var pendingRecordingRequest: PendingRecordingRequest?
    private var sceneIsActive = true

    var isInUse: Bool {
        activity != .idle || pendingRecordingRequest != nil
    }

    func requestAndStartRecording(ownerID: String, maximumDurationSeconds: Int) async throws {
        guard activity == .idle, pendingRecordingRequest == nil else {
            throw RuntimeAudioError.audioInUse
        }
        let request = PendingRecordingRequest(ownerID: ownerID)
        pendingRecordingRequest = request
        defer {
            if pendingRecordingRequest?.id == request.id {
                pendingRecordingRequest = nil
            }
        }
        let permissionGranted = await requestRecordPermission()
        guard permissionGranted else { throw RuntimeAudioError.microphonePermissionDenied }
        try Task.checkCancellation()
        try await waitForActiveScene(requestID: request.id)
        guard pendingRecordingRequest?.id == request.id, activity == .idle else {
            throw CancellationError()
        }

        let maximumDuration = min(max(maximumDurationSeconds, 5), 60)
        do {
            try startRecording(ownerID: ownerID, maximumDuration: maximumDuration)
        } catch {
            deactivateSession()
            if let temporaryRecordingURL {
                try? FileManager.default.removeItem(at: temporaryRecordingURL)
            }
            recorder = nil
            temporaryRecordingURL = nil
            activity = .idle
            if let runtimeError = error as? RuntimeAudioError { throw runtimeError }
            throw RuntimeAudioError.recordingUnavailable
        }
    }

    func finishRecording(ownerID: String) -> URL? {
        guard case .recording(let activeOwnerID) = activity,
              activeOwnerID == ownerID else { return nil }
        return finishRecordingInternal(ownerID: ownerID, publishCompletion: false)
    }

    func discardRecording(ownerID: String) {
        guard case .recording(let activeOwnerID) = activity,
              activeOwnerID == ownerID else { return }
        let url = finishRecordingInternal(ownerID: ownerID, publishCompletion: false)
        if let url { try? FileManager.default.removeItem(at: url) }
    }

    func cancelPendingRecording(ownerID: String) {
        guard pendingRecordingRequest?.ownerID == ownerID else { return }
        pendingRecordingRequest = nil
    }

    func startPlayback(ownerID: String, fileURL: URL) throws {
        guard activity == .idle, pendingRecordingRequest == nil else {
            throw RuntimeAudioError.audioInUse
        }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)
            let player = try AVAudioPlayer(contentsOf: fileURL)
            guard player.prepareToPlay(), player.play() else {
                throw RuntimeAudioError.playbackUnavailable
            }
            self.player = player
            elapsedSeconds = 0
            durationSeconds = player.duration
            activity = .playing(ownerID: ownerID)
            monitorPlayback(ownerID: ownerID)
        } catch {
            player = nil
            activity = .idle
            deactivateSession()
            if let runtimeError = error as? RuntimeAudioError { throw runtimeError }
            throw RuntimeAudioError.playbackUnavailable
        }
    }

    func pausePlayback(ownerID: String) {
        guard case .playing(let activeOwnerID) = activity,
              activeOwnerID == ownerID else { return }
        player?.pause()
        elapsedSeconds = player?.currentTime ?? elapsedSeconds
        monitorTask?.cancel()
        monitorTask = nil
        activity = .paused(ownerID: ownerID)
    }

    func resumePlayback(ownerID: String) throws {
        guard case .paused(let activeOwnerID) = activity,
              activeOwnerID == ownerID,
              let player else { return }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            guard player.play() else { throw RuntimeAudioError.playbackUnavailable }
            activity = .playing(ownerID: ownerID)
            monitorPlayback(ownerID: ownerID)
        } catch {
            stopPlayback(ownerID: ownerID)
            throw RuntimeAudioError.playbackUnavailable
        }
    }

    func stopPlayback(ownerID: String) {
        let isOwner: Bool
        switch activity {
        case .playing(let activeOwnerID), .paused(let activeOwnerID):
            isOwner = activeOwnerID == ownerID
        default:
            isOwner = false
        }
        guard isOwner else { return }
        monitorTask?.cancel()
        monitorTask = nil
        player?.stop()
        player = nil
        elapsedSeconds = 0
        durationSeconds = 0
        activity = .idle
        deactivateSession()
    }

    func sceneDidBecomeActive() {
        sceneIsActive = true
    }

    func sceneDidBecomeInactive() {
        sceneIsActive = false
        stopActiveAudioForSceneTransition()
    }

    func sceneDidEnterBackground() {
        sceneIsActive = false
        pendingRecordingRequest = nil
        stopActiveAudioForSceneTransition()
    }

    private func stopActiveAudioForSceneTransition() {
        switch activity {
        case .recording(let ownerID):
            _ = finishRecordingInternal(ownerID: ownerID, publishCompletion: true)
        case .playing(let ownerID), .paused(let ownerID):
            stopPlayback(ownerID: ownerID)
        case .idle:
            break
        }
    }

    func consumeRecordingCompletion(_ id: UUID) {
        guard completedRecording?.id == id else { return }
        completedRecording = nil
    }
}

private extension RuntimeAudioHost {
    private func requestRecordPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func waitForActiveScene(requestID: UUID) async throws {
        while !sceneIsActive {
            guard pendingRecordingRequest?.id == requestID else {
                throw CancellationError()
            }
            try await Task.sleep(for: .milliseconds(50))
        }
    }

    private func startRecording(ownerID: String, maximumDuration: Int) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.defaultToSpeaker, .allowBluetoothHFP]
        )
        try session.setActive(true)

        let fileURL = try RuntimeVoiceRecordingFiles.makeFileURL()
        temporaryRecordingURL = fileURL
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 32_000,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
        let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        RuntimeVoiceRecordingFiles.applyProtection(to: fileURL)
        guard recorder.prepareToRecord(), recorder.record() else {
            throw RuntimeAudioError.recordingUnavailable
        }

        self.recorder = recorder
        elapsedSeconds = 0
        durationSeconds = TimeInterval(maximumDuration)
        completedRecording = nil
        activity = .recording(ownerID: ownerID)
        monitorRecording(ownerID: ownerID, maximumDuration: TimeInterval(maximumDuration))
    }

    private func monitorRecording(ownerID: String, maximumDuration: TimeInterval) {
        monitorTask?.cancel()
        monitorTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .milliseconds(100))
                } catch {
                    return
                }
                guard let self,
                      case .recording(let activeOwnerID) = self.activity,
                      activeOwnerID == ownerID else { return }
                self.elapsedSeconds = min(self.recorder?.currentTime ?? 0, maximumDuration)
                if self.elapsedSeconds >= maximumDuration || self.recorder?.isRecording == false {
                    _ = self.finishRecordingInternal(
                        ownerID: ownerID,
                        publishCompletion: true
                    )
                    return
                }
            }
        }
    }

    private func monitorPlayback(ownerID: String) {
        monitorTask?.cancel()
        monitorTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .milliseconds(100))
                } catch {
                    return
                }
                guard let self,
                      case .playing(let activeOwnerID) = self.activity,
                      activeOwnerID == ownerID else { return }
                self.elapsedSeconds = self.player?.currentTime ?? 0
                if self.player?.isPlaying == false {
                    self.stopPlayback(ownerID: ownerID)
                    return
                }
            }
        }
    }

    private func finishRecordingInternal(
        ownerID: String,
        publishCompletion: Bool
    ) -> URL? {
        guard case .recording(let activeOwnerID) = activity,
              activeOwnerID == ownerID else { return nil }
        monitorTask?.cancel()
        monitorTask = nil
        recorder?.stop()
        recorder = nil
        let resultURL = temporaryRecordingURL
        temporaryRecordingURL = nil
        activity = .idle
        durationSeconds = 0
        deactivateSession()
        if publishCompletion, let resultURL {
            completedRecording = RecordingCompletion(ownerID: ownerID, fileURL: resultURL)
        }
        return resultURL
    }

    private func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }
}

enum RuntimeAudioError: LocalizedError, Equatable {
    case microphonePermissionDenied
    case recordingUnavailable
    case playbackUnavailable
    case audioInUse

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            "Microphone access was not granted. You can change it in Settings."
        case .recordingUnavailable:
            "Voice recording is unavailable on this device."
        case .playbackUnavailable:
            "This voice note could not be played."
        case .audioInUse:
            "Another voice note is already using audio."
        }
    }
}

enum RuntimeVoiceRecordingFiles {
    static let filePrefix = "makeyour-voice-"

    static func makeFileURL(
        in directory: URL? = nil,
        fileManager: FileManager = .default
    ) throws -> URL {
        let directory = directory ?? defaultDirectory(fileManager: fileManager)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        applyProtection(to: directory, fileManager: fileManager)
        return directory
            .appendingPathComponent("\(filePrefix)\(UUID().uuidString.lowercased())")
            .appendingPathExtension("m4a")
    }

    static func removeAllStagedRecordings(
        in directory: URL? = nil,
        fileManager: FileManager = .default
    ) {
        let directory = directory ?? defaultDirectory(fileManager: fileManager)
        guard let files = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else { return }
        for file in files where
            file.lastPathComponent.hasPrefix(filePrefix) && file.pathExtension == "m4a" {
            try? fileManager.removeItem(at: file)
        }
    }

    static func applyProtection(
        to url: URL,
        fileManager: FileManager = .default
    ) {
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var mutableURL = url
        try? mutableURL.setResourceValues(resourceValues)
        try? fileManager.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: url.path
        )
    }

    private static func defaultDirectory(fileManager: FileManager) -> URL {
        let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return applicationSupport
            .appendingPathComponent("MakeYour", isDirectory: true)
            .appendingPathComponent("recording-staging", isDirectory: true)
    }
}
