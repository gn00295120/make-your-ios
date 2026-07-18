import XCTest
@testable import MakeYourIOS

// swiftlint:disable:next type_body_length
final class TinyGameCompilerTests: XCTestCase {
    private let compiler = TinyGameCompiler()

    func testCompilerResolvesValidProgramAndIndexesRulesInSourceOrder() throws {
        let program = TinyGameTestFixtures.catcherProgram()
        let compiled = try compiler.compile(program)

        XCTAssertEqual(compiled.templatesByID.count, 3)
        XCTAssertEqual(compiled.variableSpecsByID.count, 3)
        XCTAssertEqual(compiled.controlsByID.count, 2)
        XCTAssertTrue(compiled.knownTags.isSuperset(of: ["player", "collectible", "catcher"]))
        XCTAssertEqual(
            compiled.rulesByTrigger[.collision]?.map(\.id),
            ["collect-star", "reach-target"]
        )
    }

    func testCompilerFailsClosedForUnresolvedTemplateAndTagReferences() {
        var missingTemplate = TinyGameTestFixtures.catcherProgram()
        missingTemplate.spawns[0].templateID = "missing"
        XCTAssertThrowsError(try compiler.compile(missingTemplate)) { error in
            XCTAssertEqual(
                error as? TinyGameCompilerError,
                .unresolvedReference("template missing")
            )
        }

        var missingTag = TinyGameTestFixtures.catcherProgram()
        missingTag.rules[1].trigger.subjectTag = "ghost"
        XCTAssertThrowsError(try compiler.compile(missingTag)) { error in
            XCTAssertEqual(error as? TinyGameCompilerError, .invalidRule("collect-star"))
        }
    }

    func testCompilerRejectsEveryAuditedCollectionBudget() {
        var variables = TinyGameTestFixtures.catcherProgram()
        variables.variables = (0...TinyGameAuditLimits.maximumVariables).map {
            TinyGameVariableSpec(id: "value-\($0)", initialValue: 0)
        }
        assertLimit(variables, expected: "variables")

        var templates = TinyGameTestFixtures.catcherProgram()
        let base = templates.templates[0]
        templates.templates = (0...TinyGameAuditLimits.maximumTemplates).map { index in
            var template = base
            template.id = "template-\(index)"
            return template
        }
        assertLimit(templates, expected: "templates")

        var entities = TinyGameTestFixtures.catcherProgram()
        entities.spawns = (0...TinyGameAuditLimits.maximumInitialEntities).map {
            TinyGameEntitySpawn(id: "entity-\($0)", templateID: "player", x: 100, y: 100)
        }
        assertLimit(entities, expected: "initial entities")

        var rules = TinyGameTestFixtures.catcherProgram()
        rules.rules = (0...TinyGameAuditLimits.maximumRules).map {
            TinyGameRuleSpec(
                id: "rule-\($0)",
                trigger: TinyGameTriggerSpec(kind: .start),
                effects: [TinyGameEffectSpec(kind: .win)]
            )
        }
        assertLimit(rules, expected: "rules")
    }

    func testCompilerRejectsInvalidBooleanAndContextualRuleTarget() {
        var invalidBoolean = TinyGameTestFixtures.catcherProgram()
        invalidBoolean.variables[2].initialValue = 2
        XCTAssertThrowsError(try compiler.compile(invalidBoolean)) { error in
            XCTAssertEqual(
                error as? TinyGameCompilerError,
                .invalidValue("boolean variable started")
            )
        }

        var invalidTarget = TinyGameTestFixtures.catcherProgram()
        invalidTarget.rules[0].effects = [TinyGameEffectSpec(
            kind: .destroy,
            target: .subject
        )]
        XCTAssertThrowsError(try compiler.compile(invalidTarget)) { error in
            XCTAssertEqual(error as? TinyGameCompilerError, .invalidRule("mark-started"))
        }
    }

    func testCompilerRejectsControlsWithoutAnInitiallyReachableTarget() {
        var immovable = TinyGameTestFixtures.catcherProgram()
        immovable.templates[0].movement = .none
        XCTAssertThrowsError(try compiler.compile(immovable)) { error in
            XCTAssertEqual(
                error as? TinyGameCompilerError,
                .invalidValue("movement control move")
            )
        }

        var missingActionAnchor = TinyGameTestFixtures.catcherProgram()
        missingActionAnchor.controls = [missingActionAnchor.controls[1]]
        missingActionAnchor.spawns.removeAll(where: { $0.templateID == "player" })
        XCTAssertThrowsError(try compiler.compile(missingActionAnchor)) { error in
            XCTAssertEqual(
                error as? TinyGameCompilerError,
                .unresolvedReference("action target player")
            )
        }
    }

    func testCompilerRejectsOversizedEntitiesAndPartiallyOutsideInitialSpawns() {
        var oversized = TinyGameTestFixtures.catcherProgram()
        oversized.templates[0].width = oversized.world.width + 1
        XCTAssertThrowsError(try compiler.compile(oversized)) { error in
            XCTAssertEqual(
                error as? TinyGameCompilerError,
                .invalidValue("template player")
            )
        }

        var outside = TinyGameTestFixtures.catcherProgram()
        outside.spawns[0].x = 0
        XCTAssertThrowsError(try compiler.compile(outside)) { error in
            XCTAssertEqual(
                error as? TinyGameCompilerError,
                .invalidValue("spawn player-one")
            )
        }
    }

