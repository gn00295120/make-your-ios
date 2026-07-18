import XCTest
@testable import MakeYourIOS

final class MarketDataClientTests: XCTestCase {
    func testQuoteRequestUsesOnlyFixedTwelveDataHost() throws {
        let request = try MarketDataClient.makeQuoteRequest(
            symbol: " aapl ",
            apiKey: "test-provider-key"
        )
        let url = try XCTUnwrap(request.url)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map {
            ($0.name, $0.value)
        })

        XCTAssertEqual(url.scheme, "https")
        XCTAssertEqual(url.host, "api.twelvedata.com")
        XCTAssertEqual(url.path, "/quote")
        XCTAssertEqual(query["symbol"]!, "AAPL")
        XCTAssertEqual(query["apikey"]!, "test-provider-key")
    }

    func testHistoryRequestMapsRangeToBoundedDailyOutput() throws {
        let request = try MarketDataClient.makeHistoryRequest(
            symbol: "MSFT",
            range: .threeMonths,
            apiKey: "owned-key"
        )
        let components = try XCTUnwrap(
            URLComponents(url: XCTUnwrap(request.url), resolvingAgainstBaseURL: false)
        )
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map {
            ($0.name, $0.value)
        })

        XCTAssertEqual(request.url?.host, "api.twelvedata.com")
        XCTAssertEqual(request.url?.path, "/time_series")
        XCTAssertEqual(query["interval"]!, "1day")
        XCTAssertEqual(query["outputsize"]!, "96")
        XCTAssertEqual(query["order"]!, "ASC")
        XCTAssertEqual(query["timezone"]!, "UTC")
    }

    func testAAPLUsesDemoButOtherSymbolsRequireOwnedKey() throws {
        XCTAssertEqual(
            try MarketDataClient.resolvedAPIKey(symbol: "AAPL", storedAPIKey: nil),
            "demo"
        )
        XCTAssertEqual(
            try MarketDataClient.resolvedAPIKey(symbol: "MSFT", storedAPIKey: " private-key "),
            "private-key"
        )
        XCTAssertThrowsError(
            try MarketDataClient.resolvedAPIKey(symbol: "MSFT", storedAPIKey: nil)
        ) { error in
            XCTAssertEqual(error as? MarketDataError, .apiKeyRequired(symbol: "MSFT"))
        }
    }

    func testQuoteDecoderNormalizesNumbersAndProviderTimestamp() throws {
        let data = Data(
            """
            {
              "symbol":"AAPL",
              "name":"Apple Inc",
              "exchange":"NASDAQ",
              "currency":"USD",
              "timestamp":1784284200,
              "close":"214.75",
              "previous_close":"210.00",
              "change":"4.75",
              "percent_change":"2.2619"
            }
            """.utf8
        )
        let fetchedAt = Date(timeIntervalSince1970: 1_800_000_000)

        let quote = try MarketDataClient.decodeQuote(data, fetchedAt: fetchedAt)

        XCTAssertEqual(quote.symbol, "AAPL")
        XCTAssertEqual(quote.price, 214.75)
        XCTAssertEqual(quote.change, 4.75)
        XCTAssertEqual(quote.percentChange, 2.2619)
        XCTAssertEqual(quote.asOf, Date(timeIntervalSince1970: 1_784_284_200))
        XCTAssertEqual(quote.fetchedAt, fetchedAt)
    }

    func testHistoryDecoderSortsAndDropsInvalidRows() throws {
        let data = Data(
            """
            {
              "meta":{"symbol":"AAPL"},
              "values":[
                {"datetime":"2026-07-17","close":"214.75"},
                {"datetime":"bad-date","close":"999"},
                {"datetime":"2026-07-15","close":"210.00"}
              ],
              "status":"ok"
            }
            """.utf8
        )

        let history = try MarketDataClient.decodeHistory(
            data,
            symbol: "AAPL",
            range: .oneWeek
        )

        XCTAssertEqual(history.symbol, "AAPL")
        XCTAssertEqual(history.points.map(\.close), [210, 214.75])
        XCTAssertLessThan(history.points[0].timestamp, history.points[1].timestamp)
    }

    func testPercentChangeHandlesPositiveNegativeAndZeroBaseline() {
        XCTAssertEqual(MarketMath.percentChange(current: 110, previous: 100), 10, accuracy: 0.0001)
        XCTAssertEqual(MarketMath.percentChange(current: 90, previous: 100), -10, accuracy: 0.0001)
        XCTAssertEqual(MarketMath.percentChange(current: 100, previous: 0), 0)
    }
}
