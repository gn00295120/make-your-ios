// swiftlint:disable file_length
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
    var logic: RuntimeLogic?
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
        logic: RuntimeLogic? = nil,
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
        self.logic = logic
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
    var valueBinding: String?
    var events: [RuntimeEvent]?
    var control: RuntimeControlSpec?
    var presentation: ComponentPresentation?
    var image: ImageSpec?
    var collection: RecordCollectionSpec?
    var liveData: LiveDataListSpec?
    var newsFeed: NewsFeedSpec?
    var marketWatch: MarketWatchSpec?
    var ledger: LedgerSpec?
    var game: GameSpec?
    var deviceInput: DeviceInputSpec?

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
        valueBinding: String? = nil,
        events: [RuntimeEvent]? = nil,
        control: RuntimeControlSpec? = nil,
        presentation: ComponentPresentation? = nil,
        image: ImageSpec? = nil,
        collection: RecordCollectionSpec? = nil,
        liveData: LiveDataListSpec? = nil,
        newsFeed: NewsFeedSpec? = nil,
        marketWatch: MarketWatchSpec? = nil,
        ledger: LedgerSpec? = nil,
        game: GameSpec? = nil,
        deviceInput: DeviceInputSpec? = nil
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
        self.valueBinding = valueBinding
        self.events = events
        self.control = control
        self.presentation = presentation
        self.image = image
        self.collection = collection
        self.liveData = liveData
        self.newsFeed = newsFeed
        self.marketWatch = marketWatch
        self.ledger = ledger
        self.game = game
        self.deviceInput = deviceInput
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
    case newsFeed
    case marketWatch
    case ledger
    case game
    case deviceInput
    case control
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

struct NewsFeedSpec: Codable, Hashable, Sendable {
    var sources: [NewsSourceKind]
    var topics: [String]
    var allowsTopicEditing: Bool
    var allowsBookmarks: Bool
    var maximumItems: Int
}

enum NewsSourceKind: String, Codable, CaseIterable, Hashable, Sendable {
    case bbcWorld
    case bbcTechnology
    case nprNews
}

struct MarketWatchSpec: Codable, Hashable, Sendable {
    var provider: MarketDataProviderKind
    var initialSymbols: [String]
    var allowsSymbolEditing: Bool
    var showsChart: Bool
    var range: MarketRange
}

enum MarketDataProviderKind: String, Codable, CaseIterable, Hashable, Sendable {
    case twelveData
}

enum MarketRange: String, Codable, CaseIterable, Hashable, Sendable {
    case oneWeek
    case oneMonth
    case threeMonths
}

struct LedgerSpec: Codable, Hashable, Sendable {
    var currencyCode: String
    var categories: [String]
    var period: LedgerPeriod
    var monthlyBudget: Double
    var allowsIncome: Bool
    var initialEntries: [LedgerSeedEntry]
}

struct LedgerSeedEntry: Codable, Hashable, Sendable {
    var title: String
    var note: String
    var amount: Double
    var type: LedgerEntryType
    var category: String
    var date: String
}

enum LedgerEntryType: String, Codable, CaseIterable, Hashable, Sendable {
    case income
    case expense
}

enum LedgerPeriod: String, Codable, CaseIterable, Hashable, Sendable {
    case currentMonth
    case allTime
}

struct GameSpec: Codable, Hashable, Sendable {
    var kind: GameKind
    var difficulty: GameDifficulty
    var palette: GamePalette
    var targetScore: Int
    var levelSeed: Int
    var playerName: String
    var collectibleName: String
    var haptics: Bool
    var program: TinyGameProgram?
}

enum GameKind: String, Codable, CaseIterable, Hashable, Sendable {
    case snake
    case platformer
    case custom
}

enum GameDifficulty: String, Codable, CaseIterable, Hashable, Sendable {
    case relaxed
    case standard
    case fast
}

enum GamePalette: String, Codable, CaseIterable, Hashable, Sendable {
    case forest
    case neon
    case sky
    case candy
}

struct DeviceInputSpec: Codable, Hashable, Sendable {
    var kind: DeviceInputKind
    var buttonLabel: String
    var resultLabel: String
    var allowsRepeat: Bool
}

enum DeviceInputKind: String, Codable, CaseIterable, Hashable, Sendable {
    case cameraPhoto
    case qrCode
    case barcode
    case text
    case currentLocation
    case contact
    case documentText
    case pedometer
    case shareText
    case copyText
    case haptic

    var requiresPhotoCapture: Bool { self == .cameraPhoto }

    var requiresScanner: Bool {
        switch self {
        case .qrCode, .barcode, .text: true
        default: false
        }
    }

    var requiredCapability: AppCapability {
        switch self {
        case .cameraPhoto: .cameraCapture
        case .qrCode, .barcode, .text: .codeScanner
        case .currentLocation: .currentLocation
        case .contact: .contactPicker
        case .documentText: .documentPicker
        case .pedometer: .pedometer
        case .shareText: .shareSheet
        case .copyText: .clipboardWrite
        case .haptic: .haptics
        }
    }
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
