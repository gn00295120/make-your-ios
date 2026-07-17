import Foundation

struct ExchangeRateSnapshot: Codable, Hashable, Sendable {
    var base: String
    var asOf: String
    var fetchedAt: Date
    var rates: [String: Double]
}

struct CurrencyDescriptor: Codable, Hashable, Identifiable, Sendable {
    var code: String
    var name: String
    var symbol: String

    var id: String { code }
}

enum RateThresholdDirection: String, Codable, CaseIterable, Hashable, Sendable {
    case atOrBelow
    case atOrAbove

    var label: String {
        switch self {
        case .atOrBelow: "At or below"
        case .atOrAbove: "At or above"
        }
    }
}

enum RateThresholdEvaluator {
    static func isMet(rate: Double, target: Double, direction: RateThresholdDirection) -> Bool {
        switch direction {
        case .atOrBelow: rate <= target
        case .atOrAbove: rate >= target
        }
    }
}

private struct ExchangeRateRow: Decodable {
    var date: String
    var base: String
    var quote: String
    var rate: Double
}

private struct ExchangeCurrencyRow: Decodable {
    var code: String
    var name: String
    var symbol: String?

    enum CodingKeys: String, CodingKey {
        case code = "iso_code"
        case name
        case symbol
    }
}

private struct ExchangeAPIMessage: Decodable {
    var message: String
}

struct ExchangeRateClient: Sendable {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func latest(base: String, quotes: [String]) async throws -> ExchangeRateSnapshot {
        let request = try Self.makeRatesRequest(base: base, quotes: quotes)
        let (data, response) = try await session.data(for: request)
        try Self.validate(response: response, data: data)
        return try Self.decodeRates(data, requestedBase: base)
    }

    func currencies() async throws -> [CurrencyDescriptor] {
        let url = URL(string: "https://api.frankfurter.dev/v2/currencies")!
        let (data, response) = try await session.data(from: url)
        try Self.validate(response: response, data: data)
        let rows = try JSONDecoder().decode([ExchangeCurrencyRow].self, from: data)
        return rows.map {
            CurrencyDescriptor(
                code: $0.code.uppercased(),
                name: $0.name,
                symbol: $0.symbol ?? ""
            )
        }
        .sorted { $0.code < $1.code }
    }

    static func makeRatesRequest(base: String, quotes: [String]) throws -> URLRequest {
        let normalizedBase = base.uppercased()
        let normalizedQuotes = Set(quotes.map { $0.uppercased() })
            .subtracting([normalizedBase])
            .sorted()
        var components = URLComponents(string: "https://api.frankfurter.dev/v2/rates")!
        components.queryItems = [
            URLQueryItem(name: "base", value: normalizedBase),
            URLQueryItem(name: "quotes", value: normalizedQuotes.joined(separator: ","))
        ]
        guard let url = components.url else { throw ExchangeRateError.invalidRequest }
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.cachePolicy = .reloadRevalidatingCacheData
        return request
    }

    static func decodeRates(_ data: Data, requestedBase: String) throws -> ExchangeRateSnapshot {
        let rows = try JSONDecoder().decode([ExchangeRateRow].self, from: data)
        guard !rows.isEmpty else { throw ExchangeRateError.noRates }
        let rates = Dictionary(uniqueKeysWithValues: rows.map { ($0.quote.uppercased(), $0.rate) })
        return ExchangeRateSnapshot(
            base: requestedBase.uppercased(),
            asOf: rows.map(\.date).max() ?? "",
            fetchedAt: .now,
            rates: rates
        )
    }

    private static func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExchangeRateError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = (try? JSONDecoder().decode(ExchangeAPIMessage.self, from: data).message)
                ?? "The rates provider returned an error."
            throw ExchangeRateError.api(statusCode: httpResponse.statusCode, message: message)
        }
    }
}

enum ExchangeRateError: LocalizedError, Equatable {
    case invalidRequest
    case invalidResponse
    case noRates
    case api(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidRequest: "The currency request could not be created."
        case .invalidResponse: "The rates provider returned an invalid response."
        case .noRates: "No rates are available for this selection."
        case .api(_, let message): message
        }
    }
}
