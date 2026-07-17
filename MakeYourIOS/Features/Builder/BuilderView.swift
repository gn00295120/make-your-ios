import SwiftUI

struct BuilderView: View {
    @Environment(WorkspaceStore.self) private var store
    @Environment(AISettingsStore.self) private var aiSettings
    let openApps: () -> Void
    let openAISettings: () -> Void

    @State private var prompt = ""
    @State private var isGenerating = false
    @State private var isPresentingRuntime = false
    @State private var errorMessage: String?
    @State private var generationNote: String?

    private let client = OpenAIAppGenerationClient()
    private let suggestions = [
        "Make a travel budget converter",
        "Add a task reminder for tonight",
        "Create a simple habit checklist",
        "Make the design calmer and clearer"
    ]

    var body: some View {
        Group {
            if let project = store.selectedProject {
                VStack(spacing: 0) {
                    BuilderTopBar(
                        project: project,
                        onUseApp: { isPresentingRuntime = true }
                    )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.bar)

                    designView(project: project)
                }
            } else {
                ContentUnavailableView {
                    Label("No app selected", systemImage: "square.grid.2x2")
                } description: {
                    Text("Create an app in My Apps to start building.")
                } actions: {
                    Button("Create blank app") { store.createProject() }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .background(MakeYourTheme.canvas)
        .navigationTitle("Builder")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                projectMenu
            }
        }
        .fullScreenCover(isPresented: $isPresentingRuntime) {
            if let project = store.selectedProject {
                ImmersiveAppHostView(
                    project: project,
                    openApps: {
                        isPresentingRuntime = false
                        openApps()
                    },
                    openBuilder: { isPresentingRuntime = false },
                    openAIKey: {
                        isPresentingRuntime = false
                        openAISettings()
                    }
                )
            }
        }
        .alert("Couldn’t update this app", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func designView(project: WorkspaceProject) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ProjectBriefCard(project: project)

                DesignStudioCard(
                    project: project,
                    onTheme: { store.applyTheme($0, to: project.id) },
                    onAddImage: { store.addImageBlock(to: project.id) }
                )

                BuilderPromptCard(
                    prompt: $prompt,
                    suggestions: suggestions,
                    isReady: aiSettings.isReady,
                    isGenerating: isGenerating,
                    generationNote: generationNote,
                    onGenerate: { generate(project: project) },
                    onOpenSettings: openAISettings
                )

                RuntimeBoundaryCard()
            }
            .padding(16)
            .padding(.bottom, 20)
        }
    }

    private var projectMenu: some View {
        Menu {
            ForEach(store.projects) { project in
                Button {
                    store.select(project.id)
                    generationNote = nil
                } label: {
                    if store.selectedProjectID == project.id {
                        Label(project.document.name, systemImage: "checkmark")
                    } else {
                        Text(project.document.name)
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
        }
        .accessibilityLabel("Switch app")
    }

    private func generate(project: WorkspaceProject) {
        let request = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !request.isEmpty else { return }

        isGenerating = true
        generationNote = nil
        errorMessage = nil

        Task {
            do {
                let config = try aiSettings.connectionConfig()
                let document = try await client.generate(
                    prompt: request,
                    currentDocument: project.document,
                    config: config
                )
                try store.replaceDocument(projectID: project.id, with: document, prompt: request)
                withAnimation(.snappy) {
                    prompt = ""
                    generationNote = "Version \(document.version) passed validation and is ready to use."
                    isPresentingRuntime = true
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isGenerating = false
        }
    }
}

private struct BuilderPromptCard: View {
    @Binding var prompt: String
    let suggestions: [String]
    let isReady: Bool
    let isGenerating: Bool
    let generationNote: String?
    let onGenerate: () -> Void
    let onOpenSettings: () -> Void

    private var promptIsEmpty: Bool {
        prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Describe the next version", systemImage: "text.bubble.fill")
                    .font(.headline)
                Spacer()
                Text("AI")
                    .font(.caption2.bold())
                    .foregroundStyle(MakeYourTheme.brand)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(MakeYourTheme.brand.opacity(0.10), in: Capsule())
            }

            TextEditor(text: $prompt)
                .frame(minHeight: 104)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(alignment: .topLeading) {
                    if prompt.isEmpty {
                        Text("Example: Make a medication reminder with morning and evening check-ins…")
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 17)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }

            suggestionRow
            generationButton

            if let generationNote {
                Label(generationNote, systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .makeYourCard()
    }

    private var suggestionRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(suggestion) { prompt = suggestion }
                        .font(.caption.weight(.medium))
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                }
            }
        }
    }

    @ViewBuilder
    private var generationButton: some View {
        if isReady {
            Button(action: onGenerate) {
                HStack {
                    if isGenerating {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(isGenerating ? "Designing your app…" : "Generate next version")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(MakeYourTheme.brand)
            .disabled(promptIsEmpty || isGenerating)
        } else {
            Button(action: onOpenSettings) {
                Label("Connect an API key to generate", systemImage: "key.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(MakeYourTheme.brand)

            Text("The two sample apps are fully interactive without a key.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

private struct BuilderTopBar: View {
    let project: WorkspaceProject
    let onUseApp: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AppGlyph(symbol: project.document.symbol, tint: project.document.tint, size: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text(project.document.name).font(.subheadline.bold()).lineLimit(1)
                Text("Version \(project.document.version)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: onUseApp) {
                Label("Use App", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(project.document.tint.color)
        }
    }
}

private struct ProjectBriefCard: View {
    let project: WorkspaceProject

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Current app").font(.caption.bold()).foregroundStyle(project.document.tint.color)
                    Text(project.document.name).font(.title2.bold())
                    Text(project.document.summary).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(project.document.tint.color)
                    .accessibilityLabel("Validated")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(project.document.capabilities, id: \.self) { capability in
                        CapabilityPill(capability: capability)
                    }
                }
            }

            HStack {
                Label("\(project.document.pages.count) page", systemImage: "rectangle.stack")
                Spacer()
                Label("\(project.document.pages.flatMap(\.nodes).count) components", systemImage: "square.grid.3x3")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .makeYourCard()
    }
}

private struct RuntimeBoundaryCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.title3)
                .foregroundStyle(MakeYourTheme.brand)
            VStack(alignment: .leading, spacing: 4) {
                Text("Generated, then verified").font(.subheadline.bold())
                Text(
                    "AI creates a declarative app document. MakeYour validates every component and action "
                        + "before the native runtime uses it — no generated code is executed."
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .makeYourCard()
    }
}
