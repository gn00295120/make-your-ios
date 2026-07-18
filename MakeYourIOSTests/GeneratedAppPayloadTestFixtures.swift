import Foundation
@testable import MakeYourIOS

enum GeneratedAppPayloadTestFixtures {
    static func personalMoney() -> GeneratedAppPayload {
        GeneratedAppPayload(
            name: "Personal Money",
            summary: "Generated runtime capabilities",
            symbol: "creditcard.fill",
            tint: "mint",
            theme: GeneratedAppPayload.Theme(
                preset: "native",
                appearance: "system",
                typography: "system",
                background: "grouped",
                cornerStyle: "soft",
                density: "regular",
                defaultSurface: "card",
                palette: generatedPalette,
                typeScale: "balanced",
                titleWeight: "bold",
                elevation: "subtle",
                stroke: "hairline",
                controlShape: "native",
                motion: "subtle",
                backgroundAssetBinding: ""
            ),
            capabilities: [],
            startPageID: "home",
            initialState: [],
            logic: nil,
            pages: [
                GeneratedAppPayload.Page(
                    id: "home",
                    title: "Money",
                    nodes: [converterNode, collectionNode, liveDataNode],
                    presentation: GeneratedAppPayload.PageDesign(
                        layout: "flow",
                        showsNavigationTitle: true,
                        navigationStyle: "automatic"
                    )
                )
            ]
        )
    }

    private static var converterNode: GeneratedAppPayload.Node {
        GeneratedAppPayload.Node(
            id: "converter",
            kind: "currencyConverter",
            title: "Convert",
            subtitle: "",
            symbol: "function",
            value: "",
            placeholder: "",
            binding: "converter",
            options: ["USD", "TWD"],
            items: rateItems,
            action: action,
            valueBinding: nil,
            events: nil,
            control: nil,
            presentation: design,
            image: image,
            collection: nil,
            liveData: nil,
            newsFeed: nil,
            marketWatch: nil,
            ledger: nil,
            game: nil,
            deviceInput: nil
        )
    }

    private static var collectionNode: GeneratedAppPayload.Node {
        GeneratedAppPayload.Node(
            id: "subscriptions",
            kind: "recordCollection",
            title: "Subscriptions",
            subtitle: "",
            symbol: "creditcard.fill",
            value: "",
            placeholder: "",
            binding: "subscriptions",
            options: [],
            items: [],
            action: action,
            valueBinding: nil,
            events: nil,
            control: nil,
            presentation: design,
            image: image,
            collection: GeneratedAppPayload.Collection(
                itemName: "Subscription",
                titleLabel: "Service",
                noteLabel: "Plan",
                valueLabel: "Monthly cost",
                valueKind: "currency",
                valueUnit: "USD",
                dateLabel: "Renews",
                dateKind: "date",
                aggregate: "sum",
                allowsCompletion: false,
                allowsReminders: true
            ),
            liveData: nil,
            newsFeed: nil,
            marketWatch: nil,
            ledger: nil,
            game: nil,
            deviceInput: nil
        )
    }

    private static var liveDataNode: GeneratedAppPayload.Node {
        GeneratedAppPayload.Node(
            id: "rates",
            kind: "liveDataList",
            title: "Latest rates",
            subtitle: "",
            symbol: "chart.line.uptrend.xyaxis",
            value: "",
            placeholder: "",
            binding: "rates",
            options: [],
            items: [],
            action: action,
            valueBinding: nil,
            events: nil,
            control: nil,
            presentation: design,
            image: image,
            collection: nil,
            liveData: GeneratedAppPayload.LiveData(
                resource: "exchangeRates",
                primaryValue: "usd",
                initialSymbols: ["twd", "JPY", "twd"],
                allowsPrimarySelection: true,
                allowsItemEditing: true,
                allowsThresholds: true
            ),
            newsFeed: nil,
            marketWatch: nil,
            ledger: nil,
            game: nil,
            deviceInput: nil
        )
    }

    private static var rateItems: [GeneratedAppPayload.Item] {
        [
            GeneratedAppPayload.Item(
                id: "USD",
                title: "US Dollar",
                subtitle: "",
                value: "1",
                symbol: "circle.fill",
                isComplete: false
            ),
            GeneratedAppPayload.Item(
                id: "TWD",
                title: "New Taiwan Dollar",
                subtitle: "",
                value: "32.25",
                symbol: "circle.fill",
                isComplete: false
            )
        ]
    }

    private static var design: GeneratedAppPayload.NodeDesign {
        GeneratedAppPayload.NodeDesign(
            surface: "card",
            span: "full",
            alignment: "leading",
            emphasis: "regular",
            variant: "automatic"
        )
    }

    private static var image: GeneratedAppPayload.Image {
        GeneratedAppPayload.Image(
            aspect: "landscape",
            contentMode: "fill",
            altText: "",
            decorative: true,
            allowsUserSelection: false,
            mediaRole: "decorative",
            focalPoint: "center",
            mask: "rounded",
            overlay: "none"
        )
    }

    private static var generatedPalette: GeneratedAppPayload.Palette {
        GeneratedAppPayload.Palette(
            primaryHex: "#5450EF",
            secondaryHex: "#667085",
            accentHex: "#0A84FF",
            canvasLightHex: "#F2F2F7",
            canvasDarkHex: "#000000",
            surfaceLightHex: "#FFFFFF",
            surfaceDarkHex: "#1C1C1E"
        )
    }

    private static var action: GeneratedAppPayload.Action {
        GeneratedAppPayload.Action(type: "none", target: "", value: "")
    }
}
