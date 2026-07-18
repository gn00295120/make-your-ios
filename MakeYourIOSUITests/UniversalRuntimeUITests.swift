import XCTest

@MainActor
final class UniversalRuntimeUITests: XCTestCase {
    func testGeneratedStyleTrackerCalculatesAndRendersStateChanges() {
        let app = XCUIApplication()
        app.launchArguments = ["--demo-screen=waterline"]
        app.launch()

        let addWater = app.buttons["runtime.node.add-water"]
        let total = app.descendants(matching: .any)["runtime.node.water-total"]
        XCTAssertTrue(addWater.waitForExistence(timeout: 10))
        XCTAssertTrue(addWater.isHittable)
        XCTAssertTrue(total.waitForExistence(timeout: 3))
        XCTAssertEqual(total.value as? String, "0 ml")

        addWater.tap()
        addWater.tap()

        let updatedValue = NSPredicate(format: "value == %@", "500 ml")
        let expectation = XCTNSPredicateExpectation(predicate: updatedValue, object: total)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 3), .completed)
        let progress = app.otherElements["runtime.node.water-progress"]
        XCTAssertTrue(progress.exists)
        XCTAssertTrue(progress.value as? String == "500 ml")
        XCTAssertTrue(app.buttons["runtime.host-menu"].isHittable)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Universal runtime hydration tracker"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testCustomRuleDrivenGameIsPlayableAndKeepsTheHostExit() {
        let app = XCUIApplication()
        app.launchArguments = ["--demo-screen=star-garden"]
        app.launch()

        XCTAssertTrue(app.otherElements["tiny-game.board"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["runtime.host-menu"].isHittable)

        let primary = app.buttons["tiny-game.transport.primary"]
        XCTAssertTrue(primary.waitForExistence(timeout: 3))
        for _ in 0..<4 where !primary.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(primary.isHittable)
        primary.tap()

        let moveUp = app.buttons["tiny-game.control.move-glider.up"]
        XCTAssertTrue(moveUp.exists)
        for _ in 0..<3 where !moveUp.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(moveUp.isHittable)
        XCTAssertGreaterThanOrEqual(moveUp.frame.height, 44)
        moveUp.tap()
        XCTAssertEqual(primary.label, "Pause")

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Custom rule-driven tiny game"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
