import Foundation

extension SampleDocuments {
    static let starGarden = AppDocument(
        name: "Star Garden",
        summary: "A rule-driven arcade game assembled from world, entity, control, collision, score, and win blocks.",
        symbol: "star.fill",
        tint: .plum,
        capabilities: [.haptics, .localStorage],
        theme: .preset(.bold),
        pages: [
            AppPage(
                id: "home",
                title: "Star Garden",
                nodes: [
                    ComponentNode(
                        id: "star-garden-game",
                        kind: .game,
                        title: "Starlight Rescue",
                        subtitle: "Guide the glider, collect five stars, and avoid the solar flares.",
                        symbol: "star.fill",
                        presentation: ComponentPresentation(
                            surface: .plain,
                            span: .full,
                            alignment: .leading,
                            emphasis: .strong,
                            variant: .immersive
                        ),
                        game: GameSpec(
                            kind: .custom,
                            difficulty: .standard,
                            palette: .neon,
                            targetScore: 5,
                            levelSeed: 2_026,
                            playerName: "Glider",
                            collectibleName: "Star",
                            haptics: true,
                            program: starGardenProgram
                        )
                    )
                ],
                presentation: PagePresentation(layout: .story, showsNavigationTitle: false)
            )
        ]
    )

    static let starGardenProgram = TinyGameProgram(
        version: 2,
        seed: 2_026,
        world: TinyGameWorldSpec(
            width: 320,
            height: 420,
            edgeBehavior: .clamp
        ),
        variables: [
            TinyGameVariableSpec(
                id: "score",
                initialValue: 0,
                minimumValue: 0,
                maximumValue: 5
            )
        ],
        templates: [
            TinyGameEntityTemplate(
                id: "glider",
                role: .player,
                visual: TinyGameVisualSpec(
                    kind: .sfSymbol,
                    colorRole: .primary,
                    symbol: "paperplane.fill"
                ),
                body: .kinematic,
                movement: .playerAxis,
                width: 28,
                height: 28,
                speed: 4
            ),
            TinyGameEntityTemplate(
                id: "star",
                role: .collectible,
                visual: TinyGameVisualSpec(
                    kind: .sfSymbol,
                    colorRole: .collectible,
                    symbol: "star.fill"
                ),
                body: .static,
                width: 24,
                height: 24
            ),
            TinyGameEntityTemplate(
                id: "solar-flare",
                role: .hazard,
                visual: TinyGameVisualSpec(
                    kind: .sfSymbol,
                    colorRole: .hazard,
                    symbol: "flame.fill"
                ),
                body: .static,
                width: 34,
                height: 34
            )
        ],
        spawns: [
            TinyGameEntitySpawn(id: "player", templateID: "glider", x: 160, y: 390),
            TinyGameEntitySpawn(id: "star-one", templateID: "star", x: 45, y: 55),
            TinyGameEntitySpawn(id: "star-two", templateID: "star", x: 160, y: 80),
            TinyGameEntitySpawn(id: "star-three", templateID: "star", x: 275, y: 55),
            TinyGameEntitySpawn(id: "star-four", templateID: "star", x: 75, y: 210),
            TinyGameEntitySpawn(id: "star-five", templateID: "star", x: 245, y: 250),
            TinyGameEntitySpawn(id: "flare-one", templateID: "solar-flare", x: 160, y: 180),
            TinyGameEntitySpawn(id: "flare-two", templateID: "solar-flare", x: 110, y: 300),
            TinyGameEntitySpawn(id: "flare-three", templateID: "solar-flare", x: 230, y: 340)
        ],
        controls: [
            TinyGameControlSpec(
                id: "move-glider",
                kind: .fourWay,
                label: "Glider",
                symbol: "paperplane.fill",
                targetTag: "player",
                speed: 4
            )
        ],
        rules: [
            TinyGameRuleSpec(
                id: "collect-star",
                trigger: TinyGameTriggerSpec(
                    kind: .collision,
                    subjectTag: "player",
                    otherTag: "collectible"
                ),
                conditions: [
                    TinyGameConditionSpec(variableID: "score", comparison: .less, value: 5)
                ],
                effects: [
                    TinyGameEffectSpec(kind: .addVariable, variableID: "score", value: 1),
                    TinyGameEffectSpec(kind: .destroy, target: .other),
                    TinyGameEffectSpec(kind: .feedback, feedback: .success)
                ]
            ),
            TinyGameRuleSpec(
                id: "win-with-five-stars",
                trigger: TinyGameTriggerSpec(
                    kind: .collision,
                    subjectTag: "player",
                    otherTag: "collectible"
                ),
                conditions: [
                    TinyGameConditionSpec(
                        variableID: "score",
                        comparison: .greaterOrEqual,
                        value: 5
                    )
                ],
                effects: [TinyGameEffectSpec(kind: .win)]
            ),
            TinyGameRuleSpec(
                id: "avoid-flare",
                trigger: TinyGameTriggerSpec(
                    kind: .collision,
                    subjectTag: "player",
                    otherTag: "hazard"
                ),
                effects: [
                    TinyGameEffectSpec(kind: .feedback, feedback: .error),
                    TinyGameEffectSpec(kind: .lose)
                ]
            )
        ],
        hud: [
            TinyGameHUDItemSpec(
                id: "score-hud",
                kind: .score,
                variableID: "score",
                label: "Stars",
                symbol: "star.fill"
            )
        ]
    )
}
