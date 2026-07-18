import XCTest
@testable import MakeYourIOS

final class RuntimeLogicEngineTests: XCTestCase {
    func testOrderedStepsReadPriorWritesInOneTransaction() throws {
        let engine = RuntimeLogicEngine(logic: RuntimeLogic(state: [
            state("water", type: .number, initial: "0"),
            state("goal-notified", type: .boolean, initial: "false")
        ]))
        let reachedGoal = RuntimeCondition(
            lhs: stateOperand("water"),
            comparison: .greaterOrEqual,
            rhs: literal("500")
        )
        let event = RuntimeEvent(trigger: .tap, steps: [
            RuntimeStep(
                kind: .setState,
                target: "water",
                expression: expression(.add, stateOperand("water"), literal("250")),
                condition: nil
            ),
            RuntimeStep(
                kind: .showMessage,
                target: "",
                expression: expression(
                    .concatenate,
                    literal("Goal reached at "),
                    stateOperand("water"),
                    literal(" ml")
                ),
                condition: reachedGoal
            ),
            RuntimeStep(
                kind: .setState,
                target: "goal-notified",
                expression: expression(.literal, literal("true")),
                condition: reachedGoal
            )
        ])

        let execution = try engine.execute(
            event: event,
            values: ["water": "250", "goal-notified": "false"]
        )

        XCTAssertEqual(execution.values["water"], "500")
        XCTAssertEqual(execution.values["goal-notified"], "true")
        XCTAssertEqual(execution.effects, [.message("Goal reached at 500 ml")])
    }

    func testInvalidCalculationReturnsNoPartialTransaction() {
        let engine = RuntimeLogicEngine(logic: RuntimeLogic(state: [
            state("water", type: .number, initial: "0"),
            state("result", type: .number, initial: "0")
        ]))
        let original = ["water": "50", "result": "1"]
        let event = RuntimeEvent(trigger: .tap, steps: [
            RuntimeStep(
                kind: .setState,
                target: "water",
                expression: expression(.literal, literal("100")),
                condition: nil
            ),
            RuntimeStep(
                kind: .setState,
                target: "result",
                expression: expression(.divide, stateOperand("water"), literal("0")),
                condition: nil
            )
        ])

        XCTAssertThrowsError(try engine.execute(event: event, values: original)) { error in
            XCTAssertEqual(error as? RuntimeLogicExecutionError, .divideByZero)
        }
        XCTAssertEqual(original, ["water": "50", "result": "1"])
    }

    func testOverflowAndInvalidTypedValuesAreRejected() {
        let engine = RuntimeLogicEngine(logic: RuntimeLogic(state: [
            state("amount", type: .number, initial: "0"),
            state("enabled", type: .boolean, initial: "false")
        ]))
        let overflow = RuntimeEvent(trigger: .tap, steps: [
            RuntimeStep(
                kind: .setState,
                target: "amount",
                expression: expression(
                    .multiply,
                    literal("1000000000000000"),
                    literal("2")
                ),
                condition: nil
            )
        ])
        let invalidBoolean = RuntimeEvent(trigger: .tap, steps: [
            RuntimeStep(
                kind: .setState,
                target: "enabled",
                expression: expression(.literal, literal("yes")),
                condition: nil
            )
        ])

        XCTAssertThrowsError(try engine.execute(
            event: overflow,
            values: ["amount": "0", "enabled": "false"]
        )) { error in
            XCTAssertEqual(error as? RuntimeLogicExecutionError, .calculationOverflow)
        }
        XCTAssertThrowsError(try engine.execute(
            event: invalidBoolean,
            values: ["amount": "0", "enabled": "false"]
        )) { error in
            XCTAssertEqual(error as? RuntimeLogicExecutionError, .invalidBoolean("yes"))
        }
    }

    func testEffectsRemainOrderedAndDoNotRecursivelyExecute() throws {
        let engine = RuntimeLogicEngine(logic: RuntimeLogic())
        let event = RuntimeEvent(trigger: .tap, steps: [
            RuntimeStep(
                kind: .showMessage,
                target: "",
                expression: expression(.literal, literal("Saved")),
                condition: nil
            ),
            RuntimeStep(
                kind: .navigate,
                target: "details",
                expression: .empty,
                condition: nil
            ),
            RuntimeStep(
                kind: .scheduleNotification,
                target: "15",
                expression: expression(.literal, literal("Check in")),
                condition: nil
            ),
            RuntimeStep(
                kind: .playHaptic,
                target: "",
                expression: .empty,
                condition: nil
            )
        ])

        let execution = try engine.execute(event: event, values: [:])

        XCTAssertEqual(execution.values, [:])
        XCTAssertEqual(execution.effects, [
            .message("Saved"),
            .navigate(pageID: "details"),
            .notification(delayMinutes: 15, message: "Check in"),
            .haptic
        ])
    }

    func testInitialValuesAndPersistentKeysComeFromDefinitions() {
        let engine = RuntimeLogicEngine(logic: RuntimeLogic(state: [
            state("draft", type: .text, persistence: .session, initial: "Hello"),
            state("score", type: .number, persistence: .project, initial: "5.00"),
            state("enabled", type: .boolean, persistence: .project, initial: "TRUE")
        ]))

        XCTAssertEqual(engine.initialValues, [
            "draft": "Hello",
            "score": "5",
            "enabled": "true"
        ])
        XCTAssertEqual(engine.persistentKeys, ["score", "enabled"])
    }
}

private extension RuntimeLogicEngineTests {
    func state(
        _ key: String,
        type: RuntimeValueType,
        persistence: RuntimePersistence = .project,
        initial: String
    ) -> RuntimeStateDefinition {
        RuntimeStateDefinition(
            key: key,
            type: type,
            persistence: persistence,
            initialValue: initial
        )
    }

    func literal(_ value: String) -> RuntimeOperand {
        RuntimeOperand(source: .literal, value: value)
    }

    func stateOperand(_ key: String) -> RuntimeOperand {
        RuntimeOperand(source: .state, value: key)
    }

    func expression(
        _ operation: RuntimeExpressionOperation,
        _ operands: RuntimeOperand...
    ) -> RuntimeExpression {
        RuntimeExpression(operation: operation, operands: operands)
    }
}
