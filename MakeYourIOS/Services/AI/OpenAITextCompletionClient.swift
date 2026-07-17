import Foundation

struct OpenAITextCompletionClient: Sendable {
    private let endpoint = URL(string: "https://api.openai.com/v1/responses")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func complete(
        input: String,
        instructions: String,
        config: AIConnectionConfig
    ) async throws -> String {
        let request = try makeRequest(
            input: input,
            instructions: instructions,
            config: config
        )
        let (data, response) = try await session.data(for: request)
        try Self.validate(response: response, data: data)
        return try Self.decodeText(data)
    }

    func makeRequest(
        input: String,
        instructions: String,
        config: AIConnectionConfig
    ) throws -> URLRequest {
        let body: [String: Any] = [
            "model": config.model,
            "store": false,
            "max_output_tokens": 800,
            "safety_identifier": config.safetyIdentifier,
            "reasoning": ["effort": "low"],
            "instructions": instructions,
            "input": input
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 90
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    static func decodeText(_ data: Data) throws -> String {
        let response = try JSONDecoder().decode(TextResponse.self, from: data)
        let content = response.output.flatMap { item in
            item.content ?? []
        }

        if let refusal = content
            .compactMap(\.refusal)
            .first {
            throw OpenAITextCompletionError.refused(refusal)
        }

        let outputText = content
            .filter { $0.type == "output_text" }
            .compactMap(\.text)
            .joined(separator: "\n")

        guard !outputText.isEmpty else {
            throw OpenAITextCompletionError.missingOutput
        }
        return outputText
    }

    static func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAITextCompletionError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw apiError(from: data, statusCode: httpResponse.statusCode)
        }
    }

    private static func apiError(from data: Data, statusCode: Int) -> OpenAITextCompletionError {
        if let envelope = try? JSONDecoder().decode(TextAPIErrorEnvelope.self, from: data) {
            return .api(statusCode: statusCode, message: envelope.error.message)
        }
        return .api(statusCode: statusCode, message: "The provider returned an error.")
    }
}

private struct TextResponse: Decodable {
    struct OutputItem: Decodable {
        var type: String
        var content: [Content]?
    }

    struct Content: Decodable {
        var type: String
        var text: String?
        var refusal: String?
    }

    var output: [OutputItem]
}

private struct TextAPIErrorEnvelope: Decodable {
    struct Body: Decodable {
        var message: String
    }

    var error: Body
}

enum OpenAITextCompletionError: LocalizedError, Equatable {
    case invalidResponse
    case missingOutput
    case refused(String)
    case api(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "OpenAI returned an invalid response."
        case .missingOutput:
            "OpenAI did not return any text."
        case .refused(let reason):
            reason
        case .api(let statusCode, let message):
            "OpenAI error \(statusCode): \(message)"
        }
    }
}
