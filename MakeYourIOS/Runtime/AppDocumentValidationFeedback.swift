import Foundation

enum AppDocumentValidationFeedback {
    static func describe(error: Error, in document: AppDocument) -> String {
        guard error is AppDocumentValidationError else { return "" }

        var lines = [
            "DOCUMENT CONTEXT: \(document.pages.count) pages, "
                + "\(document.pages.flatMap(\.nodes).count) components, "
                + "\(document.logic?.state.count ?? 0) typed state entries."
        ]
        if let issue = firstLogicIssue(in: document) {
            lines.append(issue)
        } else {
            lines.append(
                "Re-check every cross-field reference and the host rule named by the validation code."
            )
        }
        return lines.joined(separator: "\n")
    }

    private static func firstLogicIssue(in document: AppDocument) -> String? {
        let validator = AppDocumentValidator()
        let definitions = document.logic?.state ?? []
        var definitionsByKey: [String: RuntimeStateDefinition] = [:]

        for (index, definition) in definitions.enumerated() {
            do {
                try validator.validateStateDefinition(definition)
            } catch {
                return "FAILING PATH: logic.state[\(index)] key=\(quoted(definition.key)); "
                    + "declared type=\(definition.type.rawValue); detail=\(error.localizedDescription)"
            }
            if definitionsByKey.updateValue(definition, forKey: definition.key) != nil {
                return "FAILING PATH: logic.state key=\(quoted(definition.key)); duplicate typed state key."
            }
        }

        let stateTypes = definitionsByKey.mapValues(\.type)
        let pageIDs = Set(document.pages.map(\.id))
        for page in document.pages {
            for node in page.nodes {
                if let issue = firstStepIssue(
                    page: page,
                    node: node,
                    validator: validator,
                    stateTypes: stateTypes,
                    pageIDs: pageIDs
                ) {
                    return issue
                }

                do {
                    try validator.validateDeclaredBindingType(node, stateTypes: stateTypes)
                    if node.kind == .control {
                        try validator.validateControl(node, definitionsByKey: definitionsByKey)
                    }
                    try validator.validateEvents(node, stateTypes: stateTypes, pageIDs: pageIDs)
                } catch {
                    return "FAILING PATH: pages[id=\(quoted(page.id))].nodes[id=\(quoted(node.id))]; "
                        + "kind=\(node.kind.rawValue); binding=\(quoted(node.binding)); "
                        + "valueBinding=\(quoted(node.valueBinding ?? "")); detail=\(error.localizedDescription)"
                }
            }
        }
        return nil
    }

    private static func firstStepIssue(
        page: AppPage,
        node: ComponentNode,
        validator: AppDocumentValidator,
        stateTypes: [String: RuntimeValueType],
        pageIDs: Set<String>
    ) -> String? {
        for event in node.events ?? [] {
            for (index, step) in event.steps.enumerated() {
                do {
                    try validator.validateStep(step, stateTypes: stateTypes, pageIDs: pageIDs)
                } catch {
                    let expectedType = step.kind == .setState
                        ? stateTypes[step.target]?.rawValue ?? "missing"
                        : step.kind == .showMessage || step.kind == .scheduleNotification
                            ? RuntimeValueType.text.rawValue
                            : "unused"
                    return """
                    FAILING PATH: pages[id=\(quoted(page.id))].nodes[id=\(quoted(node.id))].events[
                    trigger=\(event.trigger.rawValue)].steps[\(index)]; kind=\(step.kind.rawValue);
                    target=\(quoted(step.target)); expectedResultType=\(expectedType);
                    expression=\(expressionSummary(step.expression));
                    condition=\(conditionSummary(step.condition)); detail=\(error.localizedDescription)
                    """
                    .replacingOccurrences(of: "\n", with: " ")
                }
            }
        }
        return nil
    }

    private static func expressionSummary(_ expression: RuntimeExpression) -> String {
        let operands = expression.operands.map { operand in
            "\(operand.source.rawValue):\(quoted(operand.value))"
        }.joined(separator: ",")
        return "\(expression.operation.rawValue)[\(operands)]"
    }

    private static func conditionSummary(_ condition: RuntimeCondition?) -> String {
        guard let condition else { return "none" }
        return "\(condition.lhs.source.rawValue):\(quoted(condition.lhs.value)) "
            + "\(condition.comparison.rawValue) "
            + "\(condition.rhs.source.rawValue):\(quoted(condition.rhs.value))"
    }

    private static func quoted(_ value: String) -> String {
        let compact = value
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
        return "\"\(String(compact.prefix(120)))\""
    }
}
