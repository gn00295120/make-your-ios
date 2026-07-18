import XCTest
@testable import MakeYourIOS

final class NativeCapabilityTests: XCTestCase {
    func testNodesPassValidationWithExactLeastPrivilegeSets() {
        let fixtures: [(node: ComponentNode, capability: AppCapability)] = [
            (
                ComponentNode(
                    id: "map",
                    kind: .map,
                    title: "Nearby coffee",
                    map: validMapSpec()
                ),
                .mapSearch
            ),
            (
                ComponentNode(
                    id: "calendar",
                    kind: .calendarEvent,
                    title: "Plan focus time",
                    calendarEvent: validCalendarEventSpec()
                ),
                .calendarWrite
            ),
            (
                ComponentNode(
                    id: "export",
                    kind: .documentExport,
                    title: "Export notes",
                    documentExport: validDocumentExportSpec()
                ),
                .documentExport
            )
        ]

        for fixture in fixtures {
            let document = makeDocument(node: fixture.node, capability: fixture.capability)

            XCTAssertEqual(
                AppCapabilityResolver.requiredCapabilities(for: document.pages),
                Set([.localStorage, fixture.capability]),
                fixture.node.kind.rawValue
            )
            XCTAssertNoThrow(
                try AppDocumentValidator().validate(document),
                fixture.node.kind.rawValue
            )
        }
    }

    func testMapRejectsInvalidCoordinatesSearchQueryAndSpan() {
        var invalidSpecs: [RuntimeMapSpec] = []

        var invalidLatitude = validMapSpec()
        invalidLatitude.latitude = 90.01
        invalidSpecs.append(invalidLatitude)

        var invalidLongitude = validMapSpec()
        invalidLongitude.longitude = -180.01
        invalidSpecs.append(invalidLongitude)

        var missingSearchQuery = validMapSpec()
        missingSearchQuery.query = "  \n"
        invalidSpecs.append(missingSearchQuery)

        var undersizedSpan = validMapSpec()
        undersizedSpan.spanMeters = 249
        invalidSpecs.append(undersizedSpan)

        var oversizedSpan = validMapSpec()
        oversizedSpan.spanMeters = 100_001
        invalidSpecs.append(oversizedSpan)

        for (index, spec) in invalidSpecs.enumerated() {
            let node = ComponentNode(id: "map-\(index)", kind: .map, map: spec)
            assertInvalid(node, capability: .mapSearch, kind: .map, caseIndex: index)
        }
    }

    func testCalendarEventRejectsBlankTitleAndOutOfRangeDuration() {
        var invalidSpecs: [RuntimeCalendarEventSpec] = []

        var blankTitle = validCalendarEventSpec()
        blankTitle.eventTitle = " \n "
        invalidSpecs.append(blankTitle)

        var tooShort = validCalendarEventSpec()
        tooShort.durationMinutes = 4
        invalidSpecs.append(tooShort)

        var tooLong = validCalendarEventSpec()
        tooLong.durationMinutes = 1_441
        invalidSpecs.append(tooLong)

        for (index, spec) in invalidSpecs.enumerated() {
            let node = ComponentNode(
                id: "calendar-\(index)",
                kind: .calendarEvent,
                calendarEvent: spec
            )
            assertInvalid(node, capability: .calendarWrite, kind: .calendarEvent, caseIndex: index)
        }
    }

    func testDocumentExportRejectsUnsafeFilenameAndEmptyContent() {
        var invalidSpecs: [RuntimeDocumentExportSpec] = []

        var traversalFilename = validDocumentExportSpec()
        traversalFilename.fileName = "../private/notes.txt"
        invalidSpecs.append(traversalFilename)

        var windowsPathFilename = validDocumentExportSpec()
        windowsPathFilename.fileName = "private\\notes.txt"
        invalidSpecs.append(windowsPathFilename)

        var emptyContent = validDocumentExportSpec()
        emptyContent.contentTemplate = " \n "
        invalidSpecs.append(emptyContent)

        for (index, spec) in invalidSpecs.enumerated() {
            let node = ComponentNode(
                id: "export-\(index)",
                kind: .documentExport,
                documentExport: spec
            )
            assertInvalid(
                node,
                capability: .documentExport,
                kind: .documentExport,
                caseIndex: index
            )
        }
    }

