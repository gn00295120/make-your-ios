import Foundation

struct GeneratedAppPayload: Decodable {
    var name: String
    var summary: String
    var symbol: String
    var tint: String
    var theme: Theme
    var capabilities: [String]
    var startPageID: String
    var initialState: [StateEntry]
    var pages: [Page]

    func makeDocument(existingID: UUID, version: Int) -> AppDocument {
        let documentPages = makePages()
        let safeStartPageID = documentPages.contains(where: { $0.id == startPageID })
            ? startPageID
            : documentPages.first?.id ?? "home"

        return AppDocument(
            id: existingID,
            name: String(name.prefix(48)),
            summary: String(summary.prefix(240)),
            symbol: Self.allowedSymbols.contains(symbol) ? symbol : "square.grid.2x2.fill",
            tint: AppTint(rawValue: tint) ?? .indigo,
            version: version,
            updatedAt: .now,
            startPageID: safeStartPageID,
            capabilities: makeCapabilities(for: documentPages),
            initialState: makeInitialState(),
            theme: makeTheme(),
            pages: documentPages.isEmpty ? SampleDocuments.blank.pages : documentPages
        )
    }

    private func makeTheme() -> AppVisualTheme {
        AppVisualTheme(
            preset: VisualThemePreset(rawValue: theme.preset) ?? .native,
            appearance: ThemeAppearance(rawValue: theme.appearance) ?? .system,
            typography: ThemeTypography(rawValue: theme.typography) ?? .system,
            background: ThemeBackground(rawValue: theme.background) ?? .grouped,
            cornerStyle: ThemeCornerStyle(rawValue: theme.cornerStyle) ?? .soft,
            density: ThemeDensity(rawValue: theme.density) ?? .regular,
            defaultSurface: ComponentSurface(rawValue: theme.defaultSurface) ?? .card
        )
    }

    private func makePages() -> [AppPage] {
        pages.prefix(AppDocumentValidator.maximumPages).enumerated().map { pageIndex, page in
            let pageID = normalizedID(page.id, fallback: "page-\(pageIndex + 1)")
            let nodes = page.nodes.prefix(20).enumerated().map { nodeIndex, node in
                let kind = ComponentKind(rawValue: node.kind) ?? .text
                let presentation = makePresentation(node.presentation, for: kind)
                let binding = normalizedID(node.binding, fallback: "value-\(nodeIndex + 1)")
                return ComponentNode(
                    id: normalizedID(node.id, fallback: "\(pageID)-node-\(nodeIndex + 1)"),
                    kind: kind,
                    title: String(node.title.prefix(120)),
                    subtitle: String(node.subtitle.prefix(320)),
                    symbol: Self.allowedSymbols.contains(node.symbol) ? node.symbol : "sparkles",
                    value: String(node.value.prefix(800)),
                    placeholder: String(node.placeholder.prefix(160)),
                    binding: binding,
                    options: Array(node.options.prefix(20)).map { String($0.prefix(40)) },
                    items: makeItems(
                        node.items,
                        pageID: pageID,
                        nodeIndex: nodeIndex,
                        kind: kind
                    ),
                    action: RuntimeAction(
                        type: RuntimeActionType(rawValue: node.action.type) ?? .none,
                        target: normalizedID(node.action.target, fallback: ""),
                        value: String(node.action.value.prefix(240))
                    ),
                    presentation: presentation,
                    image: kind == .image ? makeImage(node.image, fallbackTitle: node.title) : nil,
                    collection: kind == .recordCollection ? makeCollection(node.collection) : nil,
                    liveData: kind == .liveDataList ? makeLiveData(node.liveData) : nil,
                    newsFeed: kind == .newsFeed ? makeNewsFeed(node.newsFeed) : nil,
                    marketWatch: kind == .marketWatch ? makeMarketWatch(node.marketWatch) : nil,
                    ledger: kind == .ledger ? makeLedger(node.ledger) : nil,
                    game: kind == .game ? makeGame(node.game) : nil,
                    deviceInput: kind == .deviceInput ? makeDeviceInput(node.deviceInput) : nil
                )
            }
            return AppPage(
                id: pageID,
                title: String(page.title.prefix(60)),
                nodes: nodes,
                presentation: PagePresentation(
                    layout: PageLayout(rawValue: page.presentation.layout) ?? .flow,
                    showsNavigationTitle: page.presentation.showsNavigationTitle
                )
            )
        }
    }
}

