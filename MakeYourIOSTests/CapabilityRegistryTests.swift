import XCTest
@testable import MakeYourIOS

final class CapabilityRegistryTests: XCTestCase {
    func testRegistryExhaustivelyTracksAppCapabilityOrder() {
        let entries = CapabilityRegistry.orderedMetadata

        XCTAssertEqual(entries.map(\.capability), AppCapability.allCases)
        XCTAssertEqual(Set(entries.map(\.capability)).count, entries.count)
    }

    func testEveryCapabilityHasAHostEnforcedContract() {
        for entry in CapabilityRegistry.orderedMetadata {
            XCTAssertFalse(entry.hostEnforcedSummary.isEmpty, entry.capability.rawValue)
            XCTAssertFalse(entry.hostEnforcedSummary.contains("coming soon"), entry.capability.rawValue)
        }
    }

    func testSensitiveInputsArePermissionGatedAndUserTriggered() {
        for capability in [
            AppCapability.cameraCapture,
            .codeScanner,
            .currentLocation,
            .pedometer
        ] {
            let entry = CapabilityRegistry.metadata(for: capability)

            XCTAssertEqual(entry.privacyRisk, .high)
            XCTAssertEqual(entry.availability, .permissionGated)
            XCTAssertTrue(entry.requiresExplicitUserAction)
            XCTAssertNotNil(entry.frameworkOrPermissionNote)
        }
    }

    func testPhotoPickerIsSystemMediatedInsteadOfBroadLibraryAccess() {
        let entry = CapabilityRegistry.metadata(for: .photoPicker)

        XCTAssertEqual(entry.availability, .systemMediated)
        XCTAssertTrue(entry.requiresExplicitUserAction)
        XCTAssertTrue(entry.hostEnforcedSummary.contains("explicitly chooses"))
    }

    func testSystemPickersDoNotClaimBroadDataAccess() {
        let contact = CapabilityRegistry.metadata(for: .contactPicker)
        let document = CapabilityRegistry.metadata(for: .documentPicker)

        XCTAssertEqual(contact.availability, .systemMediated)
        XCTAssertTrue(contact.requiresExplicitUserAction)
        XCTAssertTrue(contact.hostEnforcedSummary.contains("single contact"))
        XCTAssertEqual(document.availability, .systemMediated)
        XCTAssertTrue(document.requiresExplicitUserAction)
        XCTAssertTrue(document.hostEnforcedSummary.contains("one user-selected"))
    }

    func testOutputOnlyDeviceActionsRemainExplicitAndBounded() {
        let share = CapabilityRegistry.metadata(for: .shareSheet)
        let clipboard = CapabilityRegistry.metadata(for: .clipboardWrite)
        let haptics = CapabilityRegistry.metadata(for: .haptics)

        XCTAssertEqual(share.availability, .systemMediated)
        XCTAssertTrue(share.requiresExplicitUserAction)
        XCTAssertTrue(clipboard.requiresExplicitUserAction)
        XCTAssertTrue(clipboard.hostEnforcedSummary.contains("clipboard reading"))
        XCTAssertTrue(haptics.requiresExplicitUserAction)
        XCTAssertEqual(haptics.privacyRisk, .low)
    }

    func testNetworkAndAIHaveDistinctExternalBoundaries() {
        let network = CapabilityRegistry.metadata(for: .network)
        let aiRequest = CapabilityRegistry.metadata(for: .aiRequests)

        XCTAssertEqual(network.availability, .fixedProvider)
        XCTAssertTrue(network.hostEnforcedSummary.contains("arbitrary URLs"))
        XCTAssertEqual(aiRequest.availability, .credentialGated)
        XCTAssertTrue(aiRequest.requiresExplicitUserAction)
        XCTAssertTrue(aiRequest.hostEnforcedSummary.contains("reviews and confirms"))
    }

    func testRawValueLookupRejectsUnknownCapabilities() {
        XCTAssertEqual(
            CapabilityRegistry.metadata(forRawValue: AppCapability.codeScanner.rawValue),
            CapabilityRegistry.metadata(for: .codeScanner)
        )
        XCTAssertNil(CapabilityRegistry.metadata(forRawValue: "camera.backgroundCapture"))
    }
}
