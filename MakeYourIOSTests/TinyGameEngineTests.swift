import XCTest
@testable import MakeYourIOS

// swiftlint:disable file_length
// The engine safety suite stays together so each fixed-step invariant is exercised consistently.
// swiftlint:disable:next type_body_length
final class TinyGameEngineTests: XCTestCase {
    private let compiler = TinyGameCompiler()

    func testFixedStepReplayIsDeterministicForSeedAndInputTrace() throws {
        let compiled = try compiler.compile(TinyGameTestFixtures.catcherProgram(targetScore: 10))
        var first = TinyGameEngine(program: compiled)
        var second = TinyGameEngine(program: compiled)
        first.start()
        second.start()

        for index in 0..<24 {
            if index == 1 {
                first.setDirectionalInput(x: 1, y: 0, controlID: "move")
                second.setDirectionalInput(x: 1, y: 0, controlID: "move")
            }
            if index == 4 || index == 9 {
                first.activateControl("fire")
                second.activateControl("fire")
            }
            if index == 12 {
                first.setDirectionalInput(x: -1, y: 0, controlID: "move")
                second.setDirectionalInput(x: -1, y: 0, controlID: "move")
            }
            first.step()
            second.step()
            XCTAssertEqual(first.snapshot, second.snapshot, "Mismatch at tick \(index + 1)")
            XCTAssertEqual(first.drainFeedback(), second.drainFeedback())
        }
    }

    func testOrderedCollisionEffectsCollectDestroyAndWin() throws {
        let compiled = try compiler.compile(TinyGameTestFixtures.catcherProgram(
            targetScore: 1,
            includesTimer: false
        ))
        var engine = TinyGameEngine(program: compiled)

        engine.start()
        engine.step()

        XCTAssertEqual(engine.variables["score"], 1)
        XCTAssertEqual(engine.phase, .won)
        XCTAssertFalse(engine.entities.contains(where: { $0.id == "star-one" }))
        XCTAssertEqual(engine.drainFeedback(), [.light])
    }

    func testTickRuleSpawnsWithBoundedDeterministicIdentity() throws {
        let program = TinyGameTestFixtures.catcherProgram(
            targetScore: 10,
            starY: 40,
            includesTimer: true
        )
        let compiled = try compiler.compile(program)
        var engine = TinyGameEngine(program: compiled)

        engine.start()
        engine.step()
        XCTAssertEqual(engine.entities.filter { $0.role == .collectible }.count, 1)
        engine.step()

        let collectibles = engine.entities.filter { $0.role == .collectible }
        XCTAssertEqual(collectibles.count, 2)
        XCTAssertEqual(collectibles.filter { $0.id.hasPrefix("spawn-2-") }.count, 1)
    }

    func testLeaveWorldEffectsConsumeLastLifeAndLose() throws {
        let compiled = try compiler.compile(TinyGameTestFixtures.catcherProgram(
            targetScore: 10,
            initialLives: 1,
            starY: 470,
            starVelocityY: 20,
            includesTimer: false
        ))
        var engine = TinyGameEngine(program: compiled)

        engine.start()
        engine.step()

        XCTAssertEqual(engine.variables["lives"], 0)
        XCTAssertEqual(engine.phase, .lost)
        XCTAssertFalse(engine.entities.contains(where: { $0.id == "star-one" }))
    }

    func testActionControlAndRestartRestoreInitialSnapshotAndRandomStream() throws {
        let compiled = try compiler.compile(TinyGameTestFixtures.catcherProgram(targetScore: 10))
        var engine = TinyGameEngine(program: compiled)
        let initial = engine.snapshot

        engine.start()
        engine.activateControl("fire")
        engine.setDirectionalInput(x: 1, y: 0, controlID: "move")
        engine.step()
        XCTAssertNotEqual(engine.snapshot, initial)

        engine.restart()
        XCTAssertEqual(engine.snapshot, initial)

        engine.start()
        engine.activateControl("fire")
        let firstSpawnID = try XCTUnwrap(
            engine.entities.first(where: { $0.role == .projectile })?.id
        )
        engine.restart()
        engine.start()
        engine.activateControl("fire")
        XCTAssertEqual(
            engine.entities.first(where: { $0.role == .projectile })?.id,
            firstSpawnID
        )
    }

