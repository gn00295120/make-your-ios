import XCTest
@testable import MakeYourIOS

final class GeneratedCapabilityPayloadTests: XCTestCase {
    func testPayloadBuildsNewsMarketAndLedgerApps() throws {
        let nodes = [newsNode, marketNode, ledgerNode]
        let document = payload(nodes: nodes).makeDocument(existingID: UUID(), version: 2)

        XCTAssertEqual(document.pages[0].nodes.map(\.id), ["news-feed", "market-watch", "ledger"])
        XCTAssertEqual(document.pages[0].nodes[0].newsFeed?.sources, [.bbcWorld, .nprNews])
        XCTAssertEqual(document.pages[0].nodes[1].marketWatch?.initialSymbols, ["AAPL", "MSFT"])
        XCTAssertEqual(document.pages[0].nodes[2].ledger?.initialEntries.first?.type, .expense)
        XCTAssertEqual(Set(document.capabilities), [.localStorage, .network])
        XCTAssertNoThrow(try AppDocumentValidator().validate(document))
    }

    func testPayloadBuildsBothPlayableGameTemplates() throws {
        let document = payload(nodes: [snakeNode, platformerNode])
            .makeDocument(existingID: UUID(), version: 2)

        XCTAssertEqual(document.pages[0].nodes.map(\.game?.kind), [.snake, .platformer])
        XCTAssertEqual(document.pages[0].nodes[1].game?.levelSeed, 99)
        XCTAssertEqual(Set(document.capabilities), [.haptics, .localStorage])
        XCTAssertNoThrow(try AppDocumentValidator().validate(document))
    }

    func testPayloadBuildsPhotoAndScannerWithExactHostDerivedCapabilities() throws {
        let document = payload(nodes: [cameraNode, scannerNode], declaredCapabilities: [
            "http.request", "ai.complete"
        ]).makeDocument(existingID: UUID(), version: 2)

        XCTAssertEqual(document.pages[0].nodes.map(\.deviceInput?.kind), [.cameraPhoto, .qrCode])
        XCTAssertEqual(
            Set(document.capabilities),
            [.cameraCapture, .codeScanner, .localStorage]
        )
        XCTAssertFalse(document.capabilities.contains(.network))
        XCTAssertFalse(document.capabilities.contains(.aiRequests))
        XCTAssertNoThrow(try AppDocumentValidator().validate(document))
    }

    private func payload(
        nodes: [GeneratedAppPayload.Node],
        declaredCapabilities: [String] = []
    ) -> GeneratedAppPayload {
        GeneratedAppPayload(
            name: "Generated capabilities",
            summary: "A strict generated fixture",
            symbol: "sparkles",
            tint: "sky",
            theme: GeneratedAppPayload.Theme(
                preset: "native",
                appearance: "system",
                typography: "system",
                background: "grouped",
                cornerStyle: "soft",
                density: "regular",
                defaultSurface: "card",
                palette: GeneratedAppPayload.Palette(
                    primaryHex: "#5450EF",
                    secondaryHex: "#667085",
                    accentHex: "#0A84FF",
                    canvasLightHex: "#F2F2F7",
                    canvasDarkHex: "#000000",
                    surfaceLightHex: "#FFFFFF",
                    surfaceDarkHex: "#1C1C1E"
                ),
                typeScale: "balanced",
                titleWeight: "bold",
                elevation: "subtle",
                stroke: "hairline",
                controlShape: "native",
                motion: "subtle",
                backgroundAssetBinding: ""
            ),
            capabilities: declaredCapabilities,
            startPageID: "home",
            initialState: [],
            pages: [
                GeneratedAppPayload.Page(
                    id: "home",
                    title: "Home",
                    nodes: nodes,
                    presentation: GeneratedAppPayload.PageDesign(
                        layout: "flow",
                        showsNavigationTitle: true,
                        navigationStyle: "automatic"
                    )
                )
            ]
        )
    }

