import XCTest
@testable import MakeYourIOS

final class SpeechTranscriptCapabilityTests: XCTestCase {
    func testTranscriptComposesWithVoiceNoteUsingExactCapabilities() {
        let document = makeDocument()

        XCTAssertEqual(
            AppCapabilityResolver.requiredCapabilities(for: document.pages),
            [.localStorage, .microphoneRecordLocal, .speechTranscribeOnDevice]
        )
        XCTAssertNoThrow(try AppDocumentValidator().validate(document))
    }

    func testTranscriptMayReferenceVoiceNoteOnAnotherPage() {
        var document = makeDocument()
        let voice = document.pages[0].nodes.removeFirst()
        document.pages.append(AppPage(id: "record", title: "Record", nodes: [voice]))

        XCTAssertNoThrow(try AppDocumentValidator().validate(document))
    }

    func testTranscriptRejectsInvalidSourceDestinationLocaleAndLabel() {
        var invalidDocuments: [AppDocument] = []

        var missingSource = makeDocument()
        missingSource.pages[0].nodes[1].speechTranscript?.sourceBinding = "missing-voice"
        invalidDocuments.append(missingSource)

        var sameDestination = makeDocument()
        sameDestination.pages[0].nodes[1].binding = "quick-voice"
        invalidDocuments.append(sameDestination)

        var invalidLocale = makeDocument()
        invalidLocale.pages[0].nodes[1].speechTranscript?.localeIdentifier = "en US"
        invalidDocuments.append(invalidLocale)

        var blankLabel = makeDocument()
        blankLabel.pages[0].nodes[1].speechTranscript?.buttonLabel = " \n "
        invalidDocuments.append(blankLabel)

        var noSpec = makeDocument()
        noSpec.pages[0].nodes[1].speechTranscript = nil
        invalidDocuments.append(noSpec)

        var noTextState = makeDocument()
        noTextState.logic = nil
        invalidDocuments.append(noTextState)

        for (index, document) in invalidDocuments.enumerated() {
            XCTAssertThrowsError(try AppDocumentValidator().validate(document), "case \(index)") {
                XCTAssertEqual(
                    $0 as? AppDocumentValidationError,
                    .invalidComponentConfiguration(.speechTranscript)
                )
            }
        }
    }

    func testTranscriptBindingMustBeTextAndSupportsValueChanged() {
        var valid = makeDocument()
        valid.pages[0].nodes[1].events = [RuntimeEvent(trigger: .valueChanged, steps: [])]
        XCTAssertNoThrow(try AppDocumentValidator().validate(valid))

        var invalid = valid
        invalid.logic?.state[0].type = .number
        invalid.logic?.state[0].initialValue = "0"
        XCTAssertThrowsError(try AppDocumentValidator().validate(invalid)) {
            XCTAssertEqual($0 as? AppDocumentValidationError, .invalidRuntimeLogic)
        }
    }

    func testTranscriptRegistryMakesOnDeviceNoFallbackBoundaryExplicit() {
        let entry = CapabilityRegistry.metadata(for: .speechTranscribeOnDevice)

        XCTAssertEqual(entry.category, .media)
        XCTAssertEqual(entry.privacyRisk, .high)
        XCTAssertEqual(entry.availability, .permissionGated)
        XCTAssertTrue(entry.requiresExplicitUserAction)
        XCTAssertTrue(entry.hostEnforcedSummary.contains("review"))
        XCTAssertTrue(entry.frameworkOrPermissionNote?.contains("requiresOnDeviceRecognition") == true)
        XCTAssertTrue(entry.frameworkOrPermissionNote?.contains("network fallback is unavailable") == true)
    }

    func testLocaleAndTranscriptNormalizationAreBounded() {
        XCTAssertTrue(RuntimeSpeechLocale.isValid("zh-Hant-TW"))
        XCTAssertEqual(RuntimeSpeechLocale.normalized(" zh_TW "), "zh-TW")
        XCTAssertFalse(RuntimeSpeechLocale.isValid("en US"))
        XCTAssertFalse(RuntimeSpeechLocale.isValid("中文"))
        XCTAssertFalse(RuntimeSpeechLocale.isValid(String(repeating: "a", count: 36)))

        let longText = "  " + String(repeating: "a", count: 2_050) + "  "
        XCTAssertEqual(
            RuntimeSpeechTranscriptNormalizer.normalize(longText).count,
            RuntimeSpeechHost.maximumTranscriptLength
        )
        XCTAssertEqual(RuntimeSpeechTranscriptNormalizer.normalize(" \n hello \n"), "hello")
        let complexText = String(repeating: "👨‍👩‍👧‍👦", count: 2_000)
        let normalizedComplexText = RuntimeSpeechTranscriptNormalizer.normalize(complexText)
        XCTAssertLessThanOrEqual(
            normalizedComplexText.utf8.count,
            RuntimeSpeechHost.maximumTranscriptBytes
        )
    }

    func testLocaleFallbackIsRejectedAndRecognitionRequestRequiresOnDevice() {
        let supported: Set<Locale> = [Locale(identifier: "en-US"), Locale(identifier: "zh-TW")]
        XCTAssertTrue(RuntimeSpeechLocaleResolver.accepts(
            requestedIdentifier: "en-US",
            actual: Locale(identifier: "en_US"),
            supportedLocales: supported
        ))
        XCTAssertFalse(RuntimeSpeechLocaleResolver.accepts(
            requestedIdentifier: "en-US",
            actual: Locale(identifier: "en-GB"),
            supportedLocales: supported
        ))
        XCTAssertTrue(RuntimeSpeechLocaleResolver.accepts(
            requestedIdentifier: "",
            actual: Locale(identifier: "zh-TW"),
            supportedLocales: supported
        ))

        let request = RuntimeSpeechRequestFactory.make(
            fileURL: URL(fileURLWithPath: "/tmp/local-voice-note.m4a")
        )
        XCTAssertTrue(request.requiresOnDeviceRecognition)
        XCTAssertFalse(request.shouldReportPartialResults)
    }

    private func makeDocument() -> AppDocument {
        let voice = ComponentNode(
            id: "voice",
            kind: .voiceNote,
            title: "Voice",
            binding: "quick-voice",
            voiceNote: RuntimeVoiceNoteSpec(
                maximumDurationSeconds: 30,
                recordButtonLabel: "Record"
            )
        )
        let transcript = ComponentNode(
            id: "transcript",
            kind: .speechTranscript,
            title: "Transcript",
            binding: "quick-transcript",
            speechTranscript: RuntimeSpeechTranscriptSpec(
                sourceBinding: "quick-voice",
                localeIdentifier: "zh-TW",
                buttonLabel: "Review transcript"
            )
        )
        return AppDocument(
            name: "Speech test",
            summary: "Local speech composition",
            symbol: "text.bubble.fill",
            tint: .plum,
            capabilities: [
                .localStorage, .microphoneRecordLocal, .speechTranscribeOnDevice
            ],
            logic: RuntimeLogic(state: [
                RuntimeStateDefinition(
                    key: "quick-transcript",
                    type: .text,
                    persistence: .project,
                    initialValue: ""
                )
            ]),
            pages: [AppPage(id: "home", title: "Home", nodes: [voice, transcript])]
        )
    }
}
