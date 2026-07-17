import SwiftUI

struct RecordDraft {
    var id: UUID
    var title: String
    var note: String
    var numericValue: String
    var date: Date
    var isComplete: Bool

    init(
        id: UUID = UUID(),
        title: String = "",
        note: String = "",
        numericValue: String = "",
        date: Date = .now,
        isComplete: Bool = false
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.numericValue = numericValue
        self.date = date
        self.isComplete = isComplete
    }
}

struct RecordEditorView: View {
    let spec: RecordCollectionSpec
    let onSave: (RecordDraft) -> Void
    let onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var draft: RecordDraft
    @State private var confirmingDelete = false

    init(
        spec: RecordCollectionSpec,
        existing: RecordDraft?,
        onSave: @escaping (RecordDraft) -> Void,
        onDelete: (() -> Void)?
    ) {
        self.spec = spec
        self.onSave = onSave
        self.onDelete = onDelete
        _draft = State(initialValue: existing ?? RecordDraft())
    }

    private var title: String {
        onDelete == nil ? "New \(spec.itemName)" : "Edit \(spec.itemName)"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(spec.itemName) {
                    TextField(spec.titleLabel, text: $draft.title)
                    if !spec.noteLabel.isEmpty {
                        TextField(spec.noteLabel, text: $draft.note, axis: .vertical)
                            .lineLimit(2...4)
                    }
                }

                if spec.valueKind != .none || spec.dateKind != .none {
                    Section("Details") {
                        if spec.valueKind != .none {
                            TextField(spec.valueLabel, text: $draft.numericValue)
                                .keyboardType(.decimalPad)
                        }
                        if spec.dateKind != .none {
                            DatePicker(
                                spec.dateLabel,
                                selection: $draft.date,
                                displayedComponents: spec.dateKind == .date ? .date : [.date, .hourAndMinute]
                            )
                        }
                    }
                }

                if spec.allowsCompletion {
                    Section("Status") { Toggle("Completed", isOn: $draft.isComplete) }
                }

                if onDelete != nil {
                    Section {
                        Button("Delete \(spec.itemName)", role: .destructive) {
                            confirmingDelete = true
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(onDelete == nil ? "Add" : "Save") { onSave(draft) }
                        .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .confirmationDialog(
                "Delete this \(spec.itemName.lowercased())?",
                isPresented: $confirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { onDelete?() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}
