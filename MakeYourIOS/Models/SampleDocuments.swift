import Foundation

enum SampleDocuments {
    static let quickConvert = AppDocument(
        name: "Quick Convert",
        summary: "A calm, one-screen currency converter for everyday travel.",
        symbol: "arrow.left.arrow.right.circle.fill",
        tint: .indigo,
        capabilities: [.localStorage, .safeCalculation],
        theme: .preset(.editorial),
        pages: [
            AppPage(
                id: "home",
                title: "Quick Convert",
                nodes: [
                    ComponentNode(
                        kind: .hero,
                        title: "Money, without the math",
                        subtitle: "Convert the currencies you use most.",
                        symbol: "globe.asia.australia.fill",
                        presentation: ComponentPresentation(
                            surface: .plain,
                            span: .full,
                            alignment: .center,
                            emphasis: .strong,
                            variant: .centered
                        )
                    ),
                    ComponentNode(
                        id: "currency-converter",
                        kind: .currencyConverter,
                        title: "Convert",
                        subtitle: "Demo rates are stored on-device.",
                        options: ["USD", "TWD", "JPY", "EUR", "GBP"],
                        items: [
                            ComponentItem(id: "USD", title: "US Dollar", value: "1"),
                            ComponentItem(id: "TWD", title: "New Taiwan Dollar", value: "32.45"),
                            ComponentItem(id: "JPY", title: "Japanese Yen", value: "149.82"),
                            ComponentItem(id: "EUR", title: "Euro", value: "0.92"),
                            ComponentItem(id: "GBP", title: "British Pound", value: "0.78")
                        ],
                        presentation: ComponentPresentation(
                            surface: .outlined,
                            span: .full,
                            alignment: .leading,
                            emphasis: .regular,
                            variant: .split
                        )
                    ),
                    ComponentNode(
                        kind: .infoBanner,
                        title: "Private by design",
                        subtitle: "Your amount never leaves this device.",
                        symbol: "lock.shield.fill",
                        presentation: ComponentPresentation(
                            surface: .plain,
                            span: .full,
                            alignment: .leading,
                            emphasis: .subtle,
                            variant: .automatic
                        )
                    )
                ],
                presentation: PagePresentation(layout: .story, showsNavigationTitle: true)
            )
        ]
    )

    static let gentleTasks = AppDocument(
        name: "Gentle Tasks",
        summary: "A tiny task list that reminds you without turning life into a dashboard.",
        symbol: "checkmark.circle.fill",
        tint: .mint,
        capabilities: [.localStorage, .localNotifications],
        theme: .preset(.soft),
        pages: [
            AppPage(
                id: "home",
                title: "Today",
                nodes: [
                    ComponentNode(
                        kind: .hero,
                        title: "A lighter day",
                        subtitle: "Three good things are enough.",
                        symbol: "sun.max.fill",
                        presentation: ComponentPresentation(
                            surface: .plain,
                            span: .full,
                            alignment: .center,
                            emphasis: .strong,
                            variant: .centered
                        )
                    ),
                    ComponentNode(
                        id: "daily-tasks",
                        kind: .taskList,
                        title: "Today",
                        subtitle: "Tap the bell to schedule a gentle reminder.",
                        items: [
                            ComponentItem(
                                title: "Send the project update",
                                subtitle: "10:30",
                                symbol: "paperplane.fill"
                            ),
                            ComponentItem(
                                title: "Walk outside for ten minutes",
                                subtitle: "15:00",
                                symbol: "figure.walk"
                            ),
                            ComponentItem(
                                title: "Write tomorrow's first step",
                                subtitle: "18:30",
                                symbol: "pencil.line"
                            )
                        ],
                        presentation: ComponentPresentation(
                            surface: .material,
                            span: .full,
                            alignment: .leading,
                            emphasis: .regular,
                            variant: .timeline
                        )
                    ),
                    ComponentNode(
                        kind: .infoBanner,
                        title: "You stay in control",
                        subtitle: "Notifications are requested only when you tap a reminder.",
                        symbol: "hand.raised.fill",
                        presentation: ComponentPresentation(
                            surface: .plain,
                            span: .full,
                            alignment: .leading,
                            emphasis: .subtle,
                            variant: .automatic
                        )
                    )
                ],
                presentation: .flow
            )
        ]
    )

    static let blank = AppDocument(
        name: "New App",
        summary: "Tell MakeYour what you want this app to do.",
        symbol: "square.grid.2x2.fill",
        tint: .sky,
        theme: .preset(.minimal),
        pages: [
            AppPage(
                id: "home",
                title: "New App",
                nodes: [
                    ComponentNode(
                        kind: .hero,
                        title: "Start with a sentence",
                        subtitle: "Describe the small app you wish already existed.",
                        symbol: "wand.and.stars",
                        presentation: ComponentPresentation(
                            surface: .plain,
                            span: .full,
                            alignment: .center,
                            emphasis: .strong,
                            variant: .centered
                        )
                    ),
                    ComponentNode(
                        kind: .infoBanner,
                        title: "Try a concrete outcome",
                        subtitle: "“Make a hydration tracker with a daily target and quick-add buttons.”",
                        symbol: "quote.bubble.fill",
                        presentation: ComponentPresentation(
                            surface: .outlined,
                            span: .full,
                            alignment: .leading,
                            emphasis: .regular,
                            variant: .automatic
                        )
                    )
                ],
                presentation: .flow
            )
        ]
    )

}
