import Foundation

extension SampleDocuments {
    static let dailyBrief = AppDocument(
        name: "Daily Brief",
        summary: "Collect, filter, bookmark, and organize live headlines around your interests.",
        symbol: "newspaper.fill",
        tint: .plum,
        capabilities: [.localStorage, .network],
        theme: .preset(.editorial),
        pages: [
            AppPage(
                id: "home",
                title: "Daily Brief",
                nodes: [
                    ComponentNode(
                        id: "brief-hero",
                        kind: .hero,
                        title: "News without the noise",
                        subtitle: "Follow a few topics, save what matters, and return later.",
                        symbol: "newspaper.fill",
                        presentation: showcaseEditorialHero
                    ),
                    ComponentNode(
                        id: "brief-feed",
                        kind: .newsFeed,
                        title: "Your briefing",
                        subtitle: "Live headlines from credited original sources.",
                        symbol: "bookmark.fill",
                        presentation: showcaseEditorial,
                        newsFeed: NewsFeedSpec(
                            sources: [.bbcWorld, .bbcTechnology, .nprNews],
                            topics: ["technology", "climate", "science"],
                            allowsTopicEditing: true,
                            allowsBookmarks: true,
                            maximumItems: 24
                        )
                    )
                ],
                presentation: PagePresentation(layout: .story, showsNavigationTitle: true)
            )
        ]
    )

    static let marketPocket = AppDocument(
        name: "Market Pocket",
        summary: "A personal stock watchlist with latest prices and recent history.",
        symbol: "chart.xyaxis.line",
        tint: .sky,
        capabilities: [.localStorage, .network],
        theme: .preset(.minimal),
        pages: [
            AppPage(
                id: "home",
                title: "Market Pocket",
                nodes: [
                    ComponentNode(
                        id: "market-hero",
                        kind: .hero,
                        title: "Keep the market in perspective",
                        subtitle: "Latest or delayed reference data, never trading advice.",
                        symbol: "chart.line.uptrend.xyaxis",
                        presentation: showcaseEditorialHero
                    ),
                    ComponentNode(
                        id: "market-watch",
                        kind: .marketWatch,
                        title: "My watchlist",
                        subtitle: "AAPL works in demo mode; connect your own provider key for more symbols.",
                        symbol: "chart.xyaxis.line",
                        presentation: showcaseSplit,
                        marketWatch: MarketWatchSpec(
                            provider: .twelveData,
                            initialSymbols: ["AAPL"],
                            allowsSymbolEditing: true,
                            showsChart: true,
                            range: .oneMonth
                        )
                    )
                ],
                presentation: PagePresentation(layout: .dashboard, showsNavigationTitle: true)
            )
        ]
    )

    static let pocketLedger = AppDocument(
        name: "Pocket Ledger",
        summary: "Track income, expenses, categories, balance, and a monthly budget.",
        symbol: "dollarsign.circle.fill",
        tint: .mint,
        capabilities: [.localStorage],
        theme: .preset(.soft),
        pages: [
            AppPage(
                id: "home",
                title: "Pocket Ledger",
                nodes: [
                    ComponentNode(
                        id: "ledger-main",
                        kind: .ledger,
                        title: "This month",
                        subtitle: "Every number is calculated from entries stored on this iPhone.",
                        symbol: "dollarsign.circle.fill",
                        presentation: showcaseCards,
                        ledger: LedgerSpec(
                            currencyCode: "TWD",
                            categories: ["Income", "Food", "Transport", "Home", "Fun", "Other"],
                            period: .currentMonth,
                            monthlyBudget: 30_000,
                            allowsIncome: true,
                            initialEntries: [
                                LedgerSeedEntry(
                                    title: "Freelance payment",
                                    note: "Landing page project",
                                    amount: 18_000,
                                    type: .income,
                                    category: "Income",
                                    date: showcaseDay(dayOffset: -5)
                                ),
                                LedgerSeedEntry(
                                    title: "Groceries",
                                    note: "Weekly shop",
                                    amount: 1_280,
                                    type: .expense,
                                    category: "Food",
                                    date: showcaseDay(dayOffset: -2)
                                ),
                                LedgerSeedEntry(
                                    title: "Metro",
                                    note: "Transit top-up",
                                    amount: 500,
                                    type: .expense,
                                    category: "Transport",
                                    date: showcaseDay(dayOffset: -1)
                                )
                            ]
                        )
                    )
                ],
                presentation: PagePresentation(layout: .dashboard, showsNavigationTitle: true)
            )
        ]
    )

