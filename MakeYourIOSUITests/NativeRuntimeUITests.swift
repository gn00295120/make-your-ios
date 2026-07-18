import XCTest

@MainActor
final class NativeRuntimeUITests: XCTestCase {
    func testDeviceLabRendersMapCalendarReviewAndExportPreview() {
        let app = XCUIApplication()
        app.launchArguments = ["--demo-screen=device"]
        app.launch()

        let directions = app.buttons["Open directions in Maps"]
        scrollUntilVisible(directions, in: app)
        XCTAssertTrue(directions.exists)
        XCTAssertTrue(directions.isHittable)

        let review = app.buttons["Review calendar event"]
        scrollUntilVisible(review, in: app)
        XCTAssertTrue(review.exists)
        XCTAssertTrue(review.isHittable)
        review.tap()

        XCTAssertTrue(app.navigationBars["Review event"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Add Event"].exists)
        let calendarBoundary = app.staticTexts[
            "MakeYour can add this single event, but cannot read your existing calendar."
        ]
        scrollUntilVisible(calendarBoundary, in: app, attempts: 6)
        XCTAssertTrue(calendarBoundary.exists)
        app.buttons["Cancel"].tap()

        let preview = app.staticTexts["A private tiny app made in MakeYour."]
        scrollUntilVisible(preview, in: app)
        XCTAssertTrue(preview.exists)
        XCTAssertTrue(app.buttons["Review and export"].isHittable)

        let recordVoiceNote = app.buttons["Record a voice note"]
        scrollUntilVisible(recordVoiceNote, in: app)
        XCTAssertTrue(recordVoiceNote.isHittable)
        XCTAssertFalse(app.alerts.firstMatch.exists)
        XCTAssertTrue(app.buttons["runtime.host-menu"].isHittable)
    }

    private func scrollUntilVisible(
        _ element: XCUIElement,
        in app: XCUIApplication,
        attempts: Int = 12,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for _ in 0..<attempts where !element.isHittable {
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.72))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.42))
            start.press(forDuration: 0.01, thenDragTo: end)
        }
        XCTAssertTrue(element.waitForExistence(timeout: 3), file: file, line: line)
    }
}
