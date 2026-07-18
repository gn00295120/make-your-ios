import XCTest
@testable import MakeYourIOS

// swiftlint:disable:next type_body_length
final class GeneratedAppPayloadTests: XCTestCase {
    private let styledPayloadJSON = """
    {
      "name": "Field Notes",
      "summary": "A styled photo notebook with AI reflection.",
      "symbol": "book.fill",
      "tint": "plum",
      "theme": {
        "preset": "editorial",
        "appearance": "light",
        "typography": "serif",
        "background": "paper",
        "cornerStyle": "square",
        "density": "airy",
        "defaultSurface": "plain",
        "palette": {
          "primaryHex": "#292524",
          "secondaryHex": "#78716C",
          "accentHex": "#B45309",
          "canvasLightHex": "#FAF8F3",
          "canvasDarkHex": "#1C1917",
          "surfaceLightHex": "#FFFDF8",
          "surfaceDarkHex": "#292524"
        },
        "typeScale": "editorial",
        "titleWeight": "bold",
        "elevation": "flat",
        "stroke": "hairline",
        "controlShape": "angular",
        "motion": "none",
        "backgroundAssetBinding": ""
      },
      "capabilities": ["storage.local"],
      "startPageID": "home",
      "initialState": [],
      "pages": [
        {
          "id": "home",
          "title": "Field Notes",
          "presentation": {
            "layout":"story","showsNavigationTitle":false,"navigationStyle":"chips"
          },
          "nodes": [
            {
              "id": "photo",
              "kind": "image",
              "title": "Today",
              "subtitle": "Choose a photo",
              "symbol": "photo.fill",
              "value": "",
              "placeholder": "",
              "binding": "daily-photo",
              "options": [],
              "items": [],
              "action": {"type":"none","target":"","value":""},
              "presentation": {
                "surface":"plain","span":"full","alignment":"center",
                "emphasis":"strong","variant":"photoOverlay"
              },
              "image": {
                "aspect":"banner","contentMode":"fill","altText":"Daily photo",
                "decorative":false,"allowsUserSelection":true,
                "mediaRole":"hero","focalPoint":"top","mask":"rounded","overlay":"scrim"
              },
              "collection": null,
              "liveData": null,
              "newsFeed": null,
              "marketWatch": null,
              "ledger": null,
              "game": null,
              "deviceInput": null
            },
            {
              "id": "assistant",
              "kind": "aiAssistant",
              "title": "Reflect",
              "subtitle": "Review before sending",
              "symbol": "sparkles",
              "value": "Summarize the user's note and ask one thoughtful question.",
              "placeholder": "Write a note",
              "binding": "note",
              "options": ["Help me reflect"],
              "items": [],
              "action": {"type":"none","target":"","value":"Ask AI"},
              "presentation": {
                "surface":"outlined","span":"full","alignment":"leading",
                "emphasis":"regular","variant":"automatic"
              },
              "image": null,
              "collection": null,
              "liveData": null,
              "newsFeed": null,
              "marketWatch": null,
              "ledger": null,
              "game": null,
              "deviceInput": null
            }
          ]
        }
      ]
    }
    """

    func testPayloadBuildsStyledPhotoAndAIMiniAppWithRequiredCapabilities() throws {
        let data = Data(styledPayloadJSON.utf8)

        let payload = try JSONDecoder().decode(GeneratedAppPayload.self, from: data)
        let document = payload.makeDocument(existingID: UUID(), version: 2)

        XCTAssertEqual(document.resolvedTheme.preset, .editorial)
        XCTAssertEqual(document.resolvedTheme.resolvedPalette.accentHex, "#B45309")
        XCTAssertEqual(document.resolvedTheme.resolvedTypeScale, .editorial)
        XCTAssertEqual(document.pages[0].resolvedPresentation.layout, .story)
        XCTAssertEqual(document.pages[0].resolvedPresentation.resolvedNavigationStyle, .chips)
        XCTAssertEqual(document.pages[0].nodes.map(\.kind), [.image, .aiAssistant])
        XCTAssertEqual(document.pages[0].nodes[0].image?.aspect, .banner)
        XCTAssertEqual(document.pages[0].nodes[0].image?.resolvedMediaRole, .hero)
        XCTAssertEqual(document.pages[0].nodes[0].image?.resolvedOverlay, .scrim)
        XCTAssertTrue(document.capabilities.contains(.photoPicker))
        XCTAssertTrue(document.capabilities.contains(.aiRequests))
        XCTAssertNoThrow(try AppDocumentValidator().validate(document))
    }

