import Foundation

struct MarketQuote: Codable, Hashable, Identifiable, Sendable {
    var symbol: String
    var name: String
    var exchange: String
    var currency: String
    var price: Double
    var change: Double
    var percentChange: Double
    var asOf: Date
    var fetchedAt: Date

    var id: String { symbol }
}

struct MarketPricePoint: Codable, Hashable, Identifiable, Sendable {
    var timestamp: Date
    var close: Double

    var id: Date { timestamp }
}

struct MarketHistory: Codable, Hashable, Sendable {
    var symbol: String
    var range: MarketRange
    var points: [MarketPricePoint]
    var fetchedAt: Date
}

extension MarketRange {
    var label: String {
        switch self {
        case .oneWeek: "1W"
        case .oneMonth: "1M"
        case .threeMonths: "3M"
        }
    }

    var outputSize: Int {
        switch self {
        case .oneWeek: 8
        case .oneMonth: 32
        case .threeMonths: 96
        }
    }
}

enum MarketMath {
    static func percentChange(current: Double, previous: Double) -> Double {
        guard current.isFinite, previous.isFinite, previous != 0 else { return 0 }
        return ((current - previous) / previous) * 100
    }
}

private struct MarketQuoteEnvelope: Decodable {
    var symbol: String?
    var name: String?
    var exchange: String?
    var currency: String?
    var datetime: String?
    var timestamp: String?
    var close: String?
    var price: String?
    var previousClose: String?
    var change: String?
    var percentChange: String?
    var status: String?
    var message: String?

    enum CodingKeys: String, CodingKey {
        case symbol, name, exchange, currency, datetime, timestamp, close, price, change, status, message
        case previousClose = "previous_close"
        case percentChange = "percent_change"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        symbol = try values.decodeIfPresent(String.self, forKey: .symbol)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        exchange = try values.decodeIfPresent(String.self, forKey: .exchange)
        currency = try values.decodeIfPresent(String.self, forKey: .currency)
        datetime = try values.decodeIfPresent(String.self, forKey: .datetime)
        timestamp = try values.decodeStringIfPresent(forKey: .timestamp)
        close = try values.decodeStringIfPresent(forKey: .close)
        price = try values.decodeStringIfPresent(forKey: .price)
        previousClose = try values.decodeStringIfPresent(forKey: .previousClose)
        change = try values.decodeStringIfPresent(forKey: .change)
        percentChange = try values.decodeStringIfPresent(forKey: .percentChange)
        status = try values.decodeIfPresent(String.self, forKey: .status)
        message = try values.decodeIfPresent(String.self, forKey: .message)
    }
}

private struct MarketHistoryEnvelope: Decodable {
    struct Meta: Decodable {
        var symbol: String?
    }

    struct Value: Decodable {
        var datetime: String
        var close: String
    }

    var meta: Meta?
    var values: [Value]?
    var status: String?
    var message: String?
}

private extension KeyedDecodingContainer {
    func decodeStringIfPresent(forKey key: Key) throws -> String? {
        if let value = try? decodeIfPresent(String.self, forKey: key) { return value }
        if let value = try? decodeIfPresent(Int64.self, forKey: key) { return String(value) }
        if let value = try? decodeIfPresent(Double.self, forKey: key) { return String(value) }
        return nil
    }
}

struct MarketCredentialStore: Sendable {
    private static let account = "twelve-data-api-key"
    private let keychain: KeychainStore

    init(service: String = "com.longweiwang.makeyourios.market-data") {
        keychain = KeychainStore(service: service)
    }

    func readAPIKey() throws -> String? {
        try keychain.read(account: Self.account)
    }

    func saveAPIKey(_ value: String) throws {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (4...256).contains(trimmed.count) else {
            throw MarketDataError.invalidAPIKey
        }
        try keychain.save(trimmed, account: Self.account)
    }

    func deleteAPIKey() throws {
        try keychain.delete(account: Self.account)
    }
}

