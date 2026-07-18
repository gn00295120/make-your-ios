import Foundation

extension GeneratedAppPayload {
    func makeVoiceNote(_ voiceNote: VoiceNote?) -> RuntimeVoiceNoteSpec {
        let requestedLabel = voiceNote?.recordButtonLabel
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let label = requestedLabel.isEmpty ? "Record voice note" : requestedLabel
        return RuntimeVoiceNoteSpec(
            maximumDurationSeconds: min(max(voiceNote?.maximumDurationSeconds ?? 60, 5), 60),
            recordButtonLabel: String(label.prefix(60))
        )
    }
}
