import Foundation

// The compiler keeps every audit rule in one reviewable boundary.
// swiftlint:disable file_length

enum TinyGameAuditLimits {
    static let maximumVariables = 32
    static let maximumTemplates = 24
    static let maximumInitialEntities = 128
    static let maximumRuntimeEntities = 192
    static let maximumControls = 6
    static let maximumRules = 64
    static let maximumConditionsPerRule = 4
    static let maximumEffectsPerRule = 6
    static let maximumHUDItems = 8
    static let maximumSpawnsPerTick = 4
    static let maximumEffectsPerTick = 256
    static let maximumContactsPerTick = 512
    static let maximumCatchUpTicks = 4
}

struct TinyGameCompiledProgram: Sendable {
    let source: TinyGameProgram
    let variableSpecsByID: [String: TinyGameVariableSpec]
    let templatesByID: [String: TinyGameEntityTemplate]
    let controlsByID: [String: TinyGameControlSpec]
    let knownTags: Set<String>
    let rulesByTrigger: [TinyGameTriggerKind: [TinyGameRuleSpec]]
}

// swiftlint:disable:next type_body_length
struct TinyGameCompiler: Sendable {
    func compile(_ program: TinyGameProgram) throws -> TinyGameCompiledProgram {
        guard program.version == TinyGameProgram.currentVersion else {
            throw TinyGameCompilerError.unsupportedVersion(program.version)
        }
        guard (0...999_999).contains(program.seed) else {
            throw TinyGameCompilerError.invalidValue("seed")
        }

        try validateCounts(program)
        try validateWorld(program.world)
        try validateUniqueIDs(program)

        let variableSpecs = Dictionary(uniqueKeysWithValues: program.variables.map { ($0.id, $0) })
        let templates = Dictionary(uniqueKeysWithValues: program.templates.map { ($0.id, $0) })
        let controls = Dictionary(uniqueKeysWithValues: program.controls.map { ($0.id, $0) })
        try validateVariables(program.variables)
        try validateTemplates(program.templates, world: program.world)

        let knownTags = Set(program.templates.flatMap { template in
            template.tags + [template.role.rawValue]
        })
        try validateSpawns(program.spawns, templates: templates, world: program.world)
        try validateControls(
            program.controls,
            templates: templates,
            spawns: program.spawns,
            knownTags: knownTags
        )
        let reachableTags = reachableEntityTags(in: program, templates: templates)
        try validateRules(
            program.rules,
            variables: variableSpecs,
            templates: templates,
            reachableTags: reachableTags,
            world: program.world
        )
        try validateHUD(program.hud, variables: variableSpecs)

        let rulesByTrigger = Dictionary(grouping: program.rules, by: { $0.trigger.kind })
        return TinyGameCompiledProgram(
            source: program,
            variableSpecsByID: variableSpecs,
            templatesByID: templates,
            controlsByID: controls,
            knownTags: knownTags,
            rulesByTrigger: rulesByTrigger
        )
    }

    private func validateCounts(_ program: TinyGameProgram) throws {
        try requireMaximum(program.variables.count, TinyGameAuditLimits.maximumVariables, "variables")
        try requireMaximum(program.templates.count, TinyGameAuditLimits.maximumTemplates, "templates")
        try requireMaximum(
            program.spawns.count,
            TinyGameAuditLimits.maximumInitialEntities,
            "initial entities"
        )
        try requireMaximum(program.controls.count, TinyGameAuditLimits.maximumControls, "controls")
        try requireMaximum(program.rules.count, TinyGameAuditLimits.maximumRules, "rules")
        try requireMaximum(program.hud.count, TinyGameAuditLimits.maximumHUDItems, "HUD items")
        guard !program.templates.isEmpty else {
            throw TinyGameCompilerError.invalidValue("templates")
        }
        for rule in program.rules {
            try requireMaximum(
                rule.conditions.count,
                TinyGameAuditLimits.maximumConditionsPerRule,
                "conditions in rule \(rule.id)"
            )
            try requireMaximum(
                rule.effects.count,
                TinyGameAuditLimits.maximumEffectsPerRule,
                "effects in rule \(rule.id)"
            )
            guard !rule.effects.isEmpty else {
                throw TinyGameCompilerError.invalidRule(rule.id)
            }
            let spawnCount = rule.effects.filter { $0.kind == .spawn }.count
            try requireMaximum(
                spawnCount,
                TinyGameAuditLimits.maximumSpawnsPerTick,
                "spawn effects in rule \(rule.id)"
            )
        }
        try validateAggregateRuleBudgets(program.rules)
    }