    func testPayloadBuildsGeneratedCollectionsLiveDataAndCurrencyRateKeys() throws {
        let payload = GeneratedAppPayloadTestFixtures.personalMoney()

        let document = payload.makeDocument(existingID: UUID(), version: 2)

        XCTAssertEqual(document.pages[0].nodes[0].items.map(\.id), ["USD", "TWD"])
        XCTAssertEqual(document.pages[0].nodes[1].collection?.valueKind, .currency)
        XCTAssertEqual(document.pages[0].nodes[2].liveData?.primaryValue, "USD")
        XCTAssertEqual(document.pages[0].nodes[2].liveData?.initialSymbols, ["TWD", "JPY"])
        XCTAssertTrue(document.capabilities.contains(.safeCalculation))
        XCTAssertTrue(document.capabilities.contains(.localNotifications))
        XCTAssertTrue(document.capabilities.contains(.network))
        XCTAssertNoThrow(try AppDocumentValidator().validate(document))
    }

    func testPayloadCanonicalizesPaletteRendererAndBackgroundBindingBeforeValidation() throws {
        var payload = GeneratedAppPayloadTestFixtures.personalMoney()
        payload.theme.palette.primaryHex = "#abcdef"
        payload.theme.palette.accentHex = "not-a-color"
        payload.theme.backgroundAssetBinding = "Personal-Backdrop"
        payload.pages[0].nodes[0].presentation.variant = "immersive"

        let document = payload.makeDocument(existingID: UUID(), version: 3)

        XCTAssertTrue(document.resolvedTheme.resolvedPalette.isValid)
        XCTAssertEqual(document.resolvedTheme.resolvedPalette.primaryHex, "#ABCDEF")
        XCTAssertEqual(document.resolvedTheme.backgroundAssetBinding, "personal-backdrop")
        XCTAssertEqual(document.pages[0].nodes[0].resolvedPresentation.variant, .automatic)
        XCTAssertTrue(document.capabilities.contains(.photoPicker))
        XCTAssertNoThrow(try AppDocumentValidator().validate(document))
    }

    func testPayloadAllowsEditableImageConfigurationOnHero() throws {
        var payload = GeneratedAppPayloadTestFixtures.personalMoney()
        payload.pages[0].nodes[0].kind = "hero"
        payload.pages[0].nodes[0].binding = "hero-photo"
        payload.pages[0].nodes[0].presentation.variant = "fullBleed"
        payload.pages[0].nodes[0].image?.altText = "Personal hero image"
        payload.pages[0].nodes[0].image?.decorative = false
        payload.pages[0].nodes[0].image?.allowsUserSelection = true
        payload.pages[0].nodes[0].image?.mediaRole = "hero"
        payload.pages[0].nodes[0].image?.mask = "none"
        payload.pages[0].nodes[0].image?.overlay = "scrim"

        let document = payload.makeDocument(existingID: UUID(), version: 4)
        let hero = document.pages[0].nodes[0]

        XCTAssertEqual(hero.kind, .hero)
        XCTAssertEqual(hero.image?.resolvedMediaRole, .hero)
        XCTAssertEqual(hero.resolvedPresentation.variant, .fullBleed)
        XCTAssertTrue(document.capabilities.contains(.photoPicker))
        XCTAssertNoThrow(try AppDocumentValidator().validate(document))
    }

