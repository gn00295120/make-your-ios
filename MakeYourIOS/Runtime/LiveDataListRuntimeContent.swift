import SwiftUI

extension LiveDataListRuntimeView {
    var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(node.title)
                    .font(design.sectionFont)
                    .accessibilityAddTraits(.isHeader)
                if !node.subtitle.isEmpty {
                    Text(node.subtitle)
                        .font(design.captionFont)
                        .foregroundStyle(design.secondaryForeground)
                }
            }
            Spacer()
            if spec.allowsItemEditing {
                Button { showingCurrencyPicker = true } label: {
                    Image(systemName: "plus")
                        .font(.subheadline.bold())
                        .foregroundStyle(design.accent)
                        .frame(width: 44, height: 44)
                        .background(
                            design.accent.opacity(0.12),
                            in: RoundedRectangle(
                                cornerRadius: design.controlCornerRadius,
                                style: .continuous
                            )
                        )
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
                        .font(.system(
                            .subheadline,
                            design: design.theme.typography.fontDesign,
                            weight: .bold
                        ))
                        .foregroundStyle(design.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(
                            design.accent.opacity(0.12),
                            in: RoundedRectangle(
                                cornerRadius: design.controlCornerRadius,
                                style: .continuous
                            )
                        )
                }
                .accessibilityLabel("Primary currency, \(watchState.base)")
            } else {
                Label(watchState.base, systemImage: "globe")
                    .font(.subheadline.bold())
                    .foregroundStyle(design.accent)
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
            .tint(design.accent)
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
            VStack(spacing: variant == .cards ? 9 : 0) {
                ForEach(Array(watchState.symbols.enumerated()), id: \.element) { index, symbol in
                    rateRow(symbol)
                    if variant != .cards, index < watchState.symbols.count - 1 {
                        Divider().padding(.leading, 50)
                    }
                }
            }
        }
    }

    var providerNote: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(design.warning)
            }
            HStack(spacing: 5) {
                Image(systemName: "clock")
                if let snapshot = watchState.snapshot {
                    Text("Latest reference rates · \(snapshot.asOf) · Frankfurter")
                } else {
                    Text("Latest daily reference rates · Frankfurter")
                }
            }
            .font(design.captionFont)
            .foregroundStyle(design.secondaryForeground)
        }
    }

    private func rateRow(_ symbol: String) -> some View {
        let rate = watchState.snapshot?.rates[symbol]
        let rule = watchState.rules[symbol]
        return HStack(alignment: .center, spacing: 11) {
            currencyBadge(symbol)
            adaptiveRateContent(symbol: symbol, rate: rate, rule: rule)
            alertButton(symbol: symbol, rule: rule)
            removeButton(symbol)
        }
        .padding(.vertical, variant == .dense ? 1 : 6)
        .padding(.horizontal, variant == .cards ? 12 : 0)
        .background { rateRowBackground }
        .accessibilityElement(children: dynamicTypeSize.isAccessibilitySize ? .contain : .contain)
    }

    private func currencyBadge(_ symbol: String) -> some View {
        Text(symbol)
            .font(.caption.bold().monospaced())
            .foregroundStyle(design.accent)
            .frame(width: 42, height: 42)
            .background(
                design.accent.opacity(0.11),
                in: RoundedRectangle(
                    cornerRadius: design.controlCornerRadius,
                    style: .continuous
                )
            )
    }

    private func adaptiveRateContent(
        symbol: String,
        rate: Double?,
        rule: RateRule?
    ) -> some View {
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
    }

    @ViewBuilder
    private func alertButton(symbol: String, rule: RateRule?) -> some View {
        if spec.allowsThresholds {
            Button {
                selectedAlertSymbol = SelectedSymbol(code: symbol)
            } label: {
                Image(systemName: alertSymbol(rule))
                    .foregroundStyle(
                        rule?.isEnabled == true ? design.accent : design.secondaryForeground
                    )
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Set rate alert for \(symbol)")
        }
    }

    @ViewBuilder
    private func removeButton(_ symbol: String) -> some View {
        if spec.allowsItemEditing {
            Button { removeSymbol(symbol) } label: {
                Image(systemName: "minus.circle")
                    .foregroundStyle(design.secondaryForeground)
                    .frame(width: 32, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(symbol)")
        }
    }

    @ViewBuilder
    private var rateRowBackground: some View {
        if variant == .cards {
            RoundedRectangle(cornerRadius: design.compactCornerRadius, style: .continuous)
                .fill(design.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: design.compactCornerRadius, style: .continuous)
                        .stroke(
                            design.borderColor.opacity(design.borderOpacity),
                            lineWidth: design.borderWidth
                        )
                }
        }
    }

    private func rateDetails(symbol: String, rate: Double?, rule: RateRule?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(currencyName(symbol))
                .font(.system(
                    .subheadline,
                    design: design.theme.typography.fontDesign,
                    weight: .semibold
                ))
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
            if let rule {
                Text(ruleSummary(rule, symbol: symbol))
                    .font(.caption2)
                    .foregroundStyle(
                        rule.hasTriggered ? design.accent : design.secondaryForeground
                    )
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
            } else {
                Text("1 \(watchState.base) in \(symbol)")
                    .font(.caption2)
                    .foregroundStyle(design.secondaryForeground)
            }
        }
    }

    private func rateValue(symbol: String, rate: Double?) -> some View {
        Group {
            if let rate {
                Text(rate, format: .number.precision(.fractionLength(2...6)))
                    .foregroundStyle(design.accent)
            } else {
                Text("—").foregroundStyle(design.secondaryForeground)
            }
        }
        .font(.system(
            .headline,
            design: design.theme.typography.fontDesign,
            weight: .bold
        ).monospacedDigit())
        .contentTransition(design.reduceMotion ? .identity : .numericText())
        .accessibilityLabel(rate.map { "Current rate \($0) \(symbol)" } ?? "Rate unavailable")
    }
}