    func testCompilerRejectsAggregateTriggerBudgets() {
        var excessiveSpawns = TinyGameTestFixtures.catcherProgram(includesTimer: false)
        excessiveSpawns.rules = (0...TinyGameAuditLimits.maximumSpawnsPerTick).map { index in
            TinyGameRuleSpec(
                id: "spawn-rule-\(index)",
                trigger: TinyGameTriggerSpec(kind: .start),
                effects: [TinyGameEffectSpec(
                    kind: .spawn,
                    target: .player,
                    templateID: "star"
                )]
            )
        }
        assertLimit(excessiveSpawns, expected: "start spawn effects")

        var excessiveEffects = TinyGameTestFixtures.catcherProgram(includesTimer: false)
        excessiveEffects.rules = (0..<43).map { index in
            TinyGameRuleSpec(
                id: "effect-rule-\(index)",
                trigger: TinyGameTriggerSpec(kind: .tickInterval, everyTicks: 1),
                effects: (0..<6).map { _ in
                    TinyGameEffectSpec(kind: .feedback, feedback: .light)
                }
            )
        }
        assertLimit(excessiveEffects, expected: "tickInterval effects")
    }

    func testCompilerRejectsDeclaredButUnreachableRuleTags() {
        var program = TinyGameTestFixtures.catcherProgram(includesTimer: false)
        program.templates.append(TinyGameEntityTemplate(
            id: "dormant",
            role: .enemy,
            visual: TinyGameVisualSpec(kind: .circle, colorRole: .hazard),
            body: .kinematic,
            width: 20,
            height: 20,
            tags: ["unreachable"]
        ))
        program.rules = [TinyGameRuleSpec(
            id: "unreachable-collision",
            trigger: TinyGameTriggerSpec(
                kind: .collision,
                subjectTag: "player",
                otherTag: "unreachable"
            ),
            effects: [TinyGameEffectSpec(kind: .win)]
        )]

        XCTAssertThrowsError(try compiler.compile(program)) { error in
            XCTAssertEqual(
                error as? TinyGameCompilerError,
                .invalidRule("unreachable-collision")
            )
        }
    }

    func testCompilerAcceptsBoundedV3PlatformerProgram() throws {
        let compiled = try compiler.compile(TinyGameTestFixtures.platformerProgram())

        XCTAssertEqual(compiled.source.version, 3)
        XCTAssertEqual(compiled.templatesByID["runner"]?.movement, .platformerAxis)
        XCTAssertEqual(
            compiled.templatesByID["cloud-platform"]?.physics?.collisionMode,
            .oneWayPlatform
        )
        XCTAssertEqual(compiled.controlsByID["jump"]?.action?.kind, .jump)
        XCTAssertEqual(compiled.controlsByID["fire"]?.action?.kind, .projectile)
    }

    func testCompilerRejectsV3FeaturesDeclaredAsVersionTwo() {
        var program = TinyGameTestFixtures.platformerProgram()
        program.version = 2

        XCTAssertThrowsError(try compiler.compile(program)) { error in
            XCTAssertEqual(
                error as? TinyGameCompilerError,
                .invalidValue("version 2 features")
            )
        }
    }

    func testCompilerRejectsV3BodyWithoutExplicitPhysics() {
        var program = TinyGameTestFixtures.platformerProgram()
        program.templates[0].physics = nil

        XCTAssertThrowsError(try compiler.compile(program)) { error in
            XCTAssertEqual(
                error as? TinyGameCompilerError,
                .invalidValue("physics in runner")
            )
        }
    }

    func testCompilerRejectsUnsupportedMovableSolidTopology() {
        var program = TinyGameTestFixtures.platformerProgram()
        program.spawns.append(TinyGameEntitySpawn(
            id: "runner-two",
            templateID: "runner",
            x: 140,
            y: 404
        ))

        XCTAssertThrowsError(try compiler.compile(program)) { error in
            XCTAssertEqual(
                error as? TinyGameCompilerError,
                .invalidValue("movable solid topology")
            )
        }
    }

    func testCompilerRejectsRuntimeSolidSpawns() {
        var actionProgram = TinyGameTestFixtures.platformerProgram()
        actionProgram.controls[2].spawnTemplateID = "ground"
        XCTAssertThrowsError(try compiler.compile(actionProgram)) { error in
            XCTAssertEqual(
                error as? TinyGameCompilerError,
                .invalidValue("projectile action fire")
            )
        }

        var ruleProgram = TinyGameTestFixtures.platformerProgram()
        ruleProgram.rules = [TinyGameRuleSpec(
            id: "unsafe-platform-spawn",
            trigger: TinyGameTriggerSpec(kind: .start),
            effects: [TinyGameEffectSpec(
                kind: .spawn,
                target: .player,
                templateID: "ground"
            )]
        )]
        XCTAssertThrowsError(try compiler.compile(ruleProgram)) { error in
            XCTAssertEqual(
                error as? TinyGameCompilerError,
                .invalidValue("runtime solid spawn ground")
            )
        }
    }

    func testCompilerRejectsUnboundedProjectileAndInvalidJumpActions() {
        var projectile = TinyGameTestFixtures.platformerProgram()
        projectile.templates[3].physics?.lifetimeTicks = 0
        XCTAssertThrowsError(try compiler.compile(projectile)) { error in
            XCTAssertEqual(
                error as? TinyGameCompilerError,
                .invalidValue("projectile action fire")
            )
        }

        var jump = TinyGameTestFixtures.platformerProgram()
        jump.controls[1].action?.impulse = 0
        XCTAssertThrowsError(try compiler.compile(jump)) { error in
            XCTAssertEqual(
                error as? TinyGameCompilerError,
                .invalidValue("jump action jump")
            )
        }
    }

    private func assertLimit(
        _ program: TinyGameProgram,
        expected: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try compiler.compile(program), file: file, line: line) { error in
            XCTAssertEqual(
                error as? TinyGameCompilerError,
                .limitExceeded(expected),
                file: file,
                line: line
            )
        }
    }
}