private extension GeneratedAppPayload {
    private func makeItems(
        _ items: [Item],
        pageID: String,
        nodeIndex: Int,
        kind: ComponentKind
    ) -> [ComponentItem] {
        items.prefix(30).enumerated().map { itemIndex, item in
            let generatedID = "\(pageID)-node-\(nodeIndex + 1)-item-\(itemIndex + 1)"
            let itemID = kind == .currencyConverter
                ? normalizedCurrencyCode(item.id, fallback: generatedID)
                : normalizedID(item.id, fallback: generatedID)
            return ComponentItem(
                id: itemID,
                title: String(item.title.prefix(100)),
                subtitle: String(item.subtitle.prefix(120)),
                value: String(item.value.prefix(80)),
                symbol: Self.allowedSymbols.contains(item.symbol) ? item.symbol : "circle.fill",
                isComplete: item.isComplete
            )
        }
    }

    private func makePresentation(
        _ design: NodeDesign,
        for kind: ComponentKind
    ) -> ComponentPresentation {
        let requestedSpan = ComponentSpan(rawValue: design.span) ?? .full
        let supportsCompactSpan = [.text, .metric, .infoBanner, .image].contains(kind)
        return ComponentPresentation(
            surface: ComponentSurface(rawValue: design.surface) ?? .automatic,
            span: supportsCompactSpan ? requestedSpan : .full,
            alignment: ComponentAlignment(rawValue: design.alignment) ?? .leading,
            emphasis: ComponentEmphasis(rawValue: design.emphasis) ?? .regular,
            variant: ComponentVariant(rawValue: design.variant) ?? .automatic
        )
    }

    private func makeImage(_ image: Image?, fallbackTitle: String) -> ImageSpec {
        let fallbackAltText = fallbackTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let altText = (image?.altText ?? "").isEmpty
            ? (fallbackAltText.isEmpty ? "User-selected image" : fallbackAltText)
            : image?.altText ?? fallbackAltText
        return ImageSpec(
            aspect: ImageAspect(rawValue: image?.aspect ?? "") ?? .landscape,
            contentMode: ImageContentMode(rawValue: image?.contentMode ?? "") ?? .fill,
            altText: String(altText.prefix(180)),
            decorative: image?.decorative ?? false,
            allowsUserSelection: image?.allowsUserSelection ?? true
        )
    }

    private func makeCollection(_ collection: Collection?) -> RecordCollectionSpec {
        RecordCollectionSpec(
            itemName: String((collection?.itemName ?? "Item").prefix(40)),
            titleLabel: String((collection?.titleLabel ?? "Name").prefix(60)),
            noteLabel: String((collection?.noteLabel ?? "Notes").prefix(60)),
            valueLabel: String((collection?.valueLabel ?? "Value").prefix(60)),
            valueKind: RecordValueKind(rawValue: collection?.valueKind ?? "") ?? .none,
            valueUnit: String((collection?.valueUnit ?? "").uppercased().prefix(12)),
            dateLabel: String((collection?.dateLabel ?? "Date").prefix(60)),
            dateKind: RecordDateKind(rawValue: collection?.dateKind ?? "") ?? .none,
            aggregate: RecordAggregate(rawValue: collection?.aggregate ?? "") ?? .none,
            allowsCompletion: collection?.allowsCompletion ?? false,
            allowsReminders: collection?.allowsReminders ?? false
        )
    }

    private func makeLiveData(_ liveData: LiveData?) -> LiveDataListSpec {
        let base = normalizedCurrencyCode(liveData?.primaryValue ?? "USD", fallback: "USD")
        var seen = Set<String>()
        let symbols = (liveData?.initialSymbols ?? ["TWD", "JPY", "EUR"])
            .compactMap { normalizedCurrencyCode($0, fallback: "") }
            .filter { !$0.isEmpty && $0 != base && seen.insert($0).inserted }
        return LiveDataListSpec(
            resource: LiveResourceKind(rawValue: liveData?.resource ?? "") ?? .exchangeRates,
            primaryValue: base,
            initialSymbols: symbols.isEmpty ? ["TWD", "JPY", "EUR"].filter { $0 != base } : symbols,
            allowsPrimarySelection: liveData?.allowsPrimarySelection ?? true,
            allowsItemEditing: liveData?.allowsItemEditing ?? true,
            allowsThresholds: liveData?.allowsThresholds ?? true
        )
    }

