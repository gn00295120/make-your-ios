import XCTest
@testable import MakeYourIOS

final class GeneratedShortcutAccessPayloadTests: XCTestCase {
    func testGeneratedMarkerIsSanitizedAndCapabilityIsHostDerived() throws {
        var payload = GeneratedAppPayloadTestFixtures.personalMoney()
        payload.capabilities = ["ai.complete", "http.request"]
        payload.pages[0].nodes = [maliciousNode()]

        let document = payload.makeDocument(existingID: UUID(), version: 2)
        let marker = try XCTUnwrap(document.pages.first?.nodes.first)

        XCTAssertEqual(marker.kind, .shortcutAccess)
        XCTAssertEqual(marker.value, "")
        XCTAssertEqual(marker.placeholder, "")
        XCTAssertEqual(marker.binding, "")
        XCTAssertEqual(marker.options, [])
        XCTAssertEqual(marker.items, [])
        XCTAssertEqual(marker.action, .none)
        XCTAssertNil(marker.valueBinding)
        XCTAssertEqual(marker.events, [])
        XCTAssertEqual(marker.resolvedPresentation.span, .full)
        XCTAssertEqual(
            Set(document.capabilities),
            [.localStorage, .shortcutsOpenTinyApp]
        )
        XCTAssertNoThrow(try AppDocumentValidator().validate(document))
    }

    private func maliciousNode() -> GeneratedAppPayload.Node {
        GeneratedAppPayload.Node(
            id: "shortcut-access",
            kind: "shortcutAccess",
            title: "Open my app",
            subtitle: "Use Shortcuts",
            symbol: "bolt.fill",
            value: "secret state",
            placeholder: "hidden input",
            binding: "unsafe-binding",
            options: ["Run"],
            items: [GeneratedAppPayload.Item(
                id: "item",
                title: "Hidden",
                subtitle: "",
                value: "value",
                symbol: "circle.fill",
                isComplete: false
            )],
            action: GeneratedAppPayload.Action(
                type: "navigate",
                target: "somewhere",
                value: "run"
            ),
            valueBinding: "shared-state",
            events: [GeneratedAppPayload.Event(trigger: "appear", steps: [])],
            control: nil,
            presentation: GeneratedAppPayload.NodeDesign(
                surface: "material",
                span: "half",
                alignment: "leading",
                emphasis: "regular",
                variant: "cards"
            ),
            image: nil,
            collection: nil,
            liveData: nil,
            newsFeed: nil,
            marketWatch: nil,
            ledger: nil,
            game: nil,
            deviceInput: nil
        )
    }
}
