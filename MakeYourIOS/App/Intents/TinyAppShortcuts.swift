import AppIntents
import Foundation

enum TinyAppShortcutEligibility {
    static func isEligible(_ document: AppDocument) -> Bool {
        let accessNodes = document.pages.flatMap(\.nodes).filter { $0.kind == .shortcutAccess }
        guard accessNodes.count == 1,
              (try? AppDocumentValidator().validate(document)) != nil else { return false }
        return AppCapabilityResolver.requiredCapabilities(for: document)
            .contains(.shortcutsOpenTinyApp)
    }
}

struct TinyAppEntity: AppEntity, Equatable {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Tiny App"
    static let defaultQuery = TinyAppEntityQuery()

    let id: UUID
    let name: String
    let symbolName: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "MakeYour tiny app",
            image: .init(systemName: symbolName, isTemplate: true)
        )
    }
}

struct TinyAppShortcutCatalog: Sendable {
    static let maximumArchiveBytes = 16 * 1_024 * 1_024
    static let maximumSuggestedEntities = 100

    let fileURL: URL

    init(fileURL: URL = WorkspaceStore.defaultFileURL) {
        self.fileURL = fileURL
    }

    func loadEntities() throws -> [TinyAppEntity] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
        guard data.count <= Self.maximumArchiveBytes else {
            throw TinyAppShortcutCatalogError.archiveTooLarge
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let archive: WorkspaceArchive
        do {
            archive = try decoder.decode(WorkspaceArchive.self, from: data)
        } catch {
            throw TinyAppShortcutCatalogError.invalidArchive
        }

        var seen = Set<UUID>()
        return archive.projects
            .sorted(by: { $0.updatedAt > $1.updatedAt })
            .compactMap { project in
                guard seen.insert(project.id).inserted,
                      TinyAppShortcutEligibility.isEligible(project.document) else { return nil }
                let symbol = GeneratedAppPayload.allowedSymbols.contains(project.document.symbol)
                    ? project.document.symbol
                    : "square.grid.2x2.fill"
                return TinyAppEntity(id: project.id, name: project.document.name, symbolName: symbol)
            }
    }

    func entity(for id: UUID) throws -> TinyAppEntity? {
        try loadEntities().first(where: { $0.id == id })
    }
}

enum TinyAppShortcutCatalogError: LocalizedError, Equatable {
    case archiveTooLarge
    case invalidArchive

    var errorDescription: String? {
        switch self {
        case .archiveTooLarge:
            "The local tiny app catalog is too large for Shortcuts."
        case .invalidArchive:
            "The local tiny app catalog could not be read safely."
        }
    }
}

struct TinyAppEntityQuery: EntityStringQuery {
    private let catalog: TinyAppShortcutCatalog

    init() {
        catalog = TinyAppShortcutCatalog()
    }

    init(catalog: TinyAppShortcutCatalog) {
        self.catalog = catalog
    }

    func entities(for identifiers: [UUID]) async throws -> [TinyAppEntity] {
        let entities = try catalog.loadEntities()
        let byID = entities.reduce(into: [UUID: TinyAppEntity]()) { result, entity in
            result[entity.id] = entity
        }
        return identifiers.compactMap { byID[$0] }
    }

    func suggestedEntities() async throws -> [TinyAppEntity] {
        Array(try catalog.loadEntities().prefix(TinyAppShortcutCatalog.maximumSuggestedEntities))
    }

    func entities(matching string: String) async throws -> [TinyAppEntity] {
        let query = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return try await suggestedEntities() }
        return Array(try catalog.loadEntities()
            .filter { $0.name.localizedCaseInsensitiveContains(query) }
            .prefix(TinyAppShortcutCatalog.maximumSuggestedEntities))
    }
}

struct OpenTinyAppIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Tiny App"
    static let description = IntentDescription(
        "Open one explicitly enabled tiny app in MakeYour."
    )
    static let openAppWhenRun = true
    static let authenticationPolicy: IntentAuthenticationPolicy =
        .requiresLocalDeviceAuthentication

    @available(iOS 26.0, *)
    static let supportedModes: IntentModes = .foreground(.immediate)

    @Parameter(title: "Tiny App", query: TinyAppEntityQuery())
    var tinyApp: TinyAppEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$tinyApp)")
    }

    init() {}

    init(tinyApp: TinyAppEntity) {
        self.tinyApp = tinyApp
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let currentEntity = try TinyAppShortcutCatalog().entity(for: tinyApp.id) else {
            throw TinyAppShortcutIntentError.tinyAppUnavailable
        }
        await TinyAppIntentRouter.shared.requestOpen(projectID: currentEntity.id)
        return .result(dialog: "Opening \(currentEntity.name)")
    }
}

enum TinyAppShortcutIntentError: LocalizedError {
    case tinyAppUnavailable

    var errorDescription: String? {
        "This tiny app was removed or is no longer enabled for Shortcuts."
    }
}

struct TinyAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenTinyAppIntent(),
            phrases: [
                "Open a tiny app in \(.applicationName)",
                "Open \(\.$tinyApp) in \(.applicationName)"
            ],
            shortTitle: "Open Tiny App",
            systemImageName: "square.grid.2x2.fill",
            parameterPresentation: ParameterPresentation(
                for: \.$tinyApp,
                summary: Summary("Open \(\.$tinyApp)"),
                optionsCollections: {
                    OptionsCollection(
                        TinyAppEntityQuery(),
                        title: "Tiny Apps",
                        systemImageName: "square.grid.2x2.fill"
                    )
                }
            )
        )
    }

    static let shortcutTileColor: ShortcutTileColor = .purple
}
