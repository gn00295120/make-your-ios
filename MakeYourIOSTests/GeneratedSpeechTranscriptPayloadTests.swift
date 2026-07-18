import XCTest
@testable import MakeYourIOS

final class GeneratedSpeechTranscriptPayloadTests: XCTestCase {
    func testPayloadBuildsPairedVoiceAndOnDeviceTranscriptBlocks() throws {
        var payload = GeneratedAppPayloadTestFixtures.personalMoney()
        payload.pages[0].nodes = [voiceNode, transcriptNode]
        payload.logic = GeneratedAppPayload.Logic(state: [
            GeneratedAppPayload.StateDefinition(
                key: "transcript-binding",
                type: "text",
                persistence: "project",
                initialValue: ""
            )
        ])

        let document = payload.makeDocument(existingID: UUID(), version: 2)

        XCTAssertEqual(document.pages[0].nodes[1].speechTranscript?.sourceBinding, "voice-binding")
        XCTAssertEqual(document.pages[0].nodes[1].speechTranscript?.localeIdentifier, "zh-TW")
        XCTAssertEqual(
            Set(document.capabilities),
            [.localStorage, .microphoneRecordLocal, .speechTranscribeOnDevice]
        )
        XCTAssertNoThrow(try AppDocumentValidator().validate(document))
    }

    private var voiceNode: GeneratedAppPayload.Node {
        node(id: "voice", kind: "voiceNote", voiceNote: GeneratedAppPayload.VoiceNote(
            maximumDurationSeconds: 30,
            recordButtonLabel: "Record thought"
        ))
    }

    private var transcriptNode: GeneratedAppPayload.Node {
        node(
            id: "transcript",
            kind: "speechTranscript",
            speechTranscript: GeneratedAppPayload.SpeechTranscript(
                sourceBinding: "Voice Binding",
                localeIdentifier: "zh_TW",
                buttonLabel: "Review words"
            )
        )
    }

    private func node(
        id: String,
        kind: String,
        voiceNote: GeneratedAppPayload.VoiceNote? = nil,
        speechTranscript: GeneratedAppPayload.SpeechTranscript? = nil
    ) -> GeneratedAppPayload.Node {
        GeneratedAppPayload.Node(
            id: id,
            kind: kind,
            title: id,
            subtitle: "Generated component",
            symbol: "sparkles",
            value: "",
            placeholder: "",
            binding: "\(id)-binding",
            options: [],
            items: [],
            action: GeneratedAppPayload.Action(type: "none", target: "", value: ""),
            valueBinding: nil,
            events: nil,
            control: nil,
            presentation: GeneratedAppPayload.NodeDesign(
                surface: "card",
                span: "full",
                alignment: "leading",
                emphasis: "regular",
                variant: "automatic"
            ),
            image: nil,
            collection: nil,
            liveData: nil,
            newsFeed: nil,
            marketWatch: nil,
            ledger: nil,
            game: nil,
            deviceInput: nil,
            voiceNote: voiceNote,
            speechTranscript: speechTranscript
        )
    }
}
