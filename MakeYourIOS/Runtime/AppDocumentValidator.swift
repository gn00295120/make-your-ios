import Foundation

struct AppDocumentValidator: Sendable {
    static let maximumPages = 8
    static let maximumNodes = 120
    static let maximumItemsPerNode = 80
    static let maximumStateDefinitions = 64
    static let maximumEventsPerNode = 4
    static let maximumStepsPerEvent = 8
    static let maximumOperandsPerExpression = 8

    func validate(_ document: AppDocument) throws {
        try validateStructure(document)
        try validateLogic(document)
        try validateDesign(document)
        try validateContent(document)
        try validateCapabilities(document)
    }

    private func validateDesign(_ document: AppDocument) throws {
        if let palette = document.theme?.palette, !palette.isValid {
            throw AppDocumentValidationError.invalidVisualTheme
        }
        if let binding = document.theme?.backgroundAssetBinding {
            let trimmed = binding.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty,
                  trimmed == binding,
                  binding.count <= 120,
                  binding.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" }) else {
                throw AppDocumentValidationError.invalidVisualTheme
            }
        }
        for node in document.pages.flatMap(\.nodes) {
            let variant = node.resolvedPresentation.variant
            guard RendererCatalog.supportedVariants(for: node.kind).contains(variant) else {
                throw AppDocumentValidationError.unsupportedVariant(node.kind, variant)
            }
        }
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
        guard pageIDs.allSatisfy({ !$0.isEmpty }),
              Set(pageIDs).count == pageIDs.count else {
            throw AppDocumentValidationError.duplicateIdentifier
        }

        let nodeIDs = allNodes.map(\.id)
        guard nodeIDs.allSatisfy({ !$0.isEmpty }),
              Set(nodeIDs).count == nodeIDs.count else {
            throw AppDocumentValidationError.duplicateIdentifier
        }

        for node in allNodes {
            let itemIDs = node.items.map(\.id)
            guard itemIDs.allSatisfy({ !$0.isEmpty }),
                  Set(itemIDs).count == itemIDs.count else {
                throw AppDocumentValidationError.duplicateIdentifier
            }
        }
    }

    private func validateCapabilities(_ document: AppDocument) throws {
        let required = AppCapabilityResolver.requiredCapabilities(for: document)
        let declared = Set(document.capabilities)
        guard declared.count == document.capabilities.count else {
            throw AppDocumentValidationError.duplicateIdentifier
        }
        if let missing = required.subtracting(declared).sorted(by: { $0.rawValue < $1.rawValue }).first {
            throw AppDocumentValidationError.missingCapability(missing)
        }
        if let unnecessary = declared.subtracting(required)
            .sorted(by: { $0.rawValue < $1.rawValue })
            .first {
            throw AppDocumentValidationError.unnecessaryCapability(unnecessary)
        }
    }

    func validateActions(_ document: AppDocument) throws {
        let allNodes = document.pages.flatMap(\.nodes)
        let pageIDs = Set(document.pages.map(\.id))
        let bindingKinds: Set<ComponentKind> = [
            .textInput, .numberInput, .picker, .image, .deviceInput
        ]
        let bindings = allNodes
            .filter { bindingKinds.contains($0.kind) }
            .map(\.binding)
        guard bindings.allSatisfy({ !$0.isEmpty }), Set(bindings).count == bindings.count else {
            throw AppDocumentValidationError.duplicateBinding
        }

        try allNodes.forEach { node in
            try validateAction(node.action, pageIDs: pageIDs, bindings: bindings)
        }
    }

    private func validateAction(
        _ action: RuntimeAction,
        pageIDs: Set<String>,
        bindings: [String]
    ) throws {
        switch action.type {
        case .none:
            break
        case .navigate:
            guard pageIDs.contains(action.target) else {
                throw AppDocumentValidationError.invalidAction(action.type)
            }
        case .setValue:
            guard bindings.contains(action.target) else {
                throw AppDocumentValidationError.invalidAction(action.type)
            }
        case .showMessage:
            guard !action.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw AppDocumentValidationError.invalidAction(action.type)
            }
        case .scheduleNotification:
            guard let minutes = Int(action.target),
                  (1...10_080).contains(minutes),
                  !action.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw AppDocumentValidationError.invalidAction(action.type)
            }
        }
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
    case invalidAction(RuntimeActionType)
    case duplicateBinding
    case missingCapability(AppCapability)
    case unnecessaryCapability(AppCapability)
    case invalidVisualTheme
    case unsupportedVariant(ComponentKind, ComponentVariant)
    case invalidRuntimeLogic
    case invalidRuntimeReference(String)
    case invalidRuntimeExpression
    case runtimeLimitExceeded

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
        case .invalidAction(let action):
            "The \(action.rawValue) action points to an invalid target or value."
        case .duplicateBinding:
            "Stateful components need unique, non-empty bindings."
        case .missingCapability(let capability):
            "The app did not declare its \(capability.label) capability."
        case .unnecessaryCapability(let capability):
            "The app declares unused \(capability.label) access."
        case .invalidVisualTheme:
            "The app theme contains an invalid color or background binding."
        case .unsupportedVariant(let kind, let variant):
            "The \(kind.rawValue) component does not support the \(variant.rawValue) renderer."
        case .invalidRuntimeLogic:
            "The tiny app logic contains an invalid state, event, or control definition."
        case .invalidRuntimeReference(let key):
            "The tiny app logic refers to missing state \(key)."
        case .invalidRuntimeExpression:
            "The tiny app logic contains an invalid or incompatible expression."
        case .runtimeLimitExceeded:
            "The tiny app logic exceeds the runtime complexity limits."
        }
    }
}
