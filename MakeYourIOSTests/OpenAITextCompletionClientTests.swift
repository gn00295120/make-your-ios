import XCTest
@testable import MakeYourIOS

final class OpenAITextCompletionClientTests: XCTestCase {
    func testRequestUsesPrivateTextOnlyResponsesConfiguration() throws {
        let client = OpenAITextCompletionClient()
        let config = AIConnectionConfig(
            apiKey: "test-api-key",
            model: "test-model",
            safetyIdentifier: "test-safety-id"
        )

        let request = try client.makeRequest(
            input: "Summarize this note.",
            instructions: "Reply concisely.",
            config: config
        )

        XCTAssertEqual(request.url?.absoluteString, "https://api.openai.com/v1/responses")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-api-key")

        let bodyData = try XCTUnwrap(request.httpBody)
        let body = try XCTUnwrap(
            JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
        )
        XCTAssertEqual(
            Set(body.keys),
            Set([
                "model", "store", "max_output_tokens", "safety_identifier",
                "reasoning", "instructions", "input"
            ])
        )
        XCTAssertEqual(body["model"] as? String, "test-model")
        XCTAssertEqual(body["store"] as? Bool, false)
        XCTAssertEqual(body["max_output_tokens"] as? Int, 800)
        XCTAssertEqual(body["safety_identifier"] as? String, "test-safety-id")
        XCTAssertEqual(body["instructions"] as? String, "Reply concisely.")
        XCTAssertEqual(body["input"] as? String, "Summarize this note.")

        let reasoning = try XCTUnwrap(body["reasoning"] as? [String: Any])
        XCTAssertEqual(reasoning["effort"] as? String, "low")
        XCTAssertNil(body["tools"])
        XCTAssertNil(body["document"])
        XCTAssertNil(body["image"])
    }

    func testDecodeTextSkipsReasoningItemAndReadsMessageOutputText() throws {
        let data = Data(
            """
            {
              "output": [
                {
                  "id": "rs_123",
                  "type": "reasoning",
                  "summary": []
                },
                {
                  "id": "msg_123",
                  "type": "message",
                  "role": "assistant",
                  "content": [
                    {
                      "type": "output_text",
                      "text": "A concise result.",
                      "annotations": []
                    }
                  ]
                }
              ]
            }
            """.utf8
        )

        XCTAssertEqual(
            try OpenAITextCompletionClient.decodeText(data),
            "A concise result."
        )
    }

    func testDecodeTextSurfacesRefusal() throws {
        let data = Data(
            """
            {
              "output": [
                {
                  "type": "message",
                  "content": [
                    {
                      "type": "refusal",
                      "refusal": "I can’t help with that."
                    }
                  ]
                }
              ]
            }
            """.utf8
        )

        XCTAssertThrowsError(try OpenAITextCompletionClient.decodeText(data)) { error in
            XCTAssertEqual(
                error as? OpenAITextCompletionError,
                .refused("I can’t help with that.")
            )
        }
    }

    func testValidateSurfacesHTTPErrorMessage() throws {
        let data = Data(
            """
            {"error":{"message":"Rate limit reached."}}
            """.utf8
        )
        let response = try XCTUnwrap(
            HTTPURLResponse(
                url: URL(string: "https://api.openai.com/v1/responses")!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: nil
            )
        )

        XCTAssertThrowsError(
            try OpenAITextCompletionClient.validate(response: response, data: data)
        ) { error in
            XCTAssertEqual(
                error as? OpenAITextCompletionError,
                .api(statusCode: 429, message: "Rate limit reached.")
            )
        }
    }
}
