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
        XCTAssertEqual(request.timeoutInterval, OpenAIAppGenerationClient.requestTimeout)
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
        XCTAssertTrue(instructions.contains("Expression result types are exact"))
        XCTAssertTrue(instructions.contains("Expressions cannot nest"))
    }

    func testGenerationSessionWaitsForConnectivityAndAllowsLongResponses() {
        let configuration = OpenAIAppGenerationClient.sessionConfiguration()

        XCTAssertTrue(configuration.waitsForConnectivity)
        XCTAssertEqual(
            configuration.timeoutIntervalForRequest,
            OpenAIAppGenerationClient.requestTimeout
        )
        XCTAssertEqual(
            configuration.timeoutIntervalForResource,
            OpenAIAppGenerationClient.resourceTimeout
        )
        XCTAssertGreaterThanOrEqual(OpenAIAppGenerationClient.requestTimeout, 15 * 60)
        XCTAssertGreaterThan(
            OpenAIAppGenerationClient.resourceTimeout,
            OpenAIAppGenerationClient.requestTimeout
        )
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

    func testGenerationContinuouslyRepairsSemanticCandidatesUntilValidationPasses() async throws {
        let invalidResponse = try responseData(for: invalidExpressionPayload())
        let validResponse = try responseData(for: GeneratedAppPayloadTestFixtures.personalMoney())
        let queue = GenerationResponseQueue(responses: [
            invalidResponse,
            invalidResponse,
            validResponse
        ])
        let stages = GenerationStageRecorder()
        let client = OpenAIAppGenerationClient(dataLoader: { request in
            try await queue.load(request)
        })
        let base = SampleDocuments.blank

        let document = try await client.generate(
            prompt: "Build a complex travel dashboard",
            currentDocument: base,
            config: AIConnectionConfig(
                apiKey: "private-test-key",
                model: "gpt-test",
                safetyIdentifier: "test-safety"
            ),
            onStage: { stage in
                await stages.append(stage)
            }
        )

        XCTAssertEqual(document.name, "Personal Money")
        XCTAssertEqual(document.version, base.version + 1)
        let capturedRequests = await queue.capturedRequests()
        let recordedStages = await stages.snapshot()
        XCTAssertEqual(capturedRequests.count, 3)
        XCTAssertEqual(recordedStages, [
            .waitingForResponse,
            .validatingResponse(repairPass: 0),
            .repairingResponse(pass: 1),
            .validatingResponse(repairPass: 1),
            .repairingResponse(pass: 2),
            .validatingResponse(repairPass: 2)
        ])

        let firstRepairBody = try requestBody(capturedRequests[1])
        let secondRepairBody = try requestBody(capturedRequests[2])
        XCTAssertEqual(firstRepairBody["store"] as? Bool, false)
        XCTAssertFalse(String(describing: firstRepairBody).contains("private-test-key"))
        let firstRepairInput = try XCTUnwrap(firstRepairBody["input"] as? String)
        let secondRepairInput = try XCTUnwrap(secondRepairBody["input"] as? String)
        XCTAssertTrue(firstRepairInput.contains("AUTOMATIC REPAIR PASS 1"))
        XCTAssertTrue(firstRepairInput.contains("VALIDATION CODE: invalid_runtime_expression"))
        XCTAssertTrue(firstRepairInput.contains("expectedResultType=text"))
        XCTAssertTrue(firstRepairInput.contains("PREVIOUS COMPLETE CANDIDATE JSON"))
        XCTAssertTrue(secondRepairInput.contains("AUTOMATIC REPAIR PASS 2"))
    }

    func testRefusalDoesNotEnterAutomaticRepairLoop() async throws {
        let refusal = Data(
            """
            {
              "status": "completed",
              "output": [{"content": [{"type": "refusal", "refusal": "Cannot comply."}]}]
            }
            """.utf8
        )
        let queue = GenerationResponseQueue(responses: [refusal])
        let client = OpenAIAppGenerationClient(dataLoader: { request in
            try await queue.load(request)
        })

        do {
            _ = try await client.generate(
                prompt: "Create an app",
                currentDocument: SampleDocuments.blank,
                config: AIConnectionConfig(
                    apiKey: "test-key",
                    model: "gpt-test",
                    safetyIdentifier: "test-safety"
                )
            )
            XCTFail("Expected the refusal to surface without repair.")
        } catch {
            XCTAssertEqual(error as? AppGenerationError, .refused("Cannot comply."))
        }
        let requestCount = await queue.requestCount()
        XCTAssertEqual(requestCount, 1)
    }

    private func invalidExpressionPayload() -> GeneratedAppPayload {
        var payload = GeneratedAppPayloadTestFixtures.personalMoney()
        payload.logic = GeneratedAppPayload.Logic(state: [
            GeneratedAppPayload.StateDefinition(
                key: "trip-total",
                type: "number",
                persistence: "project",
                initialValue: "42"
            ),
            GeneratedAppPayload.StateDefinition(
                key: "trip-summary",
                type: "text",
                persistence: "project",
                initialValue: ""
            )
        ])
        var node = payload.pages[0].nodes[0]
        node.id = "invalid-summary"
        node.kind = "button"
        node.title = "Save summary"
        node.action = GeneratedAppPayload.Action(type: "none", target: "", value: "")
        node.events = [GeneratedAppPayload.Event(
            trigger: "tap",
            steps: [GeneratedAppPayload.Step(
                kind: "setState",
                target: "trip-summary",
                expression: GeneratedAppPayload.Expression(
                    operation: "copy",
                    operands: [GeneratedAppPayload.Operand(source: "state", value: "trip-total")]
                ),
                condition: nil
            )]
        )]
        payload.pages[0].nodes = [node]
        return payload
    }

    private func responseData(for payload: GeneratedAppPayload) throws -> Data {
        let payloadData = try JSONEncoder().encode(payload)
        let output = try XCTUnwrap(String(data: payloadData, encoding: .utf8))
        return try JSONSerialization.data(withJSONObject: [
            "status": "completed",
            "output": [[
                "content": [["type": "output_text", "text": output]]
            ]]
        ])
    }

    private func requestBody(_ request: URLRequest) throws -> [String: Any] {
        let data = try XCTUnwrap(request.httpBody)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}

private actor GenerationResponseQueue {
    private var responses: [Data]
    private var requests: [URLRequest] = []

    init(responses: [Data]) {
        self.responses = responses
    }

    func load(_ request: URLRequest) throws -> (Data, URLResponse) {
        requests.append(request)
        guard let url = request.url,
              !responses.isEmpty,
              let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
              ) else {
            throw GenerationResponseQueueError.missingResponse
        }
        return (responses.removeFirst(), response)
    }

    func capturedRequests() -> [URLRequest] {
        requests
    }

    func requestCount() -> Int {
        requests.count
    }
}

private actor GenerationStageRecorder {
    private var stages: [OpenAIAppGenerationStage] = []

    func append(_ stage: OpenAIAppGenerationStage) {
        stages.append(stage)
    }

    func snapshot() -> [OpenAIAppGenerationStage] {
        stages
    }
}

private enum GenerationResponseQueueError: Error {
    case missingResponse
}
