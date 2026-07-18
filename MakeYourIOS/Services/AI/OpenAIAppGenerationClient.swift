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

    func makeRequest(
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
            "max_output_tokens": 25_000,
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

    static func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppGenerationError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw Self.apiError(from: data, statusCode: httpResponse.statusCode)
        }
    }

    static func decodeDocument(
        _ data: Data,
        replacing currentDocument: AppDocument
    ) throws -> AppDocument {
        let apiResponse = try JSONDecoder().decode(ResponsesAPIResponse.self, from: data)
        if apiResponse.status == "incomplete" {
            throw AppGenerationError.incomplete(apiResponse.incompleteDetails?.reason ?? "unknown")
        }
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
    Preserve stable page, node, item, and binding IDs when editing existing behavior. Use concise kebab-case
    IDs for new elements. For each specialized node, fill only its matching configuration object and return
    null for image, collection, liveData, newsFeed, marketWatch, ledger, game, and deviceInput when unrelated.
    List only capabilities actually used; the host independently derives and enforces the exact capability set.
    Keep the experience focused: one to three pages and no more than twelve components per page.
    Use concise, friendly interface copy and semantic iOS patterns.
    Make an intentional visual system. Choose a semantic brand palette, type scale, title weight,
    elevation, stroke, control shape, motion level, page navigation, layout, spans, surfaces,
    alignment, and renderer variants that fit the user's taste. Do not put every component in a card.
    Palette values must be #RRGGBB. Treat primary as brand identity, secondary as supporting content,
    accent as interactive emphasis, canvas as the page base, and surface as component material.
    The host computes readable foreground colors and may increase contrast; never encode text colors.
    When the request is design-only, preserve all pages, component behavior, capabilities, state bindings,
    actions, data configuration, and IDs. Change only theme, page presentation, node presentation, and
    image presentation metadata. Never remove working behavior merely to achieve a visual style.
    Use half-width spans only for text, metric, infoBanner, and image nodes.
    Use image nodes, or an optional hero image, as private media slots. Choose a semantic media role,
    focal point, mask, and overlay. Set a meaningful kebab-case binding and alt text. A theme background
    may reference a local backgroundAssetBinding; use an empty string when no selectable background is
    intended. Bindings are logical local slots, not files. Never invent an asset ID, file path, URL,
    uploaded image, or claim that an image already exists. The user chooses every private image in the host.
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
    Use newsFeed for a live news collector or reading dashboard. Choose only the built-in source IDs,
    provide focused topic filters, and enable bookmarks or topic editing when useful. The host fetches,
    credits, caches, filters, and opens the original articles; never invent feed URLs. Declare http.request.
    Use marketWatch for stock or ETF watchlists. Configure symbols, chart range, and editing; the host uses
    the fixed Twelve Data adapter, secure local provider credentials, caching, and charts. AAPL supports the
    provider's public demo mode; other symbols may ask the user for their own Twelve Data key at runtime.
    Describe quotes as latest or delayed and never as guaranteed real-time or suitable for trading.
    Use ledger for real income and expense tracking rather than a generic collection. Choose a currency,
    useful categories, period, optional monthly budget, and realistic typed seed entries with positive amounts
    and YYYY-MM-DD dates. The host computes income, spending, balance, budget progress, and category totals.
    Use game for a complete playable snake or platformer experience. Select a bounded difficulty, palette,
    score goal, deterministic level seed, player label, and collectible label. The host owns controls, physics,
    collision, scoring, restart, pause, high scores, and haptics. Never request copyrighted characters, names,
    levels, sounds, or artwork; translate requests like Mario into an original platform adventure.
    Use deviceInput for host-owned iPhone abilities: cameraPhoto, qrCode, barcode, text scanning,
    currentLocation, contact selection, documentText import, pedometer, shareText, copyText, or haptic.
    Give it a stable binding and clear button/result labels. For shareText and copyText, put the bounded text
    payload in node.value. The host owns permission prompts, hardware checks, native pickers, result limits,
    and local persistence. Declare only the matching capability; never imply background access, silent sharing,
    full address-book browsing, arbitrary file access, or continuous location/motion tracking.
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
    struct IncompleteDetails: Decodable {
        var reason: String
    }

    struct Output: Decodable {
        var content: [Content]?
    }

    struct Content: Decodable {
        var type: String
        var text: String?
        var refusal: String?
    }

    var status: String?
    var incompleteDetails: IncompleteDetails?
    var output: [Output]

    enum CodingKeys: String, CodingKey {
        case status
        case incompleteDetails = "incomplete_details"
        case output
    }
}

private struct APIErrorEnvelope: Decodable {
    struct Body: Decodable { var message: String }
    var error: Body
}

enum AppGenerationError: LocalizedError, Equatable {
    case invalidResponse
    case invalidDocumentEncoding
    case missingOutput
    case refused(String)
    case incomplete(String)
    case api(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "OpenAI returned an invalid response."
        case .invalidDocumentEncoding: "The current app could not be encoded for generation."
        case .missingOutput: "The model did not return an app document."
        case .refused(let reason): reason
        case .incomplete(let reason):
            "OpenAI stopped before the app document was complete (\(reason)). Try again."
        case .api(let statusCode, let message): "OpenAI error \(statusCode): \(message)"
        }
    }
}