    func testPausePreventsTicksAndVariableWritesClampToDeclaredRange() throws {
        var program = TinyGameTestFixtures.catcherProgram(
            targetScore: 10,
            starY: 40,
            includesTimer: false
        )
        program.rules.append(TinyGameRuleSpec(
            id: "overflow-score",
            trigger: TinyGameTriggerSpec(kind: .tickInterval, everyTicks: 1),
            effects: [TinyGameEffectSpec(
                kind: .addVariable,
                variableID: "score",
                value: 1_000_000
            )]
        ))
        let compiled = try compiler.compile(program)
        var engine = TinyGameEngine(program: compiled)

        engine.start()
        engine.step()
        XCTAssertEqual(engine.variables["score"], 10)
        engine.togglePause()
        let paused = engine.snapshot
        engine.step()
        XCTAssertEqual(engine.snapshot, paused)
    }

    func testFirstTerminalRuleWinsAndStopsLaterRuleEvaluation() throws {
        var program = TinyGameTestFixtures.catcherProgram(includesTimer: false)
        program.rules = [
            TinyGameRuleSpec(
                id: "win-first",
                trigger: TinyGameTriggerSpec(
                    kind: .collision,
                    subjectTag: "player",
                    otherTag: "collectible"
                ),
                effects: [TinyGameEffectSpec(kind: .win)]
            ),
            TinyGameRuleSpec(
                id: "lose-second",
                trigger: TinyGameTriggerSpec(
                    kind: .collision,
                    subjectTag: "player",
                    otherTag: "collectible"
                ),
                effects: [TinyGameEffectSpec(kind: .lose)]
            )
        ]
        let compiled = try compiler.compile(program)
        var engine = TinyGameEngine(program: compiled)

        engine.start()
        engine.step()

        XCTAssertEqual(engine.phase, .won)
    }

    func testCollisionRulesFireOnContactBeginRatherThanEveryOverlapTick() throws {
        var program = TinyGameTestFixtures.catcherProgram(
            targetScore: 10,
            includesTimer: false
        )
        program.rules.removeAll(where: { $0.id == "reach-target" })
        program.rules[1].effects = [
            TinyGameEffectSpec(kind: .addVariable, variableID: "score", value: 1)
        ]
        let compiled = try compiler.compile(program)
        var engine = TinyGameEngine(program: compiled)

        engine.start()
        engine.step()
        engine.step()

        XCTAssertEqual(engine.variables["score"], 1)
    }

    func testDestroyedEntityCannotScoreAgainFromAStaleContactSnapshot() throws {
        var program = TinyGameTestFixtures.catcherProgram(
            targetScore: 10,
            includesTimer: false
        )
        program.rules.removeAll(where: { $0.id == "reach-target" })
        program.spawns.append(TinyGameEntitySpawn(
            id: "player-two",
            templateID: "player",
            x: 160,
            y: 440
        ))
        let compiled = try compiler.compile(program)
        var engine = TinyGameEngine(program: compiled)

        engine.start()
        engine.step()

        XCTAssertEqual(engine.variables["score"], 1)
        XCTAssertFalse(engine.entities.contains(where: { $0.id == "star-one" }))
    }

