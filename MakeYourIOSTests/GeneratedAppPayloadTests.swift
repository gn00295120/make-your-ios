import XCTest
@testable import MakeYourIOS

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
        "defaultSurface": "plain"
      },
      "capabilities": ["storage.local"],
      "startPageID": "home",
      "initialState": [],
      "pages": [
        {
          "id": "home",
          "title": "Field Notes",
          "presentation": {"layout":"story","showsNavigationTitle":false},
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
                "decorative":false,"allowsUserSelection":true
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
        XCTAssertEqual(document.pages[0].resolvedPresentation.layout, .story)
        XCTAssertEqual(document.pages[0].nodes.map(\.kind), [.image, .aiAssistant])
        XCTAssertEqual(document.pages[0].nodes[0].image?.aspect, .banner)
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
}
