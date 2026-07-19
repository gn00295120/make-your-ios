import Foundation

struct GeneratedAppPayload: Codable {
    var name: String
    var summary: String
    var symbol: String
    var tint: String
    var theme: Theme
    var capabilities: [String]
    var startPageID: String
    var initialState: [StateEntry]
    var logic: Logic?
    var pages: [Page]

    func makeDocument(existingID: UUID, version: Int) -> AppDocument {
        let documentPages = makePages()
        let documentTheme = makeTheme()
        let safeStartPageID = documentPages.contains(where: { $0.id == startPageID })
            ? startPageID
            : documentPages.first?.id ?? "home"

        var document = AppDocument(
            id: existingID,
            name: String(name.prefix(48)),
            summary: String(summary.prefix(240)),
            symbol: Self.allowedSymbols.contains(symbol) ? symbol : "square.grid.2x2.fill",
            tint: AppTint(rawValue: tint) ?? .indigo,
            version: version,
            updatedAt: .now,
            startPageID: safeStartPageID,
            capabilities: [],
            initialState: makeInitialState(),
            logic: makeLogic(),
            theme: documentTheme,
            pages: documentPages.isEmpty ? SampleDocuments.blank.pages : documentPages
        )
        document.capabilities = AppCapabilityResolver.requiredCapabilities(for: document)
            .sorted(by: { $0.rawValue < $1.rawValue })
        return document
    }

    private func makePages() -> [AppPage] {
        pages.prefix(AppDocumentValidator.maximumPages).enumerated().map { pageIndex, page in
            let pageID = normalizedID(page.id, fallback: "page-\(pageIndex + 1)")
            let nodes = page.nodes.prefix(20).enumerated().map { nodeIndex, node in
                makeNode(node, pageID: pageID, nodeIndex: nodeIndex)
            }
            return AppPage(
                id: pageID,
                title: String(page.title.prefix(60)),
                nodes: nodes,
                presentation: PagePresentation(
                    layout: PageLayout(rawValue: page.presentation.layout) ?? .flow,
                    showsNavigationTitle: page.presentation.showsNavigationTitle,
                    navigationStyle: PageNavigationStyle(
                        rawValue: page.presentation.navigationStyle
                    ) ?? .automatic
                )
            )
        }
    }
}

private extension GeneratedAppPayload {
    private func makeNode(_ node: Node, pageID: String, nodeIndex: Int) -> ComponentNode {
        let kind = ComponentKind(rawValue: node.kind) ?? .text
        return ComponentNode(
            id: normalizedID(node.id, fallback: "\(pageID)-node-\(nodeIndex + 1)"),
            kind: kind,
            title: String(node.title.prefix(120)),
            subtitle: String(node.subtitle.prefix(320)),
            symbol: Self.allowedSymbols.contains(node.symbol) ? node.symbol : "sparkles",
            value: kind == .shortcutAccess ? "" : String(node.value.prefix(800)),
            placeholder: kind == .shortcutAccess ? "" : String(node.placeholder.prefix(160)),
            binding: kind == .shortcutAccess ? "" : normalizedID(
                node.binding,
                fallback: "value-\(nodeIndex + 1)"
            ),
            options: kind == .shortcutAccess ? [] : Array(node.options.prefix(20)).map {
                String($0.prefix(40))
            },
            items: kind == .shortcutAccess ? [] : makeItems(
                node.items,
                pageID: pageID,
                nodeIndex: nodeIndex,
                kind: kind
            ),
            action: kind == .shortcutAccess
                ? .none
                : RuntimeAction(
                    type: RuntimeActionType(rawValue: node.action.type) ?? .none,
                    target: normalizedID(node.action.target, fallback: ""),
                    value: String(node.action.value.prefix(240))
                ),
            valueBinding: kind == .shortcutAccess ? nil : normalizedOptionalID(node.valueBinding),
            events: kind == .shortcutAccess ? [] : makeEvents(node.events),
            control: kind == .control ? makeControl(node.control) : nil,
            presentation: makePresentation(node.presentation, for: kind),
            image: makeImage(node.image, for: kind, fallbackTitle: node.title),
            collection: kind == .recordCollection ? makeCollection(node.collection) : nil,
            liveData: kind == .liveDataList ? makeLiveData(node.liveData) : nil,
            newsFeed: kind == .newsFeed ? makeNewsFeed(node.newsFeed) : nil,
            marketWatch: kind == .marketWatch ? makeMarketWatch(node.marketWatch) : nil,
            ledger: kind == .ledger ? makeLedger(node.ledger) : nil,
            game: kind == .game ? makeGame(node.game) : nil,
            deviceInput: kind == .deviceInput ? makeDeviceInput(node.deviceInput) : nil,
            map: kind == .map ? makeMap(node.map) : nil,
            calendarEvent: kind == .calendarEvent ? makeCalendarEvent(node.calendarEvent) : nil,
            documentExport: kind == .documentExport ? makeDocumentExport(node.documentExport) : nil,
            voiceNote: kind == .voiceNote ? makeVoiceNote(node.voiceNote) : nil,
            speechTranscript: kind == .speechTranscript
                ? makeSpeechTranscript(node.speechTranscript)
                : nil
        )
    }

