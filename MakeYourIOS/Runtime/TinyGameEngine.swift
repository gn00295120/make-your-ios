import Foundation

// Fixed-step systems intentionally stay together so their order can be audited as one unit.
// swiftlint:disable file_length

enum TinyGamePhase: String, Equatable, Sendable {
    case ready
    case playing
    case paused
    case won
    case lost
}

struct TinyGameVariableValue: Equatable, Sendable {
    var id: String
    var value: Int
}

// Coordinate fields intentionally use the conventional x/y names used by the IR.
// swiftlint:disable identifier_name
struct TinyGameEntityState: Equatable, Identifiable, Sendable {
    var id: String
    var templateID: String
    var role: TinyGameEntityRole
    var visual: TinyGameVisualSpec
    var body: TinyGameBodyKind
    var movement: TinyGameMovementKind
    var width: Int
    var height: Int
    var x: Int
    var y: Int
    var velocityX: Int
    var velocityY: Int
    var speed: Int
    var tags: Set<String>
}
// swiftlint:enable identifier_name

struct TinyGameSnapshot: Equatable, Sendable {
    var phase: TinyGamePhase
    var tick: Int
    var variables: [TinyGameVariableValue]
    var entities: [TinyGameEntityState]
}

// swiftlint:disable:next type_body_length
struct TinyGameEngine: Sendable {
    let program: TinyGameCompiledProgram

    private(set) var phase: TinyGamePhase = .ready
    private(set) var tick = 0
    private(set) var variables: [String: Int]
    private(set) var entities: [TinyGameEntityState]

    private var random: TinyGameSeededRandomNumberGenerator
    private var directionalInputs: [String: TinyGameInputVector] = [:]
    private var activeContactKeys: Set<TinyGameContactKey> = []
    private var activeOutsideEntityIDs: Set<String> = []
    private var pendingFeedback: [TinyGameFeedback] = []
    private var startRulesDidRun = false
    private var effectsAppliedThisTick = 0
    private var spawnsThisTick = 0

    init(program: TinyGameCompiledProgram) {
        self.program = program
        variables = Dictionary(uniqueKeysWithValues: program.source.variables.map {
            ($0.id, $0.initialValue)
        })
        entities = program.source.spawns.compactMap { spawn in
            guard let template = program.templatesByID[spawn.templateID] else { return nil }
            return Self.makeEntity(
                id: spawn.id,
                template: template,
                x: spawn.x,
                y: spawn.y
            )
        }.sorted(by: { $0.id < $1.id })
        random = TinyGameSeededRandomNumberGenerator(
            seed: UInt64(program.source.seed) &+ 0x9E37_79B9_7F4A_7C15
        )
    }

    var snapshot: TinyGameSnapshot {
        TinyGameSnapshot(
            phase: phase,
            tick: tick,
            variables: variables.keys.sorted().map {
                TinyGameVariableValue(id: $0, value: variables[$0] ?? 0)
            },
            entities: entities.sorted(by: { $0.id < $1.id })
        )
    }

    mutating func start() {
        switch phase {
        case .ready:
            phase = .playing
            runStartRulesIfNeeded()
        case .paused:
            phase = .playing
        case .playing, .won, .lost:
            break
        }
    }

    mutating func togglePause() {
        switch phase {
        case .ready:
            start()
        case .playing:
            phase = .paused
        case .paused:
            phase = .playing
        case .won, .lost:
            break
        }
    }

    // swiftlint:disable:next identifier_name
    mutating func setDirectionalInput(x: Int, y: Int, controlID: String) {
        guard let control = program.controlsByID[controlID],
              control.kind == .fourWay || control.kind == .horizontal else { return }
        let horizontal = min(max(x, -1), 1)
        let vertical = control.kind == .horizontal ? 0 : min(max(y, -1), 1)
        directionalInputs[controlID] = TinyGameInputVector(x: horizontal, y: vertical)
    }

    mutating func activateControl(_ controlID: String) {
        guard phase == .playing,
              let control = program.controlsByID[controlID],
              control.kind == .actionButton,
              let anchor = firstEntity(withTag: control.targetTag) else { return }
        _ = spawnEntity(
            templateID: control.spawnTemplateID,
            x: anchor.x,
            y: anchor.y
        )
    }

    mutating func step() {
        guard phase == .playing else { return }
        effectsAppliedThisTick = 0
        spawnsThisTick = 0
        tick += 1

        applyDirectionalInputs()
        integrateEntities()
        let outsideIDs = Set(entities.filter(isOutsideWorld).map(\.id))
        let leavingIDs = outsideIDs.subtracting(activeOutsideEntityIDs)
        activeOutsideEntityIDs = outsideIDs
        applyWorldEdges(to: outsideIDs)

        runTickRules()
        guard phase == .playing else { return }
        runCollisionRules()
        guard phase == .playing else { return }
        runLeaveWorldRules(for: leavingIDs)

        if program.source.world.edgeBehavior == .destroy {
            entities.removeAll(where: { outsideIDs.contains($0.id) })
        }
        activeOutsideEntityIDs.formIntersection(entities.map(\.id))
        entities.sort(by: { $0.id < $1.id })
    }

