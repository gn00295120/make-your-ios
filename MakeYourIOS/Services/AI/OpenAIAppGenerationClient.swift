import Foundation

struct OpenAIAppGenerationClient: Sendable {
    private let endpoint = URL(string: "https://api.openai.com/v1/responses")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func generate(
        prompt: String,
        currentDocument: AppDocument,
        config: AIConnectionConfig
    ) async throws -> AppDocument {
        let request = try makeRequest(
            prompt: prompt,
            currentDocument: currentDocument,
            config: config
        )
        let (data, response) = try await session.data(for: request)
        try Self.validate(response: response, data: data)
        return try Self.decodeDocument(data, replacing: currentDocument)
    }

    private func makeRequest(
        prompt: String,
        currentDocument: AppDocument,
        config: AIConnectionConfig
    ) throws -> URLRequest {
        let currentJSON = try Self.encodedDocument(currentDocument)
        let input = """
        USER REQUEST:
        \(prompt)

        CURRENT APP DOCUMENT:
        \(currentJSON)

        Return a complete replacement document. Preserve what already works unless the user asks to change it.
        """

        let body: [String: Any] = [
            "model": config.model,
            "store": false,
            "max_output_tokens": 8_000,
            "safety_identifier": config.safetyIdentifier,
            "reasoning": ["effort": "low"],
            "instructions": Self.instructions,
            "input": input,
            "text": [
                "format": [
                    "type": "json_schema",
                    "name": "make_your_app",
                    "strict": true,
                    "schema": Self.responseSchema
                ]
            ]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 90
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private static func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppGenerationError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw Self.apiError(from: data, statusCode: httpResponse.statusCode)
        }
    }

    private static func decodeDocument(
        _ data: Data,
        replacing currentDocument: AppDocument
    ) throws -> AppDocument {
        let apiResponse = try JSONDecoder().decode(ResponsesAPIResponse.self, from: data)
        if let refusal = apiResponse.output
            .compactMap(\.content)
            .flatMap({ $0 })
            .compactMap(\.refusal)
            .first {
            throw AppGenerationError.refused(refusal)
        }

        guard let text = apiResponse.output
            .compactMap(\.content)
            .flatMap({ $0 })
            .first(where: { $0.type == "output_text" })?
            .text,
              let payloadData = text.data(using: .utf8) else {
            throw AppGenerationError.missingOutput
        }

        let payload = try JSONDecoder().decode(GeneratedAppPayload.self, from: payloadData)
        let document = payload.makeDocument(
            existingID: currentDocument.id,
            version: currentDocument.version + 1
        )
        try AppDocumentValidator().validate(document)
        return document
    }

    private static let instructions = """
    You are the product designer for MakeYour, a native iOS personal mini-app runtime.
    Convert the user's request into a coherent, immediately usable app document.
    You may only use the component kinds and capabilities allowed by the response schema.
    Never emit code, scripts, URLs, secrets, custom APIs, or unsupported SF Symbols.
    Keep the experience focused: one to three pages and no more than twelve components per page.
    Use concise, friendly interface copy and semantic iOS patterns.
    Make an intentional visual system. Choose a theme, page layout, spans, surfaces, alignment,
    and variants that fit the user's taste. Do not put every component in a card.
    Use half-width spans only for text, metric, infoBanner, and image nodes.
    Use image nodes as private photo slots. Set a meaningful binding and alt text; never invent an asset ID.
    If the user asks for an AI feature, use aiAssistant and declare ai.complete. Put its focused task
    instruction in value, input hint in placeholder, quick prompts in options, and button label in action.value.
    AI components may only transform text that the user explicitly reviews and sends.
    For currencyConverter, provide currency codes in options and item values as numeric rates relative to USD.
    Use recordCollection for any user-editable, persistent set of personal records such as expenses,
    subscriptions, pantry items, inventory, reading logs, medications, or contacts. Configure its typed
    title, note, number/currency, date, aggregate, completion, and reminder fields. Its aggregate is computed
    by the runtime, so do not add a separate metric that claims to mirror the collection.
    Use liveDataList with the exchangeRates resource for a latest-rate watchlist. Put the ISO base currency
    in primaryValue and initial quote currency codes in initialSymbols. The host supplies the provider,
    currency catalog, refresh, cache, editable rows, per-row above/below thresholds, and Test Alert; never
    put rates, URLs, API keys, or provider instructions in the document. Declare http.request.
    Exchange rates are latest daily reference data, not streaming market quotes. Describe them as latest,
    not real-time, tick-by-tick, guaranteed, or suitable for trading.
    For taskList and checklist, seed realistic example items that the user can replace.
    Do not create a metric that claims to live-update from a taskList; cross-component computed bindings
    are not supported yet. Use taskList state itself instead.
    For a standalone scheduleNotification button, action.target is delay minutes and action.value is the message.
    If the request cannot be represented safely, make a useful local-only approximation.
    Explain the limitation in an infoBanner.
    Generated apps are private documents inside one host app, never standalone iOS binaries.
    """

    private static func encodedDocument(_ document: AppDocument) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(document)
        guard let json = String(bytes: data, encoding: .utf8) else {
            throw AppGenerationError.invalidDocumentEncoding
        }
        return json
    }

    private static func apiError(from data: Data, statusCode: Int) -> AppGenerationError {
        if let envelope = try? JSONDecoder().decode(APIErrorEnvelope.self, from: data) {
            return .api(statusCode: statusCode, message: envelope.error.message)
        }
        return .api(statusCode: statusCode, message: "The provider returned an error.")
    }
}

private struct ResponsesAPIResponse: Decodable {
    struct Output: Decodable {
        var content: [Content]?
    }

    struct Content: Decodable {
        var type: String
        var text: String?
        var refusal: String?
    }

    var output: [Output]
}

private struct APIErrorEnvelope: Decodable {
    struct Body: Decodable { var message: String }
    var error: Body
}

enum AppGenerationError: LocalizedError {
    case invalidResponse
    case invalidDocumentEncoding
    case missingOutput
    case refused(String)
    case api(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "OpenAI returned an invalid response."
        case .invalidDocumentEncoding: "The current app could not be encoded for generation."
        case .missingOutput: "The model did not return an app document."
        case .refused(let reason): reason
        case .api(let statusCode, let message): "OpenAI error \(statusCode): \(message)"
        }
    }
}
