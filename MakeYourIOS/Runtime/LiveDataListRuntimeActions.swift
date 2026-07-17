import Foundation

extension LiveDataListRuntimeView {
    func load() {
        do {
            if let saved = try stateStore.load(
                WatchState.self,
                projectID: projectID,
                nodeID: node.id,
                namespace: "live-data"
            ) {
                watchState = saved
            }
        } catch {
            errorMessage = "Saved watchlist could not be read."
        }
    }

    func loadCurrencies() async {
        do {
            currencies = try await client.currencies()
        } catch {
            if currencies.isEmpty { currencies = Self.fallbackCurrencies }
        }
    }

    func refresh() async {
        guard !watchState.symbols.isEmpty else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let snapshot = try await client.latest(
                base: watchState.base,
                quotes: watchState.symbols
            )
            watchState.snapshot = snapshot
            errorMessage = nil
            evaluateRules(snapshot)
            persist()
        } catch {
            errorMessage = watchState.snapshot == nil
                ? error.localizedDescription
                : "Couldn’t refresh. Showing the last saved rates."
        }
    }

    func selectBase(_ newBase: String) {
        let normalized = newBase.uppercased()
        guard normalized != watchState.base else { return }
        let previousBase = watchState.base
        watchState.base = normalized
        watchState.symbols.removeAll { $0 == normalized }
        if previousBase != normalized, !watchState.symbols.contains(previousBase) {
            watchState.symbols.append(previousBase)
        }
        watchState.rules = [:]
        watchState.snapshot = nil
        persist()
        Task { await refresh() }
    }

    func addSymbol(_ code: String) {
        let normalized = code.uppercased()
        guard normalized != watchState.base, !watchState.symbols.contains(normalized) else { return }
        watchState.symbols.append(normalized)
        showingCurrencyPicker = false
        persist()
        Task { await refresh() }
    }

    func removeSymbol(_ symbol: String) {
        watchState.symbols.removeAll { $0 == symbol }
        watchState.rules[symbol] = nil
        watchState.snapshot?.rates[symbol] = nil
        persist()
    }

    func saveRule(_ draft: RateAlertDraft, for symbol: String) {
        guard let target = draft.targetValue, target > 0 else { return }
        watchState.rules[symbol] = RateRule(
            target: target,
            direction: draft.direction,
            isEnabled: draft.isEnabled,
            hasTriggered: false
        )
        selectedAlertSymbol = nil
        persist()
    }

    func deleteRule(for symbol: String) {
        watchState.rules[symbol] = nil
        selectedAlertSymbol = nil
        persist()
    }

    func testAlertMessage(_ draft: RateAlertDraft, for symbol: String) -> String {
        let target = draft.targetValue ?? watchState.snapshot?.rates[symbol] ?? 0
        return alertMessage(symbol: symbol, target: target, direction: draft.direction)
    }

    func evaluateRules(_ snapshot: ExchangeRateSnapshot) {
        for symbol in watchState.symbols {
            guard var rule = watchState.rules[symbol],
                  rule.isEnabled,
                  let rate = snapshot.rates[symbol],
                  RateThresholdEvaluator.isMet(
                      rate: rate,
                      target: rule.target,
                      direction: rule.direction
                  ) else {
                continue
            }
            rule.hasTriggered = true
            rule.isEnabled = false
            watchState.rules[symbol] = rule
            if runtimeAlert == nil {
                runtimeAlert = RuntimeAlert(
                    title: "Rate target reached",
                    message: "1 \(watchState.base) is now \(formattedRate(rate)) \(symbol). "
                        + alertMessage(symbol: symbol, target: rule.target, direction: rule.direction)
                )
            }
        }
    }

    func persist() {
        do {
            try stateStore.save(
                watchState,
                projectID: projectID,
                nodeID: node.id,
                namespace: "live-data"
            )
        } catch {
            errorMessage = "Watchlist changes could not be saved."
        }
    }

    func currencyName(_ code: String) -> String {
        availableCurrencies.first(where: { $0.code == code })?.name
            ?? Locale.current.localizedString(forCurrencyCode: code)
            ?? code
    }

    func ruleSummary(_ rule: RateRule, symbol: String) -> String {
        if rule.hasTriggered { return "Target reached · tap to re-enable" }
        let comparison = rule.direction == .atOrBelow ? "≤" : "≥"
        return "Alert \(comparison) \(formattedRate(rule.target)) \(symbol)"
            + (rule.isEnabled ? "" : " · paused")
    }

    func alertSymbol(_ rule: RateRule?) -> String {
        if rule?.hasTriggered == true { return "bell.badge.fill" }
        return rule?.isEnabled == true ? "bell.fill" : "bell"
    }

    func alertMessage(
        symbol: String,
        target: Double,
        direction: RateThresholdDirection
    ) -> String {
        let condition = direction == .atOrBelow ? "at or below" : "at or above"
        return "Alert when 1 \(watchState.base) is \(condition) "
            + "\(formattedRate(target)) \(symbol)."
    }

    func formattedRate(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2...6)))
    }

    static func normalizedSymbols(_ symbols: [String]) -> [String] {
        var seen = Set<String>()
        return symbols.compactMap { value in
            let code = value.uppercased()
            guard code.count == 3, seen.insert(code).inserted else { return nil }
            return code
        }
    }

    static let fallbackCurrencies: [CurrencyDescriptor] = [
        "AUD", "BRL", "CAD", "CHF", "CNY", "CZK", "DKK", "EUR", "GBP", "HKD",
        "HUF", "IDR", "ILS", "INR", "ISK", "JPY", "KRW", "MXN", "MYR", "NOK",
        "NZD", "PHP", "PLN", "RON", "SEK", "SGD", "THB", "TRY", "TWD", "USD", "ZAR"
    ].map { code in
        CurrencyDescriptor(
            code: code,
            name: Locale.current.localizedString(forCurrencyCode: code) ?? code,
            symbol: ""
        )
    }
}
