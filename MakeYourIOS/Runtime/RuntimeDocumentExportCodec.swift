import Foundation
import UniformTypeIdentifiers

enum RuntimeDocumentExportCodec {
    static func contentType(for format: RuntimeDocumentFormat) -> UTType {
        switch format {
        case .plainText: .plainText
        case .json: .json
        case .csv: .commaSeparatedText
        }
    }

    static func normalizedFileName(_ value: String, format: RuntimeDocumentFormat) -> String {
        let requested = (value as NSString).deletingPathExtension
        let allowed = CharacterSet.alphanumerics.union(.whitespaces).union(
            CharacterSet(charactersIn: "-_()")
        )
        let scalars = requested.unicodeScalars.filter { allowed.contains($0) }
        let base = String(String.UnicodeScalarView(scalars))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let safeBase = base.isEmpty ? "Tiny App Export" : String(base.prefix(64))
        return "\(safeBase).\(fileExtension(for: format))"
    }

    static func validatedContent(_ value: String, format: RuntimeDocumentFormat) throws -> String {
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              value.count <= 2_000,
              value.utf8.count <= 8_192 else {
            throw RuntimeDocumentExportError.invalidContent
        }
        guard format == .json else { return value }
        guard let data = value.data(using: .utf8) else {
            throw RuntimeDocumentExportError.invalidContent
        }
        _ = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        return value
    }

    private static func fileExtension(for format: RuntimeDocumentFormat) -> String {
        switch format {
        case .plainText: "txt"
        case .json: "json"
        case .csv: "csv"
        }
    }
}

private enum RuntimeDocumentExportError: Error {
    case invalidContent
}
