import XCTest
@testable import MakeYourIOS

final class CurrencyCalculatorTests: XCTestCase {
    func testConvertsBetweenTwoNonBaseCurrencies() {
        let rates = ["USD": 1.0, "TWD": 32.0, "JPY": 160.0]
        let result = CurrencyCalculator.convert(
            amount: 3_200,
            from: "TWD",
            to: "JPY",
            rates: rates
        )

        XCTAssertEqual(result, 16_000, accuracy: 0.001)
    }

    func testZeroSourceRateReturnsZero() {
        let result = CurrencyCalculator.convert(
            amount: 100,
            from: "USD",
            to: "TWD",
            rates: ["USD": 0, "TWD": 32]
        )

        XCTAssertEqual(result, 0)
    }
}
