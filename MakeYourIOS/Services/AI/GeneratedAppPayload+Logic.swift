import Foundation

extension GeneratedAppPayload {
    func makeLogic() -> RuntimeLogic? {
        guard let logic else { return nil }
        var seen = Set<String>()
        let state = logic.state.prefix(64).compactMap { definition -> RuntimeStateDefinition? in
            let key = normalizedLogicID(definition.key)
            guard !key.isEmpty, seen.insert(key).inserted else { return nil }
            let type = RuntimeValueType(rawValue: definition.type) ?? .text
            return RuntimeStateDefinition(
                key: key,
                type: type,
                persistence: RuntimePersistence(rawValue: definition.persistence) ?? .session,
                initialValue: normalizedInitialValue(definition.initialValue, for: type)
            )
        }
        return RuntimeLogic(state: state)
    }

    func makeEvents(_ events: [Event]?) -> [RuntimeEvent]? {
        guard let events else { return nil }
        return events.prefix(4).map { event in
            RuntimeEvent(
                trigger: RuntimeEventTrigger(rawValue: event.trigger) ?? .tap,
                steps: event.steps.prefix(8).map(makeStep)
            )
        }
    }

    func makeControl(_ control: Control?) -> RuntimeControlSpec {
        let minimum = finiteValue(control?.minimum)
        let maximum = finiteValue(control?.maximum)
        let safeMaximum = maximum > minimum ? maximum : minimum + 1
        let requestedStep = finiteValue(control?.step)
        return RuntimeControlSpec(
            kind: RuntimeControlKind(rawValue: control?.kind ?? "") ?? .toggle,
            minimum: minimum,
            maximum: safeMaximum,
            step: requestedStep > 0 ? min(requestedStep, safeMaximum - minimum) : 1,
            unit: String((control?.unit ?? "").prefix(20))
        )
    }

    func normalizedOptionalID(_ value: String?) -> String? {
        guard let value else { return nil }
        let normalized = normalizedLogicID(value)
        return normalized.isEmpty ? nil : normalized
    }
}

private extension GeneratedAppPayload {
    func makeStep(_ step: Step) -> RuntimeStep {
        let kind = RuntimeStepKind(rawValue: step.kind) ?? .setState
        let target: String
        switch kind {
        case .setState, .navigate:
            target = normalizedLogicID(step.target)
        case .showMessage, .scheduleNotification, .playHaptic:
            target = String(step.target.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120))
        }
        return RuntimeStep(
            kind: kind,
            target: target,
            expression: makeExpression(step.expression),
            condition: step.condition.map(makeCondition)
        )
    }

    func makeExpression(_ expression: Expression) -> RuntimeExpression {
        RuntimeExpression(
            operation: RuntimeExpressionOperation(rawValue: expression.operation) ?? .literal,
            operands: expression.operands.prefix(8).map(makeOperand)
        )
    }

    func makeCondition(_ condition: Condition) -> RuntimeCondition {
        RuntimeCondition(
            lhs: makeOperand(condition.lhs),
            comparison: RuntimeComparison(rawValue: condition.comparison) ?? .equals,
            rhs: makeOperand(condition.rhs)
        )
    }

    func makeOperand(_ operand: Operand) -> RuntimeOperand {
        let source = RuntimeOperandSource(rawValue: operand.source) ?? .literal
        return RuntimeOperand(
            source: source,
            value: source == .state
                ? normalizedLogicID(operand.value)
                : String(operand.value.prefix(800))
        )
    }

    func normalizedInitialValue(_ value: String, for type: RuntimeValueType) -> String {
        switch type {
        case .text:
            String(value.prefix(800))
        case .number:
            if let number = Double(value), number.isFinite {
                String(number)
            } else {
                "0"
            }
        case .boolean:
            value.lowercased() == "true" ? "true" : "false"
        }
    }

    func normalizedLogicID(_ value: String) -> String {
        let allowed = value.lowercased().unicodeScalars.map { scalar -> Character in
            CharacterSet.alphanumerics.contains(scalar) || scalar == "-" ? Character(String(scalar)) : "-"
        }
        let normalized = String(allowed)
            .split(separator: "-", omittingEmptySubsequences: true)
            .joined(separator: "-")
        return String(normalized.prefix(60))
    }

    func finiteValue(_ value: Double?) -> Double {
        guard let value, value.isFinite else { return 0 }
        return value
    }
}
