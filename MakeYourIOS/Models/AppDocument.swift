import Foundation
import SwiftUI

struct AppDocument: Codable, Hashable, Identifiable, Sendable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int
    var id: UUID
    var name: String
    var summary: String
    var symbol: String
    var tint: AppTint
    var version: Int
    var updatedAt: Date
    var startPageID: String
    var capabilities: [AppCapability]
    var initialState: [String: String]
    var theme: AppVisualTheme?
    var pages: [AppPage]

    init(
        schemaVersion: Int = AppDocument.currentSchemaVersion,
        id: UUID = UUID(),
        name: String,
        summary: String,
        symbol: String,
        tint: AppTint,
        version: Int = 1,
        updatedAt: Date = .now,
        startPageID: String = "home",
        capabilities: [AppCapability] = [.localStorage],
        initialState: [String: String] = [:],
        theme: AppVisualTheme? = nil,
        pages: [AppPage]
    ) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.name = name
        self.summary = summary
        self.symbol = symbol
        self.tint = tint
        self.version = version
        self.updatedAt = updatedAt
        self.startPageID = startPageID
        self.capabilities = capabilities
        self.initialState = initialState
        self.theme = theme
        self.pages = pages
    }

    var resolvedTheme: AppVisualTheme {
        theme ?? .legacy
    }
}

enum AppTint: String, Codable, CaseIterable, Hashable, Sendable {
    case indigo
    case coral
    case mint
    case sky
    case amber
    case plum

    var color: Color {
        switch self {
        case .indigo: Color(red: 0.33, green: 0.29, blue: 0.94)
        case .coral: Color(red: 0.96, green: 0.36, blue: 0.36)
        case .mint: Color(red: 0.11, green: 0.68, blue: 0.53)
        case .sky: Color(red: 0.10, green: 0.57, blue: 0.93)
        case .amber: Color(red: 0.95, green: 0.58, blue: 0.13)
        case .plum: Color(red: 0.63, green: 0.28, blue: 0.78)
        }
    }
}

enum AppCapability: String, Codable, CaseIterable, Hashable, Sendable {
    case localStorage = "storage.local"
    case safeCalculation = "calculation.safe"
    case localNotifications = "notifications.scheduleLocal"
    case photoPicker = "photo.pick"
    case network = "http.request"
    case aiRequests = "ai.complete"

    var label: String {
        switch self {
        case .localStorage: "Local data"
        case .safeCalculation: "Calculations"
        case .localNotifications: "Notifications"
        case .photoPicker: "Photos"
        case .network: "Internet access"
        case .aiRequests: "AI requests"
        }
    }

    var symbol: String {
        switch self {
        case .localStorage: "externaldrive"
        case .safeCalculation: "function"
        case .localNotifications: "bell.badge"
        case .photoPicker: "photo.on.rectangle"
        case .network: "network"
        case .aiRequests: "sparkles"
        }
    }
}

struct AppPage: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var title: String
    var nodes: [ComponentNode]
    var presentation: PagePresentation?

    var resolvedPresentation: PagePresentation {
        presentation ?? .flow
    }
}

struct ComponentNode: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var kind: ComponentKind
    var title: String
    var subtitle: String
    var symbol: String
    var value: String
    var placeholder: String
    var binding: String
    var options: [String]
    var items: [ComponentItem]
    var action: RuntimeAction
    var presentation: ComponentPresentation?
    var image: ImageSpec?
    var collection: RecordCollectionSpec?
    var liveData: LiveDataListSpec?

    init(
        id: String = UUID().uuidString,
        kind: ComponentKind,
        title: String = "",
        subtitle: String = "",
        symbol: String = "",
        value: String = "",
        placeholder: String = "",
        binding: String = "",
        options: [String] = [],
        items: [ComponentItem] = [],
        action: RuntimeAction = .none,
        presentation: ComponentPresentation? = nil,
        image: ImageSpec? = nil,
        collection: RecordCollectionSpec? = nil,
        liveData: LiveDataListSpec? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.value = value
        self.placeholder = placeholder
        self.binding = binding
        self.options = options
        self.items = items
        self.action = action
        self.presentation = presentation
        self.image = image
        self.collection = collection
        self.liveData = liveData
    }

    var resolvedPresentation: ComponentPresentation {
        presentation ?? .automatic
    }
}

enum ComponentKind: String, Codable, CaseIterable, Hashable, Sendable {
    case hero
    case sectionHeader
    case text
    case metric
    case textInput
    case numberInput
    case picker
    case button
    case checklist
    case infoBanner
    case currencyConverter
    case taskList
    case image
    case aiAssistant
    case recordCollection
    case liveDataList
    case divider
}

struct RecordCollectionSpec: Codable, Hashable, Sendable {
    var itemName: String
    var titleLabel: String
    var noteLabel: String
    var valueLabel: String
    var valueKind: RecordValueKind
    var valueUnit: String
    var dateLabel: String
    var dateKind: RecordDateKind
    var aggregate: RecordAggregate
    var allowsCompletion: Bool
    var allowsReminders: Bool
}

enum RecordValueKind: String, Codable, CaseIterable, Hashable, Sendable {
    case none
    case number
    case currency
}

enum RecordDateKind: String, Codable, CaseIterable, Hashable, Sendable {
    case none
    case date
    case dateTime
}

enum RecordAggregate: String, Codable, CaseIterable, Hashable, Sendable {
    case none
    case count
    case sum
}

struct LiveDataListSpec: Codable, Hashable, Sendable {
    var resource: LiveResourceKind
    var primaryValue: String
    var initialSymbols: [String]
    var allowsPrimarySelection: Bool
    var allowsItemEditing: Bool
    var allowsThresholds: Bool
}

enum LiveResourceKind: String, Codable, CaseIterable, Hashable, Sendable {
    case exchangeRates
}

struct ComponentItem: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var title: String
    var subtitle: String
    var value: String
    var symbol: String
    var isComplete: Bool

    init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String = "",
        value: String = "",
        symbol: String = "",
        isComplete: Bool = false
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.symbol = symbol
        self.isComplete = isComplete
    }
}

struct RuntimeAction: Codable, Hashable, Sendable {
    var type: RuntimeActionType
    var target: String
    var value: String

    static let none = RuntimeAction(type: .none, target: "", value: "")
}

enum RuntimeActionType: String, Codable, CaseIterable, Hashable, Sendable {
    case none
    case navigate
    case setValue
    case showMessage
    case scheduleNotification
}