    func testTerminalStartRulePreventsLaterStartMutations() throws {
        var program = TinyGameTestFixtures.catcherProgram(includesTimer: false)
        program.rules = [
            TinyGameRuleSpec(
                id: "finish-on-start",
                trigger: TinyGameTriggerSpec(kind: .start),
                effects: [TinyGameEffectSpec(kind: .win)]
            ),
            TinyGameRuleSpec(
                id: "must-not-run",
                trigger: TinyGameTriggerSpec(kind: .start),
                effects: [TinyGameEffectSpec(
                    kind: .addVariable,
                    variableID: "score",
                    value: 1
                )]
            )
        ]
        let compiled = try compiler.compile(program)
        var engine = TinyGameEngine(program: compiled)

        engine.start()

        XCTAssertEqual(engine.phase, .won)
        XCTAssertEqual(engine.variables["score"], 0)
    }

    func testLeaveWorldRuleFiresOnlyWhenCrossingTheBoundary() throws {
        var program = TinyGameTestFixtures.catcherProgram(includesTimer: false)
        program.world.edgeBehavior = .clamp
        program.spawns[0].x = 288
        program.rules = [TinyGameRuleSpec(
            id: "count-boundary-crossing",
            trigger: TinyGameTriggerSpec(kind: .leaveWorld, subjectTag: "player"),
            effects: [TinyGameEffectSpec(
                kind: .addVariable,
                variableID: "score",
                value: 1
            )]
        )]
        let compiled = try compiler.compile(program)
        var engine = TinyGameEngine(program: compiled)

        engine.start()
        engine.setDirectionalInput(x: 1, y: 0, controlID: "move")
        engine.step()
        engine.step()
        XCTAssertEqual(engine.variables["score"], 1)

        engine.setDirectionalInput(x: -1, y: 0, controlID: "move")
        engine.step()
        engine.setDirectionalInput(x: 1, y: 0, controlID: "move")
        engine.step()
        engine.step()
        XCTAssertEqual(engine.variables["score"], 2)
    }

    func testSpawnEffectWithoutALiveAnchorDoesNotFallBackToWorldOrigin() throws {
        var program = TinyGameTestFixtures.catcherProgram(includesTimer: false)
        var dormant = program.templates[2]
        dormant.id = "dormant"
        dormant.tags = ["dormant"]
        program.templates.append(dormant)
        program.controls.append(TinyGameControlSpec(
            id: "make-anchor",
            kind: .actionButton,
            label: "Anchor",
            symbol: "circle.fill",
            targetTag: "player",
            spawnTemplateID: "dormant"
        ))
        program.rules = [TinyGameRuleSpec(
            id: "spawn-near-missing-anchor",
            trigger: TinyGameTriggerSpec(kind: .start),
            effects: [TinyGameEffectSpec(
                kind: .spawn,
                target: .tag,
                targetTag: "dormant",
                templateID: "star"
            )]
        )]
        let compiled = try compiler.compile(program)
        var engine = TinyGameEngine(program: compiled)
        let entityCount = engine.entities.count

        engine.start()

        XCTAssertEqual(engine.entities.count, entityCount)
        XCTAssertFalse(engine.entities.contains(where: { $0.id.hasPrefix("spawn-") }))
    }

    func testIrrelevantOverlapsCannotStarveARelevantCollision() throws {
        var program = TinyGameTestFixtures.catcherProgram(
            targetScore: 10,
            includesTimer: false
        )
        program.rules.removeAll(where: { $0.id == "reach-target" })
        program.templates.append(TinyGameEntityTemplate(
            id: "clutter",
            role: .decoration,
            visual: TinyGameVisualSpec(kind: .circle, colorRole: .surface),
            body: .static,
            width: 16,
            height: 16
        ))
        program.spawns.append(contentsOf: (0..<40).map { index in
            TinyGameEntitySpawn(
                id: "clutter-\(index)",
                templateID: "clutter",
                x: 160,
                y: 440
            )
        })
        let compiled = try compiler.compile(program)
        var engine = TinyGameEngine(program: compiled)

        engine.start()
        engine.step()

        XCTAssertEqual(engine.variables["score"], 1)
    }

