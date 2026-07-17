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
    }

    struct PageDesign: Decodable {
        var layout: String
        var showsNavigationTitle: Bool
    }

    struct Page: Decodable {
        var id: String
        var title: String
        var nodes: [Node]
        var presentation: PageDesign
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
        var presentation: NodeDesign
        var image: Image
        var collection: Collection?
        var liveData: LiveData?
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
