import XCTest

@MainActor
final class LiveAIGenerationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSavedKeyGeneratesAndRunsComposableTinyApp() throws {
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
            "Create a one-page local app named E2E Counter. Declare a project-persisted number state "
                + "with key total and initial value 0. Add a metric with exact ID total-metric, title "
                + "Total, and valueBinding total. Add a button with exact ID add-one and title Add one. "
                + "Its tap event must set total to total plus literal 1. Set its legacy action to none. "
                + "Use only local storage and safe calculation. Do not add network, AI, notifications, "
                + "photos, device components, games, or specialized data components."
        )

        let generateButton = app.buttons["builder.generate"]
        XCTAssertTrue(generateButton.isEnabled)
        generateButton.tap()

        let capabilityApproval = app.buttons["capability-review.approve"]
        if capabilityApproval.waitForExistence(timeout: 5) {
            capabilityApproval.tap()
        }

        let hostMenu = app.buttons["runtime.host-menu"]
        let addButton = app.buttons["runtime.node.add-one"]
        let total = app.descendants(matching: .any)["runtime.node.total-metric"]
        let generationSucceeded = hostMenu.waitForExistence(timeout: 120)
            && addButton.waitForExistence(timeout: 10)
            && total.waitForExistence(timeout: 5)
        if !generationSucceeded {
            attachScreenshot(app, name: "live-generation-failure")
        }
        XCTAssertTrue(generationSucceeded, visibleFailure(in: app))

        XCTAssertEqual(total.value as? String, "0")
        addButton.tap()
        let updatedValue = NSPredicate(format: "value == %@", "1")
        let expectation = XCTNSPredicateExpectation(predicate: updatedValue, object: total)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
        attachScreenshot(app, name: "live-generation-success")
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