    func testSolidGroundStopsGravityAndMarksPlayerGrounded() throws {
        let compiled = try compiler.compile(TinyGameTestFixtures.platformerProgram())
        var engine = TinyGameEngine(program: compiled)

        XCTAssertTrue(try XCTUnwrap(
            engine.entities.first(where: { $0.id == "runner-one" })
        ).isGrounded)

        engine.start()
        engine.step()

        let player = try XCTUnwrap(engine.entities.first(where: { $0.id == "runner-one" }))
        XCTAssertEqual(player.y, 404)
        XCTAssertEqual(player.velocityY, 0)
        XCTAssertTrue(player.isGrounded)
    }

    func testGroundedJumpDoesNotClearHorizontalInputOrAllowAirJump() throws {
        let compiled = try compiler.compile(TinyGameTestFixtures.platformerProgram())
        var engine = TinyGameEngine(program: compiled)
        engine.start()
        engine.setDirectionalInput(x: 1, y: 0, controlID: "move")
        engine.activateControl("jump")
        engine.activateControl("jump")

        let launched = try XCTUnwrap(engine.entities.first(where: { $0.id == "runner-one" }))
        XCTAssertEqual(launched.velocityY, -18)
        XCTAssertFalse(launched.isGrounded)
        XCTAssertEqual(engine.controlAvailability("jump").reason, .cooldown)
        XCTAssertFalse(engine.controlAvailability("jump").isEnabled)

        engine.step()

        let airborne = try XCTUnwrap(engine.entities.first(where: { $0.id == "runner-one" }))
        XCTAssertEqual(airborne.velocityX, 8)
        XCTAssertEqual(airborne.velocityY, -14)
        XCTAssertEqual(airborne.x, 88)
        XCTAssertEqual(airborne.y, 390)
        XCTAssertFalse(airborne.isGrounded)

        for _ in 0..<3 { engine.step() }
        XCTAssertEqual(engine.controlAvailability("jump").reason, .airborne)
        XCTAssertFalse(engine.controlAvailability("jump").isEnabled)
    }

    func testOneWayPlatformLandsFromAboveAndDoesNotBlockFromBelow() throws {
        let landingProgram = TinyGameTestFixtures.platformerProgram(playerY: 270)
        var landing = TinyGameEngine(program: try compiler.compile(landingProgram))
        landing.start()
        for _ in 0..<4 { landing.step() }

        let landed = try XCTUnwrap(landing.entities.first(where: { $0.id == "runner-one" }))
        XCTAssertEqual(landed.y, 296)
        XCTAssertEqual(landed.velocityY, 0)
        XCTAssertTrue(landed.isGrounded)

        let risingProgram = TinyGameTestFixtures.platformerProgram(
            playerY: 350,
            playerVelocityY: -24
        )
        var rising = TinyGameEngine(program: try compiler.compile(risingProgram))
        rising.start()
        rising.step()
        rising.step()

        let passedThrough = try XCTUnwrap(
            rising.entities.first(where: { $0.id == "runner-one" })
        )
        XCTAssertEqual(passedThrough.y, 314)
        XCTAssertEqual(passedThrough.velocityY, -16)
        XCTAssertFalse(passedThrough.isGrounded)
    }

    func testFacingProjectileHonorsCooldownMaximumActiveAndLifetime() throws {
        let program = TinyGameTestFixtures.platformerProgram(
            projectileLifetime: 3,
            projectileMaximumActive: 2
        )
        var engine = TinyGameEngine(program: try compiler.compile(program))
        engine.start()
        engine.setDirectionalInput(x: -1, y: 0, controlID: "move")
        engine.step()

        let anchor = try XCTUnwrap(engine.entities.first(where: { $0.id == "runner-one" }))
        engine.activateControl("fire")
        engine.activateControl("fire")
        var projectiles = engine.entities.filter { $0.templateID == "spark" }
        XCTAssertEqual(projectiles.count, 1, "cooldown must reject a second activation in one tick")
        XCTAssertEqual(projectiles[0].x, anchor.x - 22)
        XCTAssertEqual(projectiles[0].velocityX, -18)

        engine.step()
        engine.activateControl("fire")
        XCTAssertEqual(engine.entities.filter { $0.templateID == "spark" }.count, 2)

        engine.step()
        engine.activateControl("fire")
        XCTAssertEqual(
            engine.entities.filter { $0.templateID == "spark" }.count,
            2,
            "maximumActive must reject a third live projectile"
        )
        XCTAssertEqual(engine.controlAvailability("fire").reason, .maximumActive)

        engine.step()
        projectiles = engine.entities.filter { $0.templateID == "spark" }
        XCTAssertEqual(projectiles.count, 1, "the oldest projectile expires at its bounded lifetime")
        engine.activateControl("fire")
        XCTAssertEqual(engine.entities.filter { $0.templateID == "spark" }.count, 2)
    }

