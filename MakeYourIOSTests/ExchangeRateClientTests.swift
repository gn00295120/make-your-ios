import XCTest
@testable import MakeYourIOS

final class ExchangeRateClientTests: XCTestCase {
    func testRatesRequestUsesFixedHostAndEncodedCurrencyFilters() throws {
        let request = try ExchangeRateClient.makeRatesRequest(
            base: "usd",
            quotes: ["twd", "JPY", "TWD"]
        )

        XCTAssertEqual(request.url?.host, "api.frankfurter.dev")
        XCTAssertEqual(request.url?.path, "/v2/rates")
        let components = try XCTUnwrap(URLComponents(url: XCTUnwrap(request.url), resolvingAgainstBaseURL: false))
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) })
        XCTAssertEqual(query["base"]!, "USD")
        XCTAssertEqual(query["quotes"]!, "JPY,TWD")
    }

    func testDecodeRatesNormalizesRowsIntoSnapshot() throws {
        let data = Data(
            """
            [
              {"date":"2026-07-16","base":"USD","quote":"TWD","rate":29.42},
              {"date":"2026-07-15","base":"USD","quote":"JPY","rate":158.16}
            ]
            """.utf8
        )

        let snapshot = try ExchangeRateClient.decodeRates(data, requestedBase: "USD")

        XCTAssertEqual(snapshot.base, "USD")
        XCTAssertEqual(snapshot.asOf, "2026-07-16")
        XCTAssertEqual(snapshot.rates["TWD"], 29.42)
        XCTAssertEqual(snapshot.rates["JPY"], 158.16)
    }

    func testThresholdEvaluatorSupportsAboveAndBelow() {
        XCTAssertTrue(RateThresholdEvaluator.isMet(rate: 29.4, target: 30, direction: .atOrBelow))
        XCTAssertFalse(RateThresholdEvaluator.isMet(rate: 30.1, target: 30, direction: .atOrBelow))
        XCTAssertTrue(RateThresholdEvaluator.isMet(rate: 30.1, target: 30, direction: .atOrAbove))
        XCTAssertFalse(RateThresholdEvaluator.isMet(rate: 29.4, target: 30, direction: .atOrAbove))
    }
}
