import XCTest

@MainActor
final class GameRuntimeUITests: XCTestCase {
    func testSkyboundControlsStaySafeAndTransportStateIsPlayable() {
        let app = launchGame("platformer", boardIdentifier: "game.board.platformer")
        let primary = app.buttons["game.transport.primary"]
        let restart = app.buttons["game.transport.restart"]
        let moveRight = app.buttons["game.direction.right"]
        let stop = app.buttons["game.direction.stop"]
        let jump = app.buttons["game.action.jump"]

        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label == 'Start'")).count, 1)
        assertControlsAreHittable([primary, restart, moveRight, stop, jump], in: app)

        primary.tap()
        waitForLabel("Pause", on: primary)
        moveRight.tap()
        jump.tap()
        stop.tap()
        primary.tap()
        waitForLabel("Resume", on: primary)
        primary.tap()
        waitForLabel("Pause", on: primary)
        restart.tap()
        waitForLabel("Start", on: primary)

        attachScreenshot(of: app, named: "Skybound game fixed")
    }

    func testNeonSnakeHasOneStartAndCompactPlayableBoard() {
        let app = launchGame("snake", boardIdentifier: "game.board.snake")
        let board = app.otherElements["game.board.snake"]
        let primary = app.buttons["game.transport.primary"]
        let restart = app.buttons["game.transport.restart"]
        let moveUp = app.buttons["game.direction.up"]
        let moveLeft = app.buttons["game.direction.left"]
        let moveDown = app.buttons["game.direction.down"]
        let moveRight = app.buttons["game.direction.right"]

        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label == 'Start'")).count, 1)
        XCTAssertLessThanOrEqual(board.frame.height, 330)
        assertControlsAreHittable(
            [primary, restart, moveUp, moveLeft, moveDown, moveRight],
            in: app
        )

        moveUp.tap()
        primary.tap()
        waitForLabel("Pause", on: primary)
        primary.tap()
        waitForLabel("Resume", on: primary)
        restart.tap()
        waitForLabel("Start", on: primary)

        attachScreenshot(of: app, named: "Neon Snake game fixed")
    }

    private func launchGame(_ screen: String, boardIdentifier: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--demo-screen=\(screen)"]
        app.launch()

        let board = app.otherElements[boardIdentifier]
        XCTAssertTrue(board.waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["game.transport.primary"].waitForExistence(timeout: 3))
        return app
    }

    private func assertControlsAreHittable(
        _ controls: [XCUIElement],
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let windowFrame = app.windows.firstMatch.frame
        for control in controls {
            XCTAssertTrue(control.exists, file: file, line: line)
            XCTAssertTrue(control.isHittable, "\(control.identifier) should be hittable", file: file, line: line)
            XCTAssertGreaterThanOrEqual(control.frame.minX, windowFrame.minX + 8, file: file, line: line)
            XCTAssertLessThanOrEqual(control.frame.maxX, windowFrame.maxX - 8, file: file, line: line)
            XCTAssertGreaterThanOrEqual(control.frame.height, 44, file: file, line: line)
        }
    }

    private func waitForLabel(
        _ label: String,
        on element: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let predicate = NSPredicate(format: "label == %@", label)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 3), .completed, file: file, line: line)
    }

    private func attachScreenshot(of app: XCUIApplication, named name: String) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