    func testV3ReplayAndRestartRemainDeterministic() throws {
        let compiled = try compiler.compile(TinyGameTestFixtures.platformerProgram())
        var first = TinyGameEngine(program: compiled)
        var second = TinyGameEngine(program: compiled)
        let initial = first.snapshot
        XCTAssertEqual(initial.controls.map(\.id), ["fire", "jump", "move"])
        first.start()
        second.start()

        for index in 0..<16 {
            if index == 0 {
                first.activateControl("jump")
                second.activateControl("jump")
                XCTAssertEqual(
                    first.controlAvailability("jump").availableAtTick,
                    4
                )
            }
            if index == 2 {
                first.setDirectionalInput(x: -1, y: 0, controlID: "move")
                second.setDirectionalInput(x: -1, y: 0, controlID: "move")
            }
            if index == 3 || index == 8 {
                first.activateControl("fire")
                second.activateControl("fire")
            }
            first.step()
            second.step()
            XCTAssertEqual(first.snapshot, second.snapshot, "Mismatch at V3 tick \(index + 1)")
        }

        first.restart()
        XCTAssertEqual(first.snapshot, initial)
        XCTAssertEqual(first.controlAvailability("jump").availableAtTick, 0)
        first.start()
        first.activateControl("jump")
        XCTAssertEqual(
            first.entities.first(where: { $0.id == "runner-one" })?.velocityY,
            -18
        )
    }

    func testV3SweptSensorCollisionCatchesFastProjectileBetweenFrames() throws {
        var program = TinyGameTestFixtures.platformerProgram()
        program.variables = [TinyGameVariableSpec(
            id: "hits",
            initialValue: 0,
            minimumValue: 0,
            maximumValue: 10
        )]
        program.templates[3].velocityX = 80
        program.templates[3].physics?.maximumVelocityX = 80
        program.templates.append(TinyGameEntityTemplate(
            id: "target",
            role: .enemy,
            visual: TinyGameVisualSpec(kind: .rectangle, colorRole: .hazard),
            body: .static,
            width: 12,
            height: 28,
            tags: ["target"],
            physics: TinyGamePhysicsSpec(collisionMode: .sensor)
        ))
        program.spawns.append(TinyGameEntitySpawn(
            id: "target-one",
            templateID: "target",
            x: 145,
            y: 404
        ))
        program.rules = [TinyGameRuleSpec(
            id: "projectile-hit",
            trigger: TinyGameTriggerSpec(
                kind: .collision,
                subjectTag: "friendly",
                otherTag: "target"
            ),
            effects: [
                TinyGameEffectSpec(kind: .addVariable, variableID: "hits", value: 1),
                TinyGameEffectSpec(kind: .destroy, target: .other)
            ]
        )]
        var engine = TinyGameEngine(program: try compiler.compile(program))
        engine.start()
        engine.activateControl("fire")
        engine.step()

        XCTAssertEqual(engine.variables["hits"], 1)
        XCTAssertFalse(engine.entities.contains(where: { $0.id == "target-one" }))
        let projectile = try XCTUnwrap(
            engine.entities.first(where: { $0.templateID == "spark" })
        )
        XCTAssertGreaterThan(projectile.x, 145)
    }
}
