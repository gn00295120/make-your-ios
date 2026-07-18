import XCTest
@testable import MakeYourIOS

final class LedgerRuntimeTests: XCTestCase {
    func testSummaryCalculatesSignedBalanceAndCategories() {
        let entries = [
            entry(amount: 1_000, type: .income, category: "Income"),
            entry(amount: 120, type: .expense, category: "Food"),
            entry(amount: 80, type: .expense, category: "Food"),
            entry(amount: 50, type: .expense, category: "Transport")
        ]

        let summary = LedgerCalculator.summary(for: entries)

        XCTAssertEqual(summary.income, 1_000)
        XCTAssertEqual(summary.expenses, 250)
        XCTAssertEqual(summary.balance, 750)
        XCTAssertEqual(summary.expensesByCategory, ["Food": 200, "Transport": 50])
    }

    func testCurrentMonthFilterExcludesOtherMonths() throws {
        let calendar = Calendar(identifier: .gregorian)
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 7, day: 18)))
        let current = entry(date: "2026-07-02")
        let previous = entry(date: "2026-06-30")

        XCTAssertEqual(
            LedgerCalculator.entries([current, previous], for: .currentMonth, now: now, calendar: calendar),
            [current]
        )
        XCTAssertEqual(
            LedgerCalculator.entries([current, previous], for: .allTime, now: now, calendar: calendar).count,
            2
        )
    }

    private func entry(
        amount: Double = 10,
        type: LedgerEntryType = .expense,
        category: String = "Other",
        date: String = "2026-07-18"
    ) -> LedgerRuntimeEntry {
        LedgerRuntimeEntry(
            id: UUID(),
            title: "Entry",
            note: "",
            amount: amount,
            type: type,
            category: category,
            date: LedgerDateCodec.parse(date)!
        )
    }
}
