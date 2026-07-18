import Foundation

struct RuntimeLogic: Codable, Hashable, Sendable {
    var state: [RuntimeStateDefinition]

    init(state: [RuntimeStateDefinition] = []) {
        self.state = state
    }
}

struct RuntimeStateDefinition: Codable, Hashable, Sendable {
    var key: String
    var type: RuntimeValueType
    var persistence: RuntimePersistence
    var initialValue: String
}

enum RuntimeValueType: String, Codable, CaseIterable, Hashable, Sendable {
    case text
    case number
    case boolean
    case date
    case list
    case object
}

enum RuntimePersistence: String, Codable, CaseIterable, Hashable, Sendable {
    case session
    case project
}

struct RuntimeEvent: Codable, Hashable, Sendable {
    var trigger: RuntimeEventTrigger
    var steps: [RuntimeStep]
    var intervalSeconds: Int?

    init(
        trigger: RuntimeEventTrigger,
        steps: [RuntimeStep],
        intervalSeconds: Int? = nil
    ) {
        self.trigger = trigger
        self.steps = steps
        self.intervalSeconds = intervalSeconds
    }
}

enum RuntimeEventTrigger: String, Codable, CaseIterable, Hashable, Sendable {
    case tap
    case valueChanged
    case appear
    case timer
}

struct RuntimeStep: Codable, Hashable, Sendable {
    var kind: RuntimeStepKind
    var target: String
    var expression: RuntimeExpression
    var condition: RuntimeCondition?
}

enum RuntimeStepKind: String, Codable, CaseIterable, Hashable, Sendable {
    case setState
    case navigate
    case showMessage
    case scheduleNotification
    case playHaptic
}

struct RuntimeExpression: Codable, Hashable, Sendable {
    var operation: RuntimeExpressionOperation
    var operands: [RuntimeOperand]

    static let empty = RuntimeExpression(
        operation: .literal,
        operands: [RuntimeOperand(source: .literal, value: "")]
    )
}

enum RuntimeExpressionOperation: String, Codable, CaseIterable, Hashable, Sendable {
    case literal
    case copy
    case add
    case subtract
    case multiply
    case divide
    case min
    case max
    case concatenate
    case listAppend
    case listRemove
    case listCount
    case listContains
    case listJoin
    case objectSet
    case objectRemove
    case objectGet
    case objectCount
    case dateAddDays
    case dateDaysBetween
}

struct RuntimeOperand: Codable, Hashable, Sendable {
    var source: RuntimeOperandSource
    var value: String
}

enum RuntimeOperandSource: String, Codable, CaseIterable, Hashable, Sendable {
    case literal
    case state
    case currentDate
}

struct RuntimeCondition: Codable, Hashable, Sendable {
    var lhs: RuntimeOperand
    var comparison: RuntimeComparison
    var rhs: RuntimeOperand
}

enum RuntimeComparison: String, Codable, CaseIterable, Hashable, Sendable {
    case equals
    case notEquals
    case less
    case lessOrEqual
    case greater
    case greaterOrEqual
    case isEmpty
    case isNotEmpty
}

struct RuntimeControlSpec: Codable, Hashable, Sendable {
    var kind: RuntimeControlKind
    var minimum: Double
    var maximum: Double
    var step: Double
    var unit: String
}

enum RuntimeControlKind: String, Codable, CaseIterable, Hashable, Sendable {
    case toggle
    case slider
    case stepper
    case progress
    case datePicker
    case timePicker
    case dateTimePicker
}
