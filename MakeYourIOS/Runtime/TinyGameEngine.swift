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

enum TinyGameControlBlockReason: String, Equatable, Sendable {
    case ready
    case gameNotPlaying
    case cooldown
    case airborne
    case maximumActive
    case entityBudget
    case missingTarget
}

struct TinyGameControlAvailability: Equatable, Sendable {
    var id: String
    var isEnabled: Bool
    var reason: TinyGameControlBlockReason
    var availableAtTick: Int
    var cooldownTicksRemaining: Int
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
    var collisionMode: TinyGameCollisionMode
    var maximumVelocityX: Int
    var maximumVelocityY: Int
    var lifetimeTicks: Int
    var ageTicks: Int
    var facingX: Int
    var isGrounded: Bool
}
// swiftlint:enable identifier_name

struct TinyGameSnapshot: Equatable, Sendable {
    var phase: TinyGamePhase
    var tick: Int
    var variables: [TinyGameVariableValue]
    var entities: [TinyGameEntityState]
    var controls: [TinyGameControlAvailability]
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
    private var controlAvailableAtTick: [String: Int] = [:]
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
        refreshRestingGroundedState()
    }

    var snapshot: TinyGameSnapshot {
        TinyGameSnapshot(
            phase: phase,
            tick: tick,
            variables: variables.keys.sorted().map {
                TinyGameVariableValue(id: $0, value: variables[$0] ?? 0)
            },
            entities: entities.sorted(by: { $0.id < $1.id }),
            controls: program.source.controls
                .sorted(by: { $0.id < $1.id })
                .map { controlAvailability($0.id) }
        )
    }

    func controlAvailability(_ controlID: String) -> TinyGameControlAvailability {
        let availableAt = controlAvailableAtTick[controlID, default: 0]
        let remaining = max(availableAt - tick, 0)
        func result(
            _ enabled: Bool,
            _ reason: TinyGameControlBlockReason
        ) -> TinyGameControlAvailability {
            TinyGameControlAvailability(
                id: controlID,
                isEnabled: enabled,
                reason: reason,
                availableAtTick: availableAt,
                cooldownTicksRemaining: remaining
            )
        }

        guard phase == .playing else { return result(false, .gameNotPlaying) }
        guard let control = program.controlsByID[controlID] else {
            return result(false, .missingTarget)
        }
        guard control.kind == .actionButton else { return result(true, .ready) }
        guard remaining == 0 else { return result(false, .cooldown) }
        guard let anchor = firstEntity(withTag: control.targetTag) else {
            return result(false, .missingTarget)
        }
        guard let action = control.action else {
            return entities.count < TinyGameAuditLimits.maximumRuntimeEntities
                && spawnsThisTick < TinyGameAuditLimits.maximumSpawnsPerTick
                ? result(true, .ready)
                : result(false, .entityBudget)
        }
        switch action.kind {
        case .jump:
            return anchor.isGrounded
                ? result(true, .ready)
                : result(false, .airborne)
        case .projectile:
            guard entities.count < TinyGameAuditLimits.maximumRuntimeEntities,
                  spawnsThisTick < TinyGameAuditLimits.maximumSpawnsPerTick else {
                return result(false, .entityBudget)
            }
            let activeCount = entities.filter {
                $0.templateID == control.spawnTemplateID
            }.count
            return activeCount < action.maximumActive
                ? result(true, .ready)
                : result(false, .maximumActive)
        }
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
              controlAvailability(controlID).isEnabled,
              let anchorIndex = firstEntityIndex(withTag: control.targetTag) else { return }
        guard let action = control.action else {
            let anchor = entities[anchorIndex]
            _ = spawnEntity(
                templateID: control.spawnTemplateID,
                x: anchor.x,
                y: anchor.y
            )
            return
        }
        switch action.kind {
        case .jump:
            guard entities[anchorIndex].isGrounded else { return }
            entities[anchorIndex].velocityY = -action.impulse
            entities[anchorIndex].isGrounded = false
            controlAvailableAtTick[controlID] = tick + action.cooldownTicks
        case .projectile:
            let activeCount = entities.filter {
                $0.templateID == control.spawnTemplateID
            }.count
            guard activeCount < action.maximumActive else { return }
            let anchor = entities[anchorIndex]
            let facing = anchor.facingX == 0 ? 1 : anchor.facingX
            guard let identifier = spawnEntity(
                templateID: control.spawnTemplateID,
                x: anchor.x + action.offsetX * facing,
                y: anchor.y + action.offsetY
            ), let spawnedIndex = entities.firstIndex(where: { $0.id == identifier }) else {
                return
            }
            entities[spawnedIndex].facingX = facing
            if entities[spawnedIndex].velocityX != 0 {
                entities[spawnedIndex].velocityX = abs(entities[spawnedIndex].velocityX) * facing
            }
            controlAvailableAtTick[controlID] = tick + action.cooldownTicks
        }
    }

    mutating func step() {
        guard phase == .playing else { return }
        effectsAppliedThisTick = 0
        spawnsThisTick = 0
        tick += 1

        applyDirectionalInputs()
        let previousPositions = Dictionary(uniqueKeysWithValues: entities.map {
            ($0.id, TinyGamePoint(x: $0.x, y: $0.y))
        })
        integrateEntities()
        resolvePhysicalContacts(previousPositions: previousPositions)
        let outsideIDs = Set(entities.filter(isOutsideWorld).map(\.id))
        let leavingIDs = outsideIDs.subtracting(activeOutsideEntityIDs)
        activeOutsideEntityIDs = outsideIDs
        applyWorldEdges(to: outsideIDs)

        runTickRules()
        guard phase == .playing else { return }
        runCollisionRules(previousPositions: previousPositions)
        guard phase == .playing else { return }
        runLeaveWorldRules(for: leavingIDs)

        ageAndExpireEntities()

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
                guard entities[index].movement == .playerAxis
                        || entities[index].movement == .platformerAxis else { continue }
                entities[index].velocityX = input.x * control.speed
                if input.x != 0 { entities[index].facingX = input.x }
                if entities[index].movement == .playerAxis {
                    entities[index].velocityY = input.y * control.speed
                }
            }
        }
    }

    private mutating func integrateEntities() {
        let gravityX = program.source.world.gravityX
        let gravityY = program.source.world.gravityY
        for index in entities.indices {
            if entities[index].collisionMode == .solid,
               entities[index].body == .kinematic || entities[index].body == .dynamic {
                entities[index].isGrounded = false
            }
            switch entities[index].body {
            case .none, .static:
                continue
            case .kinematic:
                clampVelocity(at: index)
                entities[index].x += entities[index].velocityX
                entities[index].y += entities[index].velocityY
            case .dynamic:
                entities[index].velocityX += gravityX
                entities[index].velocityY += gravityY
                clampVelocity(at: index)
                entities[index].x += entities[index].velocityX
                entities[index].y += entities[index].velocityY
            }
        }
    }

    private mutating func clampVelocity(at index: Int) {
        let maximumX = entities[index].maximumVelocityX
        let maximumY = entities[index].maximumVelocityY
        if maximumX > 0 {
            entities[index].velocityX = min(max(entities[index].velocityX, -maximumX), maximumX)
        }
        if maximumY > 0 {
            entities[index].velocityY = min(max(entities[index].velocityY, -maximumY), maximumY)
        }
    }

    private mutating func resolvePhysicalContacts(
        previousPositions: [String: TinyGamePoint]
    ) {
        let moverIDs = entities
            .filter {
                $0.collisionMode == .solid
                    && ($0.body == .kinematic || $0.body == .dynamic)
            }
            .map(\.id)
            .sorted()
        let obstacleIDs = entities
            .filter {
                $0.body == .static
                    && ($0.collisionMode == .solid || $0.collisionMode == .oneWayPlatform)
            }
            .map(\.id)
            .sorted()

        for moverID in moverIDs {
            for obstacleID in obstacleIDs where obstacleID != moverID {
                guard let moverIndex = entities.firstIndex(where: { $0.id == moverID }),
                      let obstacle = entity(withID: obstacleID),
                      let previous = previousPositions[moverID] else { continue }
                switch obstacle.collisionMode {
                case .oneWayPlatform:
                    resolveOneWayContact(
                        moverIndex: moverIndex,
                        obstacle: obstacle,
                        previous: previous
                    )
                case .solid:
                    resolveSolidContact(
                        moverIndex: moverIndex,
                        obstacle: obstacle,
                        previous: previous
                    )
                case .sensor:
                    break
                }
            }
        }
    }

    private mutating func resolveOneWayContact(
        moverIndex: Int,
        obstacle: TinyGameEntityState,
        previous: TinyGamePoint
    ) {
        let mover = entities[moverIndex]
        let platformTop = obstacle.y - obstacle.height / 2
        let previousBottom = previous.y + mover.height / 2
        let currentBottom = mover.y + mover.height / 2
        guard mover.velocityY >= 0,
              previousBottom <= platformTop,
              currentBottom >= platformTop,
              horizontalOverlap(mover, obstacle) else { return }
        entities[moverIndex].y = platformTop - mover.height / 2
        entities[moverIndex].velocityY = 0
        entities[moverIndex].isGrounded = true
    }

    // Axis-separated resolution uses the pre-step position to avoid tunneling through thin platforms.
    // swiftlint:disable:next function_body_length
    private mutating func resolveSolidContact(
        moverIndex: Int,
        obstacle: TinyGameEntityState,
        previous: TinyGamePoint
    ) {
        let mover = entities[moverIndex]
        let obstacleLeft = obstacle.x - obstacle.width / 2
        let obstacleRight = obstacle.x + obstacle.width / 2
        let obstacleTop = obstacle.y - obstacle.height / 2
        let obstacleBottom = obstacle.y + obstacle.height / 2
        let previousLeft = previous.x - mover.width / 2
        let previousRight = previous.x + mover.width / 2
        let previousTop = previous.y - mover.height / 2
        let previousBottom = previous.y + mover.height / 2
        let currentLeft = mover.x - mover.width / 2
        let currentRight = mover.x + mover.width / 2
        let currentTop = mover.y - mover.height / 2
        let currentBottom = mover.y + mover.height / 2

        if mover.velocityY >= 0,
           previousBottom <= obstacleTop,
           currentBottom >= obstacleTop,
           horizontalOverlap(mover, obstacle) {
            entities[moverIndex].y = obstacleTop - mover.height / 2
            entities[moverIndex].velocityY = 0
            entities[moverIndex].isGrounded = true
            return
        }
        if mover.velocityY <= 0,
           previousTop >= obstacleBottom,
           currentTop <= obstacleBottom,
           horizontalOverlap(mover, obstacle) {
            entities[moverIndex].y = obstacleBottom + mover.height / 2
            entities[moverIndex].velocityY = 0
            return
        }
        if mover.velocityX >= 0,
           previousRight <= obstacleLeft,
           currentRight >= obstacleLeft,
           verticalOverlap(mover, obstacle) {
            entities[moverIndex].x = obstacleLeft - mover.width / 2
            entities[moverIndex].velocityX = 0
            return
        }
        if mover.velocityX <= 0,
           previousLeft >= obstacleRight,
           currentLeft <= obstacleRight,
           verticalOverlap(mover, obstacle) {
            entities[moverIndex].x = obstacleRight + mover.width / 2
            entities[moverIndex].velocityX = 0
            return
        }
        guard intersects(mover, obstacle) else { return }

        let resolutions: [(distance: Int, axis: TinyGameResolutionAxis)] = [
            (abs(currentBottom - obstacleTop), .above),
            (abs(obstacleBottom - currentTop), .below),
            (abs(currentRight - obstacleLeft), .left),
            (abs(obstacleRight - currentLeft), .right)
        ]
        guard let resolution = resolutions.enumerated().min(by: { first, second in
            first.element.distance == second.element.distance
                ? first.offset < second.offset
                : first.element.distance < second.element.distance
        })?.element.axis else { return }
        switch resolution {
        case .above:
            entities[moverIndex].y = obstacleTop - mover.height / 2
            entities[moverIndex].velocityY = 0
            entities[moverIndex].isGrounded = true
        case .below:
            entities[moverIndex].y = obstacleBottom + mover.height / 2
            entities[moverIndex].velocityY = 0
        case .left:
            entities[moverIndex].x = obstacleLeft - mover.width / 2
            entities[moverIndex].velocityX = 0
        case .right:
            entities[moverIndex].x = obstacleRight + mover.width / 2
            entities[moverIndex].velocityX = 0
        }
    }

    private func horizontalOverlap(
        _ first: TinyGameEntityState,
        _ second: TinyGameEntityState
    ) -> Bool {
        abs(first.x - second.x) * 2 < first.width + second.width
    }

    private func verticalOverlap(
        _ first: TinyGameEntityState,
        _ second: TinyGameEntityState
    ) -> Bool {
        abs(first.y - second.y) * 2 < first.height + second.height
    }

    private mutating func refreshRestingGroundedState() {
        let obstacles = entities.filter {
            $0.body == .static
                && ($0.collisionMode == .solid || $0.collisionMode == .oneWayPlatform)
        }
        for index in entities.indices where entities[index].collisionMode == .solid {
            guard entities[index].body == .kinematic || entities[index].body == .dynamic else {
                continue
            }
            let bottom = entities[index].y + entities[index].height / 2
            let restsOnWorld = program.source.world.edgeBehavior == .solid
                && bottom == program.source.world.height
            let restsOnPlatform = obstacles.contains { obstacle in
                bottom == obstacle.y - obstacle.height / 2
                    && horizontalOverlap(entities[index], obstacle)
            }
            entities[index].isGrounded = restsOnWorld || restsOnPlatform
        }
    }

    private mutating func ageAndExpireEntities() {
        for index in entities.indices where entities[index].lifetimeTicks > 0 {
            entities[index].ageTicks += 1
        }
        entities.removeAll { entity in
            entity.lifetimeTicks > 0 && entity.ageTicks >= entity.lifetimeTicks
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
                    if entities[index].y > maximumY,
                       entities[index].velocityY >= 0,
                       entities[index].collisionMode == .solid {
                        entities[index].isGrounded = true
                    }
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

    private mutating func runCollisionRules(previousPositions: [String: TinyGamePoint]) {
        let contacts = collisionContacts(previousPositions: previousPositions)
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

    private func collisionContacts(
        previousPositions: [String: TinyGamePoint]
    ) -> [TinyGameContact] {
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
                let hasContact = intersects(first, second)
                    || (program.source.version >= 3
                        && sweptIntersects(
                            first,
                            second,
                            previousPositions: previousPositions
                        ))
                if isRelevantCollisionPair(first, second, for: collisionRules), hasContact {
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

    private func sweptIntersects(
        _ first: TinyGameEntityState,
        _ second: TinyGameEntityState,
        previousPositions: [String: TinyGamePoint]
    ) -> Bool {
        guard let firstStart = previousPositions[first.id],
              let secondStart = previousPositions[second.id] else { return false }
        let startX = Double(firstStart.x - secondStart.x)
        let startY = Double(firstStart.y - secondStart.y)
        let relativeDeltaX = Double(
            (first.x - firstStart.x) - (second.x - secondStart.x)
        )
        let relativeDeltaY = Double(
            (first.y - firstStart.y) - (second.y - secondStart.y)
        )
        let halfWidth = Double(first.width + second.width) / 2
        let halfHeight = Double(first.height + second.height) / 2
        guard let horizontal = sweptInterval(
            start: startX,
            delta: relativeDeltaX,
            halfExtent: halfWidth
        ), let vertical = sweptInterval(
            start: startY,
            delta: relativeDeltaY,
            halfExtent: halfHeight
        ) else { return false }
        let entry = max(max(horizontal.lowerBound, vertical.lowerBound), 0)
        let exit = min(min(horizontal.upperBound, vertical.upperBound), 1)
        return entry <= exit
    }

    private func sweptInterval(
        start: Double,
        delta: Double,
        halfExtent: Double
    ) -> ClosedRange<Double>? {
        if delta == 0 {
            return abs(start) <= halfExtent
                ? -Double.infinity...Double.infinity
                : nil
        }
        let first = (-halfExtent - start) / delta
        let second = (halfExtent - start) / delta
        return min(first, second)...max(first, second)
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

    private func firstEntityIndex(withTag tag: String) -> Int? {
        guard let identifier = firstEntity(withTag: tag)?.id else { return nil }
        return entities.firstIndex(where: { $0.id == identifier })
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
            tags: Set(template.tags + [template.role.rawValue]),
            collisionMode: template.physics?.collisionMode ?? .sensor,
            maximumVelocityX: template.physics?.maximumVelocityX ?? 0,
            maximumVelocityY: template.physics?.maximumVelocityY ?? 0,
            lifetimeTicks: template.physics?.lifetimeTicks ?? 0,
            ageTicks: 0,
            facingX: template.velocityX < 0 ? -1 : 1,
            isGrounded: false
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

// Coordinate fields mirror the declarative game coordinate system.
// swiftlint:disable identifier_name
private struct TinyGamePoint: Sendable {
    var x: Int
    var y: Int
}
// swiftlint:enable identifier_name

private enum TinyGameResolutionAxis: Sendable {
    case above
    case below
    case left
    case right
}

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
