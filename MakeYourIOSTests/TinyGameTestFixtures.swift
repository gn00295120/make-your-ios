@testable import MakeYourIOS

// swiftlint:disable:next type_body_length
enum TinyGameTestFixtures {
    // swiftlint:disable:next function_body_length
    static func platformerProgram(
        playerY: Int = 404,
        playerVelocityY: Int = 0,
        projectileLifetime: Int = 6,
        projectileMaximumActive: Int = 2
    ) -> TinyGameProgram {
        let player = TinyGameEntityTemplate(
            id: "runner",
            role: .player,
            visual: TinyGameVisualSpec(kind: .rectangle, colorRole: .accent),
            body: .dynamic,
            movement: .platformerAxis,
            width: 24,
            height: 32,
            velocityY: playerVelocityY,
            speed: 8,
            tags: ["hero"],
            physics: TinyGamePhysicsSpec(
                collisionMode: .solid,
                maximumVelocityX: 20,
                maximumVelocityY: 32
            )
        )
        let ground = TinyGameEntityTemplate(
            id: "ground",
            role: .decoration,
            visual: TinyGameVisualSpec(kind: .rectangle, colorRole: .surface),
            body: .static,
            width: 320,
            height: 40,
            tags: ["ground"],
            physics: TinyGamePhysicsSpec(collisionMode: .solid)
        )
        let oneWay = TinyGameEntityTemplate(
            id: "cloud-platform",
            role: .decoration,
            visual: TinyGameVisualSpec(kind: .rectangle, colorRole: .primary),
            body: .static,
            width: 140,
            height: 16,
            tags: ["platform"],
            physics: TinyGamePhysicsSpec(collisionMode: .oneWayPlatform)
        )
        let projectile = TinyGameEntityTemplate(
            id: "spark",
            role: .projectile,
            visual: TinyGameVisualSpec(kind: .circle, colorRole: .collectible),
            body: .kinematic,
            movement: .constant,
            width: 12,
            height: 12,
            velocityX: 18,
            tags: ["friendly"],
            physics: TinyGamePhysicsSpec(
                collisionMode: .sensor,
                maximumVelocityX: 18,
                maximumVelocityY: 18,
                lifetimeTicks: projectileLifetime
            )
        )

        return TinyGameProgram(
            version: 3,
            seed: 303,
            tickRate: .thirty,
            world: TinyGameWorldSpec(
                width: 320,
                height: 480,
                gravityY: 4,
                edgeBehavior: .solid
            ),
            templates: [player, ground, oneWay, projectile],
            spawns: [
                TinyGameEntitySpawn(id: "runner-one", templateID: "runner", x: 80, y: playerY),
                TinyGameEntitySpawn(id: "ground-one", templateID: "ground", x: 160, y: 440),
                TinyGameEntitySpawn(
                    id: "cloud-one",
                    templateID: "cloud-platform",
                    x: 160,
                    y: 320
                )
            ],
            controls: [
                TinyGameControlSpec(
                    id: "move",
                    kind: .horizontal,
                    label: "Move",
                    symbol: "arrow.left.and.right",
                    targetTag: "player",
                    speed: 8
                ),
                TinyGameControlSpec(
                    id: "jump",
                    kind: .actionButton,
                    label: "Jump",
                    symbol: "arrow.up",
                    targetTag: "player",
                    action: TinyGameControlActionSpec(
                        kind: .jump,
                        impulse: 18,
                        cooldownTicks: 4
                    )
                ),
                TinyGameControlSpec(
                    id: "fire",
                    kind: .actionButton,
                    label: "Fire",
                    symbol: "bolt.fill",
                    targetTag: "player",
                    spawnTemplateID: "spark",
                    action: TinyGameControlActionSpec(
                        kind: .projectile,
                        cooldownTicks: 1,
                        maximumActive: projectileMaximumActive,
                        offsetX: 22
                    )
                )
            ]
        )
    }

