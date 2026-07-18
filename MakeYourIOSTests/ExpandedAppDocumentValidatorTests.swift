import XCTest
@testable import MakeYourIOS

final class ExpandedAppDocumentValidatorTests: XCTestCase {
    func testExpandedCapabilitySamplesPassValidation() throws {
        for document in [
            SampleDocuments.dailyBrief,
            SampleDocuments.marketPocket,
            SampleDocuments.pocketLedger,
            SampleDocuments.skybound,
            SampleDocuments.neonSnake,
            SampleDocuments.captureKit
        ] {
            XCTAssertNoThrow(try AppDocumentValidator().validate(document), document.name)
        }
    }

    func testCapabilityResolverProducesExactLeastPrivilegeSets() {
        XCTAssertEqual(
            AppCapabilityResolver.requiredCapabilities(for: SampleDocuments.dailyBrief.pages),
            [.localStorage, .network]
        )
        XCTAssertEqual(
            AppCapabilityResolver.requiredCapabilities(for: SampleDocuments.captureKit.pages),
            [
                .calendarWrite, .cameraCapture, .clipboardWrite, .codeScanner, .contactPicker,
                .currentLocation, .documentExport, .documentPicker, .haptics, .localStorage,
                .mapSearch, .pedometer, .shareSheet
            ]
        )
        XCTAssertFalse(
            AppCapabilityResolver.requiredCapabilities(for: SampleDocuments.captureKit.pages)
                .contains(.aiRequests)
        )
    }

    func testUnusedSensitiveCapabilityIsRejected() {
        var document = SampleDocuments.neonSnake
        document.capabilities.append(.cameraCapture)

        XCTAssertThrowsError(try AppDocumentValidator().validate(document)) { error in
            XCTAssertEqual(
                error as? AppDocumentValidationError,
                .unnecessaryCapability(.cameraCapture)
            )
        }
    }

    func testEveryDeviceAbilityDerivesOnlyItsMatchingHostCapability() throws {
        for kind in DeviceInputKind.allCases {
            let node = ComponentNode(
                id: "device-\(kind.rawValue)",
                kind: .deviceInput,
                title: "Device ability",
                value: [.shareText, .copyText].contains(kind) ? "Bounded payload" : "",
                binding: "result-\(kind.rawValue)",
                deviceInput: DeviceInputSpec(
                    kind: kind,
                    buttonLabel: "Run",
                    resultLabel: "Result",
                    allowsRepeat: true
                )
            )
            let page = AppPage(id: "home", title: "Home", nodes: [node])
            let capabilities = AppCapabilityResolver.requiredCapabilities(for: [page])
            XCTAssertEqual(capabilities, [.localStorage, kind.requiredCapability], kind.rawValue)

            let document = AppDocument(
                name: "Device test",
                summary: "A host ability fixture",
                symbol: "sparkles",
                tint: .sky,
                startPageID: "home",
                capabilities: capabilities.sorted(by: { $0.rawValue < $1.rawValue }),
                pages: [page]
            )
            XCTAssertNoThrow(try AppDocumentValidator().validate(document), kind.rawValue)
        }
    }

    func testSpecializedNodeRejectsUnrelatedConfiguration() {
        var document = SampleDocuments.neonSnake
        document.pages[0].nodes[0].newsFeed = NewsFeedSpec(
            sources: [.bbcWorld],
            topics: [],
            allowsTopicEditing: true,
            allowsBookmarks: true,
            maximumItems: 10
        )

        XCTAssertThrowsError(try AppDocumentValidator().validate(document)) { error in
            XCTAssertEqual(
                error as? AppDocumentValidationError,
                .invalidComponentConfiguration(.game)
            )
        }
    }

    func testInvalidNavigationAndNotificationActionsAreRejected() {
        var navigation = SampleDocuments.blank
        navigation.pages[0].nodes.append(ComponentNode(
            id: "bad-navigation",
            kind: .button,
            title: "Open",
            action: RuntimeAction(type: .navigate, target: "missing", value: "")
        ))
        XCTAssertThrowsError(try AppDocumentValidator().validate(navigation)) { error in
            XCTAssertEqual(error as? AppDocumentValidationError, .invalidAction(.navigate))
        }

        var notification = SampleDocuments.blank
        notification.pages[0].nodes.append(ComponentNode(
            id: "bad-notification",
            kind: .button,
            title: "Remind me",
            action: RuntimeAction(type: .scheduleNotification, target: "0", value: "")
        ))
        notification.capabilities = [.localNotifications, .localStorage]
        XCTAssertThrowsError(try AppDocumentValidator().validate(notification)) { error in
            XCTAssertEqual(
                error as? AppDocumentValidationError,
                .invalidAction(.scheduleNotification)
            )
        }
    }

    func testDuplicateStatefulBindingsAreRejected() {
        var document = SampleDocuments.captureKit
        let statefulIndices = document.pages[0].nodes.indices.filter {
            document.pages[0].nodes[$0].kind == .deviceInput
        }
        guard statefulIndices.count >= 2 else {
            return XCTFail("Device Lab needs two stateful fixtures for duplicate-binding validation.")
        }
        document.pages[0].nodes[statefulIndices[1]].binding =
            document.pages[0].nodes[statefulIndices[0]].binding

        XCTAssertThrowsError(try AppDocumentValidator().validate(document)) { error in
            XCTAssertEqual(error as? AppDocumentValidationError, .duplicateBinding)
        }
    }

    func testInvalidMarketSymbolLedgerDateAndGameBoundsAreRejected() {
        var market = SampleDocuments.marketPocket
        market.pages[0].nodes[1].marketWatch?.initialSymbols = ["https://invalid"]
        XCTAssertThrowsError(try AppDocumentValidator().validate(market)) { error in
            XCTAssertEqual(
                error as? AppDocumentValidationError,
                .invalidComponentConfiguration(.marketWatch)
            )
        }

        var ledger = SampleDocuments.pocketLedger
        ledger.pages[0].nodes[0].ledger?.initialEntries[0].date = "2026-02-30"
        XCTAssertThrowsError(try AppDocumentValidator().validate(ledger)) { error in
            XCTAssertEqual(
                error as? AppDocumentValidationError,
                .invalidComponentConfiguration(.ledger)
            )
        }

        var game = SampleDocuments.neonSnake
        game.pages[0].nodes[0].game?.targetScore = 1_000
        XCTAssertThrowsError(try AppDocumentValidator().validate(game)) { error in
            XCTAssertEqual(
                error as? AppDocumentValidationError,
                .invalidComponentConfiguration(.game)
            )
        }
    }
}