    mutating func restart() {
        self = TinyGameEngine(program: program)
    }

    mutating func drainFeedback() -> [TinyGameFeedback] {
        defer { pendingFeedback.removeAll(keepingCapacity: true) }
        return pendingFeedback
    }

    private mutating func runStartRulesIfNeeded() {
        guard !startRulesDidRun else { return }
        startRulesDidRun = true
        effectsAppliedThisTick = 0
        spawnsThisTick = 0
        for rule in program.rulesByTrigger[.start] ?? [] {
            guard phase == .playing else { return }
            guard conditionsPass(rule.conditions) else { continue }
            apply(rule.effects, event: .empty)
        }
    }

    private mutating func applyDirectionalInputs() {
        for control in program.source.controls.sorted(by: { $0.id < $1.id }) {
            guard control.kind == .fourWay || control.kind == .horizontal else { continue }
            let input = directionalInputs[control.id] ?? .zero
            for index in entities.indices where entities[index].tags.contains(control.targetTag) {
                guard entities[index].movement == .playerAxis else { continue }
                entities[index].velocityX = input.x * control.speed
                entities[index].velocityY = input.y * control.speed
            }
        }
    }

    private mutating func integrateEntities() {
        let gravityX = program.source.world.gravityX
        let gravityY = program.source.world.gravityY
        for index in entities.indices {
            switch entities[index].body {
            case .none, .static:
                continue
            case .kinematic:
                entities[index].x += entities[index].velocityX
                entities[index].y += entities[index].velocityY
            case .dynamic:
                entities[index].velocityX += gravityX
                entities[index].velocityY += gravityY
                entities[index].x += entities[index].velocityX
                entities[index].y += entities[index].velocityY
            }
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    private mutating func applyWorldEdges(to leavingIDs: Set<String>) {
        guard !leavingIDs.isEmpty else { return }
        let world = program.source.world
        for index in entities.indices where leavingIDs.contains(entities[index].id) {
            let halfWidth = entities[index].width / 2
            let halfHeight = entities[index].height / 2
            let minimumX = halfWidth
            let maximumX = world.width - halfWidth
            let minimumY = halfHeight
            let maximumY = world.height - halfHeight

            switch world.edgeBehavior {
            case .destroy:
                continue
            case .solid:
                if entities[index].x < minimumX || entities[index].x > maximumX {
                    entities[index].velocityX = 0
                }
                if entities[index].y < minimumY || entities[index].y > maximumY {
                    entities[index].velocityY = 0
                }
                entities[index].x = min(max(entities[index].x, minimumX), maximumX)
                entities[index].y = min(max(entities[index].y, minimumY), maximumY)
            case .clamp:
                entities[index].x = min(max(entities[index].x, minimumX), maximumX)
                entities[index].y = min(max(entities[index].y, minimumY), maximumY)
            case .wrap:
                if entities[index].x < -halfWidth { entities[index].x = world.width + halfWidth }
                if entities[index].x > world.width + halfWidth { entities[index].x = -halfWidth }
                if entities[index].y < -halfHeight { entities[index].y = world.height + halfHeight }
                if entities[index].y > world.height + halfHeight { entities[index].y = -halfHeight }
            case .bounce:
                if entities[index].x < minimumX || entities[index].x > maximumX {
                    entities[index].velocityX *= -1
                }
                if entities[index].y < minimumY || entities[index].y > maximumY {
                    entities[index].velocityY *= -1
                }
                entities[index].x = min(max(entities[index].x, minimumX), maximumX)
                entities[index].y = min(max(entities[index].y, minimumY), maximumY)
            }
        }
    }

    private mutating func runTickRules() {
        for rule in program.rulesByTrigger[.tickInterval] ?? [] {
            guard phase == .playing else { return }
            guard tick.isMultiple(of: rule.trigger.everyTicks),
                  conditionsPass(rule.conditions) else { continue }
            apply(rule.effects, event: .empty)
        }
    }

    private mutating func runCollisionRules() {
        let contacts = collisionContacts()
        let currentContactKeys = Set(contacts.map(\.key))
        let beganContacts = contacts.filter { !activeContactKeys.contains($0.key) }
        activeContactKeys = currentContactKeys
        guard !beganContacts.isEmpty else { return }
        for contact in beganContacts {
            guard entity(withID: contact.first.id) != nil,
                  entity(withID: contact.second.id) != nil else { continue }
            for rule in program.rulesByTrigger[.collision] ?? [] {
                guard phase == .playing else { return }
                let event: TinyGameRuleEvent?
                if contact.first.tags.contains(rule.trigger.subjectTag),
                   contact.second.tags.contains(rule.trigger.otherTag) {
                    event = TinyGameRuleEvent(subjectID: contact.first.id, otherID: contact.second.id)
                } else if contact.second.tags.contains(rule.trigger.subjectTag),
                          contact.first.tags.contains(rule.trigger.otherTag) {
                    event = TinyGameRuleEvent(subjectID: contact.second.id, otherID: contact.first.id)
                } else {
                    event = nil
                }
                guard let event, conditionsPass(rule.conditions) else { continue }
                apply(rule.effects, event: event)
            }
        }
    }

    private mutating func runLeaveWorldRules(for identifiers: Set<String>) {
        guard !identifiers.isEmpty else { return }
        for identifier in identifiers.sorted() {
            guard phase == .playing else { return }
            guard let entity = entity(withID: identifier) else { continue }
            for rule in program.rulesByTrigger[.leaveWorld] ?? [] {
                guard phase == .playing else { return }
                guard entity.tags.contains(rule.trigger.subjectTag),
                      conditionsPass(rule.conditions) else { continue }
                apply(
                    rule.effects,
                    event: TinyGameRuleEvent(subjectID: identifier, otherID: nil)
                )
            }
        }
    }

    private func collisionContacts() -> [TinyGameContact] {
        let collisionRules = program.rulesByTrigger[.collision] ?? []
        guard !collisionRules.isEmpty else { return [] }
        let collisionTags = Set(collisionRules.flatMap { rule in
            [rule.trigger.subjectTag, rule.trigger.otherTag]
        })
        let candidates = entities
            .filter { $0.body != .none && !$0.tags.isDisjoint(with: collisionTags) }
            .sorted(by: { $0.id < $1.id })
        guard candidates.count > 1 else { return [] }
        var contacts: [TinyGameContact] = []
        for firstIndex in 0..<(candidates.count - 1) {
            for secondIndex in (firstIndex + 1)..<candidates.count {
                let first = candidates[firstIndex]
                let second = candidates[secondIndex]
                if isRelevantCollisionPair(first, second, for: collisionRules),
                   intersects(first, second) {
                    contacts.append(TinyGameContact(first: first, second: second))
                    if contacts.count == TinyGameAuditLimits.maximumContactsPerTick {
                        return contacts
                    }
                }
            }
        }
        return contacts
    }

    private func isRelevantCollisionPair(
        _ first: TinyGameEntityState,
        _ second: TinyGameEntityState,
        for rules: [TinyGameRuleSpec]
    ) -> Bool {
        rules.contains { rule in
            let subjectTag = rule.trigger.subjectTag
            let otherTag = rule.trigger.otherTag
            return (first.tags.contains(subjectTag) && second.tags.contains(otherTag))
                || (second.tags.contains(subjectTag) && first.tags.contains(otherTag))
        }
    }

    private func intersects(_ first: TinyGameEntityState, _ second: TinyGameEntityState) -> Bool {
        abs(first.x - second.x) * 2 < first.width + second.width
            && abs(first.y - second.y) * 2 < first.height + second.height
    }

    private func conditionsPass(_ conditions: [TinyGameConditionSpec]) -> Bool {
        conditions.allSatisfy { condition in
            let current = variables[condition.variableID] ?? 0
            switch condition.comparison {
            case .equal: return current == condition.value
            case .notEqual: return current != condition.value
            case .less: return current < condition.value
            case .lessOrEqual: return current <= condition.value
            case .greater: return current > condition.value
            case .greaterOrEqual: return current >= condition.value
            }
        }
    }

    private mutating func apply(_ effects: [TinyGameEffectSpec], event: TinyGameRuleEvent) {
        for effect in effects {
            guard effectsAppliedThisTick < TinyGameAuditLimits.maximumEffectsPerTick else { return }
            effectsAppliedThisTick += 1
            apply(effect, event: event)
            if phase == .won || phase == .lost { return }
        }
    }

    // A closed switch over the bounded effect IR is clearer than indirect dispatch here.
    // swiftlint:disable:next cyclomatic_complexity
    private mutating func apply(_ effect: TinyGameEffectSpec, event: TinyGameRuleEvent) {
        switch effect.kind {
        case .setVariable:
            setVariable(effect.variableID, to: effect.value)
        case .addVariable:
            let current = variables[effect.variableID] ?? 0
            setVariable(effect.variableID, to: current + effect.value)
        case .setVelocity:
            guard let identifier = targetID(for: effect, event: event),
                  let index = entities.firstIndex(where: { $0.id == identifier }) else { return }
            entities[index].velocityX = effect.x
            entities[index].velocityY = effect.y
        case .spawn:
            guard let anchorID = targetID(for: effect, event: event),
                  let anchor = entity(withID: anchorID) else { return }
            let jitter = effect.value > 0
                ? random.nextInt(in: -effect.value...effect.value)
                : 0
            _ = spawnEntity(
                templateID: effect.templateID,
                x: anchor.x + effect.x + jitter,
                y: anchor.y + effect.y
            )
        case .destroy:
            guard let identifier = targetID(for: effect, event: event) else { return }
            entities.removeAll(where: { $0.id == identifier })
        case .win:
            if phase == .playing { phase = .won }
        case .lose:
            if phase == .playing { phase = .lost }
        case .feedback:
            pendingFeedback.append(effect.feedback)
        }
    }

    private mutating func setVariable(_ identifier: String, to requestedValue: Int) {
        guard let spec = program.variableSpecsByID[identifier] else { return }
        variables[identifier] = min(max(requestedValue, spec.minimumValue), spec.maximumValue)
    }

    // swiftlint:disable:next identifier_name
    private mutating func spawnEntity(templateID: String, x: Int, y: Int) -> String? {
        guard spawnsThisTick < TinyGameAuditLimits.maximumSpawnsPerTick,
              entities.count < TinyGameAuditLimits.maximumRuntimeEntities,
              let template = program.templatesByID[templateID] else { return nil }
        spawnsThisTick += 1
        let identifier = nextSpawnIdentifier()
        entities.append(Self.makeEntity(id: identifier, template: template, x: x, y: y))
        return identifier
    }

    private mutating func nextSpawnIdentifier() -> String {
        var candidate: String
        repeat {
            candidate = "spawn-\(tick)-\(String(random.next(), radix: 36))"
        } while entities.contains(where: { $0.id == candidate })
        return candidate
    }

    private func targetID(
        for effect: TinyGameEffectSpec,
        event: TinyGameRuleEvent
    ) -> String? {
        switch effect.target {
        case .subject: event.subjectID
        case .other: event.otherID
        case .player: firstEntity(withTag: TinyGameEntityRole.player.rawValue)?.id
        case .tag: firstEntity(withTag: effect.targetTag)?.id
        }
    }

    private func firstEntity(withTag tag: String) -> TinyGameEntityState? {
        entities.filter { $0.tags.contains(tag) }.min(by: { $0.id < $1.id })
    }

    private func entity(withID identifier: String) -> TinyGameEntityState? {
        entities.first(where: { $0.id == identifier })
    }

    private func isOutsideWorld(_ entity: TinyGameEntityState) -> Bool {
        let halfWidth = entity.width / 2
        let halfHeight = entity.height / 2
        return entity.x - halfWidth < 0
            || entity.x + halfWidth > program.source.world.width
            || entity.y - halfHeight < 0
            || entity.y + halfHeight > program.source.world.height
    }

    // swiftlint:disable identifier_name
    private static func makeEntity(
        id: String,
        template: TinyGameEntityTemplate,
        x: Int,
        y: Int
    ) -> TinyGameEntityState {
        TinyGameEntityState(
            id: id,
            templateID: template.id,
            role: template.role,
            visual: template.visual,
            body: template.body,
            movement: template.movement,
            width: template.width,
            height: template.height,
            x: x,
            y: y,
            velocityX: template.velocityX,
            velocityY: template.velocityY,
            speed: template.speed,
            tags: Set(template.tags + [template.role.rawValue])
        )
    }
    // swiftlint:enable identifier_name
}

// Coordinate fields intentionally mirror directional input axes.
// swiftlint:disable identifier_name
private struct TinyGameInputVector: Sendable {
    var x: Int
    var y: Int

    static let zero = TinyGameInputVector(x: 0, y: 0)
}
// swiftlint:enable identifier_name

private struct TinyGameRuleEvent: Sendable {
    var subjectID: String?
    var otherID: String?

    static let empty = TinyGameRuleEvent(subjectID: nil, otherID: nil)
}

private struct TinyGameContact: Sendable {
    var first: TinyGameEntityState
    var second: TinyGameEntityState

    var key: TinyGameContactKey {
        TinyGameContactKey(firstID: first.id, secondID: second.id)
    }
}

private struct TinyGameContactKey: Hashable, Sendable {
    var firstID: String
    var secondID: String
}

private struct TinyGameSeededRandomNumberGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }

    mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        let width = UInt64(range.upperBound - range.lowerBound + 1)
        return range.lowerBound + Int(next() % width)
    }
}
