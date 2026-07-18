import SwiftUI

struct LedgerEditorView: View {
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
