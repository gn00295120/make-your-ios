import XCTest
@testable import MakeYourIOS

final class GameRuntimeModelsTests: XCTestCase {
    func testSnakeLayoutAndFoodAreDeterministicForSeed() {
        let first = SnakeEngine(difficulty: .standard, targetScore: 8, seed: 77)
        let second = SnakeEngine(difficulty: .standard, targetScore: 8, seed: 77)

        XCTAssertEqual(first.snake, second.snake)
        XCTAssertEqual(first.food, second.food)
        XCTAssertEqual(first.tickInterval, second.tickInterval)
    }

    func testSnakeRejectsReverseDirectionAndLosesAtWall() {
        var engine = SnakeEngine(columns: 8, rows: 8, difficulty: .standard, targetScore: 10, seed: 5)
        engine.start()
        engine.changeDirection(.left)
        engine.step()

        XCTAssertEqual(engine.direction, .right)
        for _ in 0..<10 where engine.phase == .playing { engine.step() }
        XCTAssertEqual(engine.phase, .lost)
    }

    func testSnakeCanCollectFoodAndReachTarget() throws {
        let candidate = (0...1_000).lazy.compactMap { seed -> SnakeEngine? in
            let engine = SnakeEngine(
                columns: 8,
                rows: 8,
                difficulty: .relaxed,
                targetScore: 1,
                seed: seed
            )
            let head = engine.snake[0]
            return engine.food.row == head.row && engine.food.column > head.column ? engine : nil
        }.first
        var engine = try XCTUnwrap(candidate)
        let steps = engine.food.column - engine.snake[0].column

        engine.start()
        for _ in 0..<steps { engine.step() }

        XCTAssertEqual(engine.score, 1)
        XCTAssertEqual(engine.phase, .won)
    }

    func testPlatformerLevelIsDeterministicAndMovementIsPlayable() {
        var engine = PlatformerEngine(seed: 44, difficulty: .standard, targetScore: 6)
        let copy = PlatformerEngine(seed: 44, difficulty: .standard, targetScore: 6)
        XCTAssertEqual(engine.platforms, copy.platforms)
        XCTAssertEqual(engine.collectibles, copy.collectibles)
        XCTAssertEqual(engine.hazards, copy.hazards)

        engine.start()
        for _ in 0..<90 { engine.update(deltaTime: 1.0 / 60.0, input: .idle) }
        XCTAssertTrue(engine.isGrounded)
        let groundedY = engine.player.originY
        engine.update(
            deltaTime: 1.0 / 60.0,
            input: PlatformerInput(horizontal: 1, jump: true)
        )
        XCTAssertGreaterThan(engine.player.originX, 48)
        XCTAssertLessThan(engine.player.originY, groundedY)
        XCTAssertLessThan(engine.velocityY, 0)
    }

    func testPlatformerHazardCausesLossAndRestartResetsState() {
        var engine = PlatformerEngine(seed: 9, difficulty: .fast, targetScore: 8)
        engine.start()
        for _ in 0..<1_000 where engine.phase == .playing {
            engine.update(
                deltaTime: 1.0 / 60.0,
                input: PlatformerInput(horizontal: 1, jump: false)
            )
        }
        XCTAssertEqual(engine.phase, .lost)

        engine.restart()
        XCTAssertEqual(engine.phase, .ready)
        XCTAssertEqual(engine.score, 0)
        XCTAssertEqual(engine.player.originX, 48)
    }
}
