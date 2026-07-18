import Foundation

enum GamePhase: String, Equatable, Sendable {
    case ready
    case playing
    case paused
    case won
    case lost
}

struct GridPoint: Hashable, Sendable {
    var column: Int
    var row: Int
}

enum SnakeDirection: CaseIterable, Sendable {
    case north
    case down
    case left
    case right

    fileprivate var offset: GridPoint {
        switch self {
        case .north: GridPoint(column: 0, row: -1)
        case .down: GridPoint(column: 0, row: 1)
        case .left: GridPoint(column: -1, row: 0)
        case .right: GridPoint(column: 1, row: 0)
        }
    }

    fileprivate func isOpposite(to other: SnakeDirection) -> Bool {
        switch (self, other) {
        case (.north, .down), (.down, .north), (.left, .right), (.right, .left): true
        default: false
        }
    }
}

struct SnakeEngine: Sendable {
    let columns: Int
    let rows: Int
    let difficulty: GameDifficulty
    let targetScore: Int
    let seed: Int

    private(set) var snake: [GridPoint]
    private(set) var food: GridPoint
    private(set) var score = 0
    private(set) var phase: GamePhase = .ready
    private(set) var direction: SnakeDirection = .right

    private var pendingDirection: SnakeDirection = .right
    private var random: SeededRandomNumberGenerator

    init(
        columns: Int = 18,
        rows: Int = 22,
        difficulty: GameDifficulty,
        targetScore: Int,
        seed: Int
    ) {
        self.columns = max(columns, 8)
        self.rows = max(rows, 8)
        self.difficulty = difficulty
        self.targetScore = max(targetScore, 1)
        self.seed = seed
        let center = GridPoint(column: self.columns / 2, row: self.rows / 2)
        snake = [
            center,
            GridPoint(column: center.column - 1, row: center.row),
            GridPoint(column: center.column - 2, row: center.row)
        ]
        random = SeededRandomNumberGenerator(seed: UInt64(max(seed, 0) + 1))
        food = GridPoint(column: 1, row: 1)
        food = nextFood()
    }

    var tickInterval: TimeInterval {
        switch difficulty {
        case .relaxed: 0.23
        case .standard: 0.16
        case .fast: 0.105
        }
    }

    mutating func start() {
        if phase == .ready || phase == .paused { phase = .playing }
    }

    mutating func togglePause() {
        switch phase {
        case .playing: phase = .paused
        case .paused, .ready: phase = .playing
        case .won, .lost: break
        }
    }

    mutating func changeDirection(_ newDirection: SnakeDirection) {
        guard !newDirection.isOpposite(to: direction) else { return }
        pendingDirection = newDirection
    }

    mutating func step() {
        guard phase == .playing, let head = snake.first else { return }
        direction = pendingDirection
        let offset = direction.offset
        let next = GridPoint(
            column: head.column + offset.column,
            row: head.row + offset.row
        )
        guard (0..<columns).contains(next.column), (0..<rows).contains(next.row) else {
            phase = .lost
            return
        }

        let isEating = next == food
        let occupied = isEating ? snake : Array(snake.dropLast())
        guard !occupied.contains(next) else {
            phase = .lost
            return
        }

        snake.insert(next, at: 0)
        if isEating {
            score += 1
            if score >= targetScore {
                phase = .won
            } else {
                food = nextFood()
            }
        } else {
            snake.removeLast()
        }
    }

    mutating func restart() {
        self = SnakeEngine(
            columns: columns,
            rows: rows,
            difficulty: difficulty,
            targetScore: targetScore,
            seed: seed
        )
    }

    private mutating func nextFood() -> GridPoint {
        let occupied = Set(snake)
        let empty = (0..<rows).flatMap { row in
            (0..<columns).compactMap { column -> GridPoint? in
                let point = GridPoint(column: column, row: row)
                return occupied.contains(point) ? nil : point
            }
        }
        guard !empty.isEmpty else { return snake[0] }
        return empty[Int(random.next() % UInt64(empty.count))]
    }
}

struct PlatformRect: Equatable, Identifiable, Sendable {
    var id: Int
    var originX: Double
    var originY: Double
    var width: Double
    var height: Double

    var maxX: Double { originX + width }
    var maxY: Double { originY + height }

    func intersects(_ other: PlatformRect) -> Bool {
        originX < other.maxX
            && maxX > other.originX
            && originY < other.maxY
            && maxY > other.originY
    }
}

struct PlatformerCollectible: Equatable, Identifiable, Sendable {
    var id: Int
    var centerX: Double
    var centerY: Double
    var isCollected = false
}

struct PlatformerInput: Equatable, Sendable {
    var horizontal: Double
    var jump: Bool

