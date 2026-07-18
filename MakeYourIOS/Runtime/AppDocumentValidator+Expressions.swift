import Foundation

extension AppDocumentValidator {
    // Exhaustive expression interpreter validation; every operation is intentionally explicit.
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func validateExpression(
        _ expression: RuntimeExpression,
        expectedType: RuntimeValueType?,
        stateTypes: [String: RuntimeValueType]
    ) throws -> RuntimeValueType {
        let operands = expression.operands
        guard !operands.isEmpty,
              operands.count <= Self.maximumOperandsPerExpression else {
            throw AppDocumentValidationError.invalidRuntimeExpression
        }

        let resultType: RuntimeValueType
        switch expression.operation {
        case .literal:
            guard operands.count == 1, operands[0].source == .literal else {
                throw AppDocumentValidationError.invalidRuntimeExpression
            }
            resultType = try operandType(
                operands[0],
                expectedLiteralType: expectedType,
                stateTypes: stateTypes
            )
        case .copy:
            guard operands.count == 1 else {
                throw AppDocumentValidationError.invalidRuntimeExpression
            }
            resultType = try operandType(
                operands[0],
                expectedLiteralType: expectedType,
                stateTypes: stateTypes
            )
        case .add, .multiply, .min, .max:
            guard operands.count >= 2 else {
                throw AppDocumentValidationError.invalidRuntimeExpression
            }
            try operands.forEach {
                guard try operandType(
                    $0,
                    expectedLiteralType: .number,
                    stateTypes: stateTypes
                ) == .number else {
                    throw AppDocumentValidationError.invalidRuntimeExpression
                }
            }
            resultType = .number
        case .subtract, .divide:
            guard operands.count == 2 else {
                throw AppDocumentValidationError.invalidRuntimeExpression
            }
            try operands.forEach {
                guard try operandType(
                    $0,
                    expectedLiteralType: .number,
                    stateTypes: stateTypes
                ) == .number else {
                    throw AppDocumentValidationError.invalidRuntimeExpression
                }
            }
            if expression.operation == .divide,
               operands[1].source == .literal,
               runtimeNumber(operands[1].value) == 0 {
                throw AppDocumentValidationError.invalidRuntimeExpression
            }
            resultType = .number
        case .concatenate:
            try operands.forEach { _ = try operandType($0, expectedLiteralType: nil, stateTypes: stateTypes) }
            resultType = .text
        case .listAppend, .listRemove, .listContains, .listJoin:
            guard operands.count == 2,
                  try operandType(
                    operands[0],
                    expectedLiteralType: .list,
                    stateTypes: stateTypes
                  ) == .list else {
                throw AppDocumentValidationError.invalidRuntimeExpression
            }
            let itemType = try operandType(
                operands[1],
                expectedLiteralType: .text,
                stateTypes: stateTypes
            )
            guard [.text, .number, .boolean, .date].contains(itemType) else {
                throw AppDocumentValidationError.invalidRuntimeExpression
            }
            switch expression.operation {
            case .listAppend, .listRemove: resultType = .list
            case .listContains: resultType = .boolean
            case .listJoin: resultType = .text
            default: throw AppDocumentValidationError.invalidRuntimeExpression
            }
        case .listCount:
            guard operands.count == 1,
                  try operandType(
                    operands[0],
                    expectedLiteralType: .list,
                    stateTypes: stateTypes
                  ) == .list else {
                throw AppDocumentValidationError.invalidRuntimeExpression
            }
            resultType = .number
        case .objectSet:
            guard operands.count == 3,
                  try operandType(
                    operands[0],
                    expectedLiteralType: .object,
                    stateTypes: stateTypes
                  ) == .object,
                  try operandType(
                    operands[1],
                    expectedLiteralType: .text,
                    stateTypes: stateTypes
                  ) == .text else {
                throw AppDocumentValidationError.invalidRuntimeExpression
            }
            let valueType = try operandType(
                operands[2],
                expectedLiteralType: .text,
                stateTypes: stateTypes
            )
            guard [.text, .number, .boolean, .date].contains(valueType) else {
                throw AppDocumentValidationError.invalidRuntimeExpression
            }
            resultType = .object
        case .objectRemove, .objectGet:
            guard operands.count == 2,
                  try operandType(
                    operands[0],
                    expectedLiteralType: .object,
                    stateTypes: stateTypes
                  ) == .object,
                  try operandType(
                    operands[1],
                    expectedLiteralType: .text,
                    stateTypes: stateTypes
                  ) == .text else {
                throw AppDocumentValidationError.invalidRuntimeExpression
            }
            resultType = expression.operation == .objectRemove ? .object : .text
        case .objectCount:
            guard operands.count == 1,
                  try operandType(
                    operands[0],
                    expectedLiteralType: .object,
                    stateTypes: stateTypes
                  ) == .object else {
                throw AppDocumentValidationError.invalidRuntimeExpression
            }
            resultType = .number
        case .dateAddDays:
            guard operands.count == 2,
                  try operandType(
                    operands[0],
                    expectedLiteralType: .date,
                    stateTypes: stateTypes
                  ) == .date,
                  try operandType(
                    operands[1],
                    expectedLiteralType: .number,
                    stateTypes: stateTypes
                  ) == .number else {
                throw AppDocumentValidationError.invalidRuntimeExpression
            }
            resultType = .date
        case .dateDaysBetween:
            guard operands.count == 2 else {
                throw AppDocumentValidationError.invalidRuntimeExpression
            }
            for operand in operands {
                guard try operandType(
                    operand,
                    expectedLiteralType: .date,
                    stateTypes: stateTypes
                ) == .date else {
                    throw AppDocumentValidationError.invalidRuntimeExpression
                }
            }
            resultType = .number
        }

        guard expectedType == nil || resultType == expectedType else {
            throw AppDocumentValidationError.invalidRuntimeExpression
        }
        return resultType
    }
}
