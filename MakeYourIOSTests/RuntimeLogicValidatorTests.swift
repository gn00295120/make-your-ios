import XCTest
@testable import MakeYourIOS

// Validator cases intentionally share one canonical generated-document fixture.
// swiftlint:disable:next type_body_length
final class RuntimeLogicValidatorTests: XCTestCase {
    // swiftlint:disable:next function_body_length
    func testComposableLogicControlAndCapabilitiesPassValidation() throws {
        let calculate = RuntimeStep(
            kind: .setState,
            target: "total",
            expression: RuntimeExpression(
                operation: .add,
                operands: [
                    RuntimeOperand(source: .state, value: "subtotal"),
                    RuntimeOperand(source: .state, value: "tip")
                ]
            ),
            condition: RuntimeCondition(
                lhs: RuntimeOperand(source: .state, value: "enabled"),
                comparison: .equals,
                rhs: RuntimeOperand(source: .literal, value: "true")
            )
        )
        let slider = ComponentNode(
            id: "tip-control",
            kind: .control,
            title: "Tip",
            binding: "tip",
            valueBinding: "tip",
            events: [RuntimeEvent(trigger: .valueChanged, steps: [
                calculate,
                RuntimeStep(kind: .playHaptic, target: "", expression: .empty, condition: nil)
            ])],
            control: RuntimeControlSpec(
                kind: .slider,
                minimum: 0,
                maximum: 30,
                step: 1,
                unit: "%"
            )
        )
        let progress = ComponentNode(
            id: "tip-progress",
            kind: .control,
            title: "Tip progress",
            binding: "tip",
            valueBinding: "tip",
            control: RuntimeControlSpec(
                kind: .progress,
                minimum: 0,
                maximum: 30,
                step: 1,
                unit: "%"
            )
        )
        let reminder = ComponentNode(
            id: "reminder",
            kind: .button,
            title: "Remind me",
            events: [RuntimeEvent(trigger: .tap, steps: [RuntimeStep(
                kind: .scheduleNotification,
                target: "30",
                expression: RuntimeExpression(
                    operation: .literal,
                    operands: [RuntimeOperand(source: .literal, value: "Review the total")]
                ),
                condition: nil
            )])]
        )
        var document = makeDocument(nodes: [slider, progress, reminder])
        document.capabilities = AppCapabilityResolver.requiredCapabilities(for: document)
            .sorted(by: { $0.rawValue < $1.rawValue })

        XCTAssertEqual(
            Set(document.capabilities),
            [.haptics, .localNotifications, .localStorage, .safeCalculation]
        )
        XCTAssertNoThrow(try AppDocumentValidator().validate(document))
    }

    func testMissingStateReferenceIsRejected() {
        var document = makeDocument(nodes: [ComponentNode(
            id: "result",
            kind: .metric,
            title: "Result",
            valueBinding: "missing"
        )])
        document.capabilities = [.localStorage]

        XCTAssertThrowsError(try AppDocumentValidator().validate(document)) { error in
            XCTAssertEqual(
                error as? AppDocumentValidationError,
                .invalidRuntimeReference("missing")
            )
        }
    }

    func testLiteralDivisionByZeroIsRejected() {
        let step = RuntimeStep(
            kind: .setState,
            target: "total",
            expression: RuntimeExpression(
                operation: .divide,
                operands: [
                    RuntimeOperand(source: .state, value: "subtotal"),
                    RuntimeOperand(source: .literal, value: "0")
                ]
            ),
            condition: nil
        )
        var document = makeDocument(nodes: [ComponentNode(
            id: "calculate",
            kind: .button,
            title: "Calculate",
            events: [RuntimeEvent(trigger: .tap, steps: [step])]
        )])
        document.capabilities = AppCapabilityResolver.requiredCapabilities(for: document)
            .sorted(by: { $0.rawValue < $1.rawValue })

        XCTAssertThrowsError(try AppDocumentValidator().validate(document)) { error in
            XCTAssertEqual(error as? AppDocumentValidationError, .invalidRuntimeExpression)
        }
    }

