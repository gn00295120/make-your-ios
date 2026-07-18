import SwiftUI

struct AITextRuntimeView: View {
    private struct PendingRequest: Identifiable {
        let id = UUID()
        let input: String
    }

    let node: ComponentNode
    let tint: AppTint

    @Environment(AISettingsStore.self) private var aiSettings
    @Environment(\.runtimeDesign) private var design
    @State private var input = ""
    @State private var output = ""
    @State private var pendingRequest: PendingRequest?
    @State private var isRunning = false
    @State private var errorMessage: String?

    private let client = OpenAITextCompletionClient()

    private var trimmedInput: String {
        input.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var variant: ComponentVariant {
        RendererCatalog.normalizedVariant(node.resolvedPresentation.variant, for: .aiAssistant)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: variant == .compact ? 9 : 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(node.title.isEmpty ? "Ask AI" : node.title)
                        .font(design.sectionFont)
                        .accessibilityAddTraits(.isHeader)
                    if !node.subtitle.isEmpty {
                        Text(node.subtitle)
                            .font(design.captionFont)
                            .foregroundStyle(design.secondaryForeground)
                    }
                }
                Spacer()
                Label("AI", systemImage: "sparkles")
                    .font(.caption2.bold())
                    .foregroundStyle(design.accent)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(design.accent.opacity(0.12), in: Capsule())
                    .accessibilityLabel("Uses OpenAI")
            }

            TextEditor(text: $input)
                .frame(minHeight: variant == .compact ? 72 : 96)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(
                    variant == .cards ? design.surface : design.accent.opacity(0.07),
                    in: RoundedRectangle(
                        cornerRadius: design.controlCornerRadius,
                        style: .continuous
                    )
                )
                .overlay {
                    if variant == .framed || design.increasedContrast {
                        RoundedRectangle(
                            cornerRadius: design.controlCornerRadius,
                            style: .continuous
                        )
                        .stroke(
                            design.accent.opacity(design.increasedContrast ? 0.9 : 0.5),
                            lineWidth: max(1, design.borderWidth)
                        )
                    }
                }
                .overlay(alignment: .topLeading) {
                    if input.isEmpty {
                        Text(node.placeholder.isEmpty ? "Enter text for AI…" : node.placeholder)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 17)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }

            if !node.options.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(node.options.prefix(6), id: \.self) { suggestion in
                            Button(suggestion) { input = suggestion }
                                .font(.caption.weight(.medium))
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.capsule)
                                .tint(design.accent)
                        }
                    }
                }
            }

            if aiSettings.canStartRuntimeAI {
                Button(action: prepareRequest) {
                    HStack {
                        if isRunning {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(isRunning ? "Thinking…" : (node.action.value.isEmpty ? "Ask AI" : node.action.value))
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                }
                .buttonStyle(.borderedProminent)
                .tint(design.accent)
                .disabled(trimmedInput.isEmpty || isRunning)
            } else {
                Label("Add an API key in the AI Key tab to use this feature.", systemImage: "key.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Label(
                "Only the text you review is sent to OpenAI. Photos and other app data stay local.",
                systemImage: "hand.raised.fill"
            )
            .font(.caption2)
            .foregroundStyle(.secondary)

            if !output.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    Label("AI result", systemImage: "sparkles")
                        .font(.caption.bold())
                        .foregroundStyle(design.accent)
                    Text(output)
                        .font(design.bodyFont)
                        .textSelection(.enabled)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    variant == .cards ? design.surface : design.accent.opacity(0.09),
                    in: RoundedRectangle(cornerRadius: design.compactCornerRadius)
                )
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .sheet(item: $pendingRequest) { request in
            AIRequestConfirmationView(
                task: node.value,
                input: request.input,
                initiallyAcknowledged: aiSettings.runtimeDisclosureAccepted,
                onCancel: { pendingRequest = nil },
                onSend: { sendConfirmedRequest(request) }
            )
                .presentationDetents([.medium, .large])
        }
    }

    private func prepareRequest() {
        guard !trimmedInput.isEmpty else { return }
        guard trimmedInput.count <= 4_000 else {
            errorMessage = "Keep AI input under 4,000 characters."
            return
        }
        errorMessage = nil
        pendingRequest = PendingRequest(input: trimmedInput)
    }

    private func sendConfirmedRequest(_ request: PendingRequest) {
        aiSettings.acceptRuntimeDisclosure()
        pendingRequest = nil
        isRunning = true
        errorMessage = nil
        let capturedInput = request.input

        Task {
            do {
                let config = try aiSettings.runtimeConnectionConfig()
                output = try await client.complete(
                    input: capturedInput,
                    instructions: instructions,
                    config: config
                )
            } catch {
                errorMessage = error.localizedDescription
            }
            isRunning = false
        }
    }

    private var instructions: String {
        let task = node.value.isEmpty ? "Respond helpfully and concisely." : node.value
        return """
        You are a focused assistant inside a private personal mini app.
        Follow the task below using only the user's submitted text.
        Do not claim access to photos, files, device data, other fields, or other apps.

        MINI-APP TASK:
        \(task)
        """
    }
}