    func testPayloadBuildsTypedLogicEventsAndControl() throws {
        var payload = GeneratedAppPayloadTestFixtures.personalMoney()
        payload.logic = GeneratedAppPayload.Logic(state: [
            GeneratedAppPayload.StateDefinition(
                key: "tip-percent",
                type: "number",
                persistence: "project",
                initialValue: "15"
            )
        ])
        payload.pages[0].nodes[0].kind = "control"
        payload.pages[0].nodes[0].binding = "tip-percent"
        payload.pages[0].nodes[0].valueBinding = "tip-percent"
        payload.pages[0].nodes[0].events = [GeneratedAppPayload.Event(
            trigger: "valueChanged",
            steps: [GeneratedAppPayload.Step(
                kind: "setState",
                target: "tip-percent",
                expression: GeneratedAppPayload.Expression(
                    operation: "copy",
                    operands: [GeneratedAppPayload.Operand(source: "state", value: "tip-percent")]
                ),
                condition: nil
            )]
        )]
        payload.pages[0].nodes[0].control = GeneratedAppPayload.Control(
            kind: "slider",
            minimum: 0,
            maximum: 30,
            step: 1,
            unit: "%"
        )

        let document = payload.makeDocument(existingID: UUID(), version: 5)
        let node = document.pages[0].nodes[0]

        XCTAssertEqual(document.logic?.state.first?.type, .number)
        XCTAssertEqual(document.logic?.state.first?.persistence, .project)
        XCTAssertEqual(node.kind, .control)
        XCTAssertEqual(node.valueBinding, "tip-percent")
        XCTAssertEqual(node.events?.first?.steps.first?.kind, .setState)
        XCTAssertEqual(node.control?.kind, .slider)
        XCTAssertNoThrow(try AppDocumentValidator().validate(document))
    }

    func testPayloadBuildsNativeMapCalendarAndExportComponents() throws {
        var payload = GeneratedAppPayloadTestFixtures.personalMoney()
        var mapNode = payload.pages[0].nodes[0]
        mapNode.id = "trip-map"
        mapNode.kind = "map"
        mapNode.map = GeneratedAppPayload.Map(
            mode: "placeSearch",
            query: "Taipei Main Station",
            latitude: 25.0478,
            longitude: 121.517,
            spanMeters: 4_000,
            allowsSearch: true,
            allowsDirections: true
        )

        var calendarNode = payload.pages[0].nodes[0]
        calendarNode.id = "trip-calendar"
        calendarNode.kind = "calendarEvent"
        calendarNode.calendarEvent = GeneratedAppPayload.CalendarEvent(
            eventTitle: "Leave for {{trip-name}}",
            notes: "Bring tickets",
            location: "Taipei Main Station",
            startOffsetMinutes: 60,
            durationMinutes: 45,
            allowsEditing: true
        )

        var exportNode = payload.pages[0].nodes[0]
        exportNode.id = "trip-export"
        exportNode.kind = "documentExport"
        exportNode.documentExport = GeneratedAppPayload.DocumentExport(
            fileName: "trip-plan",
            format: "plainText",
            contentTemplate: "Trip: {{trip-name}}",
            buttonLabel: "Export plan"
        )
        payload.pages[0].nodes = [mapNode, calendarNode, exportNode]

        let document = payload.makeDocument(existingID: UUID(), version: 6)

        XCTAssertEqual(document.pages[0].nodes.map(\.kind), [
            .map, .calendarEvent, .documentExport
        ])
        XCTAssertEqual(document.pages[0].nodes[0].map?.query, "Taipei Main Station")
        XCTAssertEqual(document.pages[0].nodes[1].calendarEvent?.durationMinutes, 45)
        XCTAssertEqual(document.pages[0].nodes[2].documentExport?.format, .plainText)
        XCTAssertTrue(document.capabilities.contains(.mapSearch))
        XCTAssertTrue(document.capabilities.contains(.calendarWrite))
        XCTAssertTrue(document.capabilities.contains(.documentExport))
        XCTAssertNoThrow(try AppDocumentValidator().validate(document))
    }