    private func validateAggregateRuleBudgets(_ rules: [TinyGameRuleSpec]) throws {
        for triggerKind in TinyGameTriggerKind.allCases {
            let effects = rules
                .filter { $0.trigger.kind == triggerKind }
                .flatMap(\.effects)
            try requireMaximum(
                effects.count,
                TinyGameAuditLimits.maximumEffectsPerTick,
                "\(triggerKind.rawValue) effects"
            )
            try requireMaximum(
                effects.filter { $0.kind == .spawn }.count,
                TinyGameAuditLimits.maximumSpawnsPerTick,
                "\(triggerKind.rawValue) spawn effects"
            )
        }
    }

    private func validateWorld(_ world: TinyGameWorldSpec) throws {
        guard (240...4_096).contains(world.width),
              (240...4_096).contains(world.height),
              (-64...64).contains(world.gravityX),
              (-64...64).contains(world.gravityY) else {
            throw TinyGameCompilerError.invalidValue("world")
        }
    }

    private func validateUniqueIDs(_ program: TinyGameProgram) throws {
        let groups: [(String, [String])] = [
            ("variable", program.variables.map(\.id)),
            ("template", program.templates.map(\.id)),
            ("entity", program.spawns.map(\.id)),
            ("control", program.controls.map(\.id)),
            ("rule", program.rules.map(\.id)),
            ("HUD", program.hud.map(\.id))
        ]
        for (label, identifiers) in groups {
            guard identifiers.allSatisfy(isSafeID) else {
                throw TinyGameCompilerError.invalidValue("\(label) ID")
            }
            guard Set(identifiers).count == identifiers.count else {
                throw TinyGameCompilerError.duplicateID(label)
            }
        }
    }

