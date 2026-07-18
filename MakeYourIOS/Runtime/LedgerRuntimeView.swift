import Charts
import SwiftUI

struct LedgerRuntimeView: View {
    private struct EditorContext: Identifiable {
        var id = UUID()
        var entry: LedgerRuntimeEntry?
    }

    let projectID: UUID
    let node: ComponentNode
    let tint: AppTint

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.runtimeDesign) private var design

    @State private var entries: [LedgerRuntimeEntry] = []
    @State private var editorContext: EditorContext?
    @State private var statusMessage: String?

    private let stateStore = ProjectRuntimeStateStore()

    private var spec: LedgerSpec {
        node.ledger ?? LedgerSpec(
            currencyCode: "USD",
            categories: ["Other"],
            period: .currentMonth,
            monthlyBudget: 0,
            allowsIncome: true,
            initialEntries: []
        )
    }

    private var visibleEntries: [LedgerRuntimeEntry] {
        LedgerCalculator.entries(entries, for: spec.period)
            .sorted { $0.date > $1.date }
    }

    private var summary: LedgerSummary {
        LedgerCalculator.summary(for: visibleEntries)
    }

    private var variant: ComponentVariant {
        RendererCatalog.normalizedVariant(node.resolvedPresentation.variant, for: .ledger)
    }

    private var contentSpacing: CGFloat {
        [.compact, .dense].contains(variant) ? 10 : design.componentSpacing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: contentSpacing) {
            header
            summaryGrid
            budgetView
            categoryChart
            entryList

            if let statusMessage {
                Label(statusMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear(perform: load)
        .sheet(item: $editorContext) { context in
            LedgerEditorView(
                spec: spec,
                existing: context.entry,
                onSave: save,
                onDelete: context.entry.map { entry in { delete(entry.id) } }
            )
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Label(
                    node.title,
                    systemImage: node.symbol.isEmpty ? "dollarsign.circle.fill" : node.symbol
                )
                .font(design.sectionFont)
                .accessibilityAddTraits(.isHeader)
                if !node.subtitle.isEmpty {
                    Text(node.subtitle)
                        .font(design.captionFont)
                        .foregroundStyle(design.secondaryForeground)
                }
            }
            Spacer()
            Button {
                editorContext = EditorContext(entry: nil)
            } label: {
                Image(systemName: "plus")
                    .font(.subheadline.bold())
                    .frame(width: 44, height: 44)
                    .foregroundStyle(design.accent)
                    .background(design.accent.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add entry")
        }
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: summaryColumns, spacing: 10) {
            summaryCell("Balance", value: summary.balance, symbol: "equal.circle.fill")
            summaryCell("Spent", value: summary.expenses, symbol: "arrow.down.right")
            if spec.allowsIncome {
                summaryCell("Income", value: summary.income, symbol: "arrow.up.right")
                summaryCell("Entries", text: visibleEntries.count.formatted(), symbol: "list.bullet")
            }
        }
    }

    private var summaryColumns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 10, alignment: .top), count: count)
    }

    @ViewBuilder
    private var budgetView: some View {
        if spec.monthlyBudget > 0, spec.period == .currentMonth {
            let ratio = min(summary.expenses / spec.monthlyBudget, 1)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Monthly budget").font(.caption.weight(.semibold))
                    Spacer()
                    Text("\(money(summary.expenses)) / \(money(spec.monthlyBudget))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: ratio).tint(ratio >= 1 ? design.danger : design.accent)
                    .accessibilityLabel("Monthly budget used")
                    .accessibilityValue(Text(ratio, format: .percent))
            }
        }
    }

    @ViewBuilder
    private var categoryChart: some View {
        let totals = summary.expensesByCategory
            .map { CategoryTotal(category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
            .prefix(6)
        if !totals.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Spending by category").font(.caption.weight(.semibold))
                Chart(Array(totals)) { total in
                    BarMark(
                        x: .value("Amount", total.amount),
                        y: .value("Category", total.category)
                    )
                    .foregroundStyle(design.accent.gradient)
                    .cornerRadius(4)
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(totals.count) * 30 + 16)
                .accessibilityLabel("Spending by category chart")
                .accessibilityValue(categoryAccessibilitySummary(Array(totals)))
            }
        }
    }

    @ViewBuilder
    private var entryList: some View {
        if visibleEntries.isEmpty {
            ContentUnavailableView(
                "No entries yet",
                systemImage: "tray",
                description: Text("Tap Add to record income or spending.")
            )
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: variant == .cards ? 10 : 0) {
                ForEach(Array(visibleEntries.enumerated()), id: \.element.id) { index, entry in
                    Button {
                        editorContext = EditorContext(entry: entry)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: entry.type == .income ? "arrow.up.right" : "arrow.down.right")
                                .foregroundStyle(entry.type == .income ? design.success : design.accent)
                                .frame(width: 30)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.title).font(.subheadline.weight(.semibold))
                                Text("\(entry.category) · \(entry.date.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text((entry.type == .income ? "+" : "−") + money(entry.amount))
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(entry.type == .income ? .green : .primary)
                        }
                        .padding(.vertical, [.compact, .dense].contains(variant) ? 6 : 9)
                        .padding(.horizontal, variant == .cards ? 12 : 0)
                        .background(
                            variant == .cards ? design.surface : .clear,
                            in: RoundedRectangle(
                                cornerRadius: design.compactCornerRadius,
                                style: .continuous
                            )
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if variant != .cards, index < visibleEntries.count - 1 {
                        Divider().padding(.leading, 40)
                    }
                }
            }
        }
    }

    private func summaryCell(_ title: String, value: Double, symbol: String) -> some View {
        summaryCell(title, text: money(value), symbol: symbol)
    }

    private func summaryCell(_ title: String, text: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.headline.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(variant == .dense ? 10 : 12)
        .background(
            variant == .cards ? design.surface : design.accent.opacity(0.08),
            in: RoundedRectangle(cornerRadius: design.compactCornerRadius, style: .continuous)
        )
        .overlay {
            if variant == .cards || design.increasedContrast {
                RoundedRectangle(cornerRadius: design.compactCornerRadius, style: .continuous)
                    .stroke(
                        design.borderColor.opacity(design.borderOpacity),
                        lineWidth: design.borderWidth
                    )
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(text)
    }

    private func categoryAccessibilitySummary(_ totals: [CategoryTotal]) -> String {
        totals.map { "\($0.category): \(money($0.amount))" }.joined(separator: ", ")
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: spec.currencyCode))
    }
}

