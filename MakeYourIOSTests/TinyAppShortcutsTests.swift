import AppIntents
import XCTest
@testable import MakeYourIOS

@MainActor
final class TinyAppShortcutsTests: XCTestCase {
    func testOptInMarkerDerivesExactCapabilityAndReviewedContract() {
        let document = SampleDocuments.shortcutShelf

        XCTAssertEqual(
            AppCapabilityResolver.requiredCapabilities(for: document),
            [.localStorage, .shortcutsOpenTinyApp]
        )
        XCTAssertTrue(TinyAppShortcutEligibility.isEligible(document))
        XCTAssertNoThrow(try AppDocumentValidator().validate(document))

        let metadata = CapabilityRegistry.metadata(for: .shortcutsOpenTinyApp)
        XCTAssertEqual(metadata.category, .automation)
        XCTAssertEqual(metadata.privacyRisk, .moderate)
        XCTAssertEqual(metadata.availability, .systemMediated)
        XCTAssertTrue(metadata.requiresExplicitUserAction)
        XCTAssertTrue(metadata.hostEnforcedSummary.contains("stable IDs, names, and safe icons"))
        XCTAssertTrue(metadata.frameworkOrPermissionNote?.contains("local device authentication") == true)
    }

    func testMarkerRejectsBehaviorAndDuplicateExposure() {
        var actionDocument = SampleDocuments.shortcutShelf
        actionDocument.pages[0].nodes[1].action = RuntimeAction(
            type: .navigate,
            target: "home",
            value: ""
        )

        var eventDocument = SampleDocuments.shortcutShelf
        eventDocument.pages[0].nodes[1].events = [RuntimeEvent(trigger: .appear, steps: [])]

        var duplicateDocument = SampleDocuments.shortcutShelf
        duplicateDocument.pages[0].nodes.append(ComponentNode(
            id: "another-shortcut",
            kind: .shortcutAccess,
            title: "Another shortcut"
        ))

        for document in [actionDocument, eventDocument, duplicateDocument] {
            XCTAssertThrowsError(try AppDocumentValidator().validate(document)) {
                XCTAssertEqual(
                    $0 as? AppDocumentValidationError,
                    .invalidComponentConfiguration(.shortcutAccess)
                )
            }
            XCTAssertFalse(TinyAppShortcutEligibility.isEligible(document))
        }
    }

    func testCatalogReturnsOnlyValidOptInProjectsWithBoundedSafeMetadata() throws {
        let (directory, archiveURL) = makeArchiveURL()
        defer { try? FileManager.default.removeItem(at: directory) }

        let newestID = UUID()
        var unsafeSymbolDocument = SampleDocuments.shortcutShelf
        unsafeSymbolDocument.name = "Newest Shelf"
        unsafeSymbolDocument.symbol = "unsafe.custom.symbol"

        var invalidDocument = SampleDocuments.shortcutShelf
        invalidDocument.pages[0].nodes[1].value = "hidden behavior"

        let archive = WorkspaceArchive(
            projects: [
                WorkspaceProject(
                    id: UUID(),
                    document: SampleDocuments.blank,
                    updatedAt: Date(timeIntervalSince1970: 300)
                ),
                WorkspaceProject(
                    id: newestID,
                    document: unsafeSymbolDocument,
                    updatedAt: Date(timeIntervalSince1970: 400)
                ),
                WorkspaceProject(
                    id: UUID(),
                    document: invalidDocument,
                    updatedAt: Date(timeIntervalSince1970: 500)
                ),
                WorkspaceProject(
                    id: newestID,
                    document: SampleDocuments.shortcutShelf,
                    updatedAt: Date(timeIntervalSince1970: 100)
                )
            ],
            selectedProjectID: nil
        )
        try write(archive, to: archiveURL)

        let entities = try TinyAppShortcutCatalog(fileURL: archiveURL).loadEntities()

        XCTAssertEqual(entities, [
            TinyAppEntity(
                id: newestID,
                name: "Newest Shelf",
                symbolName: "square.grid.2x2.fill"
            )
        ])
    }

    func testEntityQueryPreservesRequestedOrderAndSearchesCaseInsensitively() async throws {
        let (directory, archiveURL) = makeArchiveURL()
        defer { try? FileManager.default.removeItem(at: directory) }
        let alphaID = UUID()
        let betaID = UUID()
        var alpha = SampleDocuments.shortcutShelf
        alpha.name = "Alpha Notes"
        var beta = SampleDocuments.shortcutShelf
        beta.name = "BETA Notes"
        try write(
            WorkspaceArchive(
                projects: [
                    WorkspaceProject(id: alphaID, document: alpha),
                    WorkspaceProject(id: betaID, document: beta)
                ],
                selectedProjectID: nil
            ),
            to: archiveURL
        )
        let query = TinyAppEntityQuery(catalog: TinyAppShortcutCatalog(fileURL: archiveURL))

        let resolved = try await query.entities(for: [betaID, UUID(), alphaID])
        let matching = try await query.entities(matching: "notes")

        XCTAssertEqual(resolved.map(\.id), [betaID, alphaID])
        XCTAssertEqual(Set(matching.map(\.id)), [alphaID, betaID])
    }