    // A full vertical fixture is kept together so tests exercise the same generated document.
    // swiftlint:disable:next function_body_length
    static func catcherProgram(
        targetScore: Int = 3,
        initialLives: Int = 3,
        starY: Int = 420,
        starVelocityY: Int = 8,
        includesTimer: Bool = true
    ) -> TinyGameProgram {
        let variables = [
            TinyGameVariableSpec(
                id: "score",
                initialValue: 0,
                minimumValue: 0,
                maximumValue: max(targetScore, 10)
            ),
            TinyGameVariableSpec(
                id: "lives",
                initialValue: initialLives,
                minimumValue: 0,
                maximumValue: 5
            ),
            TinyGameVariableSpec(
                id: "started",
                kind: .boolean,
                initialValue: 0,
                minimumValue: 0,
                maximumValue: 1
            )
        ]
        let templates = [playerTemplate, starTemplate(velocityY: starVelocityY), projectileTemplate]
        var rules = [
            TinyGameRuleSpec(
                id: "mark-started",
                trigger: TinyGameTriggerSpec(kind: .start),
                effects: [TinyGameEffectSpec(
                    kind: .setVariable,
                    variableID: "started",
                    value: 1
                )]
            ),
            TinyGameRuleSpec(
                id: "collect-star",
                trigger: TinyGameTriggerSpec(
                    kind: .collision,
                    subjectTag: "player",
                    otherTag: "collectible"
                ),
                effects: [
                    TinyGameEffectSpec(kind: .addVariable, variableID: "score", value: 1),
                    TinyGameEffectSpec(kind: .destroy, target: .other),
                    TinyGameEffectSpec(kind: .feedback, feedback: .light)
                ]
            ),
            TinyGameRuleSpec(
                id: "reach-target",
                trigger: TinyGameTriggerSpec(
                    kind: .collision,
                    subjectTag: "player",
                    otherTag: "collectible"
                ),
                conditions: [TinyGameConditionSpec(
                    variableID: "score",
                    comparison: .greaterOrEqual,
                    value: targetScore
                )],
                effects: [TinyGameEffectSpec(kind: .win, feedback: .none)]
            ),
            TinyGameRuleSpec(
                id: "miss-star",
                trigger: TinyGameTriggerSpec(kind: .leaveWorld, subjectTag: "collectible"),
                effects: [
                    TinyGameEffectSpec(kind: .addVariable, variableID: "lives", value: -1),
                    TinyGameEffectSpec(kind: .destroy, target: .subject)
                ]
            ),
            TinyGameRuleSpec(
                id: "out-of-lives",
                trigger: TinyGameTriggerSpec(kind: .leaveWorld, subjectTag: "collectible"),
                conditions: [TinyGameConditionSpec(
                    variableID: "lives",
                    comparison: .lessOrEqual,
                    value: 0
                )],
                effects: [TinyGameEffectSpec(kind: .lose, feedback: .none)]
            )
        ]
        if includesTimer {
            rules.append(TinyGameRuleSpec(
                id: "spawn-stars",
                trigger: TinyGameTriggerSpec(kind: .tickInterval, everyTicks: 2),
                effects: [TinyGameEffectSpec(
                    kind: .spawn,
                    target: .player,
                    value: 20,
                    x: 0,
                    y: -320,
                    templateID: "star"
                )]
            ))
        }

        return TinyGameProgram(
            version: 2,
            seed: 91,
            tickRate: .thirty,
            world: TinyGameWorldSpec(width: 320, height: 480, edgeBehavior: .destroy),
            variables: variables,
            templates: templates,
            spawns: [
                TinyGameEntitySpawn(id: "player-one", templateID: "player", x: 160, y: 440),
                TinyGameEntitySpawn(id: "star-one", templateID: "star", x: 160, y: starY)
            ],
            controls: [
                TinyGameControlSpec(
                    id: "move",
                    kind: .horizontal,
                    label: "Move",
                    symbol: "arrow.left.and.right",
                    targetTag: "player",
                    speed: 10
                ),
                TinyGameControlSpec(
                    id: "fire",
                    kind: .actionButton,
                    label: "Fire",
                    symbol: "bolt.fill",
                    targetTag: "player",
                    spawnTemplateID: "projectile"
                )
            ],
            rules: rules,
            hud: [
                TinyGameHUDItemSpec(
                    id: "score-hud",
                    kind: .score,
                    variableID: "score",
                    label: "Score",
                    symbol: "star.fill"
                ),
                TinyGameHUDItemSpec(
                    id: "lives-hud",
                    kind: .lives,
                    variableID: "lives",
                    label: "Lives",
                    symbol: "heart.fill"
                )
            ]
        )
    }

    private static let playerTemplate = TinyGameEntityTemplate(
        id: "player",
        role: .player,
        visual: TinyGameVisualSpec(kind: .rectangle, colorRole: .accent),
        body: .kinematic,
        movement: .playerAxis,
        width: 64,
        height: 24,
        speed: 10,
        tags: ["catcher"]
    )

    private static func starTemplate(velocityY: Int) -> TinyGameEntityTemplate {
        TinyGameEntityTemplate(
            id: "star",
            role: .collectible,
            visual: TinyGameVisualSpec(kind: .circle, colorRole: .collectible),
            body: .kinematic,
            movement: .constant,
            width: 20,
            height: 20,
            velocityY: velocityY,
            tags: ["falling"]
        )
    }

    private static let projectileTemplate = TinyGameEntityTemplate(
        id: "projectile",
        role: .projectile,
        visual: TinyGameVisualSpec(
            kind: .sfSymbol,
            colorRole: .primary,
            symbol: "arrow.up.circle.fill"
        ),
        body: .kinematic,
        movement: .constant,
        width: 18,
        height: 18,
        velocityY: -12,
        tags: ["friendly"]
    )
}