    func testRuntimeComplexityLimitsAreEnforced() {
        let emptyEvent = RuntimeEvent(trigger: .tap, steps: [])
        var document = makeDocument(nodes: [ComponentNode(
            id: "too-many-events",
            kind: .button,
            title: "Run",
            events: Array(repeating: emptyEvent, count: 5)
        )])
        document.capabilities = [.localStorage]

        XCTAssertThrowsError(try AppDocumentValidator().validate(document)) { error in
            XCTAssertEqual(error as? AppDocumentValidationError, .runtimeLimitExceeded)
        }
    }

    func testInvalidControlRangeIsRejected() {
        let control = ComponentNode(
            id: "invalid-slider",
            kind: .control,
            title: "Tip",
            binding: "tip",
            control: RuntimeControlSpec(
                kind: .slider,
                minimum: 30,
                maximum: 10,
                step: 0,
                unit: "%"
            )
        )
        var document = makeDocument(nodes: [control])
        document.capabilities = [.localStorage]

        XCTAssertThrowsError(try AppDocumentValidator().validate(document)) { error in
            XCTAssertEqual(
                error as? AppDocumentValidationError,
                .invalidComponentConfiguration(.control)
            )
        }
    }

    func testDeclaredInputBindingMustMatchItsStateType() {
        let invalidNumberInput = ComponentNode(
            id: "invalid-number-input",
            kind: .numberInput,
            title: "Amount",
            binding: "enabled"
        )
        var document = makeDocument(nodes: [invalidNumberInput])
        document.capabilities = [.localStorage]

        XCTAssertThrowsError(try AppDocumentValidator().validate(document)) { error in
            XCTAssertEqual(error as? AppDocumentValidationError, .invalidRuntimeLogic)
        }
    }

    func testValueChangedRequiresASupportedBoundSource() {
        let invalidButtonEvent = ComponentNode(
            id: "invalid-value-source",
            kind: .button,
            title: "Invalid",
            binding: "total",
            events: [RuntimeEvent(trigger: .valueChanged, steps: [])]
        )
        var document = makeDocument(nodes: [invalidButtonEvent])
        document.capabilities = [.localStorage]

        XCTAssertThrowsError(try AppDocumentValidator().validate(document)) { error in
            XCTAssertEqual(error as? AppDocumentValidationError, .invalidRuntimeLogic)
        }
    }

    func testNumericConditionDerivesSafeCalculationCapability() throws {
        let conditionalMessage = ComponentNode(
            id: "conditional-message",
            kind: .button,
            title: "Check",
            events: [RuntimeEvent(trigger: .tap, steps: [RuntimeStep(
                kind: .showMessage,
                target: "",
                expression: RuntimeExpression(
                    operation: .literal,
                    operands: [RuntimeOperand(source: .literal, value: "Ready")]
                ),
                condition: RuntimeCondition(
                    lhs: RuntimeOperand(source: .state, value: "total"),
                    comparison: .greater,
                    rhs: RuntimeOperand(source: .literal, value: "0")
                )
            )])]
        )
        var document = makeDocument(nodes: [conditionalMessage])
        document.capabilities = AppCapabilityResolver.requiredCapabilities(for: document)
            .sorted(by: { $0.rawValue < $1.rawValue })

        XCTAssertTrue(document.capabilities.contains(.safeCalculation))
        XCTAssertNoThrow(try AppDocumentValidator().validate(document))
    }

    func testOutOfRangeInitialNumberIsRejectedBeforeRuntime() {
        var document = makeDocument(nodes: [])
        document.logic?.state[0].initialValue = "1000000000000001"
        document.capabilities = [.localStorage]

        XCTAssertThrowsError(try AppDocumentValidator().validate(document)) { error in
            XCTAssertEqual(error as? AppDocumentValidationError, .invalidRuntimeLogic)
        }
    }