struct MarketDataClient: Sendable {
    private let session: URLSession
    private let apiKeyProvider: @Sendable () throws -> String?

    init(
        session: URLSession = .shared,
        apiKeyProvider: @escaping @Sendable () throws -> String? = {
            try MarketCredentialStore().readAPIKey()
        }
    ) {
        self.session = session
        self.apiKeyProvider = apiKeyProvider
    }

    func quote(symbol: String) async throws -> MarketQuote {
        let normalized = try Self.normalizedSymbol(symbol)
        let key = try Self.resolvedAPIKey(
            symbol: normalized,
            storedAPIKey: apiKeyProvider()
        )
        let request = try Self.makeQuoteRequest(symbol: normalized, apiKey: key)
        let (data, response) = try await session.data(for: request)
        try Self.validate(response: response, data: data, apiKey: key)
        return try Self.decodeQuote(data)
    }

    func history(symbol: String, range: MarketRange) async throws -> MarketHistory {
        let normalized = try Self.normalizedSymbol(symbol)
        let key = try Self.resolvedAPIKey(
            symbol: normalized,
            storedAPIKey: apiKeyProvider()
        )
        let request = try Self.makeHistoryRequest(symbol: normalized, range: range, apiKey: key)
        let (data, response) = try await session.data(for: request)
        try Self.validate(response: response, data: data, apiKey: key)
        return try Self.decodeHistory(data, symbol: normalized, range: range)
    }

    static func normalizedSymbol(_ value: String) throws -> String {
        let symbol = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard (1...15).contains(symbol.count),
              symbol.allSatisfy({ $0.isLetter || $0.isNumber || ".-^".contains($0) }) else {
            throw MarketDataError.invalidSymbol
        }
        return symbol
    }

