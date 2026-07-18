import Foundation

extension SampleDocuments {
    /// Generated through MakeYour's AI Builder and kept as an offline-reviewable example.
    static let liveFXWatch = AppDocument(
        name: "Live FX Watch",
        summary: "A personal watchlist for the latest daily foreign-exchange reference rates.",
        symbol: "chart.line.uptrend.xyaxis",
        tint: .sky,
        capabilities: [.network, .localStorage],
        theme: AppVisualTheme(
            preset: .minimal,
            appearance: .light,
            typography: .rounded,
            background: .plain,
            cornerStyle: .soft,
            density: .regular,
            defaultSurface: .plain
        ),
        pages: [
            AppPage(
                id: "home",
                title: "Live FX Watch",
                nodes: [
                    ComponentNode(
                        id: "fx-hero",
                        kind: .hero,
                        title: "Rates that matter to you",
                        subtitle: "Build a personal watchlist around one home currency.",
                        symbol: "chart.line.uptrend.xyaxis",
                        presentation: centeredHero
                    ),
                    ComponentNode(
                        id: "fx-disclosure",
                        kind: .infoBanner,
                        title: "Reference rates",
                        subtitle: "Latest daily reference rates, not streaming trading quotes.",
                        symbol: "clock.fill",
                        presentation: subtlePlain
                    ),
                    ComponentNode(
                        id: "fx-watchlist",
                        kind: .liveDataList,
                        title: "My rate watchlist",
                        subtitle: "Tap the bell to set a target or test an alert.",
                        symbol: "bell.badge.fill",
                        placeholder: "Search currencies to add them to your watchlist",
                        presentation: regularPlain,
                        liveData: LiveDataListSpec(
                            resource: .exchangeRates,
                            primaryValue: "USD",
                            initialSymbols: ["TWD", "JPY", "EUR", "GBP", "KRW"],
                            allowsPrimarySelection: true,
                            allowsItemEditing: true,
                            allowsThresholds: true
                        )
                    )
                ],
                presentation: PagePresentation(layout: .dashboard, showsNavigationTitle: true)
            )
        ]
    )

    /// Generated through MakeYour's AI Builder and kept as an offline-reviewable example.
    static let useItFirst = AppDocument(
        name: "Use It First",
        summary: "A private fridge photo, pantry tracker, reminders, and reviewed text-only AI helper.",
        symbol: "leaf.fill",
        tint: .mint,
        capabilities: [.aiRequests, .localNotifications, .photoPicker, .localStorage],
        theme: .preset(.playful),
        pages: [
            AppPage(
                id: "home",
                title: "Use It First",
                nodes: [
                    ComponentNode(
                        id: "fridge-photo",
                        kind: .image,
                        title: "What’s in your fridge?",
                        subtitle: "Choose one private fridge photo.",
                        symbol: "photo.fill",
                        binding: "fridge-photo",
                        presentation: ComponentPresentation(
                            surface: .plain,
                            span: .full,
                            alignment: .leading,
                            emphasis: .strong,
                            variant: .fullBleed
                        ),
                        image: ImageSpec(
                            aspect: .banner,
                            contentMode: .fill,
                            altText: "A fridge photo selected by the user",
                            decorative: false,
                            allowsUserSelection: true,
                            mediaRole: .hero,
                            focalPoint: .center,
                            mask: ImageMask.none,
                            overlay: .scrim
                        )
                    ),
                    ComponentNode(
                        id: "fridge-hero",
                        kind: .hero,
                        title: "Use it before you lose it",
                        subtitle: "Track what expires next, then turn a few ingredients into dinner.",
                        symbol: "leaf.fill",
                        presentation: centeredHero
                    ),
                    ComponentNode(
                        id: "fridge-disclosure",
                        kind: .infoBanner,
                        title: "Private by design",
                        subtitle: "Your photo and pantry stay on this iPhone. AI receives only text you review.",
                        symbol: "lock.shield.fill",
                        presentation: ComponentPresentation(
                            surface: .tinted,
                            span: .full,
                            alignment: .leading,
                            emphasis: .subtle,
                            variant: .automatic
                        )
                    ),
                    ComponentNode(
                        id: "pantry-items",
                        kind: .recordCollection,
                        title: "Pantry",
                        subtitle: "Add what you want to use first.",
                        symbol: "cart.fill",
                        binding: "pantry-items",
                        presentation: ComponentPresentation(
                            surface: .material,
                            span: .full,
                            alignment: .leading,
                            emphasis: .regular,
                            variant: .cards
                        ),
                        collection: RecordCollectionSpec(
                            itemName: "Ingredient",
                            titleLabel: "Ingredient",
                            noteLabel: "Where / note",
                            valueLabel: "Quantity",
                            valueKind: .number,
                            valueUnit: "unit",
                            dateLabel: "Use by",
                            dateKind: .date,
                            aggregate: .count,
                            allowsCompletion: true,
                            allowsReminders: true
                        )
                    ),
                    ComponentNode(
                        id: "rescue-chef",
                        kind: .aiAssistant,
                        title: "15-minute Rescue Chef",
                        subtitle: "Type ingredients yourself. AI cannot read your photo or pantry list.",
                        symbol: "fork.knife",
                        value: recipeTask,
                        placeholder: "Example: spinach, eggs, tofu",
                        options: [
                            "spinach, eggs, tofu",
                            "tomatoes, rice, cheese",
                            "banana, oats, yogurt"
                        ],
                        action: RuntimeAction(type: .showMessage, target: "", value: "Make a recipe"),
                        presentation: ComponentPresentation(
                            surface: .outlined,
                            span: .full,
                            alignment: .leading,
                            emphasis: .regular,
                            variant: .framed
                        )
                    )
                ],
                presentation: PagePresentation(layout: .story, showsNavigationTitle: false)
            )
        ]
    )

    private static let centeredHero = ComponentPresentation(
        surface: .plain,
        span: .full,
        alignment: .center,
        emphasis: .strong,
        variant: .centered
    )

    private static let subtlePlain = ComponentPresentation(
        surface: .plain,
        span: .full,
        alignment: .leading,
        emphasis: .subtle,
        variant: .automatic
    )

    private static let regularPlain = ComponentPresentation(
        surface: .plain,
        span: .full,
        alignment: .leading,
        emphasis: .regular,
        variant: .automatic
    )

    private static let recipeTask = "Using only ingredients typed by the user, suggest one realistic "
        + "15-minute recipe with a short name, three concise steps, and one optional substitution. "
        + "Never claim to inspect other data. Do not make medical or nutrition claims."
}
