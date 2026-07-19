import XCTest

@MainActor
final class AppIntentsUITests: XCTestCase {
    func testShortcutAccessBlockRendersInsideTheEscapableHostShell() {
        let app = XCUIApplication()
        app.launchArguments = ["--demo-screen=shortcuts"]
        app.launch()

        let shortcutBlock = app.descendants(matching: .any)["runtime.shortcuts.shortcut-access"]
        scrollUntilVisible(shortcutBlock, in: app)
        XCTAssertTrue(shortcutBlock.exists)
        XCTAssertTrue(app.staticTexts["Open with Shortcuts"].exists)
        let privacyCopy = app.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Shortcuts receives only")
        ).firstMatch
        XCTAssertTrue(privacyCopy.exists)
        XCTAssertTrue(app.buttons["runtime.host-menu"].isHittable)
        XCTAssertFalse(app.alerts.firstMatch.exists)
    }

    private func scrollUntilVisible(
        _ element: XCUIElement,
        in app: XCUIApplication,
        attempts: Int = 8,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for _ in 0..<attempts where !element.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(element.waitForExistence(timeout: 5), file: file, line: line)
    }
}
