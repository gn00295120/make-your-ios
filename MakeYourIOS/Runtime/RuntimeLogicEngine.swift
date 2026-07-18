import Foundation

struct RuntimeLogicExecution: Equatable, Sendable {
    var values: [String: String]
    var effects: [RuntimeLogicEffect]
}

enum RuntimeLogicEffect: Equatable, Sendable {
    case navigate(pageID: String)
    case message(String)
    case notification(delayMinutes: Int, message: String)
    case haptic
}

enum RuntimeLogicExecutionError: LocalizedError, Equatable {
    case missingState(String)
    case invalidExpression(RuntimeExpressionOperation)
    case invalidNumber(String)
    case invalidBoolean(String)
    case divideByZero
    case calculationOverflow
    case valueTooLong
    case invalidNotificationDelay

    var errorDescription: String? {
        switch self {
        case .missingState:
            "This tiny app references state that is not available."
        case .invalidExpression:
            "This tiny app contains an invalid calculation."
        case .invalidNumber:
            "A value in this tiny app is not a valid number."
        case .invalidBoolean:
            "A value in this tiny app is not a valid true or false value."
        case .divideByZero:
            "This calculation cannot divide by zero."
        case .calculationOverflow:
            "This calculation is outside the supported range."
        case .valueTooLong:
            "This result is too long for a tiny app value."
        case .invalidNotificationDelay:
            "This reminder delay is outside the supported range."
        }
    }
}

/// Executes a validated, finite list of runtime steps as one state transaction.
/// It never emits new runtime events, so generated logic cannot recurse.
struct RuntimeLogicEngine: Sendable {
    static let maximumValueLength = 2_000
    static let maximumMagnitude = Decimal(string: "1000000000000000")!

    private let definitions: [String: RuntimeStateDefinition]

    init(logic: RuntimeLogic?) {
        definitions = (logic?.state ?? []).reduce(into: [:]) { result, definition in
            if result[definition.key] == nil {
                result[definition.key] = definition
            }
        }
    }

    var initialValues: [String: String] {
        definitions.reduce(into: [:]) { values, entry in
            values[entry.key] = normalizedInitialValue(entry.value)
        }
    }

    var persistentKeys: Set<String> {
        Set(definitions.values.lazy.filter { $0.persistence == .project }.map(\.key))
    }

    func execute(event: RuntimeEvent, values: [String: String]) throws -> RuntimeLogicExecution {
        var transaction = values
        var effects: [RuntimeLogicEffect] = []

        for step in event.steps {
            if let condition = step.condition,
               try !evaluate(condition: condition, values: transaction) {
                continue
            }

            switch step.kind {
            case .setState:
                guard let definition = definitions[step.target] else {
                    throw RuntimeLogicExecutionError.missingState(step.target)
                }
                let result = try evaluate(expression: step.expression, values: transaction)
                transaction[step.target] = try normalize(result, as: definition.type)
            case .navigate:
                effects.append(.navigate(pageID: step.target))
            case .showMessage:
                effects.append(.message(try evaluate(expression: step.expression, values: transaction)))
            case .scheduleNotification:
                guard let minutes = Int(step.target), (1...10_080).contains(minutes) else {
                    throw RuntimeLogicExecutionError.invalidNotificationDelay
                }
                effects.append(.notification(
                    delayMinutes: minutes,
                    message: try evaluate(expression: step.expression, values: transaction)
                ))
            case .playHaptic:
                effects.append(.haptic)
            }
        }

        return RuntimeLogicExecution(values: transaction, effects: effects)
    }
}

private extension RuntimeLogicEngine {
    struct ResolvedOperand {
        var value: String
        var type: RuntimeValueType?
    }