    private func validateVariables(_ variables: [TinyGameVariableSpec]) throws {
        for variable in variables {
            if variable.kind == .boolean {
                guard variable.minimumValue == 0,
                      variable.maximumValue == 1,
                      [0, 1].contains(variable.initialValue) else {
                    throw TinyGameCompilerError.invalidValue("boolean variable \(variable.id)")
                }
                continue
            }
            guard (-1_000_000...1_000_000).contains(variable.minimumValue),
                  (-1_000_000...1_000_000).contains(variable.maximumValue),
                  variable.minimumValue <= variable.maximumValue,
                  (variable.minimumValue...variable.maximumValue).contains(variable.initialValue) else {
                throw TinyGameCompilerError.invalidValue("variable \(variable.id)")
            }
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func validateTemplates(
        _ templates: [TinyGameEntityTemplate],
        world: TinyGameWorldSpec
    ) throws {
        for template in templates {
            guard (4...1_024).contains(template.width),
                  (4...1_024).contains(template.height),
                  template.width <= world.width,
                  template.height <= world.height,
                  (-128...128).contains(template.velocityX),
                  (-128...128).contains(template.velocityY),
                  (0...128).contains(template.speed),
                  template.tags.count <= 8,
                  Set(template.tags).count == template.tags.count,
                  template.tags.allSatisfy(isSafeID) else {
                throw TinyGameCompilerError.invalidValue("template \(template.id)")
            }
            if template.visual.kind == .sfSymbol {
                guard isSafeSymbol(template.visual.symbol) else {
                    throw TinyGameCompilerError.invalidValue("symbol in template \(template.id)")
                }
            } else if !template.visual.symbol.isEmpty {
                throw TinyGameCompilerError.invalidValue("unused symbol in template \(template.id)")
            }
            switch template.movement {
            case .none:
                break
            case .playerAxis:
                guard template.body == .kinematic || template.body == .dynamic,
                      template.speed > 0 else {
                    throw TinyGameCompilerError.invalidValue("player movement in \(template.id)")
                }
            case .constant:
                guard template.body == .kinematic || template.body == .dynamic,
                      template.velocityX != 0 || template.velocityY != 0 else {
                    throw TinyGameCompilerError.invalidValue("constant movement in \(template.id)")
                }
            }
            if template.body == .none || template.body == .static {
                guard template.movement == .none,
                      template.velocityX == 0,
                      template.velocityY == 0 else {
                    throw TinyGameCompilerError.invalidValue("immovable template \(template.id)")
                }
            }
        }
    }

    private func validateSpawns(
        _ spawns: [TinyGameEntitySpawn],
        templates: [String: TinyGameEntityTemplate],
        world: TinyGameWorldSpec
    ) throws {
        for spawn in spawns {
            guard let template = templates[spawn.templateID] else {
                throw TinyGameCompilerError.unresolvedReference("template \(spawn.templateID)")
            }
            let horizontalRange = (template.width / 2)...(world.width - template.width / 2)
            let verticalRange = (template.height / 2)...(world.height - template.height / 2)
            guard horizontalRange.contains(spawn.x),
                  verticalRange.contains(spawn.y) else {
                throw TinyGameCompilerError.invalidValue("spawn \(spawn.id)")
            }
        }
    }

    private func validateControls(
        _ controls: [TinyGameControlSpec],
        templates: [String: TinyGameEntityTemplate],
        spawns: [TinyGameEntitySpawn],
        knownTags: Set<String>
    ) throws {
        let initiallySpawnedTemplateIDs = Set(spawns.map(\.templateID))
        for control in controls {
            guard !control.label.isEmpty,
                  control.label.count <= 60,
                  isSafeSymbol(control.symbol),
                  knownTags.contains(control.targetTag) else {
                throw TinyGameCompilerError.invalidValue("control \(control.id)")
            }
            switch control.kind {
            case .fourWay, .horizontal:
                let controllableTemplates = templates.values.filter { template in
                    (template.tags.contains(control.targetTag)
                        || template.role.rawValue == control.targetTag)
                        && template.movement == .playerAxis
                }
                guard (1...128).contains(control.speed),
                      control.spawnTemplateID.isEmpty,
                      controllableTemplates.contains(where: {
                          initiallySpawnedTemplateIDs.contains($0.id)
                      }) else {
                    throw TinyGameCompilerError.invalidValue("movement control \(control.id)")
                }
            case .actionButton:
                let hasInitialAnchor = spawns.contains { spawn in
                    guard let template = templates[spawn.templateID] else { return false }
                    return template.tags.contains(control.targetTag)
                        || template.role.rawValue == control.targetTag
                }
                guard control.speed == 0,
                      templates[control.spawnTemplateID] != nil else {
                    throw TinyGameCompilerError.unresolvedReference(
                        "action template \(control.spawnTemplateID)"
                    )
                }
                guard hasInitialAnchor else {
                    throw TinyGameCompilerError.unresolvedReference(
                        "action target \(control.targetTag)"
                    )
                }
            }
        }
    }

    private func validateRules(
        _ rules: [TinyGameRuleSpec],
        variables: [String: TinyGameVariableSpec],
        templates: [String: TinyGameEntityTemplate],
        reachableTags: Set<String>,
        world: TinyGameWorldSpec
    ) throws {
        for rule in rules {
            try validateTrigger(rule.trigger, ruleID: rule.id, reachableTags: reachableTags)
            for condition in rule.conditions {
                guard let variable = variables[condition.variableID] else {
                    throw TinyGameCompilerError.unresolvedReference(
                        "variable \(condition.variableID)"
                    )
                }
                if variable.kind == .boolean {
                    guard [.equal, .notEqual].contains(condition.comparison),
                          [0, 1].contains(condition.value) else {
                        throw TinyGameCompilerError.invalidRule(rule.id)
                    }
                }
            }
            for effect in rule.effects {
                try validateEffect(
                    effect,
                    in: rule,
                    variables: variables,
                    templates: templates,
                    reachableTags: reachableTags,
                    world: world
                )
            }
        }
    }

    private func validateTrigger(
        _ trigger: TinyGameTriggerSpec,
        ruleID: String,
        reachableTags: Set<String>
    ) throws {
        switch trigger.kind {
        case .start:
            guard trigger.subjectTag.isEmpty,
                  trigger.otherTag.isEmpty,
                  trigger.everyTicks == 0 else {
                throw TinyGameCompilerError.invalidRule(ruleID)
            }
        case .tickInterval:
            guard trigger.subjectTag.isEmpty,
                  trigger.otherTag.isEmpty,
                  (1...3_600).contains(trigger.everyTicks) else {
                throw TinyGameCompilerError.invalidRule(ruleID)
            }
        case .collision:
            guard reachableTags.contains(trigger.subjectTag),
                  reachableTags.contains(trigger.otherTag),
                  trigger.everyTicks == 0 else {
                throw TinyGameCompilerError.invalidRule(ruleID)
            }
        case .leaveWorld:
            guard reachableTags.contains(trigger.subjectTag),
                  trigger.otherTag.isEmpty,
                  trigger.everyTicks == 0 else {
                throw TinyGameCompilerError.invalidRule(ruleID)
            }
        }
    }

    // swiftlint:disable:next function_parameter_count cyclomatic_complexity
    private func validateEffect(
        _ effect: TinyGameEffectSpec,
        in rule: TinyGameRuleSpec,
        variables: [String: TinyGameVariableSpec],
        templates: [String: TinyGameEntityTemplate],
        reachableTags: Set<String>,
        world: TinyGameWorldSpec
    ) throws {
        switch effect.kind {
        case .setVariable, .addVariable:
            guard variables[effect.variableID] != nil,
                  (-1_000_000...1_000_000).contains(effect.value) else {
                throw TinyGameCompilerError.unresolvedReference("variable \(effect.variableID)")
            }
        case .setVelocity:
            try validateEntityTarget(effect, in: rule, reachableTags: reachableTags)
            guard (-128...128).contains(effect.x), (-128...128).contains(effect.y) else {
                throw TinyGameCompilerError.invalidRule(rule.id)
            }
        case .spawn:
            try validateEntityTarget(effect, in: rule, reachableTags: reachableTags)
            guard templates[effect.templateID] != nil else {
                throw TinyGameCompilerError.unresolvedReference("template \(effect.templateID)")
            }
            guard (-world.width...world.width).contains(effect.x),
                  (-world.height...world.height).contains(effect.y),
                  (0...world.width).contains(effect.value) else {
                throw TinyGameCompilerError.invalidRule(rule.id)
            }
        case .destroy:
            try validateEntityTarget(effect, in: rule, reachableTags: reachableTags)
        case .win, .lose:
            break
        case .feedback:
            guard effect.feedback != .none else {
                throw TinyGameCompilerError.invalidRule(rule.id)
            }
        }
    }

    private func validateEntityTarget(
        _ effect: TinyGameEffectSpec,
        in rule: TinyGameRuleSpec,
        reachableTags: Set<String>
    ) throws {
        switch effect.target {
        case .subject:
            guard rule.trigger.kind == .collision || rule.trigger.kind == .leaveWorld else {
                throw TinyGameCompilerError.invalidRule(rule.id)
            }
        case .other:
            guard rule.trigger.kind == .collision else {
                throw TinyGameCompilerError.invalidRule(rule.id)
            }
        case .player:
            guard reachableTags.contains(TinyGameEntityRole.player.rawValue) else {
                throw TinyGameCompilerError.unresolvedReference("player")
            }
        case .tag:
            guard reachableTags.contains(effect.targetTag) else {
                throw TinyGameCompilerError.unresolvedReference("tag \(effect.targetTag)")
            }
        }
    }

    private func reachableEntityTags(
        in program: TinyGameProgram,
        templates: [String: TinyGameEntityTemplate]
    ) -> Set<String> {
        var templateIDs = Set(program.spawns.map(\.templateID))
        var reachableTags = tags(for: templateIDs, templates: templates)

        for control in program.controls where control.kind == .actionButton {
            guard reachableTags.contains(control.targetTag) else { continue }
            templateIDs.insert(control.spawnTemplateID)
        }
        reachableTags = tags(for: templateIDs, templates: templates)

        var priorCount = -1
        while priorCount != templateIDs.count {
            priorCount = templateIDs.count
            for rule in program.rules where triggerCanRun(rule.trigger, with: reachableTags) {
                for effect in rule.effects where effect.kind == .spawn {
                    guard targetCanResolve(effect, in: rule, with: reachableTags),
                          templates[effect.templateID] != nil else { continue }
                    templateIDs.insert(effect.templateID)
                }
            }
            reachableTags = tags(for: templateIDs, templates: templates)
        }
        return reachableTags
    }

    private func tags(
        for templateIDs: Set<String>,
        templates: [String: TinyGameEntityTemplate]
    ) -> Set<String> {
        Set(templateIDs.compactMap { templates[$0] }.flatMap { template in
            template.tags + [template.role.rawValue]
        })
    }

    private func triggerCanRun(
        _ trigger: TinyGameTriggerSpec,
        with reachableTags: Set<String>
    ) -> Bool {
        switch trigger.kind {
        case .start, .tickInterval:
            true
        case .collision:
            reachableTags.contains(trigger.subjectTag)
                && reachableTags.contains(trigger.otherTag)
        case .leaveWorld:
            reachableTags.contains(trigger.subjectTag)
        }
    }

    private func targetCanResolve(
        _ effect: TinyGameEffectSpec,
        in rule: TinyGameRuleSpec,
        with reachableTags: Set<String>
    ) -> Bool {
        switch effect.target {
        case .subject:
            rule.trigger.kind == .collision || rule.trigger.kind == .leaveWorld
        case .other:
            rule.trigger.kind == .collision
        case .player:
            reachableTags.contains(TinyGameEntityRole.player.rawValue)
        case .tag:
            reachableTags.contains(effect.targetTag)
        }
    }

    private func validateHUD(
        _ items: [TinyGameHUDItemSpec],
        variables: [String: TinyGameVariableSpec]
    ) throws {
        for item in items {
            guard variables[item.variableID] != nil,
                  !item.label.isEmpty,
                  item.label.count <= 40,
                  isSafeSymbol(item.symbol) else {
                throw TinyGameCompilerError.unresolvedReference("HUD variable \(item.variableID)")
            }
        }
    }

    private func requireMaximum(_ count: Int, _ maximum: Int, _ label: String) throws {
        guard count <= maximum else {
            throw TinyGameCompilerError.limitExceeded(label)
        }
    }

    private func isSafeID(_ value: String) -> Bool {
        guard (1...60).contains(value.count),
              value.first != "-",
              value.last != "-" else { return false }
        return value.allSatisfy { character in
            character.isLowercase || character.isNumber || character == "-"
        }
    }

    private func isSafeSymbol(_ value: String) -> Bool {
        guard (1...64).contains(value.count) else { return false }
        return value.allSatisfy { character in
            character.isLowercase || character.isNumber || character == "." || character == "-"
        }
    }
}

enum TinyGameCompilerError: LocalizedError, Equatable {
    case unsupportedVersion(Int)
    case limitExceeded(String)
    case invalidValue(String)
    case duplicateID(String)
    case unresolvedReference(String)
    case invalidRule(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version):
            "Unsupported tiny game program version \(version)."
        case .limitExceeded(let value):
            "The tiny game exceeds the \(value) budget."
        case .invalidValue(let value):
            "The tiny game has an invalid \(value)."
        case .duplicateID(let value):
            "The tiny game has a duplicate \(value) ID."
        case .unresolvedReference(let value):
            "The tiny game references an unavailable \(value)."
        case .invalidRule(let identifier):
            "The tiny game rule \(identifier) is invalid."
        }
    }
}