    func testMapRegistryUsesOnlyTheReviewedMapKitProvider() {
        let entry = CapabilityRegistry.metadata(for: .mapSearch)

        XCTAssertEqual(entry.category, .location)
        XCTAssertEqual(entry.availability, .fixedProvider)
        XCTAssertFalse(entry.requiresExplicitUserAction)
        XCTAssertTrue(entry.hostEnforcedSummary.contains("Apple Maps"))
        XCTAssertTrue(entry.hostEnforcedSummary.contains("arbitrary map providers"))
        XCTAssertTrue(entry.frameworkOrPermissionNote?.contains("MapKit") == true)
        XCTAssertTrue(entry.frameworkOrPermissionNote?.contains("no location permission") == true)
    }

    func testCalendarRegistryIsWriteOnlyPermissionGatedAndUserConfirmed() {
        let entry = CapabilityRegistry.metadata(for: .calendarWrite)

        XCTAssertEqual(entry.category, .calendar)
        XCTAssertEqual(entry.privacyRisk, .high)
        XCTAssertEqual(entry.availability, .permissionGated)
        XCTAssertTrue(entry.requiresExplicitUserAction)
        XCTAssertTrue(entry.hostEnforcedSummary.contains("visible review and confirmation"))
        XCTAssertTrue(entry.hostEnforcedSummary.contains("cannot enumerate"))
        XCTAssertTrue(entry.frameworkOrPermissionNote?.contains("write-only") == true)
        XCTAssertTrue(
            entry.frameworkOrPermissionNote?.contains(
                "NSCalendarsWriteOnlyAccessUsageDescription"
            ) == true
        )
    }

    func testDocumentExportRegistryIsSystemMediated() {
        let entry = CapabilityRegistry.metadata(for: .documentExport)

        XCTAssertEqual(entry.category, .files)
        XCTAssertEqual(entry.availability, .systemMediated)
        XCTAssertTrue(entry.requiresExplicitUserAction)
        XCTAssertTrue(entry.hostEnforcedSummary.contains("Apple's save panel"))
        XCTAssertTrue(entry.hostEnforcedSummary.contains("cannot choose a destination"))
        XCTAssertTrue(entry.frameworkOrPermissionNote?.contains("fileExporter") == true)
        XCTAssertTrue(entry.frameworkOrPermissionNote?.contains("no permission prompt") == true)
    }

    func testDocumentExportCodecNormalizesExtensionAndRejectsInvalidJSON() throws {
        XCTAssertEqual(
            RuntimeDocumentExportCodec.normalizedFileName("../Focus:Report.csv", format: .json),
            "FocusReport.json"
        )
        XCTAssertEqual(
            RuntimeDocumentExportCodec.normalizedFileName("旅行摘要", format: .plainText),
            "旅行摘要.txt"
        )
        XCTAssertNoThrow(
            try RuntimeDocumentExportCodec.validatedContent(
                #"{"status":"ready"}"#,
                format: .json
            )
        )
        XCTAssertThrowsError(
            try RuntimeDocumentExportCodec.validatedContent("{not-json}", format: .json)
        )
    }

    private func assertInvalid(
        _ node: ComponentNode,
        capability: AppCapability,
        kind: ComponentKind,
        caseIndex: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let document = makeDocument(node: node, capability: capability)

        XCTAssertThrowsError(
            try AppDocumentValidator().validate(document),
            "case \(caseIndex)",
            file: file,
            line: line
        ) {
            XCTAssertEqual(
                $0 as? AppDocumentValidationError,
                .invalidComponentConfiguration(kind),
                file: file,
                line: line
            )
        }
    }

    private func makeDocument(
        node: ComponentNode,
        capability: AppCapability
    ) -> AppDocument {
        AppDocument(
            name: "Native capability test",
            summary: "A least-privilege native capability fixture",
            symbol: "square.grid.2x2",
            tint: .indigo,
            startPageID: "home",
            capabilities: [.localStorage, capability],
            pages: [AppPage(id: "home", title: "Home", nodes: [node])]
        )
    }

    private func validMapSpec() -> RuntimeMapSpec {
        RuntimeMapSpec(
            mode: .placeSearch,
            query: "coffee",
            latitude: 25.033,
            longitude: 121.5654,
            spanMeters: 5_000,
            allowsSearch: true,
            allowsDirections: true
        )
    }

    private func validCalendarEventSpec() -> RuntimeCalendarEventSpec {
        RuntimeCalendarEventSpec(
            eventTitle: "Focus session",
            notes: "Review before saving",
            location: "Studio",
            startOffsetMinutes: 30,
            durationMinutes: 45,
            allowsEditing: true
        )
    }

    private func validDocumentExportSpec() -> RuntimeDocumentExportSpec {
        RuntimeDocumentExportSpec(
            fileName: "focus-notes.txt",
            format: .plainText,
            contentTemplate: "Today: {{focus}}",
            buttonLabel: "Review and export"
        )
    }

}
