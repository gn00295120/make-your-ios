import XCTest
@testable import MakeYourIOS

final class OpenAIAppGenerationClientTests: XCTestCase {
    func testRequestUsesStrictPrivateStructuredOutputConfiguration() throws {
        let request = try OpenAIAppGenerationClient().makeRequest(
            prompt: "Make a snake game",
            currentDocument: SampleDocuments.blank,
            config: AIConnectionConfig(
                apiKey: "test-key",
                model: "gpt-test",
                safetyIdentifier: "test-safety"
            )
        )

        XCTAssertEqual(request.url?.absoluteString, "https://api.openai.com/v1/responses")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
        let data = try XCTUnwrap(request.httpBody)
        let body = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(body["store"] as? Bool, false)
        XCTAssertEqual(body["max_output_tokens"] as? Int, 25_000)
        XCTAssertNil(body["tools"])

        let text = try XCTUnwrap(body["text"] as? [String: Any])
        let format = try XCTUnwrap(text["format"] as? [String: Any])
        XCTAssertEqual(format["type"] as? String, "json_schema")
        XCTAssertEqual(format["strict"] as? Bool, true)
        XCTAssertNotNil(format["schema"] as? [String: Any])

        let instructions = try XCTUnwrap(body["instructions"] as? String)
        XCTAssertTrue(instructions.contains("When the request is design-only"))
        XCTAssertTrue(instructions.contains("Palette values must be #RRGGBB"))
        XCTAssertTrue(instructions.contains("Never invent an asset ID, file path, URL"))
        XCTAssertTrue(instructions.contains("requires Apple's on-device recognition"))
        XCTAssertTrue(instructions.contains("never falls back to a network recognizer"))
        XCTAssertTrue(instructions.contains("saved speechTranscript into the AI editor"))
        XCTAssertTrue(instructions.contains("Use shortcutAccess only when the user explicitly asks"))
        XCTAssertTrue(instructions.contains("one fixed, precompiled"))
        XCTAssertTrue(instructions.contains("requires local device authentication"))
        XCTAssertTrue(instructions.contains("Opening from a shortcut behaves like opening the same tiny app"))
        XCTAssertTrue(instructions.contains("behavior may run"))
    }

    func testIncompleteResponseSurfacesSpecificRetryableError() {
        let data = Data(
            """
            {
              "status": "incomplete",
              "incomplete_details": {"reason": "max_output_tokens"},
              "output": []
            }
            """.utf8
        )

        XCTAssertThrowsError(
            try OpenAIAppGenerationClient.decodeDocument(data, replacing: SampleDocuments.blank)
        ) { error in
            XCTAssertEqual(
                error as? AppGenerationError,
                .incomplete("max_output_tokens")
            )
        }
    }

    func testHTTPErrorPreservesProviderMessage() throws {
        let response = try XCTUnwrap(HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/responses")!,
            statusCode: 400,
            httpVersion: nil,
            headerFields: nil
        ))
        let data = Data(#"{"error":{"message":"Invalid schema."}}"#.utf8)

        XCTAssertThrowsError(try OpenAIAppGenerationClient.validate(response: response, data: data)) { error in
            XCTAssertEqual(
                error as? AppGenerationError,
                .api(statusCode: 400, message: "Invalid schema.")
            )
        }
    }
}
