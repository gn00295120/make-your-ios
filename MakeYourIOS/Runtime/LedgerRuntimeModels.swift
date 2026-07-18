import Foundation

struct LedgerRuntimeEntry: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var title: String
    var note: String
    var amount: Double
    var type: LedgerEntryType
    var category: String
    var date: Date
}

struct LedgerSummary: Equatable, Sendable {
    var income: Double
    var expenses: Double
    var balance: Double
    var expensesByCategory: [String: Double]
}

enum LedgerCalculator {
    static func summary(for entries: [LedgerRuntimeEntry]) -> LedgerSummary {
        let income = entries
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
        let expenses = entries
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
        let expensesByCategory = entries
            .filter { $0.type == .expense }
            .reduce(into: [String: Double]()) { totals, entry in
                totals[entry.category, default: 0] += entry.amount
            }
        return LedgerSummary(
            income: income,
            expenses: expenses,
            balance: income - expenses,
            expensesByCategory: expensesByCategory
        )
    }

    static func entries(
        _ entries: [LedgerRuntimeEntry],
        for period: LedgerPeriod,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [LedgerRuntimeEntry] {
        switch period {
        case .allTime:
            entries
        case .currentMonth:
            entries.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        }
    }
}

enum LedgerDateCodec {
    static func parse(_ value: String, calendar: Calendar = Calendar(identifier: .gregorian)) -> Date? {
        let parts = value.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            return nil
        }
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
    }
}