private extension LedgerRuntimeView {
    private func load() {
        do {
            if let saved = try stateStore.load(
                [LedgerRuntimeEntry].self,
                projectID: projectID,
                nodeID: node.id,
                namespace: "ledger"
            ) {
                entries = saved
                return
            }
        } catch {
            statusMessage = "Saved entries could not be read."
        }

        entries = spec.initialEntries.map { seed in
            LedgerRuntimeEntry(
                id: UUID(),
                title: seed.title,
                note: seed.note,
                amount: seed.amount,
                type: seed.type,
                category: seed.category,
                date: LedgerDateCodec.parse(seed.date) ?? .now
            )
        }
        persist()
    }

    private func save(_ entry: LedgerRuntimeEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
        } else {
            entries.append(entry)
        }
        editorContext = nil
        persist()
    }

    private func delete(_ id: UUID) {
        entries.removeAll { $0.id == id }
        editorContext = nil
        persist()
    }

    private func persist() {
        do {
            try stateStore.save(
                entries,
                projectID: projectID,
                nodeID: node.id,
                namespace: "ledger"
            )
            statusMessage = nil
        } catch {
            statusMessage = "Changes could not be saved."
        }
    }
}

private struct CategoryTotal: Identifiable {
    var category: String
    var amount: Double
    var id: String { category }
}
