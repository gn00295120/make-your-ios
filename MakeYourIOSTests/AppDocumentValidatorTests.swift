import XCTest
@testable import MakeYourIOS

final class AppDocumentValidatorTests: XCTestCase {
    func testSampleDocumentsPassValidation() throws {
        let validator = AppDocumentValidator()
        try validator.validate(SampleDocuments.quickConvert)
        try validator.validate(SampleDocuments.gentleTasks)
        try validator.validate(SampleDocuments.blank)
        try validator.validate(SampleDocuments.museJournal)
        try validator.validate(SampleDocuments.liveFXWatch)
        try validator.validate(SampleDocuments.useItFirst)
    }

    func testConverterRequiresCalculationCapability() {
        var document = SampleDocuments.quickConvert
        document.capabilities.removeAll(where: { $0 == .safeCalculation })

        XCTAssertThrowsError(try AppDocumentValidator().validate(document)) { error in
            XCTAssertEqual(
                error as? AppDocumentValidationError,
                .missingCapability(.safeCalculation)
            )
        }
    }

    func testDuplicateNodeIdentifiersAreRejected() {
        var document = SampleDocuments.blank
        let duplicate = ComponentNode(id: "duplicate", kind: .text, title: "One")
        document.pages[0].nodes = [duplicate, duplicate]

        XCTAssertThrowsError(try AppDocumentValidator().validate(document)) { error in
            XCTAssertEqual(error as? AppDocumentValidationError, .duplicateIdentifier)
        }
    }

    func testEditableImageRequiresPhotoPickerCapability() {
        var document = SampleDocuments.museJournal
        document.capabilities.removeAll(where: { $0 == .photoPicker })

        XCTAssertThrowsError(try AppDocumentValidator().validate(document)) { error in
            XCTAssertEqual(
                error as? AppDocumentValidationError,
                .missingCapability(.photoPicker)
            )
        }
    }

    func testAIAssistantRequiresAIRequestsCapability() {
        var document = SampleDocuments.museJournal
        document.capabilities.removeAll(where: { $0 == .aiRequests })

        XCTAssertThrowsError(try AppDocumentValidator().validate(document)) { error in
            XCTAssertEqual(
                error as? AppDocumentValidationError,
                .missingCapability(.aiRequests)
            )
        }
    }

    func testImageRequiresAccessibleDescription() {
        var document = SampleDocuments.museJournal
        let imageIndex = document.pages[0].nodes.firstIndex(where: { $0.kind == .image })!
        document.pages[0].nodes[imageIndex].image?.altText = ""

        XCTAssertThrowsError(try AppDocumentValidator().validate(document)) { error in
            XCTAssertEqual(
                error as? AppDocumentValidationError,
                .invalidComponentConfiguration(.image)
            )
        }
    }

    func testLiveDataListRequiresNetworkCapability() {
        var document = SampleDocuments.blank
        document.pages[0].nodes = [
            ComponentNode(
                kind: .liveDataList,
                title: "Rates",
                liveData: LiveDataListSpec(
                    resource: .exchangeRates,
                    primaryValue: "USD",
                    initialSymbols: ["TWD", "JPY"],
                    allowsPrimarySelection: true,
                    allowsItemEditing: true,
                    allowsThresholds: true
                )
            )
        ]

        XCTAssertThrowsError(try AppDocumentValidator().validate(document)) { error in
            XCTAssertEqual(error as? AppDocumentValidationError, .missingCapability(.network))
        }
    }

    func testRecordCollectionWithRemindersRequiresNotificationCapability() {
        var document = SampleDocuments.blank
        document.pages[0].nodes = [
            ComponentNode(
                kind: .recordCollection,
                title: "Subscriptions",
                collection: RecordCollectionSpec(
                    itemName: "Subscription",
                    titleLabel: "Service",
                    noteLabel: "Plan",
                    valueLabel: "Monthly cost",
                    valueKind: .currency,
                    valueUnit: "USD",
                    dateLabel: "Renews",
                    dateKind: .date,
                    aggregate: .sum,
                    allowsCompletion: false,
                    allowsReminders: true
                )
            )
        ]

        XCTAssertThrowsError(try AppDocumentValidator().validate(document)) { error in
            XCTAssertEqual(
                error as? AppDocumentValidationError,
                .missingCapability(.localNotifications)
            )
        }
    }
}
