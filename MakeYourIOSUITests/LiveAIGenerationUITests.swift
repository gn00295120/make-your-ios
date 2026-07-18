import XCTest

@MainActor
final class LiveAIGenerationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSavedKeyGeneratesAndRunsValidatedTinyApp() throws {
        guard ProcessInfo.processInfo.arguments.contains("-run-live-ai-e2e") else {
            throw XCTSkip("Run the dedicated MakeYourIOSLiveE2E scheme to authorize one live request.")
        }

        let app = XCUIApplication()
        app.launch()

        let createButton = app.buttons["library.create"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 10))
        createButton.tap()

        let blankTemplate = app.buttons["create.template.blank-canvas"]
        XCTAssertTrue(blankTemplate.waitForExistence(timeout: 10))
        blankTemplate.tap()

        let prompt = app.textViews["builder.prompt"]
        XCTAssertTrue(prompt.waitForExistence(timeout: 10))
        prompt.tap()
        prompt.typeText(
            "Create a one-page local app named E2E Proof. Add a centered hero titled Generated live "
                + "and a text block saying GPT response validated. Use only local storage. "
                + "Do not add network, AI, notification, photo, or device components."
        )

        let generateButton = app.buttons["builder.generate"]
        XCTAssertTrue(generateButton.isEnabled)
        generateButton.tap()

        let capabilityApproval = app.buttons["capability-review.approve"]
        if capabilityApproval.waitForExistence(timeout: 5) {
            capabilityApproval.tap()
        }

        let hostMenu = app.buttons["runtime.host-menu"]
        let generatedHero = app.staticTexts["Generated live"]
        let generationSucceeded = hostMenu.waitForExistence(timeout: 120)
            && generatedHero.waitForExistence(timeout: 10)
        attachScreenshot(app, name: generationSucceeded ? "live-generation-success" : "live-generation-failure")
        XCTAssertTrue(generationSucceeded, visibleFailure(in: app))
    }

    private func visibleFailure(in app: XCUIApplication) -> String {
        let alerts = app.alerts.allElementsBoundByIndex
        let alertText = alerts.first?.staticTexts.allElementsBoundByIndex
            .map { $0.label }
            .filter { !$0.isEmpty }
            .joined(separator: " | ")
        return alertText.map { "Live generation failed: \($0)" }
            ?? "Live generation did not open the generated runtime."
    }

    private func attachScreenshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
