import SwiftUI

extension LiveDataListRuntimeView {
    var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(node.title).font(.headline)
                if !node.subtitle.isEmpty {
                    Text(node.subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if spec.allowsItemEditing {
                Button { showingCurrencyPicker = true } label: {
                    Image(systemName: "plus")
                        .font(.subheadline.bold())
                        .frame(width: 44, height: 44)
                        .background(tint.color.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add currency")
            }
        }
    }

    var statusBar: some View {
        HStack(spacing: 10) {
            if spec.allowsPrimarySelection {
                Menu {
                    ForEach(availableCurrencies) { currency in
                        Button {
                            selectBase(currency.code)
                        } label: {
                            if currency.code == watchState.base {
                                Label("\(currency.code) · \(currency.name)", systemImage: "checkmark")
                            } else {
                                Text("\(currency.code) · \(currency.name)")
                            }
                        }
                    }
                } label: {
                    Label(watchState.base, systemImage: "globe")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(tint.color.opacity(0.12), in: Capsule())
                }
                .accessibilityLabel("Primary currency, \(watchState.base)")
            } else {
                Label(watchState.base, systemImage: "globe").font(.subheadline.bold())
            }

            Spacer()

            Button {
                Task { await refresh() }
            } label: {
                if isRefreshing {
                    ProgressView().frame(width: 36, height: 36)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 36, height: 36)
                }
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .disabled(isRefreshing || watchState.symbols.isEmpty)
            .accessibilityLabel("Refresh exchange rates")
        }
    }

    @ViewBuilder
    var ratesList: some View {
        if watchState.symbols.isEmpty {
            ContentUnavailableView(
                "No currencies yet",
                systemImage: "coloncurrencysign",
                description: Text("Add a currency to compare it with \(watchState.base).")
            )
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(watchState.symbols.enumerated()), id: \.element) { index, symbol in
                    rateRow(symbol)
                    if index < watchState.symbols.count - 1 { Divider().padding(.leading, 50) }
                }
            }
        }
    }

    var providerNote: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            HStack(spacing: 5) {
                Image(systemName: "clock")
                if let snapshot = watchState.snapshot {
                    Text("Latest reference rates · \(snapshot.asOf) · Frankfurter")
                } else {
                    Text("Latest daily reference rates · Frankfurter")
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    private func rateRow(_ symbol: String) -> some View {
        let rate = watchState.snapshot?.rates[symbol]
        let rule = watchState.rules[symbol]
        return HStack(alignment: .center, spacing: 11) {
            Text(symbol)
                .font(.caption.bold().monospaced())
                .foregroundStyle(tint.color)
                .frame(width: 42, height: 42)
                .background(tint.color.opacity(0.11), in: Circle())

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 10) {
                    rateDetails(symbol: symbol, rate: rate, rule: rule)
                    Spacer(minLength: 8)
                    rateValue(symbol: symbol, rate: rate)
                }
                VStack(alignment: .leading, spacing: 5) {
                    rateDetails(symbol: symbol, rate: rate, rule: rule)
                    rateValue(symbol: symbol, rate: rate)
                }
            }

            if spec.allowsThresholds {
                Button {
                    selectedAlertSymbol = SelectedSymbol(code: symbol)
                } label: {
                    Image(systemName: alertSymbol(rule))
                        .foregroundStyle(rule?.isEnabled == true ? tint.color : Color.secondary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Set rate alert for \(symbol)")
            }

            if spec.allowsItemEditing {
                Button { removeSymbol(symbol) } label: {
                    Image(systemName: "minus.circle")
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(symbol)")
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: dynamicTypeSize.isAccessibilitySize ? .contain : .contain)
    }

    private func rateDetails(symbol: String, rate: Double?, rule: RateRule?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(currencyName(symbol))
                .font(.subheadline.weight(.semibold))
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
            if let rule {
                Text(ruleSummary(rule, symbol: symbol))
                    .font(.caption2)
                    .foregroundStyle(rule.hasTriggered ? tint.color : Color.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
            } else {
                Text("1 \(watchState.base) in \(symbol)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func rateValue(symbol: String, rate: Double?) -> some View {
        Group {
            if let rate {
                Text(rate, format: .number.precision(.fractionLength(2...6)))
                    .contentTransition(.numericText())
            } else {
                Text("—").foregroundStyle(.secondary)
            }
        }
        .font(.headline.monospacedDigit())
        .accessibilityLabel(rate.map { "Current rate \($0) \(symbol)" } ?? "Rate unavailable")
    }
}
