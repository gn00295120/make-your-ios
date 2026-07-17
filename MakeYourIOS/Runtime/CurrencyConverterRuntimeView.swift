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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(node.title).font(.headline)
                if !node.subtitle.isEmpty {
                    Text(node.subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 12) {
                HStack {
                    TextField("Amount", text: $amount)
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                        .keyboardType(.decimalPad)
                    CurrencyMenu(selection: $fromCurrency, currencies: currencies)
                }
                .padding(14)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 15, style: .continuous))

                Button {
                    withAnimation(.snappy) {
                        swap(&fromCurrency, &toCurrency)
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.subheadline.bold())
                        .foregroundStyle(tint.color)
                        .frame(width: 38, height: 38)
                        .background(tint.color.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Swap currencies")
                .padding(.vertical, -7)
                .zIndex(1)

                HStack {
                    Text(convertedAmount, format: .number.precision(.fractionLength(2)))
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                        .contentTransition(.numericText())
                    Spacer()
                    CurrencyMenu(selection: $toCurrency, currencies: currencies)
                }
                .padding(14)
                .background(
                    tint.color.opacity(0.10),
                    in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                )
            }

            Text(
                "1 \(fromCurrency) = "
                    + exchangeRate.formatted(.number.precision(.fractionLength(2...4)))
                    + " \(toCurrency)"
            )
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .onAppear {
            if !currencies.contains(fromCurrency) { fromCurrency = currencies.first ?? "USD" }
            if !currencies.contains(toCurrency) {
                toCurrency = currencies.dropFirst().first ?? currencies.first ?? "TWD"
            }
        }
    }
}

private struct CurrencyMenu: View {
    @Binding var selection: String
    let currencies: [String]

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
            .foregroundStyle(.primary)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(.background, in: Capsule())
        }
    }
}