    func testSuggestionsAreBoundedAndMissingCatalogDoesNotWrite() async throws {
        let (directory, archiveURL) = makeArchiveURL()
        defer { try? FileManager.default.removeItem(at: directory) }
        let projects = (0..<105).map { index -> WorkspaceProject in
            var document = SampleDocuments.shortcutShelf
            document.name = "Shelf \(index)"
            return WorkspaceProject(
                id: UUID(),
                document: document,
                updatedAt: Date(timeIntervalSince1970: TimeInterval(index))
            )
        }
        try write(WorkspaceArchive(projects: projects, selectedProjectID: nil), to: archiveURL)

        let query = TinyAppEntityQuery(catalog: TinyAppShortcutCatalog(fileURL: archiveURL))
        let suggestions = try await query.suggestedEntities()
        XCTAssertEqual(
            suggestions.count,
            TinyAppShortcutCatalog.maximumSuggestedEntities
        )

        let missingURL = directory.appendingPathComponent("missing.json")
        XCTAssertEqual(try TinyAppShortcutCatalog(fileURL: missingURL).loadEntities(), [])
        XCTAssertFalse(FileManager.default.fileExists(atPath: missingURL.path))
    }

    func testCorruptCatalogFailsWithoutOverwritingSource() throws {
        let (directory, archiveURL) = makeArchiveURL()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let original = Data("not-json".utf8)
        try original.write(to: archiveURL)

        XCTAssertThrowsError(try TinyAppShortcutCatalog(fileURL: archiveURL).loadEntities()) {
            XCTAssertEqual($0 as? TinyAppShortcutCatalogError, .invalidArchive)
        }
        XCTAssertEqual(try Data(contentsOf: archiveURL), original)
    }

    func testRouterUsesUniqueTokensAndConsumesOnlyTheMatchingRequest() {
        let router = TinyAppIntentRouter.shared
        if let pending = router.pendingRequest {
            router.consume(requestID: pending.id)
        }
        let projectID = UUID()

        router.requestOpen(projectID: projectID)
        let first = router.pendingRequest
        router.requestOpen(projectID: projectID)
        let second = router.pendingRequest
        router.consume(requestID: first?.id ?? UUID())

        XCTAssertEqual(first?.projectID, projectID)
        XCTAssertEqual(second?.projectID, projectID)
        XCTAssertNotEqual(first?.id, second?.id)
        XCTAssertEqual(router.pendingRequest, second)

        if let second {
            router.consume(requestID: second.id)
        }
        XCTAssertNil(router.pendingRequest)
    }

    func testDuplicatingTinyAppDoesNotDuplicateShortcutsExposure() throws {
        let (directory, archiveURL) = makeArchiveURL()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = WorkspaceStore(fileURL: archiveURL, seedSamples: false)
        let sourceID = store.createProject(document: SampleDocuments.shortcutShelf)

        let copyID = try XCTUnwrap(store.duplicate(sourceID))
        let source = try XCTUnwrap(store.projects.first(where: { $0.id == sourceID }))
        let copy = try XCTUnwrap(store.projects.first(where: { $0.id == copyID }))

        XCTAssertTrue(TinyAppShortcutEligibility.isEligible(source.document))
        XCTAssertFalse(copy.document.pages.flatMap(\.nodes).contains { $0.kind == .shortcutAccess })
        XCTAssertFalse(copy.document.capabilities.contains(.shortcutsOpenTinyApp))
        XCTAssertNoThrow(try AppDocumentValidator().validate(copy.document))
    }

    func testCompiledIntentRequiresForegroundAuthentication() {
        XCTAssertTrue(OpenTinyAppIntent.openAppWhenRun)
        XCTAssertEqual(
            OpenTinyAppIntent.authenticationPolicy,
            .requiresLocalDeviceAuthentication
        )
    }

    private func makeArchiveURL() -> (directory: URL, archive: URL) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("TinyAppShortcutsTests-\(UUID().uuidString)", isDirectory: true)
        return (directory, directory.appendingPathComponent("projects.json"))
    }

    private func write(_ archive: WorkspaceArchive, to fileURL: URL) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(archive).write(to: fileURL, options: .atomic)
    }
}