    private func makeItems(
        _ items: [Item],
        pageID: String,
        nodeIndex: Int,
        kind: ComponentKind
    ) -> [ComponentItem] {
        items.prefix(30).enumerated().map { itemIndex, item in
            let generatedID = "\(pageID)-node-\(nodeIndex + 1)-item-\(itemIndex + 1)"
            let titleCurrencyCode = normalizedCurrencyCode(item.title, fallback: "")
            let itemID = kind == .currencyConverter
                ? normalizedCurrencyCode(
                    item.id,
                    fallback: titleCurrencyCode.isEmpty ? generatedID : titleCurrencyCode
                )
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
        let supportsCompactSpan: Set<ComponentKind> = [
            .text, .metric, .infoBanner, .image, .control, .collectionView,
            .calendarEvent, .documentExport, .voiceNote, .speechTranscript, .button
        ]
        return ComponentPresentation(
            surface: ComponentSurface(rawValue: design.surface) ?? .automatic,
            span: supportsCompactSpan.contains(kind) ? requestedSpan : .full,
            alignment: ComponentAlignment(rawValue: design.alignment) ?? .leading,
            emphasis: ComponentEmphasis(rawValue: design.emphasis) ?? .regular,
            variant: RendererCatalog.normalizedVariant(
                ComponentVariant(rawValue: design.variant) ?? .automatic,
                for: kind
            )
        )
    }

    private func makeImage(
        _ image: Image?,
        for kind: ComponentKind,
        fallbackTitle: String
    ) -> ImageSpec? {
        guard kind == .image || kind == .hero else { return nil }
        guard let image else {
            return kind == .image ? .editableLandscape : nil
        }
        let fallbackAltText = fallbackTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let altText = image.altText.isEmpty
            ? (fallbackAltText.isEmpty ? "User-selected image" : fallbackAltText)
            : image.altText
        let defaultRole: MediaRole = kind == .hero ? .hero : .content
        let role = MediaRole(rawValue: image.mediaRole) ?? defaultRole
        return ImageSpec(
            aspect: ImageAspect(rawValue: image.aspect) ?? .landscape,
            contentMode: ImageContentMode(rawValue: image.contentMode) ?? .fill,
            altText: String(altText.prefix(180)),
            decorative: image.decorative || role == .decorative,
            allowsUserSelection: image.allowsUserSelection,
            mediaRole: role,
            focalPoint: ImageFocalPoint(rawValue: image.focalPoint) ?? .center,
            mask: ImageMask(rawValue: image.mask) ?? .rounded,
            overlay: ImageOverlay(rawValue: image.overlay) ?? ImageOverlay.none
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
        let kind = GameKind(rawValue: game?.kind ?? "") ?? .snake
        return GameSpec(
            kind: kind,
            difficulty: GameDifficulty(rawValue: game?.difficulty ?? "") ?? .standard,
            palette: GamePalette(rawValue: game?.palette ?? "") ?? .neon,
            targetScore: min(max(game?.targetScore ?? 10, 1), 100),
            levelSeed: min(max(game?.levelSeed ?? 42, 0), 999_999),
            playerName: String(playerName.prefix(30)),
            collectibleName: String(collectibleName.prefix(30)),
            haptics: game?.haptics ?? true,
            program: kind == .custom ? game?.program : nil
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

    private func makeMap(_ map: Map?) -> RuntimeMapSpec {
        RuntimeMapSpec(
            mode: RuntimeMapMode(rawValue: map?.mode ?? "") ?? .coordinate,
            query: String((map?.query ?? "").trimmingCharacters(in: .whitespacesAndNewlines).prefix(120)),
            latitude: min(max(safeFiniteValue(map?.latitude), -90), 90),
            longitude: min(max(safeFiniteValue(map?.longitude), -180), 180),
            spanMeters: min(max(safeFiniteValue(map?.spanMeters), 250), 100_000),
            allowsSearch: map?.allowsSearch ?? false,
            allowsDirections: map?.allowsDirections ?? false
        )
    }

    private func makeCalendarEvent(_ event: CalendarEvent?) -> RuntimeCalendarEventSpec {
        RuntimeCalendarEventSpec(
            eventTitle: String(nonEmpty(event?.eventTitle, fallback: "New event").prefix(120)),
            notes: String((event?.notes ?? "").prefix(500)),
            location: String((event?.location ?? "").prefix(160)),
            startOffsetMinutes: min(max(event?.startOffsetMinutes ?? 60, 0), 10_080),
            durationMinutes: min(max(event?.durationMinutes ?? 60, 5), 1_440),
            allowsEditing: event?.allowsEditing ?? true
        )
    }

    private func makeDocumentExport(_ export: DocumentExport?) -> RuntimeDocumentExportSpec {
        let requestedName = export?.fileName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let fileName = requestedName.isEmpty ? "MakeYour Export" : requestedName
        let format = RuntimeDocumentFormat(rawValue: export?.format ?? "") ?? .plainText
        let requestedContent = export?.contentTemplate ?? ""
        return RuntimeDocumentExportSpec(
            fileName: RuntimeDocumentExportCodec.normalizedFileName(
                String(fileName.prefix(80)),
                format: format
            ),
            format: format,
            contentTemplate: String(nonEmpty(
                requestedContent,
                fallback: "Export created in MakeYour."
            ).prefix(2_000)),
            buttonLabel: String(nonEmpty(export?.buttonLabel, fallback: "Export").prefix(60))
        )
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

}
