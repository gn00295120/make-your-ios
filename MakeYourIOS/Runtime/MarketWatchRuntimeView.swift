import SwiftUI

struct MarketWatchRuntimeView: View {
    private struct CachedState: Codable {
        var symbols: [String]
        var quotes: [String: MarketQuote]
        var histories: [String: MarketHistory]
        var lastUpdated: Date?
    }

    let projectID: UUID
    let node: ComponentNode
    let tint: AppTint

    @Environment(\.runtimeDesign) private var design

    @State private var symbols: [String]
    @State private var selectedSymbol: String
    @State private var quotes: [String: MarketQuote] = [:]
    @State private var histories: [String: MarketHistory] = [:]
    @State private var lastUpdated: Date?
    @State private var errorMessage: String?
    @State private var isRefreshing = false
    @State private var hasLoaded = false
    @State private var hasProviderKey = false
    @State private var isAddingSymbol = false
    @State private var isEditingProviderKey = false

    private let client = MarketDataClient()
    private let credentialStore = MarketCredentialStore()
    private let stateStore = ProjectRuntimeStateStore()

    init(projectID: UUID, node: ComponentNode, tint: AppTint) {
        self.projectID = projectID
        self.node = node
        self.tint = tint
        let initialSymbols = Self.normalizedSymbols(node.marketWatch?.initialSymbols ?? ["AAPL"])
        let safeSymbols = initialSymbols.isEmpty ? ["AAPL"] : initialSymbols
        _symbols = State(initialValue: safeSymbols)
        _selectedSymbol = State(initialValue: safeSymbols[0])
    }

    private var spec: MarketWatchSpec {
        node.marketWatch ?? MarketWatchSpec(
            provider: .twelveData,
            initialSymbols: ["AAPL"],
            allowsSymbolEditing: true,
            showsChart: true,
            range: .oneMonth
        )
    }

    private var selectedQuote: MarketQuote? {
        quotes[selectedSymbol]
    }

    private var selectedHistory: MarketHistory? {
        histories[selectedSymbol]
    }

    private var variant: ComponentVariant {
        RendererCatalog.normalizedVariant(node.resolvedPresentation.variant, for: .marketWatch)
    }

