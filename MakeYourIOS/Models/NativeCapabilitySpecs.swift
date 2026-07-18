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

struct RuntimeVoiceNoteSpec: Codable, Hashable, Sendable {
    var maximumDurationSeconds: Int
    var recordButtonLabel: String
}

struct RuntimeSpeechTranscriptSpec: Codable, Hashable, Sendable {
    var sourceBinding: String
    var localeIdentifier: String
    var buttonLabel: String
}

enum RuntimeSpeechLocale {
    static func isValid(_ value: String) -> Bool {
        guard value.count <= 35, value.utf8.count <= 35 else { return false }
        if value.isEmpty { return true }
        guard value.count >= 2,
              value.first != "-", value.first != "_",
              value.last != "-", value.last != "_",
              !value.contains("--"), !value.contains("__") else { return false }
        return value.unicodeScalars.allSatisfy { scalar in
            scalar.isASCII
                && (CharacterSet.alphanumerics.contains(scalar) || scalar == "-" || scalar == "_")
        }
    }

    static func normalized(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValid(trimmed) else { return "" }
        return trimmed.replacingOccurrences(of: "_", with: "-")
    }
}

enum RuntimeDocumentFormat: String, Codable, CaseIterable, Hashable, Sendable {
    case plainText
    case json
    case csv
}