    private func node(
        id: String,
        kind: String,
        newsFeed: GeneratedAppPayload.NewsFeed? = nil,
        marketWatch: GeneratedAppPayload.MarketWatch? = nil,
        ledger: GeneratedAppPayload.Ledger? = nil,
        game: GeneratedAppPayload.Game? = nil,
        deviceInput: GeneratedAppPayload.DeviceInput? = nil
    ) -> GeneratedAppPayload.Node {
        GeneratedAppPayload.Node(
            id: id,
            kind: kind,
            title: id,
            subtitle: "Generated component",
            symbol: "sparkles",
            value: "",
            placeholder: "",
            binding: "\(id)-binding",
            options: [],
            items: [],
            action: GeneratedAppPayload.Action(type: "none", target: "", value: ""),
            presentation: GeneratedAppPayload.NodeDesign(
                surface: "card",
                span: "full",
                alignment: "leading",
                emphasis: "regular",
                variant: "automatic"
            ),
            image: nil,
            collection: nil,
            liveData: nil,
            newsFeed: newsFeed,
            marketWatch: marketWatch,
            ledger: ledger,
            game: game,
            deviceInput: deviceInput
        )
    }

    private var newsNode: GeneratedAppPayload.Node {
        node(
            id: "news-feed",
            kind: "newsFeed",
            newsFeed: GeneratedAppPayload.NewsFeed(
                sources: ["bbcWorld", "nprNews"],
                topics: ["AI", "Climate"],
                allowsTopicEditing: true,
                allowsBookmarks: true,
                maximumItems: 20
            )
        )
    }

    private var marketNode: GeneratedAppPayload.Node {
        node(
            id: "market-watch",
            kind: "marketWatch",
            marketWatch: GeneratedAppPayload.MarketWatch(
                provider: "twelveData",
                initialSymbols: ["aapl", "MSFT", "aapl"],
                allowsSymbolEditing: true,
                showsChart: true,
                range: "oneMonth"
            )
        )
    }

    private var ledgerNode: GeneratedAppPayload.Node {
        node(
            id: "ledger",
            kind: "ledger",
            ledger: GeneratedAppPayload.Ledger(
                currencyCode: "twd",
                categories: ["Food", "Income"],
                period: "currentMonth",
                monthlyBudget: 20_000,
                allowsIncome: true,
                initialEntries: [
                    GeneratedAppPayload.LedgerEntry(
                        title: "Lunch",
                        note: "",
                        amount: -120,
                        type: "expense",
                        category: "Food",
                        date: "2026-07-18"
                    )
                ]
            )
        )
    }

    private var snakeNode: GeneratedAppPayload.Node {
        gameNode(id: "snake", kind: "snake", seed: 7)
    }

    private var platformerNode: GeneratedAppPayload.Node {
        gameNode(id: "platformer", kind: "platformer", seed: 99)
    }

    private func gameNode(id: String, kind: String, seed: Int) -> GeneratedAppPayload.Node {
        node(
            id: id,
            kind: "game",
            game: GeneratedAppPayload.Game(
                kind: kind,
                difficulty: "standard",
                palette: "neon",
                targetScore: 12,
                levelSeed: seed,
                playerName: "Player",
                collectibleName: "Spark",
                haptics: true
            )
        )
    }

    private var cameraNode: GeneratedAppPayload.Node {
        deviceNode(id: "camera", kind: "cameraPhoto", button: "Take photo")
    }

    private var scannerNode: GeneratedAppPayload.Node {
        deviceNode(id: "scanner", kind: "qrCode", button: "Scan QR")
    }

    private func deviceNode(id: String, kind: String, button: String) -> GeneratedAppPayload.Node {
        node(
            id: id,
            kind: "deviceInput",
            deviceInput: GeneratedAppPayload.DeviceInput(
                kind: kind,
                buttonLabel: button,
                resultLabel: "Result",
                allowsRepeat: true
            )
        )
    }
}
