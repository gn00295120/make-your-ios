import Foundation

extension GeneratedAppPayload {
    struct Theme: Decodable {
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

    struct Palette: Decodable {
        var primaryHex: String
        var secondaryHex: String
        var accentHex: String
        var canvasLightHex: String
        var canvasDarkHex: String
        var surfaceLightHex: String
        var surfaceDarkHex: String
    }

    struct PageDesign: Decodable {
        var layout: String
        var showsNavigationTitle: Bool
        var navigationStyle: String
    }

    struct Page: Decodable {
        var id: String
        var title: String
        var nodes: [Node]
        var presentation: PageDesign
    }

    struct Logic: Decodable {
        var state: [StateDefinition]
    }

    struct StateDefinition: Decodable {
        var key: String
        var type: String
        var persistence: String
        var initialValue: String
    }

    struct Event: Decodable {
        var trigger: String
        var steps: [Step]
        var intervalSeconds: Int?

        init(trigger: String, steps: [Step], intervalSeconds: Int? = nil) {
            self.trigger = trigger
            self.steps = steps
            self.intervalSeconds = intervalSeconds
        }
    }

    struct Step: Decodable {
        var kind: String
        var target: String
        var expression: Expression
        var condition: Condition?
    }

    struct Expression: Decodable {
        var operation: String
        var operands: [Operand]
    }

    struct Operand: Decodable {
        var source: String
        var value: String
    }

    struct Condition: Decodable {
        var lhs: Operand
        var comparison: String
        var rhs: Operand
    }

    struct Control: Decodable {
        var kind: String
        var minimum: Double
        var maximum: Double
        var step: Double
        var unit: String
    }

    struct NodeDesign: Decodable {
        var surface: String
        var span: String
        var alignment: String
        var emphasis: String
        var variant: String
    }

    struct Image: Decodable {
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

    struct Collection: Decodable {
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

    struct LiveData: Decodable {
        var resource: String
        var primaryValue: String
        var initialSymbols: [String]
        var allowsPrimarySelection: Bool
        var allowsItemEditing: Bool
        var allowsThresholds: Bool
    }

    struct NewsFeed: Decodable {
        var sources: [String]
        var topics: [String]
        var allowsTopicEditing: Bool
        var allowsBookmarks: Bool
        var maximumItems: Int
    }

    struct MarketWatch: Decodable {
        var provider: String
        var initialSymbols: [String]
        var allowsSymbolEditing: Bool
        var showsChart: Bool
        var range: String
    }

    struct Ledger: Decodable {
        var currencyCode: String
        var categories: [String]
        var period: String
        var monthlyBudget: Double
        var allowsIncome: Bool
        var initialEntries: [LedgerEntry]
    }

    struct LedgerEntry: Decodable {
        var title: String
        var note: String
        var amount: Double
        var type: String
        var category: String
        var date: String
    }

    struct Game: Decodable {
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

    struct DeviceInput: Decodable {
        var kind: String
        var buttonLabel: String
        var resultLabel: String
        var allowsRepeat: Bool
    }

    struct Map: Decodable {
        var mode: String
        var query: String
        var latitude: Double
        var longitude: Double
        var spanMeters: Double
        var allowsSearch: Bool
        var allowsDirections: Bool
    }

    struct CalendarEvent: Decodable {
        var eventTitle: String
        var notes: String
        var location: String
        var startOffsetMinutes: Int
        var durationMinutes: Int
        var allowsEditing: Bool
    }

    struct DocumentExport: Decodable {
        var fileName: String
        var format: String
        var contentTemplate: String
        var buttonLabel: String
    }

    struct Node: Decodable {
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
    }

    struct Item: Decodable {
        var id: String
        var title: String
        var subtitle: String
        var value: String
        var symbol: String
        var isComplete: Bool
    }

    struct Action: Decodable {
        var type: String
        var target: String
        var value: String
    }

    struct StateEntry: Decodable {
        var key: String
        var value: String
    }
}
