extension SampleDocuments {
    static let museJournal = AppDocument(
        name: "Muse Journal",
        summary: "A photo-first journal with a private, user-triggered AI reflection tool.",
        symbol: "sparkles",
        tint: .plum,
        capabilities: [.localStorage, .photoPicker, .aiRequests],
        theme: .preset(.playful),
        pages: [
            AppPage(
                id: "home",
                title: "Muse Journal",
                nodes: [
                    ComponentNode(
                        id: "journal-photo",
                        kind: .image,
                        title: "A moment worth keeping",
                        subtitle: "Choose any photo from today.",
                        symbol: "photo.fill",
                        binding: "journal-photo",
                        presentation: ComponentPresentation(
                            surface: .plain,
                            span: .full,
                            alignment: .center,
                            emphasis: .strong,
                            variant: .fullBleed
                        ),
                        image: ImageSpec(
                            aspect: .banner,
                            contentMode: .fill,
                            altText: "A journal photo selected by the user",
                            decorative: false,
                            allowsUserSelection: true,
                            mediaRole: .hero,
                            focalPoint: .center,
                            mask: ImageMask.none,
                            overlay: .scrim
                        )
                    ),
                    ComponentNode(
                        kind: .hero,
                        title: "Notice what mattered",
                        subtitle: "Write freely, then ask for a gentle reflection when you want one.",
                        symbol: "heart.fill",
                        presentation: ComponentPresentation(
                            surface: .plain,
                            span: .full,
                            alignment: .center,
                            emphasis: .strong,
                            variant: .centered
                        )
                    ),
                    ComponentNode(
                        id: "journal-ai",
                        kind: .aiAssistant,
                        title: "Reflection partner",
                        subtitle: "AI sees only the text you review on the next screen.",
                        symbol: "sparkles",
                        value: reflectionTask,
                        placeholder: "What happened, and how did it feel?",
                        binding: "journal-note",
                        options: [
                            "Help me name what I’m feeling",
                            "Find one thing I can learn from today",
                            "Turn this into a short gratitude note"
                        ],
                        action: RuntimeAction(type: .none, target: "", value: "Reflect with AI"),
                        presentation: ComponentPresentation(
                            surface: .material,
                            span: .full,
                            alignment: .leading,
                            emphasis: .regular,
                            variant: .automatic
                        )
                    )
                ],
                presentation: PagePresentation(layout: .story, showsNavigationTitle: false)
            )
        ]
    )

    private static let reflectionTask = "Reflect on the note with warmth. "
        + "Highlight one meaningful pattern and ask one useful question."
}
