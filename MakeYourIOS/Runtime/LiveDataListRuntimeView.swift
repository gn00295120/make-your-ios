import SwiftUI

struct LiveDataListRuntimeView: View {
    struct RateRule: Codable, Hashable {
        var target: Double
        var direction: RateThresholdDirection
        var isEnabled: Bool
        var hasTriggered: Bool
    }

    struct WatchState: Codable, Hashable {
        var base: String
        var symbols: [String]
        var rules: [String: RateRule]
        var snapshot: ExchangeRateSnapshot?
    }

    struct SelectedSymbol: Identifiable {
        var code: String
        var id: String { code }
    }

    struct RuntimeAlert: Identifiable {
        var id = UUID()
        var title: String
        var message: String
    }

    let projectID: UUID
    let node: ComponentNode
    let tint: AppTint

    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @State var watchState: WatchState
    @State var currencies: [CurrencyDescriptor] = []
    @State var isRefreshing = false
    @State var errorMessage: String?
    @State var showingCurrencyPicker = false
    @State var selectedAlertSymbol: SelectedSymbol?
    @State var runtimeAlert: RuntimeAlert?
    @State var hasLoaded = false

    let client = ExchangeRateClient()
    let stateStore = ProjectRuntimeStateStore()

    init(projectID: UUID, node: ComponentNode, tint: AppTint) {
        self.projectID = projectID
        self.node = node
        self.tint = tint
        let liveData = node.liveData
        _watchState = State(
            initialValue: WatchState(
                base: liveData?.primaryValue.uppercased() ?? "USD",
                symbols: Self.normalizedSymbols(liveData?.initialSymbols ?? ["TWD", "JPY", "EUR"]),
                rules: [:],
                snapshot: nil
            )
        )
    }

    var spec: LiveDataListSpec {
        node.liveData ?? LiveDataListSpec(
            resource: .exchangeRates,
            primaryValue: "USD",
            initialSymbols: ["TWD", "JPY", "EUR"],
            allowsPrimarySelection: true,
            allowsItemEditing: true,
            allowsThresholds: true
        )
    }

    var availableCurrencies: [CurrencyDescriptor] {
        currencies.isEmpty ? Self.fallbackCurrencies : currencies
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            statusBar
            ratesList
            providerNote
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task {
            guard !hasLoaded else { return }
            hasLoaded = true
            load()
            async let refreshTask: Void = refresh()
            async let currenciesTask: Void = loadCurrencies()
            _ = await (refreshTask, currenciesTask)
        }
        .sheet(isPresented: $showingCurrencyPicker) {
            CurrencyPickerSheet(
                currencies: availableCurrencies,
                excluded: Set(watchState.symbols + [watchState.base]),
                tint: tint,
                onAdd: addSymbol
            )
        }
        .sheet(item: $selectedAlertSymbol) { selection in
            RateAlertEditor(
                base: watchState.base,
                quote: selection.code,
                currentRate: watchState.snapshot?.rates[selection.code],
                existing: watchState.rules[selection.code].map {
                    RateAlertDraft(
                        target: String($0.target),
                        direction: $0.direction,
                        isEnabled: $0.isEnabled
                    )
                },
                tint: tint,
                onSave: { draft in saveRule(draft, for: selection.code) },
                onDelete: watchState.rules[selection.code] == nil
                    ? nil
                    : { deleteRule(for: selection.code) },
                onTest: { draft in testAlertMessage(draft, for: selection.code) }
            )
        }
        .alert(item: $runtimeAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

}