    func evaluate(expression: RuntimeExpression, values: [String: String]) throws -> String {
        let operands = try expression.operands.map { try resolve($0, values: values) }
        let result: String

        switch expression.operation {
        case .literal:
            guard operands.count == 1,
                  expression.operands[0].source == .literal else {
                throw RuntimeLogicExecutionError.invalidExpression(.literal)
            }
            result = operands[0].value
        case .copy:
            guard operands.count == 1 else {
                throw RuntimeLogicExecutionError.invalidExpression(.copy)
            }
            result = operands[0].value
        case .concatenate:
            guard !operands.isEmpty else {
                throw RuntimeLogicExecutionError.invalidExpression(.concatenate)
            }
            result = operands.map(\.value).joined()
        case .add, .subtract, .multiply, .divide, .min, .max:
            result = try numericResult(
                operation: expression.operation,
                operands: operands.map(\.value)
            )
        }

        guard result.count <= Self.maximumValueLength else {
            throw RuntimeLogicExecutionError.valueTooLong
        }
        return result
    }

    func evaluate(condition: RuntimeCondition, values: [String: String]) throws -> Bool {
        let lhs = try resolve(condition.lhs, values: values)
        switch condition.comparison {
        case .isEmpty:
            return lhs.value.isEmpty
        case .isNotEmpty:
            return !lhs.value.isEmpty
        default:
            break
        }

        let rhs = try resolve(condition.rhs, values: values)
        switch condition.comparison {
        case .equals, .notEquals:
            let isEqual = try equal(lhs, rhs)
            return condition.comparison == .equals ? isEqual : !isEqual
        case .less, .lessOrEqual, .greater, .greaterOrEqual:
            let leftNumber = try decimal(lhs.value)
            let rightNumber = try decimal(rhs.value)
            return numericComparison(condition.comparison, lhs: leftNumber, rhs: rightNumber)
        case .isEmpty, .isNotEmpty:
            return false
        }
    }

    func numericComparison(_ comparison: RuntimeComparison, lhs: Decimal, rhs: Decimal) -> Bool {
        switch comparison {
        case .less: lhs < rhs
        case .lessOrEqual: lhs <= rhs
        case .greater: lhs > rhs
        case .greaterOrEqual: lhs >= rhs
        default: false
        }
    }

    func resolve(_ operand: RuntimeOperand, values: [String: String]) throws -> ResolvedOperand {
        switch operand.source {
        case .literal:
            return ResolvedOperand(value: operand.value, type: nil)
        case .state:
            guard let definition = definitions[operand.value],
                  let value = values[operand.value] else {
                throw RuntimeLogicExecutionError.missingState(operand.value)
            }
            return ResolvedOperand(value: value, type: definition.type)
        }
    }

    func equal(_ lhs: ResolvedOperand, _ rhs: ResolvedOperand) throws -> Bool {
        let resolvedType = lhs.type ?? rhs.type ?? .text
        switch resolvedType {
        case .text:
            return lhs.value == rhs.value
        case .number:
            return try decimal(lhs.value) == decimal(rhs.value)
        case .boolean:
            return try boolean(lhs.value) == boolean(rhs.value)
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

    func normalize(_ value: String, as type: RuntimeValueType) throws -> String {
        switch type {
        case .text:
            guard value.count <= Self.maximumValueLength else {
                throw RuntimeLogicExecutionError.valueTooLong
            }
            return value
        case .number:
            return decimalString(try decimal(value))
        case .boolean:
            return try boolean(value) ? "true" : "false"
        }
    }

    func normalizedInitialValue(_ definition: RuntimeStateDefinition) -> String {
        (try? normalize(definition.initialValue, as: definition.type)) ?? definition.initialValue
    }

    func validateMagnitude(_ value: Decimal) throws {
        guard value <= Self.maximumMagnitude, value >= -Self.maximumMagnitude else {
            throw RuntimeLogicExecutionError.calculationOverflow
        }
    }

    func decimalString(_ value: Decimal) -> String {
        value == 0 ? "0" : NSDecimalNumber(decimal: value).stringValue
    }
}
