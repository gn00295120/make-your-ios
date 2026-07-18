import Foundation

// swiftlint:disable:next type_body_length
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
    null for control, image, collection, liveData, newsFeed, marketWatch, ledger, game, deviceInput, map,
    calendarEvent, documentExport, and voiceNote when unrelated. Return an empty valueBinding and events array when a
    node has no dynamic behavior.
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
    Use half-width spans only for text, metric, infoBanner, image, control, collectionView, calendarEvent,
    documentExport, voiceNote, and button nodes.
    Use image nodes, or an optional hero image, as private media slots. Choose a semantic media role,
    focal point, mask, and overlay. Set a meaningful kebab-case binding and alt text. A theme background
    may reference a local backgroundAssetBinding; use an empty string when no selectable background is
    intended. Bindings are logical local slots, not files. Never invent an asset ID, file path, URL,
    uploaded image, or claim that an image already exists. The user chooses every private image in the host.
    If the user asks for an AI feature, use aiAssistant and declare ai.complete. Put its focused task
    instruction in value, input hint in placeholder, quick prompts in options, and button label in action.value.
    AI components may only transform text that the user explicitly reviews and sends. Give the AI node a
    binding when its result should become shared state for another component or a valueChanged event.
    Use logic for safe cross-component state and calculations. Declare at most 64 state entries with unique
    kebab-case keys, an explicit text, number, boolean, date, list, or object type, session or project
    persistence, and a valid initialValue. Number initial values must be finite numeric strings; boolean values
    are true or false; dates are ISO-8601 timestamps; lists are bounded JSON arrays of strings; objects are
    bounded flat JSON dictionaries with string keys and values. Lists and objects do not contain nested records.
    Bind textInput, numberInput, picker, and control nodes through binding. Use valueBinding when a text,
    metric, infoBanner, or button should display a state value. Several output views and controls may share a key.
    Use control for generated toggle, slider, stepper, progress, datePicker, timePicker, and dateTimePicker
    primitives. A toggle binds boolean state; slider, stepper, and progress bind number state; date controls
    bind date state. Choose finite minimum and maximum values with minimum less than maximum, a positive step no
    larger than that range, and an optional short unit. For a toggle or date control, use minimum 0, maximum 1,
    and step 1. Use collectionView to render a list or object state; use recordCollection instead when the user
    needs rich editable records with title, note, amount, date, completion, or reminders.
    Events are bounded declarative behavior, never code. Use tap for buttons, valueChanged for input or control
    bindings, appear for a one-time visible-page action, and timer only for foreground automation. Timer uses an
    intervalSeconds from 1 through 3600; every other trigger uses zero. Use each trigger at most once per node.
    Timers pause outside the active foreground and never catch up in the background. A node may have at most
    four events and an event at most eight ordered steps. Set the legacy action to none when events implement
    the behavior so it does not run twice.
    A setState step targets a declared state key and evaluates its expression. A navigate step targets a page
    ID. A showMessage step uses its expression as the message. A scheduleNotification step puts delay minutes
    in target and the reviewed message in its expression. A playHaptic step requests one host-defined haptic.
    Expressions are flat and contain at most eight literal, state, or currentDate operands. currentDate ignores
    its value field. Use literal or copy for direct values; add, subtract, multiply, divide, min, and max only
    with number operands; use concatenate for text. Use listAppend/listRemove/listCount/listContains/listJoin
    only with a list state. Use objectSet/objectRemove/objectGet/objectCount only with a flat object state. Use
    dateAddDays with a date and integer day count, and dateDaysBetween with two dates.
    Never divide by a literal zero. Optional conditions compare two operands with equals, notEquals, less,
    lessOrEqual, greater, greaterOrEqual, isEmpty, or isNotEmpty. Ordered comparisons require numbers.
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
    Use game for a complete playable experience. Snake and platformer are polished presets and require a null
    program. For an original game, set kind to custom and provide Tiny Game Program version 3. The bounded
    program contains a 240...4096 point world, integer variables, visual entity templates, initial spawns,
    touch controls, contact-begin/timer/leave-world rules, ordered effects, and HUD items. V3 supports top-down
    games plus original platform games with deterministic solid and one-way platforms, grounded jumps, and
    facing projectiles. Keep to 32 variables,
    24 templates, 128 initial entities, 6 controls, 64 rules, 4 conditions and 6 effects per rule, and 8 HUD
    items, at most 4 spawn effects and 256 total effects in any one tick. Use only rectangle, circle, or
    allowed SF Symbol visuals; no external assets. Give every object a
    unique kebab-case ID. Use playerAxis only on kinematic/dynamic entities with positive speed, platformerAxis
    only on a dynamic solid entity, and constant movement only with a non-zero velocity. Every template fits
    inside the world and every initial spawn center keeps its full entity in bounds. In V3 every body except
    none requires an explicit physics block; body none requires null physics. Set collisionMode to sensor,
    solid, or oneWayPlatform, maximum velocities from 0 to 128, and lifetimeTicks; static physics uses zero
    velocity limits, movable physics uses positive limits, and solid/one-way entities have zero lifetime.
    The bounded platform collision slice supports one initially spawned dynamic solid player against static
    solid and one-way platforms; do not create dynamic-solid enemies or multiple solid players. Movement
    controls target an initially spawned
    playerAxis entity, or use horizontal for platformerAxis. A V3 jump action targets a grounded platformer,
    uses a positive impulse and cooldown, and has empty spawnTemplateID. A projectile action targets an initial
    anchor, spawns a sensor projectile with a positive lifetime, mirrors horizontal velocity and offsetX to the
    anchor's facing, and declares cooldownTicks and maximumActive. Runtime spawning of solid or one-way
    templates is forbidden. Collision tags and all variable or
    template references must exist. Every schema field is required: use empty strings, zero, target subject,
    and feedback none for fields unused by that trigger or effect. Start uses empty tags/everyTicks zero; timer
    uses only everyTicks; collision uses both tags; leaveWorld uses only subjectTag. Spawn x/y are offsets from
    its target and value is seeded horizontal jitter. Put collect/add/destroy rules before a conditional win
    rule because later rules read earlier variable writes for the same contact. Use deterministic seed-based
    rules for scoring, lives, spawning, feedback, and win/loss. The host owns fixed-step execution, safety
    budgets, controls, collision, pause, and restart. Never request copyrighted characters, names, levels,
    sounds, or artwork; translate requests like Mario into an original rule-driven adventure.
    Use deviceInput for host-owned iPhone abilities: cameraPhoto, qrCode, barcode, text scanning,
    currentLocation, contact selection, documentText import, pedometer, shareText, copyText, or haptic.
    Give it a stable binding and clear button/result labels. For shareText and copyText, put the bounded text
    payload in node.value. The host owns permission prompts, hardware checks, native pickers, result limits,
    and local persistence. Declare only the matching capability; never imply background access, silent sharing,
    full address-book browsing, arbitrary file access, or continuous location/motion tracking.
    Use map for a native MapKit location card. coordinate mode uses validated latitude/longitude; placeSearch
    mode requires a focused Apple Maps query. allowsSearch exposes visible user-entered search and
    allowsDirections hands the selected result to Apple Maps after a tap. It does not read the user's current
    location or contact arbitrary map providers. Declare maps.search.
    Use calendarEvent to prepare one event from eventTitle, notes, location, a start offset in minutes, and a
    5...1440 minute duration. Templates such as {{task-name}} may reference simple state. The host always shows a
    review page and requests write-only EventKit access at use time; it never lists, edits, or deletes existing
    events. Declare calendar.createEvent.
    Use documentExport for bounded plainText, json, or csv content. contentTemplate may reference state; a
    direct list or object placeholder emits its bounded canonical JSON into this reviewed export only.
    The host displays a preview, validates JSON, normalizes the file name and extension, and opens Apple's save
    panel only after a tap. It cannot silently choose or overwrite a destination. Declare files.export.
    Use voiceNote for one user-controlled local recording slot. Give it a stable binding, a 5...60 second
    maximumDurationSeconds, and a clear recordButtonLabel. The host always exposes playback and deletion,
    records only in the visible foreground after a tap, stores one bounded AAC clip in that tiny app's sandbox,
    stops at the configured limit or when the app leaves the foreground, and never uploads or transcribes the
    audio. Declare microphone.recordLocal.
    For taskList and checklist, seed realistic example items that the user can replace. Their specialized
    internal records are not exposed as logic state, so do not claim that a metric derives from their contents.
    For a standalone legacy scheduleNotification button without events, action.target is delay minutes and
    action.value is the message.
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