    static let skybound = AppDocument(
        name: "Skybound",
        summary: "An original side-scrolling platform adventure with touch controls.",
        symbol: "figure.run",
        tint: .sky,
        capabilities: [.haptics, .localStorage],
        theme: .preset(.playful),
        pages: [
            AppPage(
                id: "home",
                title: "Skybound",
                nodes: [
                    ComponentNode(
                        id: "skybound-game",
                        kind: .game,
                        title: "Cloud Run",
                        subtitle: "Collect stars and reach the beacon. No copyrighted characters or assets.",
                        symbol: "figure.run",
                        presentation: showcaseImmersive,
                        game: GameSpec(
                            kind: .platformer,
                            difficulty: .standard,
                            palette: .sky,
                            targetScore: 8,
                            levelSeed: 2_026,
                            playerName: "Nova",
                            collectibleName: "Star",
                            haptics: true,
                            program: nil
                        )
                    )
                ],
                presentation: PagePresentation(layout: .story, showsNavigationTitle: false)
            )
        ]
    )

    static let neonSnake = AppDocument(
        name: "Neon Snake",
        summary: "A complete touch-controlled snake game with scoring and high scores.",
        symbol: "gamecontroller.fill",
        tint: .plum,
        capabilities: [.haptics, .localStorage],
        theme: AppVisualTheme(
            preset: .playful,
            appearance: .dark,
            typography: .rounded,
            background: .gradient,
            cornerStyle: .round,
            density: .regular,
            defaultSurface: .material
        ),
        pages: [
            AppPage(
                id: "home",
                title: "Neon Snake",
                nodes: [
                    ComponentNode(
                        id: "snake-game",
                        kind: .game,
                        title: "Glow Garden",
                        subtitle: "Guide the trail, collect sparks, and beat your best score.",
                        symbol: "gamecontroller.fill",
                        presentation: showcaseFramed,
                        game: GameSpec(
                            kind: .snake,
                            difficulty: .standard,
                            palette: .neon,
                            targetScore: 15,
                            levelSeed: 86,
                            playerName: "Glow",
                            collectibleName: "Spark",
                            haptics: true,
                            program: nil
                        )
                    )
                ],
                presentation: PagePresentation(layout: .flow, showsNavigationTitle: false)
            )
        ]
    )

    private static let showcaseEditorialHero = ComponentPresentation(
        surface: .plain,
        span: .full,
        alignment: .leading,
        emphasis: .strong,
        variant: .editorial
    )

    private static let showcaseEditorial = ComponentPresentation(
        surface: .plain,
        span: .full,
        alignment: .leading,
        emphasis: .regular,
        variant: .editorial
    )

    private static let showcaseSplit = ComponentPresentation(
        surface: .plain,
        span: .full,
        alignment: .leading,
        emphasis: .regular,
        variant: .split
    )

    private static let showcaseCards = ComponentPresentation(
        surface: .plain,
        span: .full,
        alignment: .leading,
        emphasis: .regular,
        variant: .cards
    )

    private static let showcaseImmersive = ComponentPresentation(
        surface: .plain,
        span: .full,
        alignment: .leading,
        emphasis: .strong,
        variant: .immersive
    )

    private static let showcaseFramed = ComponentPresentation(
        surface: .outlined,
        span: .full,
        alignment: .leading,
        emphasis: .strong,
        variant: .framed
    )

    private static func showcaseDay(dayOffset: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: .now) ?? .now
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 2_026,
            components.month ?? 1,
            components.day ?? 1
        )
    }
}