    static func resolvedAPIKey(symbol: String, storedAPIKey: String?) throws -> String {
        if let storedAPIKey {
            let trimmed = storedAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        if symbol == "AAPL" { return "demo" }
        throw MarketDataError.apiKeyRequired(symbol: symbol)
    }

    static func makeQuoteRequest(symbol: String, apiKey: String) throws -> URLRequest {
        try makeRequest(
            path: "/quote",
            queryItems: [
                URLQueryItem(name: "symbol", value: normalizedSymbol(symbol)),
                URLQueryItem(name: "apikey", value: apiKey)
            ]
        )
    }

    static func makeHistoryRequest(
        symbol: String,
        range: MarketRange,
        apiKey: String
    ) throws -> URLRequest {
        try makeRequest(
            path: "/time_series",
            queryItems: [
                URLQueryItem(name: "symbol", value: normalizedSymbol(symbol)),
                URLQueryItem(name: "interval", value: "1day"),
                URLQueryItem(name: "outputsize", value: String(range.outputSize)),
                URLQueryItem(name: "order", value: "ASC"),
                URLQueryItem(name: "timezone", value: "UTC"),
                URLQueryItem(name: "apikey", value: apiKey)
            ]
        )
    }

    static func decodeQuote(_ data: Data, fetchedAt: Date = .now) throws -> MarketQuote {
        let envelope = try JSONDecoder().decode(MarketQuoteEnvelope.self, from: data)
        if envelope.status == "error" {
            throw MarketDataError.api(message: envelope.message ?? "The market provider returned an error.")
        }
        guard let symbol = envelope.symbol.flatMap({ try? normalizedSymbol($0) }),
              let price = decimal(envelope.close ?? envelope.price),
              price.isFinite,
              price >= 0 else {
            throw MarketDataError.invalidPayload
        }

        let previous = decimal(envelope.previousClose)
        let change = decimal(envelope.change) ?? previous.map { price - $0 } ?? 0
        let percent = decimal(envelope.percentChange)
            ?? previous.map { MarketMath.percentChange(current: price, previous: $0) }
            ?? 0
        let asOf = parseQuoteDate(
            datetime: envelope.datetime,
            timestamp: envelope.timestamp
        ) ?? fetchedAt

        return MarketQuote(
            symbol: symbol,
            name: envelope.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? symbol,
            exchange: envelope.exchange ?? "",
            currency: envelope.currency ?? "USD",
            price: price,
            change: change,
            percentChange: percent,
            asOf: asOf,
            fetchedAt: fetchedAt
        )
    }

    static func decodeHistory(
        _ data: Data,
        symbol: String,
        range: MarketRange,
        fetchedAt: Date = .now
    ) throws -> MarketHistory {
        let envelope = try JSONDecoder().decode(MarketHistoryEnvelope.self, from: data)
        if envelope.status == "error" {
            throw MarketDataError.api(message: envelope.message ?? "The market provider returned an error.")
        }
        let points = (envelope.values ?? []).compactMap { row -> MarketPricePoint? in
            guard let timestamp = parseDate(row.datetime),
                  let close = decimal(row.close),
                  close.isFinite,
                  close >= 0 else {
                return nil
            }
            return MarketPricePoint(timestamp: timestamp, close: close)
        }
        .sorted { $0.timestamp < $1.timestamp }
        guard !points.isEmpty else { throw MarketDataError.noHistory }

        let responseSymbol = try envelope.meta?.symbol.flatMap { try? normalizedSymbol($0) }
            ?? normalizedSymbol(symbol)
        return MarketHistory(
            symbol: responseSymbol,
            range: range,
            points: points,
            fetchedAt: fetchedAt
        )
    }

    private static func makeRequest(
        path: String,
        queryItems: [URLQueryItem]
    ) throws -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.twelvedata.com"
        components.path = path
        components.queryItems = queryItems
        guard let url = components.url else { throw MarketDataError.invalidRequest }
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        // The decoded snapshot is cached by the runtime. Avoid persisting API-key-bearing URLs.
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private static func validate(
        response: URLResponse,
        data: Data,
        apiKey: String
    ) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MarketDataError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = (try? JSONDecoder().decode(MarketQuoteEnvelope.self, from: data).message)
                ?? "The market provider returned an error."
            throw MarketDataError.api(message: redacted(message, secret: apiKey))
        }
    }

    private static func decimal(_ value: String?) -> Double? {
        guard let value else { return nil }
        return Double(value.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "%", with: ""))
    }

    private static func parseQuoteDate(datetime: String?, timestamp: String?) -> Date? {
        if let timestamp, let seconds = TimeInterval(timestamp) {
            return Date(timeIntervalSince1970: seconds)
        }
        return datetime.flatMap(parseDate)
    }

    private static func parseDate(_ value: String) -> Date? {
        let formats = ["yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd"]
        for format in formats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = format
            if let date = formatter.date(from: value) { return date }
        }
        return ISO8601DateFormatter().date(from: value)
    }

    private static func redacted(_ value: String, secret: String) -> String {
        guard !secret.isEmpty else { return value }
        return value.replacingOccurrences(of: secret, with: "••••")
    }
}

enum MarketDataError: LocalizedError, Equatable, Sendable {
    case invalidRequest
    case invalidResponse
    case invalidPayload
    case invalidSymbol
    case invalidAPIKey
    case apiKeyRequired(symbol: String)
    case noHistory
    case api(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            "The market request could not be created."
        case .invalidResponse:
            "The market provider returned an invalid response."
        case .invalidPayload:
            "The market provider returned unreadable quote data."
        case .invalidSymbol:
            "Enter a valid market symbol."
        case .invalidAPIKey:
            "Enter a valid Twelve Data API key."
        case .apiKeyRequired(let symbol):
            "Add your Twelve Data API key to load \(symbol). AAPL works with public demo data."
        case .noHistory:
            "No chart history is available for this symbol."
        case .api(let message):
            message
        }
    }
}
