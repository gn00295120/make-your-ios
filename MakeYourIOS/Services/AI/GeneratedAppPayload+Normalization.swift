import Foundation

extension GeneratedAppPayload {
    func normalizedDay(_ value: String) -> String {
        if value.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil {
            return value
        }
        return String(ISO8601DateFormatter().string(from: .now).prefix(10))
    }

    func nonEmpty(_ value: String?, fallback: String) -> String {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? fallback : trimmed
    }

    func safeFiniteValue(_ value: Double?) -> Double {
        guard let value, value.isFinite else { return 0 }
        return value
    }
}
