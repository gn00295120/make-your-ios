import SwiftUI

struct MarketSymbolEditorView: View {
    let tint: AppTint
    let onAdd: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var symbol = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Symbol") {
                    TextField("Example: AAPL", text: $symbol)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    Text("AAPL works with public demo data. Other symbols require your own Twelve Data key.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add symbol")
            .navigationBarTitleDisplayMode(.inline)
            .tint(tint.color)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: add)
                        .disabled(symbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func add() {
        do {
            let value = try MarketDataClient.normalizedSymbol(symbol)
            onAdd(value)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct MarketAPIKeyEditorView: View {
    let hasExistingKey: Bool
    let tint: AppTint
    let onChanged: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = ""
    @State private var errorMessage: String?

    private let credentialStore = MarketCredentialStore()

    var body: some View {
        NavigationStack {
            Form {
                Section("Twelve Data API key") {
                    SecureField(
                        hasExistingKey ? "Enter a replacement key" : "Paste your key",
                        text: $apiKey
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    Text("The key is stored in this device’s Keychain and is sent only to api.twelvedata.com.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if hasExistingKey {
                    Section {
                        Button("Remove provider key", role: .destructive, action: removeKey)
                    }
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Market data")
            .navigationBarTitleDisplayMode(.inline)
            .tint(tint.color)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveKey)
                        .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveKey() {
        do {
            try credentialStore.saveAPIKey(apiKey)
            apiKey = ""
            onChanged()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func removeKey() {
        do {
            try credentialStore.deleteAPIKey()
            onChanged()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
