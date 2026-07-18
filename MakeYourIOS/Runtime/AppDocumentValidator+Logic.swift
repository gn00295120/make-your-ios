import Foundation

extension AppDocumentValidator {
    func validateLogic(_ document: AppDocument) throws {
        let definitions = document.logic?.state ?? []
        guard definitions.count <= Self.maximumStateDefinitions,
              document.initialState.count <= Self.maximumStateDefinitions,
              document.initialState.allSatisfy({ key, value in
                  !key.isEmpty && key.count <= 120
                      && value.count <= RuntimeLogicEngine.maximumValueLength
              }) else {
            throw AppDocumentValidationError.runtimeLimitExceeded
        }

        var definitionsByKey: [String: RuntimeStateDefinition] = [:]
        for definition in definitions {
            try validateStateDefinition(definition)
            guard definitionsByKey.updateValue(definition, forKey: definition.key) == nil else {
                throw AppDocumentValidationError.invalidRuntimeLogic
            }
        }

        let stateTypes = definitionsByKey.mapValues(\.type)
        let pageIDs = Set(document.pages.map(\.id))
        for node in document.pages.flatMap(\.nodes) {
            if let valueBinding = node.valueBinding {
                try validateStateReference(valueBinding, stateTypes: stateTypes)
            }
            try validateDeclaredBindingType(node, stateTypes: stateTypes)
            if node.kind == .control {
                try validateControl(node, definitionsByKey: definitionsByKey)
            }
            try validateEvents(node, stateTypes: stateTypes, pageIDs: pageIDs)
        }
    }
}

private extension AppDocumentValidator {
    func validateStateDefinition(_ definition: RuntimeStateDefinition) throws {
        let trimmedKey = definition.key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty,
              trimmedKey == definition.key,
              definition.key.count <= 60,
              definition.key.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" }),
              definition.initialValue.count <= 800 else {
            throw AppDocumentValidationError.invalidRuntimeLogic
        }

        switch definition.type {
        case .text:
            break
        case .number:
            guard runtimeNumber(definition.initialValue) != nil else {
                throw AppDocumentValidationError.invalidRuntimeLogic
            }
        case .boolean:
            guard ["true", "false"].contains(definition.initialValue) else {
                throw AppDocumentValidationError.invalidRuntimeLogic
            }
        }
    }

    func validateControl(
        _ node: ComponentNode,
        definitionsByKey: [String: RuntimeStateDefinition]
    ) throws {
        guard let control = node.control,
              control.minimum.isFinite,
              control.maximum.isFinite,
              control.step.isFinite,
              abs(control.minimum) <= 1_000_000_000_000_000,
              abs(control.maximum) <= 1_000_000_000_000_000,
              control.step <= 1_000_000_000_000_000,
              control.minimum < control.maximum,
              control.step > 0,
              control.step <= control.maximum - control.minimum,
              control.unit.count <= 20,
              let state = definitionsByKey[node.binding] else {
            throw AppDocumentValidationError.invalidComponentConfiguration(.control)
        }

        switch control.kind {
        case .toggle:
            guard state.type == .boolean else {
                throw AppDocumentValidationError.invalidComponentConfiguration(.control)
            }
        case .slider, .stepper, .progress:
            guard state.type == .number,
                  let initialValue = Double(state.initialValue),
                  (control.minimum...control.maximum).contains(initialValue) else {
                throw AppDocumentValidationError.invalidComponentConfiguration(.control)
            }
        }
    }

    func validateEvents(
        _ node: ComponentNode,
        stateTypes: [String: RuntimeValueType],
        pageIDs: Set<String>
    ) throws {
        let events = node.events ?? []
        guard events.count <= Self.maximumEventsPerNode else {
            throw AppDocumentValidationError.runtimeLimitExceeded
        }
        if events.contains(where: { $0.trigger == .valueChanged }) {
            let supportedKinds: Set<ComponentKind> = [
                .textInput, .numberInput, .picker, .aiAssistant, .deviceInput, .control
            ]
            guard supportedKinds.contains(node.kind) else {
                throw AppDocumentValidationError.invalidRuntimeLogic
            }
            try validateStateReference(node.binding, stateTypes: stateTypes)
        }

        for event in events {
            guard event.steps.count <= Self.maximumStepsPerEvent else {
                throw AppDocumentValidationError.runtimeLimitExceeded
            }
            for step in event.steps {
                try validateStep(step, stateTypes: stateTypes, pageIDs: pageIDs)
            }
        }
    }

    func validateDeclaredBindingType(
        _ node: ComponentNode,
        stateTypes: [String: RuntimeValueType]
    ) throws {
        guard let stateType = stateTypes[node.binding] else { return }
        let expectedType: RuntimeValueType?
        switch node.kind {
        case .textInput, .picker, .aiAssistant, .deviceInput:
            expectedType = .text
        case .numberInput:
            expectedType = .number
        case .control:
            expectedType = nil
        default:
            return
        }
        guard expectedType == nil || stateType == expectedType else {
            throw AppDocumentValidationError.invalidRuntimeLogic
        }
    }

