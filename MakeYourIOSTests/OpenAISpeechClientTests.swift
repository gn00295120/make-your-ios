import XCTest
@testable import MakeYourIOS

#if DEBUG
final class OpenAISpeechClientTests: XCTestCase {
    func testRequestUsesFixedDemoSpeechConfiguration() throws {
        let request = try OpenAISpeechClient().makeRequest(
            text: "Make your own useful app.",
            apiKey: "test-api-key"
        )

        XCTAssertEqual(request.url?.absoluteString, "https://api.openai.com/v1/audio/speech")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-api-key")
        XCTAssertEqual(request.timeoutInterval, 120)

        let bodyData = try XCTUnwrap(request.httpBody)
        let body = try XCTUnwrap(
            JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
        )
        XCTAssertEqual(
            Set(body.keys),
            Set(["model", "input", "voice", "instructions", "response_format"])
        )
        XCTAssertEqual(body["model"] as? String, "gpt-4o-mini-tts")
        XCTAssertEqual(body["input"] as? String, "Make your own useful app.")
        XCTAssertEqual(body["voice"] as? String, "marin")
        XCTAssertEqual(body["response_format"] as? String, "mp3")
        XCTAssertTrue((body["instructions"] as? String)?.contains("natural") == true)
    }

    func testRequestRejectsEmptyAndOversizedNarration() {
        XCTAssertThrowsError(
            try OpenAISpeechClient().makeRequest(text: "   ", apiKey: "test-api-key")
        ) { error in
            XCTAssertEqual(error as? OpenAISpeechError, .invalidInput)
        }

        XCTAssertThrowsError(
            try OpenAISpeechClient().makeRequest(
                text: String(repeating: "a", count: 4_097),
                apiKey: "test-api-key"
            )
        ) { error in
            XCTAssertEqual(error as? OpenAISpeechError, .invalidInput)
        }
    }

    func testExportOptionsDecodeUTF8TextAndSafeFilename() throws {
        let narration = "MakeYour turns one sentence into a native mini app."
        let encoded = Data(narration.utf8).base64EncodedString()
        let options = try XCTUnwrap(
            DemoTTSExportOptions.parse(
                arguments: [
                    "MakeYourIOS",
                    "--demo-export-tts",
                    "--demo-tts-text-base64=\(encoded)",
                    "--demo-tts-output=05-generation.mp3"
                ]
            )
        )

        XCTAssertEqual(options.text, narration)
        XCTAssertEqual(options.outputFilename, "05-generation.mp3")
    }

    func testExportOptionsIgnoreNormalLaunchAndRejectPathTraversal() throws {
        XCTAssertNil(try DemoTTSExportOptions.parse(arguments: ["MakeYourIOS"]))

        let encoded = Data("Narration".utf8).base64EncodedString()
        XCTAssertThrowsError(
            try DemoTTSExportOptions.parse(
                arguments: [
                    "--demo-export-tts",
                    "--demo-tts-text-base64=\(encoded)",
                    "--demo-tts-output=../narration.mp3"
                ]
            )
        ) { error in
            XCTAssertEqual(error as? DemoTTSExportError, .invalidOutputFilename)
        }
    }
}
#endif
