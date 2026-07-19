import XCTest
@testable import MakeYourIOS

final class CurrencyCalculatorTests: XCTestCase {
    func testGeneratedCurrencyTitlesProduceAWorkingRateTable() {
        let items = [
            ComponentItem(id: "home-node-6-item-1", title: "USD", value: "1"),
            ComponentItem(id: "home-node-6-item-2", title: "TWD", value: "32.5"),
            ComponentItem(id: "home-node-6-item-3", title: "JPY", value: "150")
        ]

        let rates = CurrencyCalculator.rateTable(
            items: items,
            currencies: ["TWD", "USD", "JPY"]
        )

        XCTAssertEqual(rates, ["USD": 1, "TWD": 32.5, "JPY": 150])
        XCTAssertEqual(
            CurrencyCalculator.convert(amount: 100, from: "USD", to: "TWD", rates: rates),
            3_250,
            accuracy: 0.001
        )
    }

    func testDescriptiveCurrencyTitlesFallBackToStableItemIDs() {
        let items = [
            ComponentItem(id: "USD", title: "US Dollar", value: "1"),
            ComponentItem(id: "TWD", title: "New Taiwan Dollar", value: "32")
        ]

        XCTAssertEqual(
            CurrencyCalculator.rateTable(items: items, currencies: ["USD", "TWD"]),
            ["USD": 1, "TWD": 32]
        )
    }

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

    func testMissingRateDoesNotPretendCurrenciesAreOneToOne() {
        let result = CurrencyCalculator.convert(
            amount: 100,
            from: "USD",
            to: "TWD",
            rates: ["USD": 1]
        )

        XCTAssertEqual(result, 0)
    }
}
