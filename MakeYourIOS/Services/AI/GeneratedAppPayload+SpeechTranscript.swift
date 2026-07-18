import Foundation

extension GeneratedAppPayload {
    func makeSpeechTranscript(
        _ speechTranscript: SpeechTranscript?
    ) -> RuntimeSpeechTranscriptSpec {
        let sourceBinding = normalizedSpeechBinding(speechTranscript?.sourceBinding ?? "")
        let requestedLocale = speechTranscript?.localeIdentifier
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let locale = RuntimeSpeechLocale.normalized(requestedLocale)
        let requestedLabel = speechTranscript?.buttonLabel
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return RuntimeSpeechTranscriptSpec(
            sourceBinding: sourceBinding,
            localeIdentifier: String(locale.prefix(35)),
            buttonLabel: String(
                (requestedLabel.isEmpty ? "Review transcript" : requestedLabel).prefix(60)
            )
        )
    }

    private func normalizedSpeechBinding(_ value: String) -> String {
        let allowed = value.lowercased().unicodeScalars.map { scalar -> Character in
            CharacterSet.alphanumerics.contains(scalar) || scalar == "-"
                ? Character(String(scalar))
                : "-"
        }
        return String(String(allowed)
            .split(separator: "-", omittingEmptySubsequences: true)
            .joined(separator: "-")
            .prefix(60))
    }
}
