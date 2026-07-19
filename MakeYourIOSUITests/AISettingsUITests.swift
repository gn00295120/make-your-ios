import XCTest

final class AISettingsUITests: XCTestCase {
    func testModelUsesCuratedMenuInsteadOfFreeText() {
        let app = XCUIApplication()
        app.launchArguments = ["--demo-screen=ai-key"]
        app.launch()

        let modelPicker = app.buttons["settings.model-picker"]
        XCTAssertTrue(modelPicker.waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields["Model"].exists)

        modelPicker.tap()

        for option in [
            "GPT-5.6 (Recommended)",
            "GPT-5.6 Sol",
            "GPT-5.6 Terra",
            "GPT-5.6 Luna"
        ] {
            XCTAssertTrue(app.buttons[option].waitForExistence(timeout: 2))
        }
    }
}
