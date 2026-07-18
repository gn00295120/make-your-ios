import Foundation

struct RuntimeMapSpec: Codable, Hashable, Sendable {
    var mode: RuntimeMapMode
    var query: String
    var latitude: Double
    var longitude: Double
    var spanMeters: Double
    var allowsSearch: Bool
    var allowsDirections: Bool
}

enum RuntimeMapMode: String, Codable, CaseIterable, Hashable, Sendable {
    case coordinate
    case placeSearch
}

struct RuntimeCalendarEventSpec: Codable, Hashable, Sendable {
    var eventTitle: String
    var notes: String
    var location: String
    var startOffsetMinutes: Int
    var durationMinutes: Int
    var allowsEditing: Bool
}

struct RuntimeDocumentExportSpec: Codable, Hashable, Sendable {
    var fileName: String
    var format: RuntimeDocumentFormat
    var contentTemplate: String
    var buttonLabel: String
}

enum RuntimeDocumentFormat: String, Codable, CaseIterable, Hashable, Sendable {
    case plainText
    case json
    case csv
}
