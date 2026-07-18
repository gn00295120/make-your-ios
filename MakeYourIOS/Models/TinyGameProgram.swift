import Foundation

/// A bounded, declarative game description interpreted by the host runtime.
/// Numeric world values are integer points per fixed engine tick.
struct TinyGameProgram: Codable, Hashable, Sendable {
    static let currentVersion = 2

    var version: Int
    var seed: Int
    var tickRate: TinyGameTickRate
    var world: TinyGameWorldSpec
    var variables: [TinyGameVariableSpec]
    var templates: [TinyGameEntityTemplate]
    var spawns: [TinyGameEntitySpawn]
    var controls: [TinyGameControlSpec]
    var rules: [TinyGameRuleSpec]
    var hud: [TinyGameHUDItemSpec]

    init(
        version: Int = TinyGameProgram.currentVersion,
        seed: Int,
        tickRate: TinyGameTickRate = .thirty,
        world: TinyGameWorldSpec,
        variables: [TinyGameVariableSpec] = [],
        templates: [TinyGameEntityTemplate],
        spawns: [TinyGameEntitySpawn],
        controls: [TinyGameControlSpec] = [],
        rules: [TinyGameRuleSpec] = [],
        hud: [TinyGameHUDItemSpec] = []
    ) {
        self.version = version
        self.seed = seed
        self.tickRate = tickRate
        self.world = world
        self.variables = variables
        self.templates = templates
        self.spawns = spawns
        self.controls = controls
        self.rules = rules
        self.hud = hud
    }
}

enum TinyGameTickRate: Int, Codable, CaseIterable, Hashable, Sendable {
    case thirty = 30
    case sixty = 60
}

struct TinyGameWorldSpec: Codable, Hashable, Sendable {
    var width: Int
    var height: Int
    var gravityX: Int
    var gravityY: Int
    var edgeBehavior: TinyGameEdgeBehavior

    init(
        width: Int,
        height: Int,
        gravityX: Int = 0,
        gravityY: Int = 0,
        edgeBehavior: TinyGameEdgeBehavior = .solid
    ) {
        self.width = width
        self.height = height
        self.gravityX = gravityX
        self.gravityY = gravityY
        self.edgeBehavior = edgeBehavior
    }
}

enum TinyGameEdgeBehavior: String, Codable, CaseIterable, Hashable, Sendable {
    case solid
    case clamp
    case wrap
    case bounce
    case destroy
}

enum TinyGameVariableKind: String, Codable, CaseIterable, Hashable, Sendable {
    case integer
    case boolean
}

struct TinyGameVariableSpec: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var kind: TinyGameVariableKind
    var initialValue: Int
    var minimumValue: Int
    var maximumValue: Int

    init(
        id: String,
        kind: TinyGameVariableKind = .integer,
        initialValue: Int,
        minimumValue: Int = -1_000_000,
        maximumValue: Int = 1_000_000
    ) {
        self.id = id
        self.kind = kind
        self.initialValue = initialValue
        self.minimumValue = minimumValue
        self.maximumValue = maximumValue
    }
}

enum TinyGameEntityRole: String, Codable, CaseIterable, Hashable, Sendable {
    case player
    case enemy
    case collectible
    case hazard
    case projectile
    case goal
    case decoration
}

enum TinyGameVisualKind: String, Codable, CaseIterable, Hashable, Sendable {
    case rectangle
    case circle
    case sfSymbol
}

enum TinyGameColorRole: String, Codable, CaseIterable, Hashable, Sendable {
    case primary
    case accent
    case collectible
    case hazard
    case surface
    case foreground
}

struct TinyGameVisualSpec: Codable, Hashable, Sendable {
    var kind: TinyGameVisualKind
    var colorRole: TinyGameColorRole
    var symbol: String

    init(
        kind: TinyGameVisualKind,
        colorRole: TinyGameColorRole,
        symbol: String = ""
    ) {
        self.kind = kind
        self.colorRole = colorRole
        self.symbol = symbol
    }
}

enum TinyGameBodyKind: String, Codable, CaseIterable, Hashable, Sendable {
    case none
    case `static`
    case kinematic
    case dynamic
}

enum TinyGameMovementKind: String, Codable, CaseIterable, Hashable, Sendable {
    case none
    case playerAxis
    case constant
}

