import SwiftUI

struct RateAlertDraft {
    var target: String
    var direction: RateThresholdDirection
    var isEnabled: Bool

    var targetValue: Double? {
        Double(target.replacingOccurrences(of: ",", with: ""))
    }
}

struct RateAlertEditor: View {
    let base: String
    let quote: String
    let currentRate: Double?
    let tint: AppTint
    let onSave: (RateAlertDraft) -> Void
    let onDelete: (() -> Void)?
    let onTest: (RateAlertDraft) -> String

    @Environment(\.dismiss) private var dismiss
    @State private var draft: RateAlertDraft
    @State private var confirmingDelete = false
    @State private var testMessage: String?

    init(
        base: String,
        quote: String,
        currentRate: Double?,
        existing: RateAlertDraft?,
        tint: AppTint,
        onSave: @escaping (RateAlertDraft) -> Void,
        onDelete: (() -> Void)?,
        onTest: @escaping (RateAlertDraft) -> String
    ) {
        self.base = base
        self.quote = quote
        self.currentRate = currentRate
        self.tint = tint
        self.onSave = onSave
        self.onDelete = onDelete
        self.onTest = onTest
        _draft = State(
            initialValue: existing ?? RateAlertDraft(
                target: currentRate.map { String($0) } ?? "",
                direction: .atOrBelow,
                isEnabled: true
            )
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Currency pair") {
                    LabeledContent("Pair", value: "\(base) → \(quote)")
                    LabeledContent("Latest rate") {
                        if let currentRate {
                            Text(currentRate, format: .number.precision(.fractionLength(2...6)))
                                .monospacedDigit()
                        } else {
                            Text("Unavailable").foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Condition") {
                    Picker("Trigger", selection: $draft.direction) {
                        ForEach(RateThresholdDirection.allCases, id: \.self) { direction in
                            Text(direction.label).tag(direction)
                        }
                    }
                    TextField("Target rate", text: $draft.target)
                        .keyboardType(.decimalPad)
                    Toggle("Alert enabled", isOn: $draft.isEnabled)
                    Text(rulePreview)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button {
                        testMessage = onTest(draft)
                    } label: {
                        Label("Test Alert", systemImage: "bell.badge.fill")
                    }
                    .disabled(draft.targetValue == nil)
                } footer: {
                    Text("Shows a sample in-app alert now. It does not wait for the target.")
                }

                if onDelete != nil {
                    Section {
                        Button("Delete Alert", role: .destructive) { confirmingDelete = true }
                    }
                }
            }
            .tint(tint.color)
            .navigationTitle("Rate Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(draft) }
                        .disabled(draft.targetValue.map { $0 <= 0 } ?? true)
                }
            }
            .confirmationDialog(
                "Delete this rate alert?",
                isPresented: $confirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { onDelete?() }
                Button("Cancel", role: .cancel) {}
            }
            .alert(
                "Test rate alert",
                isPresented: Binding(
                    get: { testMessage != nil },
                    set: { if !$0 { testMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) { testMessage = nil }
            } message: {
                Text(testMessage ?? "")
            }
        }
    }

    private var rulePreview: String {
        let condition = draft.direction == .atOrBelow ? "at or below" : "at or above"
        return "Alert when 1 \(base) is \(condition) \(draft.target.isEmpty ? "—" : draft.target) \(quote)."
    }
}

struct CurrencyPickerSheet: View {
    let currencies: [CurrencyDescriptor]
    let excluded: Set<String>
    let tint: AppTint
    let onAdd: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var filtered: [CurrencyDescriptor] {
        currencies.filter { currency in
            guard !excluded.contains(currency.code) else { return false }
            return search.isEmpty
                || currency.code.localizedCaseInsensitiveContains(search)
                || currency.name.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { currency in
                Button {
                    onAdd(currency.code)
                    dismiss()
                } label: {
                    HStack {
                        Text(currency.code).font(.subheadline.bold().monospaced())
                            .foregroundStyle(tint.color)
                            .frame(width: 48, alignment: .leading)
                        Text(currency.name).foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "plus.circle.fill").foregroundStyle(tint.color)
                    }
                }
            }
            .searchable(text: $search, prompt: "Currency code or name")
            .navigationTitle("Add Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
