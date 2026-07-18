import Foundation

extension RuntimeLogicEngine {
    func numericComparison(_ comparison: RuntimeComparison, lhs: Decimal, rhs: Decimal) -> Bool {
        switch comparison {
        case .less: lhs < rhs
        case .lessOrEqual: lhs <= rhs
        case .greater: lhs > rhs
        case .greaterOrEqual: lhs >= rhs
        default: false
        }
    }

    func orderedComparison<T: Comparable>(_ comparison: RuntimeComparison, lhs: T, rhs: T) -> Bool {
        switch comparison {
        case .less: lhs < rhs
        case .lessOrEqual: lhs <= rhs
        case .greater: lhs > rhs
        case .greaterOrEqual: lhs >= rhs
        default: false
        }
    }

    func numericResult(
        operation: RuntimeExpressionOperation,
        operands: [String]
    ) throws -> String {
        let numbers = try operands.map(decimal)
        let requiresExactlyTwo = [.subtract, .divide].contains(operation)
        guard requiresExactlyTwo ? numbers.count == 2 : numbers.count >= 2 else {
            throw RuntimeLogicExecutionError.invalidExpression(operation)
        }

        var result = numbers[0]
        for number in numbers.dropFirst() {
            switch operation {
            case .add:
                result = try calculate(result, number, using: NSDecimalAdd)
            case .subtract:
                result = try calculate(result, number, using: NSDecimalSubtract)
            case .multiply:
                result = try calculate(result, number, using: NSDecimalMultiply)
            case .divide:
                guard number != 0 else { throw RuntimeLogicExecutionError.divideByZero }
                result = try calculate(result, number, using: NSDecimalDivide)
            case .min:
                result = Swift.min(result, number)
            case .max:
                result = Swift.max(result, number)
            default:
                throw RuntimeLogicExecutionError.invalidExpression(operation)
            }
            try validateMagnitude(result)
        }
        return decimalString(result)
    }

    func calculate(
        _ lhs: Decimal,
        _ rhs: Decimal,
        using operation: (
            UnsafeMutablePointer<Decimal>,
            UnsafePointer<Decimal>,
            UnsafePointer<Decimal>,
            Decimal.RoundingMode
        ) -> Decimal.CalculationError
    ) throws -> Decimal {
        var left = lhs
        var right = rhs
        var result = Decimal()
        let error = operation(&result, &left, &right, .bankers)
        guard error == .noError, !result.isNaN else {
            throw RuntimeLogicExecutionError.calculationOverflow
        }
        return result
    }

    func decimal(_ value: String) throws -> Decimal {
        guard let result = Decimal(
            string: value.trimmingCharacters(in: .whitespacesAndNewlines),
            locale: Locale(identifier: "en_US_POSIX")
        ), !result.isNaN else {
            throw RuntimeLogicExecutionError.invalidNumber(value)
        }
        try validateMagnitude(result)
        return result
    }

    func boolean(_ value: String) throws -> Bool {
        switch value.lowercased() {
        case "true": return true
        case "false": return false
        default: throw RuntimeLogicExecutionError.invalidBoolean(value)
        }
    }

    func integer(_ value: String) throws -> Int {
        let number = try decimal(value)
        let integer = NSDecimalNumber(decimal: number).intValue
        guard Decimal(integer) == number else {
            throw RuntimeLogicExecutionError.invalidNumber(value)
        }
        return integer
    }

    func date(_ value: String) throws -> Date {
        guard let date = RuntimeValueCodec.date(from: value) else {
            throw RuntimeLogicExecutionError.invalidDate(value)
        }
        return date
    }

    func decodedList(_ value: String) throws -> [String] {
        do {
            return try RuntimeValueCodec.decodedList(value)
        } catch RuntimeValueCodecError.collectionLimitExceeded {
            throw RuntimeLogicExecutionError.collectionLimitExceeded
        } catch {
            throw RuntimeLogicExecutionError.invalidList
        }
    }

    func encodedList(_ value: [String]) throws -> String {
        do {
            return try RuntimeValueCodec.encodedList(value)
        } catch {
            throw RuntimeLogicExecutionError.collectionLimitExceeded
        }
    }

    func decodedObject(_ value: String) throws -> [String: String] {
        do {
            return try RuntimeValueCodec.decodedObject(value)
        } catch RuntimeValueCodecError.collectionLimitExceeded {
            throw RuntimeLogicExecutionError.collectionLimitExceeded
        } catch {
            throw RuntimeLogicExecutionError.invalidObject
        }
    }

    func encodedObject(_ value: [String: String]) throws -> String {
        do {
            return try RuntimeValueCodec.encodedObject(value)
        } catch {
            throw RuntimeLogicExecutionError.collectionLimitExceeded
        }
    }

    func validateMagnitude(_ value: Decimal) throws {
        guard value <= Self.maximumMagnitude, value >= -Self.maximumMagnitude else {
            throw RuntimeLogicExecutionError.calculationOverflow
        }
    }

    func decimalString(_ value: Decimal) -> String {
        value == 0 ? "0" : NSDecimalNumber(decimal: value).stringValue
    }

    var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