struct TinyGameEntityTemplate: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var role: TinyGameEntityRole
    var visual: TinyGameVisualSpec
    var body: TinyGameBodyKind
    var movement: TinyGameMovementKind
    var width: Int
    var height: Int
    var velocityX: Int
    var velocityY: Int
    var speed: Int
    var tags: [String]

    init(
        id: String,
        role: TinyGameEntityRole,
        visual: TinyGameVisualSpec,
        body: TinyGameBodyKind,
        movement: TinyGameMovementKind = .none,
        width: Int,
        height: Int,
        velocityX: Int = 0,
        velocityY: Int = 0,
        speed: Int = 0,
        tags: [String] = []
    ) {
        self.id = id
        self.role = role
        self.visual = visual
        self.body = body
        self.movement = movement
        self.width = width
        self.height = height
        self.velocityX = velocityX
        self.velocityY = velocityY
        self.speed = speed
        self.tags = tags
    }
}

// Coordinate fields intentionally use the conventional x/y names used by the generated IR.
// swiftlint:disable identifier_name
struct TinyGameEntitySpawn: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var templateID: String
    var x: Int
    var y: Int
}
// swiftlint:enable identifier_name

enum TinyGameControlKind: String, Codable, CaseIterable, Hashable, Sendable {
    case fourWay
    case horizontal
    case actionButton
}

struct TinyGameControlSpec: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var kind: TinyGameControlKind
    var label: String
    var symbol: String
    var targetTag: String
    var speed: Int
    var spawnTemplateID: String

    init(
        id: String,
        kind: TinyGameControlKind,
        label: String,
        symbol: String,
        targetTag: String,
        speed: Int = 0,
        spawnTemplateID: String = ""
    ) {
        self.id = id
        self.kind = kind
        self.label = label
        self.symbol = symbol
        self.targetTag = targetTag
        self.speed = speed
        self.spawnTemplateID = spawnTemplateID
    }
}

enum TinyGameTriggerKind: String, Codable, CaseIterable, Hashable, Sendable {
    case start
    case tickInterval
    case collision
    case leaveWorld
}

struct TinyGameTriggerSpec: Codable, Hashable, Sendable {
    var kind: TinyGameTriggerKind
    var subjectTag: String
    var otherTag: String
    var everyTicks: Int

    init(
        kind: TinyGameTriggerKind,
        subjectTag: String = "",
        otherTag: String = "",
        everyTicks: Int = 0
    ) {
        self.kind = kind
        self.subjectTag = subjectTag
        self.otherTag = otherTag
        self.everyTicks = everyTicks
    }
}

enum TinyGameComparison: String, Codable, CaseIterable, Hashable, Sendable {
    case equal
    case notEqual
    case less
    case lessOrEqual
    case greater
    case greaterOrEqual
}

struct TinyGameConditionSpec: Codable, Hashable, Sendable {
    var variableID: String
    var comparison: TinyGameComparison
    var value: Int
}

enum TinyGameEffectKind: String, Codable, CaseIterable, Hashable, Sendable {
    case setVariable
    case addVariable
    case setVelocity
    case spawn
    case destroy
    case win
    case lose
    case feedback
}

enum TinyGameEffectTarget: String, Codable, CaseIterable, Hashable, Sendable {
    case subject
    case other
    case player
    case tag
}

enum TinyGameFeedback: String, Codable, CaseIterable, Hashable, Sendable {
    case none
    case light
    case success
    case error
}

// Coordinate fields intentionally use the conventional x/y names used by the generated IR.
// swiftlint:disable identifier_name
struct TinyGameEffectSpec: Codable, Hashable, Sendable {
    var kind: TinyGameEffectKind
    var target: TinyGameEffectTarget
    var targetTag: String
    var variableID: String
    var value: Int
    var x: Int
    var y: Int
    var templateID: String
    var feedback: TinyGameFeedback

    init(
        kind: TinyGameEffectKind,
        target: TinyGameEffectTarget = .subject,
        targetTag: String = "",
        variableID: String = "",
        value: Int = 0,
        x: Int = 0,
        y: Int = 0,
        templateID: String = "",
        feedback: TinyGameFeedback = .none
    ) {
        self.kind = kind
        self.target = target
        self.targetTag = targetTag
        self.variableID = variableID
        self.value = value
        self.x = x
        self.y = y
        self.templateID = templateID
        self.feedback = feedback
    }
}
// swiftlint:enable identifier_name

struct TinyGameRuleSpec: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var trigger: TinyGameTriggerSpec
    var conditions: [TinyGameConditionSpec]
    var effects: [TinyGameEffectSpec]

    init(
        id: String,
        trigger: TinyGameTriggerSpec,
        conditions: [TinyGameConditionSpec] = [],
        effects: [TinyGameEffectSpec]
    ) {
        self.id = id
        self.trigger = trigger
        self.conditions = conditions
        self.effects = effects
    }
}

enum TinyGameHUDKind: String, Codable, CaseIterable, Hashable, Sendable {
    case score
    case lives
    case variable
}

struct TinyGameHUDItemSpec: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var kind: TinyGameHUDKind
    var variableID: String
    var label: String
    var symbol: String
}
