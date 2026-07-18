import XCTest
@testable import MakeYourIOS

final class VoiceNoteCapabilityTests: XCTestCase {
    func testVoiceNotePassesValidationWithExactLeastPrivilegeSet() {
        let node = ComponentNode(
            id: "voice",
            kind: .voiceNote,
            title: "Quick thought",
            binding: "quick-thought",
            voiceNote: validVoiceNoteSpec()
        )
        let document = makeDocument(node: node)

        XCTAssertEqual(
            AppCapabilityResolver.requiredCapabilities(for: document.pages),
            Set([.localStorage, .microphoneRecordLocal])
        )
        XCTAssertNoThrow(try AppDocumentValidator().validate(document))
    }

    func testVoiceNoteRejectsMissingBindingInvalidDurationAndBlankLabel() {
        let missingBinding = ComponentNode(
            id: "voice-missing-binding",
            kind: .voiceNote,
            binding: "",
            voiceNote: validVoiceNoteSpec()
        )
        var tooShort = missingBinding
        tooShort.id = "voice-too-short"
        tooShort.binding = "voice-short"
        tooShort.voiceNote?.maximumDurationSeconds = 4
        var tooLong = missingBinding
        tooLong.id = "voice-too-long"
        tooLong.binding = "voice-long"
        tooLong.voiceNote?.maximumDurationSeconds = 61
        var blankLabel = missingBinding
        blankLabel.id = "voice-blank-label"
        blankLabel.binding = "voice-label"
        blankLabel.voiceNote?.recordButtonLabel = " \n "

        for (index, node) in [missingBinding, tooShort, tooLong, blankLabel].enumerated() {
            assertInvalid(node, caseIndex: index)
        }
    }

    func testVoiceNoteRegistryIsForegroundLocalAndPermissionGated() {
        let entry = CapabilityRegistry.metadata(for: .microphoneRecordLocal)

        XCTAssertEqual(entry.category, .media)
        XCTAssertEqual(entry.privacyRisk, .high)
        XCTAssertEqual(entry.availability, .permissionGated)
        XCTAssertTrue(entry.requiresExplicitUserAction)
        XCTAssertTrue(entry.hostEnforcedSummary.contains("visible tap"))
        XCTAssertTrue(entry.hostEnforcedSummary.contains("never uploaded"))
        XCTAssertTrue(entry.hostEnforcedSummary.contains("background"))
        XCTAssertTrue(entry.frameworkOrPermissionNote?.contains("NSMicrophoneUsageDescription") == true)
    }

    private func assertInvalid(
        _ node: ComponentNode,
        caseIndex: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(
            try AppDocumentValidator().validate(makeDocument(node: node)),
            "case \(caseIndex)",
            file: file,
            line: line
        ) {
            XCTAssertEqual(
                $0 as? AppDocumentValidationError,
                .invalidComponentConfiguration(.voiceNote),
                file: file,
                line: line
            )
        }
    }

    private func makeDocument(node: ComponentNode) -> AppDocument {
        AppDocument(
            name: "Voice note test",
            summary: "A least-privilege voice recording fixture",
            symbol: "mic.fill",
            tint: .indigo,
            startPageID: "home",
            capabilities: [.localStorage, .microphoneRecordLocal],
            pages: [AppPage(id: "home", title: "Home", nodes: [node])]
        )
    }

    private func validVoiceNoteSpec() -> RuntimeVoiceNoteSpec {
        RuntimeVoiceNoteSpec(
            maximumDurationSeconds: 30,
            recordButtonLabel: "Record thought"
        )
    }
}
