import SwiftUI

struct CurrencyCalculator: Sendable {
    private static let isoCurrencyCodes = Set(
        Locale.Currency.isoCurrencies.map(\.identifier)
    )

    static func normalizedCurrencyCodes(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.compactMap { value in
            let code = normalizedCurrencyCode(value)
            guard !code.isEmpty, seen.insert(code).inserted else { return nil }
            return code
        }
    }

    static func rateTable(
        items: [ComponentItem],
        currencies: [String]
    ) -> [String: Double] {
        let allowedCodes = Set(normalizedCurrencyCodes(currencies))

        return items.reduce(into: [:]) { result, item in
            guard let rate = Double(item.value), rate.isFinite, rate > 0 else { return }

            let code = [item.id, item.title]
                .map(normalizedCurrencyCode)
                .first(where: allowedCodes.contains)
            guard let code, result[code] == nil else { return }
            result[code] = rate
        }
    }

    static func preferredPair(
        currencies: [String],
        source: String,
        destination: String
    ) -> (source: String, destination: String) {
        let available = normalizedCurrencyCodes(currencies)
        let resolvedSource = available.contains(source) ? source : available.first ?? "USD"
        let resolvedDestination = available.contains(destination) && destination != resolvedSource
            ? destination
            : available.first(where: { $0 != resolvedSource }) ?? resolvedSource
        return (resolvedSource, resolvedDestination)
    }

    static func convert(
        amount: Double,
        from source: String,
        to destination: String,
        rates: [String: Double]
    ) -> Double {
        guard amount.isFinite,
              let sourceRate = rates[source],
              let destinationRate = rates[destination],
              sourceRate.isFinite,
              destinationRate.isFinite,
              sourceRate > 0,
              destinationRate > 0 else { return 0 }
        let converted = amount / sourceRate * destinationRate
        return converted.isFinite ? converted : 0
    }

    private static func normalizedCurrencyCode(_ value: String) -> String {
        let code = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let isASCII = code.utf8.allSatisfy { (65...90).contains($0) }
        return code.count == 3 && isASCII && isoCurrencyCodes.contains(code) ? code : ""
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
        let normalized = CurrencyCalculator.normalizedCurrencyCodes(node.options)
        return normalized.isEmpty ? ["USD", "TWD"] : normalized
    }

    private var rates: [String: Double] {
        CurrencyCalculator.rateTable(items: node.items, currencies: currencies)
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
        CurrencyCalculator.convert(
            amount: 1,
            from: fromCurrency,
            to: toCurrency,
            rates: rates
        )
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
            let pair = CurrencyCalculator.preferredPair(
                currencies: currencies,
                source: fromCurrency,
                destination: toCurrency
            )
            fromCurrency = pair.source
            toCurrency = pair.destination
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
        .accessibilityValue(
            "\(convertedAmount.formatted(.number.precision(.fractionLength(2)))) \(toCurrency)"
        )
        .accessibilityIdentifier("currency.converted-amount")
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
