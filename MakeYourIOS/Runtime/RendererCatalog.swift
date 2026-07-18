import Foundation

enum RendererCatalog {
    static func supportedVariants(for kind: ComponentKind) -> Set<ComponentVariant> {
        variantsByKind[kind] ?? [.automatic]
    }

    static func normalizedVariant(
        _ requested: ComponentVariant,
        for kind: ComponentKind
    ) -> ComponentVariant {
        supportedVariants(for: kind).contains(requested) ? requested : .automatic
    }

    private static let variantsByKind: [ComponentKind: Set<ComponentVariant>] = [
        .hero: [
            .automatic, .compact, .centered, .photoOverlay, .editorial, .split,
            .fullBleed, .framed, .immersive
        ],
        .sectionHeader: [.automatic, .compact, .centered, .editorial],
        .text: [.automatic, .compact, .centered, .editorial, .framed],
        .metric: [.automatic, .compact, .centered, .numberFirst, .progress, .cards, .dense, .framed],
        .textInput: [.automatic, .compact, .framed],
        .numberInput: [.automatic, .compact, .framed],
        .picker: [.automatic, .compact, .framed],
        .button: [.automatic, .compact, .outlinedAction, .softAction],
        .checklist: [.automatic, .compact, .timeline, .cards, .dense],
        .infoBanner: [.automatic, .compact, .centered, .framed],
        .currencyConverter: [.automatic, .compact, .split, .framed, .dense],
        .taskList: [.automatic, .compact, .timeline, .cards, .dense],
        .image: [.automatic, .compact, .photoOverlay, .fullBleed, .framed, .immersive],
        .aiAssistant: [.automatic, .compact, .cards, .framed],
        .recordCollection: [.automatic, .compact, .cards, .dense],
        .liveDataList: [.automatic, .compact, .cards, .dense],
        .newsFeed: [.automatic, .compact, .editorial, .cards, .dense],
        .marketWatch: [.automatic, .compact, .split, .cards, .dense],
        .ledger: [.automatic, .compact, .cards, .dense],
        .game: [.automatic, .framed, .fullBleed, .immersive],
        .deviceInput: [.automatic, .compact, .cards, .framed],
        .control: [.automatic, .compact, .framed],
        .collectionView: [.automatic, .compact, .cards, .dense, .framed],
        .map: [.automatic, .compact, .cards, .framed, .fullBleed],
        .calendarEvent: [.automatic, .compact, .cards, .framed],
        .documentExport: [.automatic, .compact, .cards, .framed],
        .divider: [.automatic, .compact]
    ]
}
