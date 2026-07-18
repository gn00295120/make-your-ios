import Charts
import SwiftUI

struct MarketQuoteRow: View {
    let symbol: String
    let quote: MarketQuote?
    let isSelected: Bool
    let tint: AppTint
    let variant: ComponentVariant
    let hasProviderKey: Bool
    let canRemove: Bool
    let onSelect: () -> Void
    let onRemove: () -> Void

    @Environment(\.runtimeDesign) private var design

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onSelect) {
                HStack(spacing: 11) {
                    symbolBadge
                    quoteIdentity
                    Spacer(minLength: 8)
                    quotePrice
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if canRemove {
                removeButton
            }
        }
        .padding(.vertical, [.compact, .dense].contains(variant) ? 4 : 7)
        .padding(.horizontal, variant == .cards ? 10 : 0)
        .background(
            variant == .cards ? design.surface : .clear,
            in: RoundedRectangle(cornerRadius: design.compactCornerRadius, style: .continuous)
        )
        .overlay {
            if variant == .cards {
                RoundedRectangle(cornerRadius: design.compactCornerRadius, style: .continuous)
                    .stroke(
                        design.borderColor.opacity(design.borderOpacity),
                        lineWidth: design.borderWidth
                    )
            }
        }
    }

    private var symbolBadge: some View {
        Text(symbol)
            .font(.caption.bold().monospaced())
            .foregroundStyle(isSelected ? design.onAccent : design.accent)
            .frame(width: 44, height: 44)
            .background(isSelected ? design.accent : design.accent.opacity(0.12), in: Circle())
    }

    private var quoteIdentity: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(quote?.name.isEmpty == false ? quote?.name ?? symbol : symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Text(metadata)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var quotePrice: some View {
        if let quote {
            VStack(alignment: .trailing, spacing: 2) {
                Text(quote.price, format: .number.precision(.fractionLength(2...4)))
                    .font(.headline.monospacedDigit())
                Text(changeText(quote))
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(changeColor(quote.change))
            }
        } else {
            Text("—")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private var removeButton: some View {
        Button(action: onRemove) {
            Image(systemName: "minus.circle")
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Remove \(symbol)")
    }

    private var metadata: String {
        guard let quote else {
            return hasProviderKey || symbol == "AAPL" ? "Waiting to refresh" : "Provider key required"
        }
        return [quote.exchange, quote.currency].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    private func changeText(_ quote: MarketQuote) -> String {
        let sign = quote.change > 0 ? "+" : ""
        return "\(sign)\(quote.change.formatted(.number.precision(.fractionLength(2...4)))) "
            + "(\(sign)\(quote.percentChange.formatted(.number.precision(.fractionLength(2))))%)"
    }

    private func changeColor(_ value: Double) -> Color {
        if value > 0 { return .green }
        if value < 0 { return .red }
        return .secondary
    }
}

struct MarketHistoryChart: View {
    let symbol: String
    let range: MarketRange
    let quote: MarketQuote?
    let history: MarketHistory?
    let tint: AppTint
    let variant: ComponentVariant
    let isRefreshing: Bool

    @Environment(\.runtimeDesign) private var design

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            header
            chartContent
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(symbol) history")
                    .font(.subheadline.weight(.semibold))
                Text(range.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let quote {
                Text(quote.currency)
                    .font(.caption.bold())
                    .foregroundStyle(design.accent)
            }
        }
    }

    @ViewBuilder
    private var chartContent: some View {
        if let points = history?.points, !points.isEmpty {
            priceChart(points)
        } else if isRefreshing {
            ProgressView("Loading chart…")
                .frame(maxWidth: .infinity, minHeight: 150)
        } else {
            ContentUnavailableView(
                "No chart data",
                systemImage: "chart.line.uptrend.xyaxis",
                description: Text("Refresh or add a provider key to load history.")
            )
            .frame(maxWidth: .infinity, minHeight: 150)
        }
    }

    private func priceChart(_ points: [MarketPricePoint]) -> some View {
        Chart(points) { point in
            AreaMark(
                x: .value("Date", point.timestamp),
                y: .value("Close", point.close)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [design.accent.opacity(0.25), design.accent.opacity(0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            LineMark(
                x: .value("Date", point.timestamp),
                y: .value("Close", point.close)
            )
            .foregroundStyle(design.accent)
            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine().foregroundStyle(.clear)
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(height: [.compact, .dense].contains(variant) ? 150 : 190)
        .accessibilityLabel("Price history for \(symbol)")
        .accessibilityValue(chartAccessibilitySummary(points))
    }

    private func chartAccessibilitySummary(_ points: [MarketPricePoint]) -> String {
        guard let first = points.first, let last = points.last else { return "No price points" }
        return "From \(first.close.formatted()) to \(last.close.formatted()), \(points.count) points"
    }
}

struct MarketProviderNotice: View {
    let errorMessage: String?
    let hasProviderKey: Bool
    let selectedQuote: MarketQuote?
    let lastUpdated: Date?
    let onAddKey: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            errorBanner
            timestamp
            attribution
            disclaimer
        }
    }

    @ViewBuilder
    private var errorBanner: some View {
        if let errorMessage {
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text(errorMessage)
                Spacer()
                if !hasProviderKey {
                    Button("Add key", action: onAddKey)
                        .font(.caption.bold())
                }
            }
            .font(.caption)
            .foregroundStyle(.orange)
        }
    }

    private var timestamp: some View {
        HStack(spacing: 5) {
            Image(systemName: "clock")
            timestampText
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }

    private var timestampText: Text {
        if let asOf = selectedQuote?.asOf {
            return Text("Latest provider timestamp: \(asOf.formatted(date: .abbreviated, time: .shortened))")
        }
        if let lastUpdated {
            return Text("Cached \(lastUpdated.formatted(date: .abbreviated, time: .shortened))")
        }
        return Text("Latest or delayed market snapshot")
    }

    private var attribution: some View {
        HStack(spacing: 4) {
            Text("Data by")
            Link("Twelve Data", destination: URL(string: "https://twelvedata.com/")!)
            Text("· Quotes may be delayed.")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }

    private var disclaimer: some View {
        Label(
            "Informational only — not investment advice or a trading service.",
            systemImage: "info.circle"
        )
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
}