    private func makeNewsFeed(_ newsFeed: NewsFeed?) -> NewsFeedSpec {
        var seenSources = Set<NewsSourceKind>()
        let sources = (newsFeed?.sources ?? [])
            .compactMap(NewsSourceKind.init(rawValue:))
            .filter { seenSources.insert($0).inserted }
            .prefix(3)
        var seenTopics = Set<String>()
        let topics = (newsFeed?.topics ?? [])
            .map { String($0.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40)) }
            .filter { !$0.isEmpty && seenTopics.insert($0.lowercased()).inserted }
            .prefix(8)
        return NewsFeedSpec(
            sources: sources.isEmpty ? [.bbcWorld, .nprNews] : Array(sources),
            topics: Array(topics),
            allowsTopicEditing: newsFeed?.allowsTopicEditing ?? true,
            allowsBookmarks: newsFeed?.allowsBookmarks ?? true,
            maximumItems: min(max(newsFeed?.maximumItems ?? 20, 5), 40)
        )
    }

    private func makeMarketWatch(_ marketWatch: MarketWatch?) -> MarketWatchSpec {
        var seen = Set<String>()
        let symbols = (marketWatch?.initialSymbols ?? [])
            .compactMap(normalizedMarketSymbol)
            .filter { seen.insert($0).inserted }
            .prefix(10)
        return MarketWatchSpec(
            provider: MarketDataProviderKind(rawValue: marketWatch?.provider ?? "") ?? .twelveData,
            initialSymbols: symbols.isEmpty ? ["AAPL"] : Array(symbols),
            allowsSymbolEditing: marketWatch?.allowsSymbolEditing ?? true,
            showsChart: marketWatch?.showsChart ?? true,
            range: MarketRange(rawValue: marketWatch?.range ?? "") ?? .oneMonth
        )
    }

    private func makeLedger(_ ledger: Ledger?) -> LedgerSpec {
        let currency = normalizedCurrencyCode(ledger?.currencyCode ?? "USD", fallback: "USD")
        var seen = Set<String>()
        let categories = (ledger?.categories ?? [])
            .map { String($0.trimmingCharacters(in: .whitespacesAndNewlines).prefix(30)) }
            .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
            .prefix(16)
        let safeCategories = categories.isEmpty
            ? ["Food", "Transport", "Home", "Fun", "Other"]
            : Array(categories)
        let fallbackCategory = safeCategories[0]
        let allowsIncome = ledger?.allowsIncome ?? true
        let entries = (ledger?.initialEntries ?? []).prefix(30).map { entry in
            let requestedCategory = entry.category.trimmingCharacters(in: .whitespacesAndNewlines)
            let category = safeCategories.first {
                $0.caseInsensitiveCompare(requestedCategory) == .orderedSame
            } ?? fallbackCategory
            return LedgerSeedEntry(
                title: String((entry.title.isEmpty ? "Entry" : entry.title).prefix(80)),
                note: String(entry.note.prefix(160)),
                amount: entry.amount.isFinite ? abs(entry.amount) : 0,
                type: allowsIncome ? (LedgerEntryType(rawValue: entry.type) ?? .expense) : .expense,
                category: category,
                date: normalizedDay(entry.date)
            )
        }
        return LedgerSpec(
            currencyCode: currency,
            categories: safeCategories,
            period: LedgerPeriod(rawValue: ledger?.period ?? "") ?? .currentMonth,
            monthlyBudget: max(0, safeFiniteValue(ledger?.monthlyBudget)),
            allowsIncome: allowsIncome,
            initialEntries: entries
        )
    }

    private func makeGame(_ game: Game?) -> GameSpec {
        let playerName = nonEmpty(game?.playerName, fallback: "Player")
        let collectibleName = nonEmpty(game?.collectibleName, fallback: "Token")
        return GameSpec(
            kind: GameKind(rawValue: game?.kind ?? "") ?? .snake,
            difficulty: GameDifficulty(rawValue: game?.difficulty ?? "") ?? .standard,
            palette: GamePalette(rawValue: game?.palette ?? "") ?? .neon,
            targetScore: min(max(game?.targetScore ?? 10, 1), 100),
            levelSeed: min(max(game?.levelSeed ?? 42, 0), 999_999),
            playerName: String(playerName.prefix(30)),
            collectibleName: String(collectibleName.prefix(30)),
            haptics: game?.haptics ?? true
        )
    }

    private func makeDeviceInput(_ deviceInput: DeviceInput?) -> DeviceInputSpec {
        let kind = DeviceInputKind(rawValue: deviceInput?.kind ?? "") ?? .qrCode
        let defaultButton = kind.requiresPhotoCapture ? "Take photo" : "Start scanning"
        let defaultResult = kind.requiresPhotoCapture ? "Captured photo" : "Scanned result"
        return DeviceInputSpec(
            kind: kind,
            buttonLabel: String(nonEmpty(deviceInput?.buttonLabel, fallback: defaultButton).prefix(60)),
            resultLabel: String(nonEmpty(deviceInput?.resultLabel, fallback: defaultResult).prefix(60)),
            allowsRepeat: deviceInput?.allowsRepeat ?? true
        )
    }

    private func makeCapabilities(for pages: [AppPage]) -> [AppCapability] {
        AppCapabilityResolver.requiredCapabilities(for: pages)
            .sorted(by: { $0.rawValue < $1.rawValue })
    }

    private func makeInitialState() -> [String: String] {
        initialState.reduce(into: [:]) { result, entry in
            result[normalizedID(entry.key, fallback: "value")] = String(entry.value.prefix(200))
        }
    }

    private func normalizedID(_ value: String, fallback: String) -> String {
        let allowed = value.lowercased().unicodeScalars.map { scalar -> Character in
            CharacterSet.alphanumerics.contains(scalar) || scalar == "-" ? Character(String(scalar)) : "-"
        }
        let normalized = String(allowed)
            .split(separator: "-", omittingEmptySubsequences: true)
            .joined(separator: "-")
        return normalized.isEmpty ? fallback : String(normalized.prefix(60))
    }

    private func normalizedCurrencyCode(_ value: String, fallback: String) -> String {
        let normalized = value.uppercased().filter(\.isLetter)
        return normalized.count == 3 ? normalized : fallback
    }

    private func normalizedMarketSymbol(_ value: String) -> String? {
        let normalized = value.uppercased().filter { character in
            character.isLetter || character.isNumber || ".-^".contains(character)
        }
        guard (1...15).contains(normalized.count) else { return nil }
        return normalized
    }

    private func normalizedDay(_ value: String) -> String {
        if value.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil {
            return value
        }
        return String(ISO8601DateFormatter().string(from: .now).prefix(10))
    }

    private func nonEmpty(_ value: String?, fallback: String) -> String {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? fallback : trimmed
    }

    private func safeFiniteValue(_ value: Double?) -> Double {
        guard let value, value.isFinite else { return 0 }
        return value
    }

}

