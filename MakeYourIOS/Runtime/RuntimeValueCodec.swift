import Foundation

enum RuntimeValueCodecError: Error, Equatable {
    case invalidDate
    case invalidList
    case invalidObject
    case collectionLimitExceeded
}

/// Canonical encoding for the bounded values stored by the declarative runtime.
/// Lists and objects intentionally contain strings only; nested arbitrary JSON is not executable state.
enum RuntimeValueCodec {
    static let maximumListItems = 64
    static let maximumObjectEntries = 64
    static let maximumCollectionItemLength = 240
    static let maximumObjectKeyLength = 60

    static func normalizedDate(_ value: String) throws -> String {
        guard let date = date(from: value) else {
            throw RuntimeValueCodecError.invalidDate
        }
        return encodedDate(date)
    }

    static func date(from value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let internetFormatter = ISO8601DateFormatter()
        internetFormatter.formatOptions = [.withInternetDateTime]
        if let date = internetFormatter.date(from: trimmed) {
            return date
        }

        let dayFormatter = DateFormatter()
        dayFormatter.calendar = Calendar(identifier: .gregorian)
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")
        dayFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dayFormatter.dateFormat = "yyyy-MM-dd"
        dayFormatter.isLenient = false
        return dayFormatter.date(from: trimmed)
    }

    static func encodedDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    static func decodedList(_ value: String) throws -> [String] {
        guard let data = value.data(using: .utf8),
              let list = try? JSONDecoder().decode([String].self, from: data),
              list.count <= maximumListItems,
              list.allSatisfy({ $0.count <= maximumCollectionItemLength }) else {
            throw RuntimeValueCodecError.invalidList
        }
        return list
    }

    static func encodedList(_ list: [String]) throws -> String {
        guard list.count <= maximumListItems,
              list.allSatisfy({ $0.count <= maximumCollectionItemLength }) else {
            throw RuntimeValueCodecError.collectionLimitExceeded
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        let data = try encoder.encode(list)
        guard let encoded = String(bytes: data, encoding: .utf8) else {
            throw RuntimeValueCodecError.invalidList
        }
        return encoded
    }

    static func normalizedList(_ value: String) throws -> String {
        try encodedList(decodedList(value))
    }

    static func decodedObject(_ value: String) throws -> [String: String] {
        guard let data = value.data(using: .utf8),
              let object = try? JSONDecoder().decode([String: String].self, from: data),
              object.count <= maximumObjectEntries,
              object.allSatisfy({ key, entryValue in
                  !key.isEmpty
                      && key.count <= maximumObjectKeyLength
                      && entryValue.count <= maximumCollectionItemLength
              }) else {
            throw RuntimeValueCodecError.invalidObject
        }
        return object
    }

    static func encodedObject(_ object: [String: String]) throws -> String {
        guard object.count <= maximumObjectEntries,
              object.allSatisfy({ key, entryValue in
                  !key.isEmpty
                      && key.count <= maximumObjectKeyLength
                      && entryValue.count <= maximumCollectionItemLength
              }) else {
            throw RuntimeValueCodecError.collectionLimitExceeded
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(object)
        guard let encoded = String(bytes: data, encoding: .utf8) else {
            throw RuntimeValueCodecError.invalidObject
        }
        return encoded
    }

    static func normalizedObject(_ value: String) throws -> String {
        try encodedObject(decodedObject(value))
    }
}
