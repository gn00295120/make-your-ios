import SwiftUI

struct CurrencyCalculator: Sendable {
    static func convert(
        amount: Double,
        from source: String,
        to destination: String,
        rates: [String: Double]
    ) -> Double {
        let sourceRate = rates[source] ?? 1
        let destinationRate = rates[destination] ?? 1
        guard sourceRate != 0 else { return 0 }
        return amount / sourceRate * destinationRate
    }
}

struct CurrencyConverterRuntimeView: View {
    let node: ComponentNode
    let tint: AppTint

    @Environment(\.runtimeDesign) private var design

    @State private var amount = "100"
    @State private var fromCurrency = "USD"
    @State private var toCurrency = "TWD"

    private var currencies: [String] {
        node.options.isEmpty ? ["USD", "TWD"] : node.options
    }

    private var rates: [String: Double] {
        Dictionary(uniqueKeysWithValues: node.items.compactMap { item in
            guard let rate = Double(item.value) else { return nil }
            return (item.id, rate)
        })
    }

    private var convertedAmount: Double {
        let input = Double(amount.replacingOccurrences(of: ",", with: "")) ?? 0
        return CurrencyCalculator.convert(
            amount: input,
            from: fromCurrency,
            to: toCurrency,
            rates: rates
        )
    }

    private var exchangeRate: Double {
        (rates[toCurrency] ?? 1) / (rates[fromCurrency] ?? 1)
    }

    private var variant: ComponentVariant {
        RendererCatalog.normalizedVariant(node.resolvedPresentation.variant, for: .currencyConverter)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: [.compact, .dense].contains(variant) ? 10 : 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(node.title).font(design.sectionFont).accessibilityAddTraits(.isHeader)
                if !node.subtitle.isEmpty {
                    Text(node.subtitle).font(design.captionFont).foregroundStyle(design.secondaryForeground)
                }
            }

            if variant == .split {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        amountField
                        swapButton
                        resultField
                    }
                    stackedFields
                }
            } else {
                stackedFields
            }

            Text(
                "1 \(fromCurrency) = "
                    + exchangeRate.formatted(.number.precision(.fractionLength(2...4)))
                    + " \(toCurrency)"
            )
                .font(design.captionFont)
                .foregroundStyle(design.secondaryForeground)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .onAppear {
            if !currencies.contains(fromCurrency) { fromCurrency = currencies.first ?? "USD" }
            if !currencies.contains(toCurrency) {
                toCurrency = currencies.dropFirst().first ?? currencies.first ?? "TWD"
            }
        }
    }

    private var stackedFields: some View {
        VStack(spacing: 12) {
            amountField
            swapButton
                .padding(.vertical, -7)
                .zIndex(1)
            resultField
        }
    }

    private var amountField: some View {
        HStack {
            TextField("Amount", text: $amount)
                .font(design.titleFont.monospacedDigit())
                .keyboardType(.decimalPad)
                .accessibilityLabel("Amount")
            CurrencyMenu(selection: $fromCurrency, currencies: currencies)
        }
        .padding(fieldPadding)
        .background(design.surface, in: fieldShape)
        .overlay { fieldBorder }
    }

    private var resultField: some View {
        HStack {
            Text(convertedAmount, format: .number.precision(.fractionLength(2)))
                .font(design.titleFont.monospacedDigit())
                .contentTransition(design.reduceMotion ? .identity : .numericText())
            Spacer()
            CurrencyMenu(selection: $toCurrency, currencies: currencies)
        }
        .padding(fieldPadding)
        .background(design.accent.opacity(0.10), in: fieldShape)
        .overlay { fieldBorder }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Converted amount")
    }

    private var swapButton: some View {
        Button {
            design.animate { swap(&fromCurrency, &toCurrency) }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.subheadline.bold())
                .foregroundStyle(design.accent)
                .frame(width: 44, height: 44)
                .background(design.accent.opacity(0.12), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Swap currencies")
    }

    private var fieldPadding: CGFloat {
        [.compact, .dense].contains(variant) ? 10 : 14
    }

    private var fieldShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: design.controlCornerRadius, style: .continuous)
    }

    private var fieldBorder: some View {
        fieldShape.stroke(
            design.borderColor.opacity(design.borderOpacity),
            lineWidth: design.borderWidth
        )
    }
}

private struct CurrencyMenu: View {
    @Binding var selection: String
    let currencies: [String]

    @Environment(\.runtimeDesign) private var design

    var body: some View {
        Menu {
            ForEach(currencies, id: \.self) { currency in
                Button(currency) { selection = currency }
            }
        } label: {
            HStack(spacing: 5) {
                Text(selection).font(.subheadline.bold())
                Image(systemName: "chevron.up.chevron.down").font(.caption2)
            }
            .foregroundStyle(design.primaryForeground)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(design.surface, in: Capsule())
        }
    }
}
