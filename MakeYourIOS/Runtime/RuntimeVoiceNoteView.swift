import SwiftUI

struct RuntimeVoiceNoteView: View {
    let projectID: UUID
    let node: ComponentNode
    let audioHost: RuntimeAudioHost
    let speechHost: RuntimeSpeechHost

    @Environment(LocalAssetStore.self) private var assetStore
    @Environment(\.runtimeDesign) private var design
    @State private var hasRecording = false
    @State private var statusMessage: String?
    @State private var isPersisting = false
    @State private var isRequestingRecording = false
    @State private var recordingRequestTask: Task<Void, Never>?

    private var spec: RuntimeVoiceNoteSpec {
        node.voiceNote ?? RuntimeVoiceNoteSpec(
            maximumDurationSeconds: 60,
            recordButtonLabel: "Record voice note"
        )
    }

    private var ownerID: String {
        "\(projectID.uuidString.lowercased()).\(node.id)"
    }

    private var activity: VoiceActivity {
        switch audioHost.activity {
        case .recording(let activeOwnerID) where activeOwnerID == ownerID:
            .recording
        case .playing(let activeOwnerID) where activeOwnerID == ownerID:
            .playing
        case .paused(let activeOwnerID) where activeOwnerID == ownerID:
            .paused
        case .idle:
            .idle
        default:
            .otherAudio
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            status
            controls
            privacyBoundary
            if let statusMessage {
                Text(statusMessage)
                    .font(design.captionFont)
                    .foregroundStyle(
                        statusMessage.hasPrefix("Voice note saved") ? Color.secondary : Color.red
                    )
                    .accessibilityIdentifier("runtime.voice.\(node.id).status")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task { refreshRecordingState() }
        .onChange(of: audioHost.completedRecording?.id) { _, _ in
            persistAutomaticRecordingIfNeeded()
        }
        .onDisappear {
            recordingRequestTask?.cancel()
            recordingRequestTask = nil
            isRequestingRecording = false
            audioHost.cancelPendingRecording(ownerID: ownerID)
            finishRecordingIfNeeded()
            audioHost.stopPlayback(ownerID: ownerID)
        }
        .accessibilityIdentifier("runtime.node.\(node.id)")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(node.title, systemImage: node.symbol.isEmpty ? "mic.fill" : node.symbol)
                .font(design.bodyFont.weight(.semibold))
            if !node.subtitle.isEmpty {
                Text(node.subtitle)
                    .font(design.captionFont)
                    .foregroundStyle(design.secondaryForeground)
            }
        }
    }

    @ViewBuilder
    private var status: some View {
        switch activity {
        case .recording:
            progress(
                label: "Recording",
                value: audioHost.elapsedSeconds,
                total: TimeInterval(spec.maximumDurationSeconds),
                symbol: "record.circle.fill"
            )
        case .playing:
            progress(
                label: "Playing",
                value: audioHost.elapsedSeconds,
                total: audioHost.durationSeconds,
                symbol: "speaker.wave.2.fill"
            )
        case .paused:
            progress(
                label: "Paused",
                value: audioHost.elapsedSeconds,
                total: audioHost.durationSeconds,
                symbol: "pause.circle.fill"
            )
        case .idle, .otherAudio:
            Label(
                hasRecording ? "Voice note saved on this iPhone" : "No voice note yet",
                systemImage: hasRecording ? "checkmark.circle.fill" : "waveform"
            )
            .font(design.captionFont.weight(.medium))
            .foregroundStyle(design.secondaryForeground)
        }
    }

    private func progress(
        label: String,
        value: TimeInterval,
        total: TimeInterval,
        symbol: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(label, systemImage: symbol)
                Spacer()
                Text("\(formattedTime(value)) / \(formattedTime(total))")
                    .monospacedDigit()
            }
            .font(design.captionFont.weight(.semibold))
            ProgressView(value: min(value, max(total, 0)), total: max(total, 1))
        }
    }

    @ViewBuilder
    private var controls: some View {
        if activity == .recording {
            Button(role: .destructive) {
                finishRecordingIfNeeded()
            } label: {
                Label("Stop recording", systemImage: "stop.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .frame(minHeight: 44)
            .accessibilityIdentifier("runtime.voice.\(node.id).stop-recording")
        } else {
            Button {
                startRecording()
            } label: {
                Label(spec.recordButtonLabel, systemImage: "mic.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .frame(minHeight: 44)
            .disabled(
                activity == .otherAudio || isPersisting || isRequestingRecording
                    || speechHost.isProcessing
            )
            .accessibilityIdentifier("runtime.voice.\(node.id).record")

            if hasRecording {
                playbackControls
            }
        }
    }

    private var playbackControls: some View {
        HStack(spacing: 8) {
            Button {
                togglePlayback()
            } label: {
                Label(playbackLabel, systemImage: playbackSymbol)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .frame(minHeight: 44)
            .disabled(activity == .otherAudio || isPersisting || speechHost.isProcessing)
            .accessibilityIdentifier("runtime.voice.\(node.id).playback")

            Button(role: .destructive) {
                deleteRecording()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .frame(minWidth: 44, minHeight: 44)
            .disabled(isPersisting || speechHost.isProcessing)
            .accessibilityLabel("Delete voice note")
            .accessibilityIdentifier("runtime.voice.\(node.id).delete")
        }
    }

    private var privacyBoundary: some View {
        Label(
            "Records only after you tap, stops at \(spec.maximumDurationSeconds) seconds, "
                + "and never uploads or records in the background.",
            systemImage: "lock.shield.fill"
        )
        .font(design.captionFont)
        .foregroundStyle(design.secondaryForeground)
    }

    private var playbackLabel: String {
        switch activity {
        case .playing: "Pause"
        case .paused: "Resume"
        default: "Play voice note"
        }
    }

    private var playbackSymbol: String {
        switch activity {
        case .playing: "pause.fill"
        default: "play.fill"
        }
    }
}

private extension RuntimeVoiceNoteView {
    private func startRecording() {
        guard !isRequestingRecording, !speechHost.isProcessing else { return }
        statusMessage = nil
        if activity == .playing || activity == .paused {
            audioHost.stopPlayback(ownerID: ownerID)
        }
        isRequestingRecording = true
        recordingRequestTask = Task { @MainActor in
            defer {
                isRequestingRecording = false
                recordingRequestTask = nil
            }
            do {
                try await audioHost.requestAndStartRecording(
                    ownerID: ownerID,
                    maximumDurationSeconds: spec.maximumDurationSeconds
                )
            } catch {
                guard !Task.isCancelled, !(error is CancellationError) else { return }
                statusMessage = error.localizedDescription
            }
        }
    }

    private func finishRecordingIfNeeded() {
        guard let fileURL = audioHost.finishRecording(ownerID: ownerID) else { return }
        persistRecording(at: fileURL)
    }

    private func persistAutomaticRecordingIfNeeded() {
        guard let completion = audioHost.completedRecording,
              completion.ownerID == ownerID else { return }
        persistRecording(at: completion.fileURL)
        audioHost.consumeRecordingCompletion(completion.id)
    }

    private func persistRecording(at fileURL: URL) {
        isPersisting = true
        defer {
            isPersisting = false
            try? FileManager.default.removeItem(at: fileURL)
        }
        do {
            let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
            try assetStore.saveVoiceRecordingData(
                data,
                projectID: projectID,
                binding: node.binding
            )
            hasRecording = true
            statusMessage = "Voice note saved locally."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func togglePlayback() {
        guard !speechHost.isProcessing else { return }
        statusMessage = nil
        do {
            switch activity {
            case .playing:
                audioHost.pausePlayback(ownerID: ownerID)
            case .paused:
                try audioHost.resumePlayback(ownerID: ownerID)
            default:
                guard let fileURL = assetStore.voiceRecordingURL(
                    projectID: projectID,
                    binding: node.binding
                ) else {
                    hasRecording = false
                    statusMessage = "The local voice note is missing."
                    return
                }
                try audioHost.startPlayback(ownerID: ownerID, fileURL: fileURL)
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func deleteRecording() {
        guard !speechHost.isProcessing else { return }
        audioHost.stopPlayback(ownerID: ownerID)
        do {
            try assetStore.deleteVoiceRecording(projectID: projectID, binding: node.binding)
            hasRecording = false
            statusMessage = nil
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func refreshRecordingState() {
        hasRecording = assetStore.hasVoiceRecording(
            projectID: projectID,
            binding: node.binding
        )
    }

    private func formattedTime(_ seconds: TimeInterval) -> String {
        let value = max(0, Int(seconds.rounded(.down)))
        return String(format: "%d:%02d", value / 60, value % 60)
    }
}

private enum VoiceActivity: Equatable {
    case idle
    case recording
    case playing
    case paused
    case otherAudio
}
