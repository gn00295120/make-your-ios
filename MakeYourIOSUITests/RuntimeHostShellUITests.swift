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

    private func launchDemo(_ name: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--demo-screen=\(name)"]
        app.launch()
        return app
    }
}
