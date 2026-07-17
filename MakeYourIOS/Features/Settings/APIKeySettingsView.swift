import SwiftUI

struct APIKeySettingsView: View {
    @Environment(AISettingsStore.self) private var settings

    @State private var draftKey = ""
    @State private var feedbackMessage: String?
    @State private var errorMessage: String?
    @State private var showingRemoveConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                connectionHero
                providerCard
                disclosureCard
                securityCard
                privacyCard
            }
            .padding(16)
            .padding(.bottom, 30)
        }
        .background(MakeYourTheme.canvas)
        .navigationTitle("AI Key")
        .alert("Couldn’t save the key", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .confirmationDialog(
            "Remove the OpenAI API key from this device?",
            isPresented: $showingRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove key", role: .destructive, action: removeKey)
            Button("Cancel", role: .cancel) {}
        }
    }

    private var connectionHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: settings.isReady ? "checkmark.shield.fill" : "key.horizontal.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                Spacer()
                Text(settings.isReady ? "READY" : "SETUP")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.16), in: Capsule())
            }

            Text(settings.isReady ? "Your builder is ready." : "Bring your own intelligence.")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            Text("Your key goes from this iPhone directly to OpenAI. MakeYour’s server never receives it.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.82))
        }
        .padding(22)
        .background(MakeYourTheme.brandGradient, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var providerCard: some View {
        @Bindable var bindableSettings = settings
        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(.black, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("OpenAI").font(.headline)
                    Text("Responses API · Structured Outputs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if settings.hasAPIKey {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .accessibilityLabel("Key saved")
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("API key").font(.subheadline.weight(.semibold))
                SecureField(settings.hasAPIKey ? "Saved — enter a new key to replace" : "sk-…", text: $draftKey)
                    .textContentType(.password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(14)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Model").font(.subheadline.weight(.semibold))
                TextField("Model", text: $bindableSettings.model)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(14)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                Text(
                    "The default favors fast, lower-cost app generation. "
                        + "You can enter another Responses API model available to your account."
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                if settings.hasAPIKey {
                    Button("Remove", role: .destructive) { showingRemoveConfirmation = true }
                        .buttonStyle(.bordered)
                }
                Spacer()
                Button(settings.hasAPIKey ? "Update key" : "Save key", action: saveKey)
                    .buttonStyle(.borderedProminent)
                    .tint(MakeYourTheme.brand)
                    .disabled(draftKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let message = feedbackMessage ?? settings.keyStatusMessage {
                Label(message, systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .makeYourCard()
    }

    private var disclosureCard: some View {
        @Bindable var bindableSettings = settings
        return VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: $bindableSettings.disclosureAccepted) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Allow requests to OpenAI").font(.headline)
                    Text("Required before generation")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(MakeYourTheme.brand)

            Divider()

            Text(
                "When you generate, MakeYour sends only your builder prompt and the current app document to OpenAI. "
                    + "It does not send runtime task data, notification contents, other projects, or your API key "
                    + "inside the prompt. OpenAI receives the key as an authorization header."
            )
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text(
                "AI features inside a mini app use a separate review flow. Before every request, MakeYour shows "
                    + "the exact text and task that will be sent; photos and other app data are excluded."
            )
                .font(.footnote)
                .foregroundStyle(.secondary)

            Link(destination: URL(string: "https://openai.com/policies/privacy-policy/")!) {
                Label("OpenAI privacy policy", systemImage: "arrow.up.right")
                    .font(.footnote.weight(.semibold))
            }
        }
        .makeYourCard()
    }

    private var securityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Stored for this device only", systemImage: "iphone.gen3.lock")
                .font(.headline)
            Text(
                "The key is stored in iOS Keychain with When Unlocked, This Device Only protection. "
                    + "It is not synced, exported with projects, written to UserDefaults, or included in logs."
            )
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .makeYourCard()
    }

    private var privacyCard: some View {
        NavigationLink {
            PrivacySafetyView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "hand.raised.square.fill")
                    .font(.title3)
                    .foregroundStyle(MakeYourTheme.brand)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Privacy & Safety").font(.headline).foregroundStyle(.primary)
                    Text("What stays local, what is sent, and how to delete it")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
        .makeYourCard()
    }

    private func saveKey() {
        do {
            try settings.saveAPIKey(draftKey)
            draftKey = ""
            feedbackMessage = "Saved securely in Keychain."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func removeKey() {
        do {
            try settings.removeAPIKey()
            feedbackMessage = "API key removed from this device."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
