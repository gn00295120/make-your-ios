import XCTest

@MainActor
final class RuntimeHostShellUITests: XCTestCase {
    func testPlatformerDemoCanExitThroughHostMenuToMyApps() {
        let app = launchDemo("platformer")

        let menu = app.buttons["runtime.host-menu"]
        XCTAssertTrue(menu.waitForExistence(timeout: 10))
        XCTAssertTrue(menu.isHittable)
        menu.tap()

        let openApps = app.buttons["runtime.open-apps"]
        XCTAssertTrue(openApps.waitForExistence(timeout: 5))
        openApps.tap()

        XCTAssertTrue(app.buttons["library.create"].waitForExistence(timeout: 8))
        XCTAssertFalse(menu.exists)
        XCTAssertTrue(app.buttons["My Apps"].isSelected)
    }

    func testSnakeDemoUsesVisibleHostMenuInDarkTheme() {
        let app = launchDemo("snake")

        let menu = app.buttons["runtime.host-menu"]
        XCTAssertTrue(menu.waitForExistence(timeout: 10))
        XCTAssertTrue(menu.isHittable)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Snake demo host shell"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testGeneratedConverterUsesCurrencyTitlesWhenIDsAreOpaque() {
        let app = launchDemo("converter-generated")

        let result = app.descendants(matching: .any)["currency.converted-amount"]
        XCTAssertTrue(result.waitForExistence(timeout: 10))
        XCTAssertEqual(result.value as? String, "3,250.00 TWD")
    }

    func testStoredTripPilotConverterUsesItsGeneratedRates() throws {
        let app = XCUIApplication()
        app.launch()

        let project = app.staticTexts["TripPilot 旅程掌控台"]
        guard project.waitForExistence(timeout: 8) else {
            throw XCTSkip("The locally generated TripPilot project is not installed.")
        }
        project.tap()

        let result = app.descendants(matching: .any)["currency.converted-amount"]
        for _ in 0..<8 where !result.isHittable {
            app.swipeUp()
        }

        XCTAssertTrue(result.waitForExistence(timeout: 5))
        XCTAssertEqual(result.value as? String, "3,250.00 TWD")

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "TripPilot currency conversion fixed"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func launchDemo(_ name: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--demo-screen=\(name)"]
        app.launch()
        return app
    }
}
