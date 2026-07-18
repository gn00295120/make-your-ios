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
    case invalidDate(String)
    case invalidList
    case invalidObject
    case collectionLimitExceeded
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
        case .invalidDate:
            "A value in this tiny app is not a valid date."
        case .invalidList:
            "A value in this tiny app is not a valid list."
        case .invalidObject:
            "A value in this tiny app is not a valid object."
        case .collectionLimitExceeded:
            "This tiny app collection exceeds the supported limit."
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
    private let now: @Sendable () -> Date

    init(
        logic: RuntimeLogic?,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        definitions = (logic?.state ?? []).reduce(into: [:]) { result, definition in
            if result[definition.key] == nil {
                result[definition.key] = definition
            }
        }
        self.now = now
    }

    var initialValues: [String: String] {
        definitions.reduce(into: [:]) { values, entry in
            values[entry.key] = normalizedInitialValue(entry.value)
        }
    }

    var persistentKeys: Set<String> {
        Set(definitions.values.lazy.filter { $0.persistence == .project }.map(\.key))
    }

    var stateDefinitions: [RuntimeStateDefinition] {
        definitions.values.sorted(by: { $0.key < $1.key })
    }

    var stateFingerprints: [String: String] {
        definitions.mapValues { "runtime-value-v1:\($0.type.rawValue)" }
    }

    func normalizedPersistedValue(_ value: String, for key: String) -> String? {
        guard let definition = definitions[key] else { return nil }
        return try? normalize(value, as: definition.type)
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

    // Exhaustive runtime interpreter dispatch; each generated expression has an explicit path.
    // swiftlint:disable:next cyclomatic_complexity function_body_length
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
        case .listAppend:
            guard operands.count == 2 else {
                throw RuntimeLogicExecutionError.invalidExpression(.listAppend)
            }
            var list = try decodedList(operands[0].value)
            list.append(operands[1].value)
            result = try encodedList(list)
        case .listRemove:
            guard operands.count == 2 else {
                throw RuntimeLogicExecutionError.invalidExpression(.listRemove)
            }
            var list = try decodedList(operands[0].value)
            if let index = list.firstIndex(of: operands[1].value) {
                list.remove(at: index)
            }
            result = try encodedList(list)
        case .listCount:
            guard operands.count == 1 else {
                throw RuntimeLogicExecutionError.invalidExpression(.listCount)
            }
            result = String(try decodedList(operands[0].value).count)
        case .listContains:
            guard operands.count == 2 else {
                throw RuntimeLogicExecutionError.invalidExpression(.listContains)
            }
            result = try decodedList(operands[0].value).contains(operands[1].value)
                ? "true"
                : "false"
        case .listJoin:
            guard operands.count == 2 else {
                throw RuntimeLogicExecutionError.invalidExpression(.listJoin)
            }
            result = try decodedList(operands[0].value).joined(separator: operands[1].value)
        case .objectSet:
            guard operands.count == 3 else {
                throw RuntimeLogicExecutionError.invalidExpression(.objectSet)
            }
            var object = try decodedObject(operands[0].value)
            object[operands[1].value] = operands[2].value
            result = try encodedObject(object)
        case .objectRemove:
            guard operands.count == 2 else {
                throw RuntimeLogicExecutionError.invalidExpression(.objectRemove)
            }
            var object = try decodedObject(operands[0].value)
            object.removeValue(forKey: operands[1].value)
            result = try encodedObject(object)
        case .objectGet:
            guard operands.count == 2 else {
                throw RuntimeLogicExecutionError.invalidExpression(.objectGet)
            }
            result = try decodedObject(operands[0].value)[operands[1].value] ?? ""
        case .objectCount:
            guard operands.count == 1 else {
                throw RuntimeLogicExecutionError.invalidExpression(.objectCount)
            }
            result = String(try decodedObject(operands[0].value).count)
        case .dateAddDays:
            guard operands.count == 2 else {
                throw RuntimeLogicExecutionError.invalidExpression(.dateAddDays)
            }
            let days = try integer(operands[1].value)
            guard (-36_500...36_500).contains(days),
                  let nextDate = utcCalendar.date(
                    byAdding: .day,
                    value: days,
                    to: try date(operands[0].value)
                  ) else {
                throw RuntimeLogicExecutionError.invalidExpression(.dateAddDays)
            }
            result = RuntimeValueCodec.encodedDate(nextDate)
        case .dateDaysBetween:
            guard operands.count == 2 else {
                throw RuntimeLogicExecutionError.invalidExpression(.dateDaysBetween)
            }
            let start = utcCalendar.startOfDay(for: try date(operands[0].value))
            let end = utcCalendar.startOfDay(for: try date(operands[1].value))
            result = String(utcCalendar.dateComponents([.day], from: start, to: end).day ?? 0)
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
            return try isEmpty(lhs)
        case .isNotEmpty:
            return try !isEmpty(lhs)
        default:
            break
        }

        let rhs = try resolve(condition.rhs, values: values)
        switch condition.comparison {
        case .equals, .notEquals:
            let isEqual = try equal(lhs, rhs)
            return condition.comparison == .equals ? isEqual : !isEqual
        case .less, .lessOrEqual, .greater, .greaterOrEqual:
            if lhs.type == .date || rhs.type == .date {
                return orderedComparison(
                    condition.comparison,
                    lhs: try date(lhs.value),
                    rhs: try date(rhs.value)
                )
            }
            return numericComparison(
                condition.comparison,
                lhs: try decimal(lhs.value),
                rhs: try decimal(rhs.value)
            )
        case .isEmpty, .isNotEmpty:
            return false
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
        case .currentDate:
            return ResolvedOperand(
                value: RuntimeValueCodec.encodedDate(now()),
                type: .date
            )
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
        case .date:
            return try date(lhs.value) == date(rhs.value)
        case .list:
            return try decodedList(lhs.value) == decodedList(rhs.value)
        case .object:
            return try decodedObject(lhs.value) == decodedObject(rhs.value)
        }
    }

    func isEmpty(_ operand: ResolvedOperand) throws -> Bool {
        switch operand.type {
        case .list:
            return try decodedList(operand.value).isEmpty
        case .object:
            return try decodedObject(operand.value).isEmpty
        default:
            return operand.value.isEmpty
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
        case .date:
            do {
                return try RuntimeValueCodec.normalizedDate(value)
            } catch {
                throw RuntimeLogicExecutionError.invalidDate(value)
            }
        case .list:
            do {
                return try RuntimeValueCodec.normalizedList(value)
            } catch {
                throw RuntimeLogicExecutionError.invalidList
            }
        case .object:
            do {
                return try RuntimeValueCodec.normalizedObject(value)
            } catch {
                throw RuntimeLogicExecutionError.invalidObject
            }
        }
    }

    func normalizedInitialValue(_ definition: RuntimeStateDefinition) -> String {
        (try? normalize(definition.initialValue, as: definition.type)) ?? definition.initialValue
    }

}
