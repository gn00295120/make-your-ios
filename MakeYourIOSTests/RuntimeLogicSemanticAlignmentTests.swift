import XCTest
@testable import MakeYourIOS

final class RuntimeLogicSemanticAlignmentTests: XCTestCase {
    func testUnusedNavigateAndHapticExpressionsDoNotInvalidateDocument() {
        let node = ComponentNode(
            id: "safe-effects",
            kind: .button,
            title: "Open",
            events: [RuntimeEvent(trigger: .tap, steps: [
                RuntimeStep(
                    kind: .navigate,
                    target: "home",
                    expression: RuntimeExpression(operation: .divide, operands: []),
                    condition: nil
                ),
                RuntimeStep(
                    kind: .playHaptic,
                    target: "",
                    expression: RuntimeExpression(operation: .add, operands: []),
                    condition: nil
                )
            ])]
        )

        XCTAssertNoThrow(try AppDocumentValidator().validate(makeDocument(nodes: [node])))
    }

    func testUnaryEmptyConditionIgnoresSchemaPlaceholderRHS() {
        let node = ComponentNode(
            id: "empty-check",
            kind: .button,
            title: "Check",
            events: [RuntimeEvent(trigger: .tap, steps: [RuntimeStep(
                kind: .showMessage,
                target: "",
                expression: RuntimeExpression(
                    operation: .literal,
                    operands: [RuntimeOperand(source: .literal, value: "Nothing saved")]
                ),
                condition: RuntimeCondition(
                    lhs: RuntimeOperand(source: .state, value: "note"),
                    comparison: .isEmpty,
                    rhs: RuntimeOperand(source: .state, value: "unused-placeholder")
                )
            )])]
        )

        XCTAssertNoThrow(try AppDocumentValidator().validate(makeDocument(nodes: [node])))
    }

    private func makeDocument(nodes: [ComponentNode]) -> AppDocument {
        var document = AppDocument(
            name: "Semantic alignment",
            summary: "Validator and runtime agree on ignored fields.",
            symbol: "function",
            tint: .mint,
            startPageID: "home",
            capabilities: [.localStorage],
            logic: RuntimeLogic(state: [RuntimeStateDefinition(
                key: "note",
                type: .text,
                persistence: .project,
                initialValue: ""
            )]),
            pages: [AppPage(id: "home", title: "Home", nodes: nodes)]
        )
        document.capabilities = AppCapabilityResolver.requiredCapabilities(for: document)
            .sorted(by: { $0.rawValue < $1.rawValue })
        return document
    }
}
