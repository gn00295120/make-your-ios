import Foundation
import XCTest
@testable import MakeYourIOS

final class AppGenerationProgressTests: XCTestCase {
    func testElapsedTimeUsesClockStyleFormatting() {
        XCTAssertEqual(AppGenerationProgress.elapsedDescription(seconds: 0), "0:00")
        XCTAssertEqual(AppGenerationProgress.elapsedDescription(seconds: 65), "1:05")
        XCTAssertEqual(AppGenerationProgress.elapsedDescription(seconds: 3_661), "61:01")
        XCTAssertEqual(AppGenerationProgress.repairing.label, "Repair")
        XCTAssertTrue(AppGenerationProgress.repairing.detail.contains("correcting"))
    }

    func testTimeoutIsPresentedAsRetryableWithoutLosingPrompt() {
        let failure = AppGenerationFailure(error: URLError(.timedOut))

        XCTAssertEqual(failure.kind, .timedOut)
        XCTAssertTrue(failure.canRetry)
        XCTAssertTrue(failure.message.contains("prompt is still here"))
    }

    func testOfflineFailureExplainsConnectivityRecovery() {
        let failure = AppGenerationFailure(error: URLError(.notConnectedToInternet))

        XCTAssertEqual(failure.kind, .offline)
        XCTAssertTrue(failure.canRetry)
        XCTAssertTrue(failure.recovery.contains("connection"))
    }

    func testProviderFailureRemainsRetryable() {
        let failure = AppGenerationFailure(
            error: AppGenerationError.api(statusCode: 503, message: "Temporarily unavailable.")
        )

        XCTAssertEqual(failure.kind, .provider)
        XCTAssertTrue(failure.canRetry)
        XCTAssertTrue(failure.message.contains("Temporarily unavailable"))
    }
}