    // The complete document fixture keeps the cross-node capability contract explicit.
    // swiftlint:disable:next function_body_length
    func testDateCollectionViewAndForegroundTimerPassValidation() throws {
        let dateControl = ComponentNode(
            id: "due-date",
            kind: .control,
            title: "Due date",
            binding: "due",
            control: RuntimeControlSpec(
                kind: .datePicker,
                minimum: 0,
                maximum: 1,
                step: 1,
                unit: ""
            )
        )
        let collection = ComponentNode(
            id: "shopping-list",
            kind: .collectionView,
            title: "Shopping list",
            placeholder: "Nothing to buy",
            binding: "items"
        )
        let timer = ComponentNode(
            id: "refresh-count",
            kind: .metric,
            title: "Items",
            valueBinding: "item-count",
            events: [RuntimeEvent(
                trigger: .timer,
                steps: [RuntimeStep(
                    kind: .setState,
                    target: "item-count",
                    expression: RuntimeExpression(
                        operation: .listCount,
                        operands: [RuntimeOperand(source: .state, value: "items")]
                    ),
                    condition: nil
                )],
                intervalSeconds: 30
            )]
        )
        var document = makeDocument(nodes: [dateControl, collection, timer])
        document.logic?.state.append(contentsOf: [
            RuntimeStateDefinition(
                key: "due",
                type: .date,
                persistence: .project,
                initialValue: "2026-07-19"
            ),
            RuntimeStateDefinition(
                key: "items",
                type: .list,
                persistence: .project,
                initialValue: #"["Milk","Eggs"]"#
            ),
            RuntimeStateDefinition(
                key: "item-count",
                type: .number,
                persistence: .session,
                initialValue: "2"
            )
        ])
        document.capabilities = AppCapabilityResolver.requiredCapabilities(for: document)
            .sorted(by: { $0.rawValue < $1.rawValue })

        XCTAssertTrue(document.capabilities.contains(.safeCalculation))
        XCTAssertNoThrow(try AppDocumentValidator().validate(document))
    }

    func testInvalidStructuredInitialValueIsRejected() {
        var document = makeDocument(nodes: [])
        document.logic?.state.append(RuntimeStateDefinition(
            key: "items",
            type: .list,
            persistence: .project,
            initialValue: #"{"not":"a-list"}"#
        ))
        document.capabilities = [.localStorage]

        XCTAssertThrowsError(try AppDocumentValidator().validate(document)) { error in
            XCTAssertEqual(error as? AppDocumentValidationError, .invalidRuntimeLogic)
        }
    }

    func testDuplicateTriggerCannotExpandOneDispatchBeyondStepBudget() {
        let node = ComponentNode(
            id: "duplicate-trigger",
            kind: .button,
            title: "Run",
            events: [
                RuntimeEvent(trigger: .tap, steps: []),
                RuntimeEvent(trigger: .tap, steps: [])
            ]
        )
        var document = makeDocument(nodes: [node])
        document.capabilities = [.localStorage]

        XCTAssertThrowsError(try AppDocumentValidator().validate(document)) { error in
            XCTAssertEqual(error as? AppDocumentValidationError, .runtimeLimitExceeded)
        }
    }

    func testTimerRequiresBoundedForegroundInterval() {
        let node = ComponentNode(
            id: "invalid-timer",
            kind: .text,
            title: "Clock",
            events: [RuntimeEvent(trigger: .timer, steps: [], intervalSeconds: 0)]
        )
        var document = makeDocument(nodes: [node])
        document.capabilities = [.localStorage]

        XCTAssertThrowsError(try AppDocumentValidator().validate(document)) { error in
            XCTAssertEqual(error as? AppDocumentValidationError, .invalidRuntimeLogic)
        }
    }

    private func makeDocument(nodes: [ComponentNode]) -> AppDocument {
        AppDocument(
            name: "Logic test",
            summary: "A composable logic fixture",
            symbol: "function",
            tint: .mint,
            startPageID: "home",
            capabilities: [.localStorage],
            logic: RuntimeLogic(state: [
                RuntimeStateDefinition(
                    key: "subtotal",
                    type: .number,
                    persistence: .session,
                    initialValue: "100"
                ),
                RuntimeStateDefinition(
                    key: "tip",
                    type: .number,
                    persistence: .project,
                    initialValue: "15"
                ),
                RuntimeStateDefinition(
                    key: "total",
                    type: .number,
                    persistence: .project,
                    initialValue: "115"
                ),
                RuntimeStateDefinition(
                    key: "enabled",
                    type: .boolean,
                    persistence: .session,
                    initialValue: "true"
                )
            ]),
            pages: [AppPage(id: "home", title: "Home", nodes: nodes)]
        )
    }
}
