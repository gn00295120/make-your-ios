import XCTest

@MainActor
final class DesignStudioUITests: XCTestCase {
    func testDesignStudioOpensWithPreviewAndSafeDraftActions() {
        let app = XCUIApplication()
        app.launchArguments = ["--demo-screen=builder"]
        app.launch()

        let openStudio = app.buttons["Open Design Studio"]
        XCTAssertTrue(openStudio.waitForExistence(timeout: 8))
        openStudio.tap()

        XCTAssertTrue(app.navigationBars["Design Studio"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["LIVE PREVIEW"].exists)
        XCTAssertTrue(app.buttons["Apply as new version"].exists)
        XCTAssertTrue(app.buttons["Cancel"].exists)
        XCTAssertTrue(app.buttons["Undo design change"].exists)
        XCTAssertTrue(app.buttons["Redo design change"].exists)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Design Studio v2"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        app.buttons["Cancel"].tap()
        XCTAssertTrue(openStudio.waitForExistence(timeout: 5))
    }

    func testPresetUndoRedoAndApplyCreateOneVersion() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--demo-screen=builder"]
        app.launch()

        let currentVersion = try versionNumber(in: app)
        app.buttons["Open Design Studio"].tap()
        XCTAssertTrue(app.navigationBars["Design Studio"].waitForExistence(timeout: 5))

        let playfulPreset = app.buttons["design.preset.playful"]
        for _ in 0..<3 where !playfulPreset.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(playfulPreset.exists)
        playfulPreset.tap()

        let undo = app.buttons["Undo design change"]
        undo.tap()
        let redo = app.buttons["Redo design change"]
        redo.tap()

        app.buttons["Apply as new version"].tap()
        XCTAssertTrue(app.buttons["Open Design Studio"].waitForExistence(timeout: 5))
        XCTAssertEqual(try versionNumber(in: app), currentVersion + 1)
    }

    private func versionNumber(in app: XCUIApplication) throws -> Int {
        let predicate = NSPredicate(format: "label BEGINSWITH 'Version '")
        let label = app.staticTexts.matching(predicate).firstMatch
        XCTAssertTrue(label.waitForExistence(timeout: 8))
        return try XCTUnwrap(Int(label.label.replacingOccurrences(of: "Version ", with: "")))
    }
}