extension GeneratedAppPayload {
    static let allowedSymbols: Set<String> = [
        "sparkles", "wand.and.stars", "square.grid.2x2.fill", "checkmark.circle.fill",
        "arrow.left.arrow.right.circle.fill", "globe.asia.australia.fill", "lock.shield.fill",
        "sun.max.fill", "paperplane.fill", "figure.walk", "pencil.line", "hand.raised.fill",
        "drop.fill", "heart.fill", "star.fill", "bell.fill", "bell.badge.fill", "clock.fill",
        "calendar", "chart.bar.fill", "chart.line.uptrend.xyaxis", "list.bullet.clipboard.fill",
        "creditcard.fill", "cart.fill", "fork.knife", "airplane", "tram.fill", "house.fill",
        "person.fill", "briefcase.fill", "book.fill", "graduationcap.fill", "bolt.fill",
        "leaf.fill", "flame.fill", "moon.stars.fill", "camera.fill", "photo.fill",
        "location.fill", "map.fill", "gift.fill", "gamecontroller.fill", "music.note",
        "headphones", "message.fill", "envelope.fill", "phone.fill", "link",
        "externaldrive", "function", "network", "circle.fill", "quote.bubble.fill",
        "photo.badge.plus", "photo.on.rectangle", "party.popper.fill", "iphone",
        "qrcode.viewfinder", "barcode.viewfinder", "text.viewfinder",
        "person.crop.circle.badge.plus", "doc.badge.plus", "figure.walk.motion",
        "square.and.arrow.up", "doc.on.clipboard", "waveform",
        "newspaper.fill", "bookmark.fill", "dollarsign.circle.fill", "chart.xyaxis.line",
        "arrow.up.right", "arrow.down.right", "figure.run", "trophy.fill"
    ]
}