    private var contentSpacing: CGFloat {
        [.compact, .dense].contains(variant) ? 10 : design.componentSpacing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: contentSpacing) {
            header
            watchlist
            if spec.showsChart {
                MarketHistoryChart(
                    symbol: selectedSymbol,
                    range: spec.range,
                    quote: selectedQuote,
                    history: selectedHistory,
                    tint: tint,
                    variant: variant,
                    isRefreshing: isRefreshing
                )
            }
            MarketProviderNotice(
                errorMessage: errorMessage,
                hasProviderKey: hasProviderKey,
                selectedQuote: selectedQuote,
                lastUpdated: lastUpdated,
                onAddKey: { isEditingProviderKey = true }
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task {
            guard !hasLoaded else { return }
            hasLoaded = true
            loadCachedState()
            refreshKeyStatus()
            await refresh()
        }
        .sheet(isPresented: $isAddingSymbol) {
            MarketSymbolEditorView(tint: tint) { symbol in
                addSymbol(symbol)
            }
        }
        .sheet(isPresented: $isEditingProviderKey) {
            MarketAPIKeyEditorView(
                hasExistingKey: hasProviderKey,
                tint: tint,
                onChanged: {
                    refreshKeyStatus()
                    Task { await refresh() }
                }
            )
        }
    }
}

extension MarketWatchRuntimeView {
    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(node.title.isEmpty ? "Market watch" : node.title)
                    .font(design.sectionFont)
                    .accessibilityAddTraits(.isHeader)
                if !node.subtitle.isEmpty {
                    Text(node.subtitle)
                        .font(design.captionFont)
                        .foregroundStyle(design.secondaryForeground)
                }
            }
            Spacer()
            Menu {
                Button {
                    Task { await refresh() }
                } label: {
                    Label("Refresh quotes", systemImage: "arrow.clockwise")
                }
                Button {
                    isEditingProviderKey = true
                } label: {
                    Label(
                        hasProviderKey ? "Manage provider key" : "Add provider key",
                        systemImage: "key.fill"
                    )
                }
            } label: {
                if isRefreshing {
                    ProgressView().frame(width: 36, height: 36)
                } else {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .frame(width: 36, height: 36)
                }
            }
            .disabled(isRefreshing)
            .tint(design.accent)
            .accessibilityLabel("Market options")
        }
    }

    @ViewBuilder
    private var watchlist: some View {
        if quotes.isEmpty && isRefreshing {
            HStack {
                Spacer()
                ProgressView("Loading market data…")
                Spacer()
            }
            .padding(.vertical, 20)
        } else {
            VStack(spacing: variant == .cards ? 10 : 0) {
                ForEach(Array(symbols.enumerated()), id: \.element) { index, symbol in
                    MarketQuoteRow(
                        symbol: symbol,
                        quote: quotes[symbol],
                        isSelected: selectedSymbol == symbol,
                        tint: tint,
                        variant: variant,
                        hasProviderKey: hasProviderKey,
                        canRemove: spec.allowsSymbolEditing && symbols.count > 1,
                        onSelect: { selectSymbol(symbol) },
                        onRemove: { removeSymbol(symbol) }
                    )
                    if variant != .cards, index < symbols.count - 1 {
                        Divider().padding(.leading, 48)
                    }
                }

                if spec.allowsSymbolEditing {
                    Button {
                        isAddingSymbol = true
                    } label: {
                        Label("Add symbol", systemImage: "plus.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(design.accent)
                }
            }
        }
    }

    private func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        var firstError: Error?
        var receivedQuote = false
        for symbol in symbols {
            do {
                quotes[symbol] = try await client.quote(symbol: symbol)
                receivedQuote = true
            } catch {
                if firstError == nil { firstError = error }
            }
        }

        if spec.showsChart {
            do {
                histories[selectedSymbol] = try await client.history(
                    symbol: selectedSymbol,
                    range: spec.range
                )
            } catch {
                if firstError == nil { firstError = error }
            }
        }

        if receivedQuote {
            lastUpdated = .now
            errorMessage = firstError.map { "Some data could not be refreshed. \($0.localizedDescription)" }
        } else if let firstError {
            errorMessage = quotes.isEmpty
                ? firstError.localizedDescription
                : "Couldn’t refresh. Showing cached market data."
        }
        persist()
    }

    private func refreshHistory(for symbol: String) async {
        do {
            histories[symbol] = try await client.history(symbol: symbol, range: spec.range)
            errorMessage = nil
            persist()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func selectSymbol(_ symbol: String) {
        selectedSymbol = symbol
        if spec.showsChart, histories[symbol] == nil {
            Task { await refreshHistory(for: symbol) }
        }
    }

    private func addSymbol(_ rawValue: String) {
        guard let symbol = try? MarketDataClient.normalizedSymbol(rawValue),
              symbols.count < 10,
              !symbols.contains(symbol) else {
            return
        }
        symbols.append(symbol)
        selectedSymbol = symbol
        isAddingSymbol = false
        persist()
        Task { await refresh() }
    }

    private func removeSymbol(_ symbol: String) {
        guard symbols.count > 1 else { return }
        symbols.removeAll { $0 == symbol }
        quotes[symbol] = nil
        histories[symbol] = nil
        if selectedSymbol == symbol {
            selectedSymbol = symbols[0]
        }
        persist()
    }

    private func loadCachedState() {
        guard let cached = try? stateStore.load(
            CachedState.self,
            projectID: projectID,
            nodeID: node.id,
            namespace: "market-watch-v1"
        ) else { return }
        let cachedSymbols = Self.normalizedSymbols(cached.symbols)
        if !cachedSymbols.isEmpty {
            symbols = cachedSymbols
            selectedSymbol = cachedSymbols.contains(selectedSymbol) ? selectedSymbol : cachedSymbols[0]
        }
        quotes = cached.quotes
        histories = cached.histories
        lastUpdated = cached.lastUpdated
    }

    private func persist() {
        do {
            try stateStore.save(
                CachedState(
                    symbols: symbols,
                    quotes: quotes,
                    histories: histories,
                    lastUpdated: lastUpdated
                ),
                projectID: projectID,
                nodeID: node.id,
                namespace: "market-watch-v1"
            )
        } catch {
            errorMessage = "Market changes could not be saved."
        }
    }

    private func refreshKeyStatus() {
        let storedKey = try? credentialStore.readAPIKey()
        hasProviderKey = storedKey?.isEmpty == false
    }

    private static func normalizedSymbols(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.compactMap { try? MarketDataClient.normalizedSymbol($0) }
            .filter { seen.insert($0).inserted }
            .prefix(10)
            .map { $0 }
    }
}
