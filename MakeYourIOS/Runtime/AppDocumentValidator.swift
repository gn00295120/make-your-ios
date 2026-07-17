import Foundation

struct AppDocumentValidator: Sendable {
    static let maximumPages = 8
    static let maximumNodes = 120
    static let maximumItemsPerNode = 80

    func validate(_ document: AppDocument) throws {
        try validateStructure(document)
        try validateContent(document)
        try validateCapabilities(document)
    }

    private func validateStructure(_ document: AppDocument) throws {
        guard document.schemaVersion == AppDocument.currentSchemaVersion else {
            throw AppDocumentValidationError.unsupportedSchema(document.schemaVersion)
        }

        guard !document.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              document.name.count <= 48 else {
            throw AppDocumentValidationError.invalidName
        }

        guard (1...Self.maximumPages).contains(document.pages.count) else {
            throw AppDocumentValidationError.invalidPageCount
        }

        guard document.pages.contains(where: { $0.id == document.startPageID }) else {
            throw AppDocumentValidationError.missingStartPage
        }

        let allNodes = document.pages.flatMap(\.nodes)
        guard allNodes.count <= Self.maximumNodes else {
            throw AppDocumentValidationError.tooManyNodes
        }

        let pageIDs = document.pages.map(\.id)
        guard Set(pageIDs).count == pageIDs.count else {
            throw AppDocumentValidationError.duplicateIdentifier
        }

        let nodeIDs = allNodes.map(\.id)
        guard Set(nodeIDs).count == nodeIDs.count else {
            throw AppDocumentValidationError.duplicateIdentifier
        }
    }

    private func validateContent(_ document: AppDocument) throws {
        let allNodes = document.pages.flatMap(\.nodes)
        for node in allNodes {
            guard node.title.count <= 120,
                  node.subtitle.count <= 320,
                  node.value.count <= 800,
                  node.placeholder.count <= 160,
                  node.binding.count <= 120,
                  node.items.count <= Self.maximumItemsPerNode else {
                throw AppDocumentValidationError.contentLimitExceeded
            }

            if node.kind == .image {
                guard let image = node.image,
                      !node.binding.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw AppDocumentValidationError.invalidComponentConfiguration(.image)
                }
                if !image.decorative,
                   image.altText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    throw AppDocumentValidationError.invalidComponentConfiguration(.image)
                }
            }

            if node.kind == .aiAssistant,
               node.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw AppDocumentValidationError.invalidComponentConfiguration(.aiAssistant)
            }

            if node.kind == .recordCollection {
                guard let collection = node.collection,
                      !collection.itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      !collection.titleLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      collection.itemName.count <= 40,
                      collection.titleLabel.count <= 60,
                      collection.noteLabel.count <= 60,
                      collection.valueLabel.count <= 60,
                      collection.valueUnit.count <= 12,
                      collection.dateLabel.count <= 60,
                      collection.aggregate != .sum || collection.valueKind != .none else {
                    throw AppDocumentValidationError.invalidComponentConfiguration(.recordCollection)
                }
            }

            if node.kind == .liveDataList {
                guard let liveData = node.liveData,
                      Self.isCurrencyCode(liveData.primaryValue),
                      !liveData.initialSymbols.isEmpty,
                      liveData.initialSymbols.count <= 30,
                      liveData.initialSymbols.allSatisfy(Self.isCurrencyCode),
                      !liveData.initialSymbols.contains(liveData.primaryValue.uppercased()) else {
                    throw AppDocumentValidationError.invalidComponentConfiguration(.liveDataList)
                }
            }
        }
    }

    private func validateCapabilities(_ document: AppDocument) throws {
        let allNodes = document.pages.flatMap(\.nodes)
        let nodeKinds = Set(allNodes.map(\.kind))
        if nodeKinds.contains(.currencyConverter),
           !document.capabilities.contains(.safeCalculation) {
            throw AppDocumentValidationError.missingCapability(.safeCalculation)
        }

        if nodeKinds.contains(.taskList),
           allNodes.contains(where: { $0.kind == .taskList }),
           !document.capabilities.contains(.localStorage) {
            throw AppDocumentValidationError.missingCapability(.localStorage)
        }

        if nodeKinds.contains(.taskList),
           !document.capabilities.contains(.localNotifications) {
            throw AppDocumentValidationError.missingCapability(.localNotifications)
        }

        if allNodes.contains(where: { $0.kind == .image && $0.image?.allowsUserSelection == true }),
           !document.capabilities.contains(.photoPicker) {
            throw AppDocumentValidationError.missingCapability(.photoPicker)
        }

        if nodeKinds.contains(.aiAssistant),
           !document.capabilities.contains(.aiRequests) {
            throw AppDocumentValidationError.missingCapability(.aiRequests)
        }

        if nodeKinds.contains(.recordCollection),
           !document.capabilities.contains(.localStorage) {
            throw AppDocumentValidationError.missingCapability(.localStorage)
        }

        if allNodes.contains(where: {
            $0.kind == .recordCollection && $0.collection?.allowsReminders == true
        }), !document.capabilities.contains(.localNotifications) {
            throw AppDocumentValidationError.missingCapability(.localNotifications)
        }

        if nodeKinds.contains(.liveDataList),
           !document.capabilities.contains(.localStorage) {
            throw AppDocumentValidationError.missingCapability(.localStorage)
        }

        if nodeKinds.contains(.liveDataList),
           !document.capabilities.contains(.network) {
            throw AppDocumentValidationError.missingCapability(.network)
        }

        if allNodes.contains(where: { $0.action.type == .scheduleNotification }),
           !document.capabilities.contains(.localNotifications) {
            throw AppDocumentValidationError.missingCapability(.localNotifications)
        }
    }

    private static func isCurrencyCode(_ value: String) -> Bool {
        let code = value.uppercased()
        return code.count == 3 && code.allSatisfy(\.isLetter)
    }
}

enum AppDocumentValidationError: LocalizedError, Equatable {
    case unsupportedSchema(Int)
    case invalidName
    case invalidPageCount
    case missingStartPage
    case tooManyNodes
    case duplicateIdentifier
    case contentLimitExceeded
    case invalidComponentConfiguration(ComponentKind)
    case missingCapability(AppCapability)

    var errorDescription: String? {
        switch self {
        case .unsupportedSchema(let version):
            "This app uses unsupported schema version \(version)."
        case .invalidName:
            "The app name is empty or too long."
        case .invalidPageCount:
            "An app must contain between 1 and \(AppDocumentValidator.maximumPages) pages."
        case .missingStartPage:
            "The start page does not exist."
        case .tooManyNodes:
            "The generated app contains too many UI components."
        case .duplicateIdentifier:
            "Every page and component needs a unique identifier."
        case .contentLimitExceeded:
            "Some generated content exceeds the runtime limits."
        case .invalidComponentConfiguration(let kind):
            "The \(kind.rawValue) component is missing required configuration."
        case .missingCapability(let capability):
            "The app did not declare its \(capability.label) capability."
        }
    }
}
