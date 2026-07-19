import Foundation

extension GeneratedAppPayload {
    struct Theme: Codable {
        var preset: String
        var appearance: String
        var typography: String
        var background: String
        var cornerStyle: String
        var density: String
        var defaultSurface: String
        var palette: Palette
        var typeScale: String
        var titleWeight: String
        var elevation: String
        var stroke: String
        var controlShape: String
        var motion: String
        var backgroundAssetBinding: String
    }

    struct Palette: Codable {
        var primaryHex: String
        var secondaryHex: String
        var accentHex: String
        var canvasLightHex: String
        var canvasDarkHex: String
        var surfaceLightHex: String
        var surfaceDarkHex: String
    }

    struct PageDesign: Codable {
        var layout: String
        var showsNavigationTitle: Bool
        var navigationStyle: String
    }

    struct Page: Codable {
        var id: String
        var title: String
        var nodes: [Node]
        var presentation: PageDesign
    }

    struct Logic: Codable {
        var state: [StateDefinition]
    }

    struct StateDefinition: Codable {
        var key: String
        var type: String
        var persistence: String
        var initialValue: String
    }

    struct Event: Codable {
        var trigger: String
        var steps: [Step]
        var intervalSeconds: Int?

        init(trigger: String, steps: [Step], intervalSeconds: Int? = nil) {
            self.trigger = trigger
            self.steps = steps
            self.intervalSeconds = intervalSeconds
        }
    }

    struct Step: Codable {
        var kind: String
        var target: String
        var expression: Expression
        var condition: Condition?
    }

    struct Expression: Codable {
        var operation: String
        var operands: [Operand]
    }

    struct Operand: Codable {
        var source: String
        var value: String
    }

    struct Condition: Codable {
        var lhs: Operand
        var comparison: String
        var rhs: Operand
    }

    struct Control: Codable {
        var kind: String
        var minimum: Double
        var maximum: Double
        var step: Double
        var unit: String
    }

    struct NodeDesign: Codable {
        var surface: String
        var span: String
        var alignment: String
        var emphasis: String
        var variant: String
    }

    struct Image: Codable {
        var aspect: String
        var contentMode: String
        var altText: String
        var decorative: Bool
        var allowsUserSelection: Bool
        var mediaRole: String
        var focalPoint: String
        var mask: String
        var overlay: String
    }

    struct Collection: Codable {
        var itemName: String
        var titleLabel: String
        var noteLabel: String
        var valueLabel: String
        var valueKind: String
        var valueUnit: String
        var dateLabel: String
        var dateKind: String
        var aggregate: String
        var allowsCompletion: Bool
        var allowsReminders: Bool
    }

    struct LiveData: Codable {
        var resource: String
        var primaryValue: String
        var initialSymbols: [String]
        var allowsPrimarySelection: Bool
        var allowsItemEditing: Bool
        var allowsThresholds: Bool
    }

    struct NewsFeed: Codable {
        var sources: [String]
        var topics: [String]
        var allowsTopicEditing: Bool
        var allowsBookmarks: Bool
        var maximumItems: Int
    }

    struct MarketWatch: Codable {
        var provider: String
        var initialSymbols: [String]
        var allowsSymbolEditing: Bool
        var showsChart: Bool
        var range: String
    }

    struct Ledger: Codable {
        var currencyCode: String
        var categories: [String]
        var period: String
        var monthlyBudget: Double
        var allowsIncome: Bool
        var initialEntries: [LedgerEntry]
    }

    struct LedgerEntry: Codable {
        var title: String
        var note: String
        var amount: Double
        var type: String
        var category: String
        var date: String
    }

    struct Game: Codable {
        var kind: String
        var difficulty: String
        var palette: String
        var targetScore: Int
        var levelSeed: Int
        var playerName: String
        var collectibleName: String
        var haptics: Bool
        var program: TinyGameProgram?
    }

    struct DeviceInput: Codable {
        var kind: String
        var buttonLabel: String
        var resultLabel: String
        var allowsRepeat: Bool
    }

    struct Map: Codable {
        var mode: String
        var query: String
        var latitude: Double
        var longitude: Double
        var spanMeters: Double
        var allowsSearch: Bool
        var allowsDirections: Bool
    }

    struct CalendarEvent: Codable {
        var eventTitle: String
        var notes: String
        var location: String
        var startOffsetMinutes: Int
        var durationMinutes: Int
        var allowsEditing: Bool
    }

    struct DocumentExport: Codable {
        var fileName: String
        var format: String
        var contentTemplate: String
        var buttonLabel: String
    }

    struct VoiceNote: Codable {
        var maximumDurationSeconds: Int
        var recordButtonLabel: String
    }

    struct SpeechTranscript: Codable {
        var sourceBinding: String
        var localeIdentifier: String
        var buttonLabel: String
    }

    struct Node: Codable {
        var id: String
        var kind: String
        var title: String
        var subtitle: String
        var symbol: String
        var value: String
        var placeholder: String
        var binding: String
        var options: [String]
        var items: [Item]
        var action: Action
        var valueBinding: String?
        var events: [Event]?
        var control: Control?
        var presentation: NodeDesign
        var image: Image?
        var collection: Collection?
        var liveData: LiveData?
        var newsFeed: NewsFeed?
        var marketWatch: MarketWatch?
        var ledger: Ledger?
        var game: Game?
        var deviceInput: DeviceInput?
        var map: Map?
        var calendarEvent: CalendarEvent?
        var documentExport: DocumentExport?
        var voiceNote: VoiceNote?
        var speechTranscript: SpeechTranscript?
    }

    struct Item: Codable {
        var id: String
        var title: String
        var subtitle: String
        var value: String
        var symbol: String
        var isComplete: Bool
    }

    struct Action: Codable {
        var type: String
        var target: String
        var value: String
    }

    struct StateEntry: Codable {
        var key: String
        var value: String
    }
}