    static let idle = PlatformerInput(horizontal: 0, jump: false)
}

struct PlatformerEngine: Sendable {
    let seed: Int
    let difficulty: GameDifficulty
    let targetScore: Int
    let worldWidth: Double
    let worldHeight: Double = 600

    private(set) var player: PlatformRect
    private(set) var velocityX = 0.0
    private(set) var velocityY = 0.0
    private(set) var isGrounded = false
    private(set) var platforms: [PlatformRect]
    private(set) var hazards: [PlatformRect]
    private(set) var collectibles: [PlatformerCollectible]
    private(set) var score = 0
    private(set) var phase: GamePhase = .ready

    private let startX = 48.0
    private let startY = 480.0

    init(seed: Int, difficulty: GameDifficulty, targetScore: Int) {
        self.seed = seed
        self.difficulty = difficulty
        self.targetScore = max(targetScore, 1)
        worldWidth = max(1_800, 650 + Double(max(targetScore, 1)) * 170)
        player = PlatformRect(id: -1, originX: startX, originY: startY, width: 34, height: 44)

        var random = SeededRandomNumberGenerator(seed: UInt64(max(seed, 0) + 1))
        var builtPlatforms = [
            PlatformRect(id: 0, originX: 0, originY: 540, width: worldWidth, height: 60)
        ]
        var builtCollectibles: [PlatformerCollectible] = []
        var builtHazards: [PlatformRect] = []
        for index in 0..<self.targetScore {
            let platformX = 240 + Double(index) * 170
            let levels = [420.0, 450.0, 480.0]
            let level = levels[Int(random.next() % UInt64(levels.count))]
            let width = 100 + Double(random.next() % 45)
            builtPlatforms.append(PlatformRect(
                id: index + 1,
                originX: platformX,
                originY: level,
                width: width,
                height: 16
            ))
            builtCollectibles.append(PlatformerCollectible(
                id: index,
                centerX: platformX + width / 2,
                centerY: level - 24
            ))
            if index > 0, index.isMultiple(of: 3) {
                builtHazards.append(PlatformRect(
                    id: index,
                    originX: platformX - 46,
                    originY: 520,
                    width: 28,
                    height: 20
                ))
            }
        }
        platforms = builtPlatforms
        collectibles = builtCollectibles
        hazards = builtHazards
    }

    var goalX: Double { worldWidth - 100 }

    mutating func start() {
        if phase == .ready || phase == .paused { phase = .playing }
    }

    mutating func togglePause() {
        switch phase {
        case .playing: phase = .paused
        case .paused, .ready: phase = .playing
        case .won, .lost: break
        }
    }

    mutating func update(deltaTime: TimeInterval, input: PlatformerInput) {
        guard phase == .playing else { return }
        let delta = min(max(deltaTime, 0), 1.0 / 20.0)
        let previous = player
        velocityX = max(-1, min(input.horizontal, 1)) * movementSpeed
        if input.jump, isGrounded {
            velocityY = -480
            isGrounded = false
        }

        player.originX = min(
            max(0, player.originX + velocityX * delta),
            worldWidth - player.width
        )
        velocityY += 1_100 * delta
        player.originY += velocityY * delta
        isGrounded = false

        if velocityY >= 0 {
            for platform in platforms where horizontalOverlap(player, platform) {
                let previousBottom = previous.maxY
                if previousBottom <= platform.originY + 2, player.maxY >= platform.originY {
                    player.originY = platform.originY - player.height
                    velocityY = 0
                    isGrounded = true
                    break
                }
            }
        }

        if hazards.contains(where: { $0.intersects(player) }) || player.originY > worldHeight {
            phase = .lost
            return
        }

        for index in collectibles.indices where !collectibles[index].isCollected {
            let token = PlatformRect(
                id: collectibles[index].id,
                originX: collectibles[index].centerX - 12,
                originY: collectibles[index].centerY - 12,
                width: 24,
                height: 24
            )
            if token.intersects(player) {
                collectibles[index].isCollected = true
                score += 1
            }
        }

        if score >= targetScore, player.maxX >= goalX {
            phase = .won
        }
    }

    mutating func restart() {
        self = PlatformerEngine(seed: seed, difficulty: difficulty, targetScore: targetScore)
    }

    private var movementSpeed: Double {
        switch difficulty {
        case .relaxed: 180
        case .standard: 230
        case .fast: 285
        }
    }

    private func horizontalOverlap(_ lhs: PlatformRect, _ rhs: PlatformRect) -> Bool {
        lhs.originX < rhs.maxX && lhs.maxX > rhs.originX
    }
}

private struct SeededRandomNumberGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}