    func testPayloadBuildsBoundedLocalVoiceNote() throws {
        var payload = GeneratedAppPayloadTestFixtures.personalMoney()
        var voiceNode = payload.pages[0].nodes[0]
        voiceNode.id = "daily-voice"
        voiceNode.kind = "voiceNote"
        voiceNode.title = "Daily thought"
        voiceNode.binding = "daily-thought"
        voiceNode.voiceNote = GeneratedAppPayload.VoiceNote(
            maximumDurationSeconds: 120,
            recordButtonLabel: "Record my thought"
        )
        payload.pages[0].nodes = [voiceNode]

        let document = payload.makeDocument(existingID: UUID(), version: 7)
        let node = document.pages[0].nodes[0]

        XCTAssertEqual(node.kind, .voiceNote)
        XCTAssertEqual(node.voiceNote?.maximumDurationSeconds, 60)
        XCTAssertEqual(node.voiceNote?.recordButtonLabel, "Record my thought")
        XCTAssertEqual(
            Set(document.capabilities),
            Set([.localStorage, .microphoneRecordLocal])
        )
        XCTAssertNoThrow(try AppDocumentValidator().validate(document))
    }

    func testPayloadBuildsAValidatedCustomTinyGameProgram() throws {
        var payload = GeneratedAppPayloadTestFixtures.personalMoney()
        var node = payload.pages[0].nodes[0]
        node.id = "generated-game"
        node.kind = "game"
        node.title = "Generated Star Garden"
        node.game = GeneratedAppPayload.Game(
            kind: "custom",
            difficulty: "standard",
            palette: "neon",
            targetScore: 5,
            levelSeed: 2_026,
            playerName: "Glider",
            collectibleName: "Star",
            haptics: true,
            program: SampleDocuments.starGardenProgram
        )
        payload.pages[0].nodes = [node]

        let document = payload.makeDocument(existingID: UUID(), version: 6)
        let game = try XCTUnwrap(document.pages[0].nodes[0].game)

        XCTAssertEqual(game.kind, .custom)
        XCTAssertEqual(game.program, SampleDocuments.starGardenProgram)
        XCTAssertNoThrow(try TinyGameCompiler().compile(try XCTUnwrap(game.program)))
        XCTAssertNoThrow(try AppDocumentValidator().validate(document))
    }

    func testSchemaShapedCustomGameJSONDecodesThroughTheFullPayloadBoundary() throws {
        var root = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(styledPayloadJSON.utf8)) as? [String: Any]
        )
        var pages = try XCTUnwrap(root["pages"] as? [[String: Any]])
        var nodes = try XCTUnwrap(pages[0]["nodes"] as? [[String: Any]])
        var gameNode = nodes[0]
        root["logic"] = NSNull()
        gameNode["valueBinding"] = ""
        gameNode["events"] = []
        gameNode["control"] = NSNull()
        gameNode["image"] = NSNull()
        let programData = try JSONEncoder().encode(SampleDocuments.starGardenProgram)
        let program = try XCTUnwrap(
            JSONSerialization.jsonObject(with: programData) as? [String: Any]
        )
        gameNode["kind"] = "game"
        gameNode["game"] = [
            "kind": "custom",
            "difficulty": "standard",
            "palette": "neon",
            "targetScore": 5,
            "levelSeed": 2_026,
            "playerName": "Glider",
            "collectibleName": "Star",
            "haptics": true,
            "program": program
        ]
        nodes = [gameNode]
        pages[0]["nodes"] = nodes
        root["pages"] = pages

        let payloadData = try JSONSerialization.data(withJSONObject: root)
        let payload = try JSONDecoder().decode(GeneratedAppPayload.self, from: payloadData)
        let document = payload.makeDocument(existingID: UUID(), version: 7)

        XCTAssertEqual(document.pages[0].nodes[0].game?.program, SampleDocuments.starGardenProgram)
        XCTAssertNoThrow(try AppDocumentValidator().validate(document))
    }
}
