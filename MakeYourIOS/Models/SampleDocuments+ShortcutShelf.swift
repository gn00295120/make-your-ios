import Foundation

extension SampleDocuments {
    static let shortcutShelf = AppDocument(
        name: "Shortcut Shelf",
        summary: "An opt-in tiny app that can be opened from Shortcuts or Siri.",
        symbol: "square.grid.2x2.fill",
        tint: .plum,
        capabilities: [.localStorage, .shortcutsOpenTinyApp],
        theme: .preset(.native),
        pages: [
            AppPage(
                id: "home",
                title: "Shortcut Shelf",
                nodes: [
                    ComponentNode(
                        id: "shortcut-hero",
                        kind: .hero,
                        title: "Your tiny app, one phrase away",
                        subtitle: "Choose this app in Shortcuts and open it without hunting through a folder.",
                        symbol: "bolt.fill",
                        presentation: ComponentPresentation(
                            surface: .plain,
                            span: .full,
                            alignment: .center,
                            emphasis: .strong,
                            variant: .centered
                        )
                    ),
                    ComponentNode(
                        id: "shortcut-access",
                        kind: .shortcutAccess,
                        title: "Open with Shortcuts",
                        subtitle: "Use Apple's Shortcuts app or Siri after you choose this tiny app.",
                        symbol: "square.grid.2x2.fill",
                        presentation: ComponentPresentation(
                            surface: .material,
                            span: .full,
                            alignment: .leading,
                            emphasis: .regular,
                            variant: .cards
                        )
                    ),
                    ComponentNode(
                        id: "shortcut-privacy",
                        kind: .infoBanner,
                        title: "Explicit and revocable",
                        subtitle: "Remove this block to stop offering the tiny app to Shortcuts.",
                        symbol: "lock.shield.fill",
                        presentation: ComponentPresentation(
                            surface: .outlined,
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
}