    func validateStep(
        _ step: RuntimeStep,
        stateTypes: [String: RuntimeValueType],
        pageIDs: Set<String>
    ) throws {
        if let condition = step.condition {
            try validateCondition(condition, stateTypes: stateTypes)
        }

        switch step.kind {
        case .setState:
            guard let targetType = stateTypes[step.target] else {
                throw AppDocumentValidationError.invalidRuntimeReference(step.target)
            }
            _ = try validateExpression(
                step.expression,
                expectedType: targetType,
                stateTypes: stateTypes
            )
        case .navigate:
            guard pageIDs.contains(step.target) else {
                throw AppDocumentValidationError.invalidRuntimeLogic
            }
            _ = try validateExpression(step.expression, expectedType: nil, stateTypes: stateTypes)
        case .showMessage:
            _ = try validateExpression(step.expression, expectedType: .text, stateTypes: stateTypes)
            try validateNonEmptyLiteralMessage(step.expression)
        case .scheduleNotification:
            guard let minutes = Int(step.target), (1...10_080).contains(minutes) else {
                throw AppDocumentValidationError.invalidRuntimeLogic
            }
            _ = try validateExpression(step.expression, expectedType: .text, stateTypes: stateTypes)
            try validateNonEmptyLiteralMessage(step.expression)
        case .playHaptic:
            _ = try validateExpression(step.expression, expectedType: nil, stateTypes: stateTypes)
        }
    }

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
        }

        guard expectedType == nil || resultType == expectedType else {
            throw AppDocumentValidationError.invalidRuntimeExpression
        }
        return resultType
    }

    func validateCondition(
        _ condition: RuntimeCondition,
        stateTypes: [String: RuntimeValueType]
    ) throws {
        let lhsExpected = stateType(for: condition.rhs, stateTypes: stateTypes)
        let lhsType = try operandType(
            condition.lhs,
            expectedLiteralType: lhsExpected,
            stateTypes: stateTypes
        )
        let rhsType = try operandType(
            condition.rhs,
            expectedLiteralType: lhsType,
            stateTypes: stateTypes
        )

        switch condition.comparison {
        case .equals, .notEquals:
            guard lhsType == rhsType else {
                throw AppDocumentValidationError.invalidRuntimeExpression
            }
        case .less, .lessOrEqual, .greater, .greaterOrEqual:
            guard lhsType == .number, rhsType == .number else {
                throw AppDocumentValidationError.invalidRuntimeExpression
            }
        case .isEmpty, .isNotEmpty:
            break
        }
    }

    func operandType(
        _ operand: RuntimeOperand,
        expectedLiteralType: RuntimeValueType?,
        stateTypes: [String: RuntimeValueType]
    ) throws -> RuntimeValueType {
        guard operand.value.count <= 800 else {
            throw AppDocumentValidationError.invalidRuntimeExpression
        }
        switch operand.source {
        case .state:
            guard let type = stateTypes[operand.value] else {
                throw AppDocumentValidationError.invalidRuntimeReference(operand.value)
            }
            return type
        case .literal:
            if let expectedLiteralType {
                try validateLiteral(operand.value, as: expectedLiteralType)
                return expectedLiteralType
            }
            if let number = Double(operand.value), number.isFinite {
                return .number
            }
            if ["true", "false"].contains(operand.value) {
                return .boolean
            }
            return .text
        }
    }

    func validateLiteral(_ value: String, as type: RuntimeValueType) throws {
        switch type {
        case .text:
            break
        case .number:
            guard runtimeNumber(value) != nil else {
                throw AppDocumentValidationError.invalidRuntimeExpression
            }
        case .boolean:
            guard ["true", "false"].contains(value) else {
                throw AppDocumentValidationError.invalidRuntimeExpression
            }
        }
    }

    func validateStateReference(
        _ key: String,
        stateTypes: [String: RuntimeValueType]
    ) throws {
        guard !key.isEmpty, stateTypes[key] != nil else {
            throw AppDocumentValidationError.invalidRuntimeReference(key)
        }
    }

    func stateType(
        for operand: RuntimeOperand,
        stateTypes: [String: RuntimeValueType]
    ) -> RuntimeValueType? {
        operand.source == .state ? stateTypes[operand.value] : nil
    }

    func validateNonEmptyLiteralMessage(_ expression: RuntimeExpression) throws {
        guard expression.operation != .literal
                || expression.operands[0].value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            throw AppDocumentValidationError.invalidRuntimeExpression
        }
    }

    func runtimeNumber(_ value: String) -> Decimal? {
        guard let number = Decimal(
            string: value.trimmingCharacters(in: .whitespacesAndNewlines),
            locale: Locale(identifier: "en_US_POSIX")
        ), !number.isNaN,
        number <= RuntimeLogicEngine.maximumMagnitude,
        number >= -RuntimeLogicEngine.maximumMagnitude else { return nil }
        return number
    }
}
