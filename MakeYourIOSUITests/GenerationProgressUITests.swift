import XCTest

@MainActor
final class GenerationProgressUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testGenerationDialogShowsLiveProgressAndCanCancel() {
        let app = XCUIApplication()
        app.launchArguments = ["--demo-screen=generation-progress"]
        app.launch()

        let dialog = app.descendants(matching: .any)["builder.generation-dialog"]
        XCTAssertTrue(dialog.waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Building your tiny app"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["builder.generation-phase"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["builder.generation-elapsed"].exists)
        XCTAssertTrue(app.staticTexts["Your request"].exists)

        let cancel = app.buttons["builder.generation.cancel"]
        XCTAssertTrue(cancel.exists)
        cancel.tap()

        XCTAssertTrue(app.buttons["library.create"].waitForExistence(timeout: 5))
    }
}
