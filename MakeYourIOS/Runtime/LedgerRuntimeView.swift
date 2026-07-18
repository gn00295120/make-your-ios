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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                .font(.headline)
                if !node.subtitle.isEmpty {
                    Text(node.subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                editorContext = EditorContext(entry: nil)
            } label: {
                Image(systemName: "plus")
                    .font(.subheadline.bold())
                    .frame(width: 44, height: 44)
                    .background(tint.color.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add entry")
        }
    }

    private var summaryGrid: some View {
        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            GridRow {
                summaryCell("Balance", value: summary.balance, symbol: "equal.circle.fill")
                summaryCell("Spent", value: summary.expenses, symbol: "arrow.down.right")
            }
            if spec.allowsIncome {
                GridRow {
                    summaryCell("Income", value: summary.income, symbol: "arrow.up.right")
                    summaryCell("Entries", text: visibleEntries.count.formatted(), symbol: "list.bullet")
                }
            }
        }
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
                ProgressView(value: ratio).tint(ratio >= 1 ? .red : tint.color)
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
                    .foregroundStyle(tint.color.gradient)
                    .cornerRadius(4)
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(totals.count) * 30 + 16)
                .accessibilityLabel("Spending by category chart")
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
            VStack(spacing: 0) {
                ForEach(Array(visibleEntries.enumerated()), id: \.element.id) { index, entry in
                    Button {
                        editorContext = EditorContext(entry: entry)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: entry.type == .income ? "arrow.up.right" : "arrow.down.right")
                                .foregroundStyle(entry.type == .income ? .green : tint.color)
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
                        .padding(.vertical, 9)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if index < visibleEntries.count - 1 { Divider().padding(.leading, 40) }
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
        .padding(12)
        .background(tint.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: spec.currencyCode))
    }

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

private struct LedgerEditorView: View {
    let spec: LedgerSpec
    let onSave: (LedgerRuntimeEntry) -> Void
    let onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var id: UUID
    @State private var title: String
    @State private var note: String
    @State private var amount: String
    @State private var type: LedgerEntryType
    @State private var category: String
    @State private var date: Date
    @State private var isConfirmingDelete = false

    init(
        spec: LedgerSpec,
        existing: LedgerRuntimeEntry?,
        onSave: @escaping (LedgerRuntimeEntry) -> Void,
        onDelete: (() -> Void)?
    ) {
        self.spec = spec
        self.onSave = onSave
        self.onDelete = onDelete
        _id = State(initialValue: existing?.id ?? UUID())
        _title = State(initialValue: existing?.title ?? "")
        _note = State(initialValue: existing?.note ?? "")
        _amount = State(initialValue: existing.map { String($0.amount) } ?? "")
        _type = State(initialValue: existing?.type ?? .expense)
        _category = State(initialValue: existing?.category ?? spec.categories[0])
        _date = State(initialValue: existing?.date ?? .now)
    }

    var body: some View {
        NavigationStack {
            Form {
                if spec.allowsIncome {
                    Picker("Type", selection: $type) {
                        Text("Expense").tag(LedgerEntryType.expense)
                        Text("Income").tag(LedgerEntryType.income)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Entry") {
                    TextField("Name", text: $title)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    Picker("Category", selection: $category) {
                        ForEach(spec.categories, id: \.self) { Text($0).tag($0) }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Note", text: $note, axis: .vertical).lineLimit(2...4)
                }

                if onDelete != nil {
                    Section {
                        Button("Delete entry", role: .destructive) { isConfirmingDelete = true }
                    }
                }
            }
            .navigationTitle(onDelete == nil ? "New entry" : "Edit entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                }
            }
            .confirmationDialog(
                "Delete this entry?",
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { onDelete?() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var parsedAmount: Double? {
        Double(amount.replacingOccurrences(of: ",", with: ""))
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && parsedAmount.map { $0.isFinite && $0 > 0 } == true
    }

    private func save() {
        guard let parsedAmount, parsedAmount > 0 else { return }
        onSave(LedgerRuntimeEntry(
            id: id,
            title: String(title.trimmingCharacters(in: .whitespacesAndNewlines).prefix(80)),
            note: String(note.trimmingCharacters(in: .whitespacesAndNewlines).prefix(160)),
            amount: parsedAmount,
            type: spec.allowsIncome ? type : .expense,
            category: category,
            date: date
        ))
    }
}
