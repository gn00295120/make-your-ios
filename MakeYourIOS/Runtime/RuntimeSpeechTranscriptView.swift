import SwiftUI

struct RuntimeSpeechTranscriptView: View {
    let projectID: UUID
    let node: ComponentNode
    @Bindable var session: RuntimeSessionState
    let audioHost: RuntimeAudioHost
    let speechHost: RuntimeSpeechHost
    let onValueChanged: () -> Void

    @Environment(LocalAssetStore.self) private var assetStore
    @Environment(\.runtimeDesign) private var design
    @State private var hasRecording = false
    @State private var requestTask: Task<Void, Never>?
    @State private var reviewTranscript = ""
    @State private var isShowingReview = false
    @State private var statusMessage: String?
    @State private var statusMessageIsError = false
    @State private var reviewErrorMessage: String?

    private var spec: RuntimeSpeechTranscriptSpec {
        node.speechTranscript ?? RuntimeSpeechTranscriptSpec(
            sourceBinding: "",
            localeIdentifier: "",
            buttonLabel: "Review transcript"
        )
    }

    private var ownerID: String {
        "\(projectID.uuidString.lowercased()).\(node.id)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            sourceStatus
            Button(action: startTranscription) {
                HStack {
                    if isWorking {
                        ProgressView()
                    } else {
                        Image(systemName: "text.bubble.fill")
                    }
                    Text(buttonTitle)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(minHeight: 44)
            .disabled(
                !hasRecording || isWorking || requestTask != nil
                    || audioHost.isInUse || isBlockedByOtherTranscript || hasPendingReview
            )
            .accessibilityIdentifier("runtime.speech.\(node.id).transcribe")

            Label(
                "Runs only after you tap, requires on-device recognition, and never falls back to the network.",
                systemImage: "lock.shield.fill"
            )
            .font(design.captionFont)
            .foregroundStyle(design.secondaryForeground)

            if let visibleMessage {
                Text(visibleMessage)
                    .font(design.captionFont)
                    .foregroundStyle(messageIsError ? Color.red : design.secondaryForeground)
                    .accessibilityIdentifier("runtime.speech.\(node.id).status")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task { refreshRecordingState() }
        .onChange(of: assetStore.revision) { _, _ in refreshRecordingState() }
        .onChange(of: speechHost.activity) { _, activity in
            handle(activity)
        }
        .onDisappear {
            requestTask?.cancel()
            requestTask = nil
            speechHost.cancel(ownerID: ownerID)
        }
        .sheet(isPresented: $isShowingReview, onDismiss: discardReview) {
            transcriptReview
        }
        .accessibilityIdentifier("runtime.node.\(node.id)")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(
                node.title.isEmpty ? "Voice transcript" : node.title,
                systemImage: node.symbol.isEmpty ? "text.bubble.fill" : node.symbol
            )
            .font(design.bodyFont.weight(.semibold))
            if !node.subtitle.isEmpty {
                Text(node.subtitle)
                    .font(design.captionFont)
                    .foregroundStyle(design.secondaryForeground)
            }
        }
    }

    private var sourceStatus: some View {
        Label(
            hasRecording ? "Local voice note ready" : "Record the linked voice note first",
            systemImage: hasRecording ? "checkmark.circle.fill" : "waveform"
        )
        .font(design.captionFont.weight(.medium))
        .foregroundStyle(design.secondaryForeground)
    }

    private var transcriptReview: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Review and correct the on-device transcript before saving it to this tiny app.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextEditor(text: $reviewTranscript)
                    .frame(minHeight: 220)
                    .padding(8)
                    .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityIdentifier("runtime.speech.\(node.id).review-editor")
                Text(
                    "\(reviewTranscript.count) / \(RuntimeSpeechHost.maximumTranscriptLength) characters"
                        + " · \(reviewTranscript.utf8.count) / "
                        + "\(RuntimeSpeechHost.maximumTranscriptBytes) bytes"
                )
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                if let reviewErrorMessage {
                    Label(reviewErrorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding()
            .navigationTitle("Review Transcript")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isShowingReview = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Use Transcript", action: useTranscript)
                        .disabled(reviewTranscript.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                            || reviewTranscript.count > RuntimeSpeechHost.maximumTranscriptLength
                            || reviewTranscript.utf8.count > RuntimeSpeechHost.maximumTranscriptBytes)
                        .accessibilityIdentifier("runtime.speech.\(node.id).use-transcript")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled(false)
    }
}

private extension RuntimeSpeechTranscriptView {
    var isWorking: Bool {
        switch speechHost.activity {
        case .authorizing(let activeOwnerID), .recognizing(let activeOwnerID):
            activeOwnerID == ownerID
        default:
            false
        }
    }

    var hasPendingReview: Bool {
        if case .completed(let activeOwnerID, _) = speechHost.activity {
            return activeOwnerID == ownerID
        }
        return false
    }

    var isBlockedByOtherTranscript: Bool {
        switch speechHost.activity {
        case .idle:
            false
        case .authorizing(let activeOwnerID), .recognizing(let activeOwnerID),
             .completed(let activeOwnerID, _), .failed(let activeOwnerID, _):
            activeOwnerID != ownerID
        }
    }

    var buttonTitle: String {
        if isWorking { return "Transcribing on device…" }
        if case .failed(let activeOwnerID, _) = speechHost.activity,
           activeOwnerID == ownerID {
            return "Try again"
        }
        return spec.buttonLabel
    }

    var visibleMessage: String? {
        if let statusMessage { return statusMessage }
        if audioHost.isInUse { return "Finish the current recording or playback first." }
        switch speechHost.activity {
        case .failed(let activeOwnerID, let message) where activeOwnerID == ownerID:
            return message
        case .authorizing(let activeOwnerID) where activeOwnerID == ownerID:
            return "Waiting for Speech Recognition permission…"
        case .recognizing(let activeOwnerID) where activeOwnerID == ownerID:
            return "Transcribing the local recording without a network fallback…"
        default:
            return nil
        }
    }

    var messageIsError: Bool {
        if statusMessage != nil { return statusMessageIsError }
        if case .failed(let activeOwnerID, _) = speechHost.activity {
            return activeOwnerID == ownerID
        }
        return false
    }

    func startTranscription() {
        guard hasRecording, !isWorking, requestTask == nil, !audioHost.isInUse,
              !isBlockedByOtherTranscript else { return }
        statusMessage = nil
        statusMessageIsError = false
        speechHost.consumeResult(ownerID: ownerID)
        guard let fileURL = assetStore.voiceRecordingURL(
            projectID: projectID,
            binding: spec.sourceBinding
        ) else {
            hasRecording = false
            statusMessage = RuntimeSpeechError.missingRecording.localizedDescription
            statusMessageIsError = true
            return
        }
        requestTask?.cancel()
        requestTask = Task { @MainActor in
            await speechHost.requestAndTranscribe(
                ownerID: ownerID,
                fileURL: fileURL,
                localeIdentifier: spec.localeIdentifier
            )
            requestTask = nil
        }
    }

    func handle(_ activity: RuntimeSpeechHost.Activity) {
        switch activity {
        case .completed(let activeOwnerID, let transcript) where activeOwnerID == ownerID:
            reviewTranscript = transcript
            reviewErrorMessage = nil
            isShowingReview = true
        case .idle where isShowingReview:
            isShowingReview = false
        default:
            break
        }
    }

    func useTranscript() {
        let transcript = String(
            reviewTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
                .prefix(RuntimeSpeechHost.maximumTranscriptLength)
        )
        guard !transcript.isEmpty else { return }
        var proposedValues = session.values
        proposedValues[node.binding] = transcript
        do {
            try session.commit(proposedValues)
            statusMessage = "Transcript saved to this tiny app."
            statusMessageIsError = false
            reviewErrorMessage = nil
            speechHost.consumeResult(ownerID: ownerID)
            isShowingReview = false
            onValueChanged()
        } catch {
            reviewErrorMessage = error.localizedDescription
        }
    }

    func discardReview() {
        reviewTranscript = ""
        reviewErrorMessage = nil
        speechHost.consumeResult(ownerID: ownerID)
    }

    func refreshRecordingState() {
        hasRecording = assetStore.hasVoiceRecording(
            projectID: projectID,
            binding: spec.sourceBinding
        )
    }
}
