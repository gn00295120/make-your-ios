// swiftlint:disable file_length
import SwiftUI

struct BuilderView: View {
    private struct PendingGeneration: Identifiable {
        var id = UUID()
        var projectID: UUID
        var document: AppDocument
        var prompt: String
        var addedCapabilities: [AppCapability]
        var mode: GenerationMode
        var previousDocument: AppDocument
        var designSummary: DesignChangeSummary?
    }

    @Environment(WorkspaceStore.self) private var store
    @Environment(AISettingsStore.self) private var aiSettings
    let openApps: () -> Void
    let openAISettings: () -> Void

    @State private var prompt = ""
    @State private var generationMode = GenerationMode.full
    @State private var isGenerating = false
    @State private var isPresentingRuntime = false
    @State private var errorMessage: String?
    @State private var generationNote: String?
    @State private var pendingGeneration: PendingGeneration?
    @State private var designStudioProject: WorkspaceProject?

    private let client = OpenAIAppGenerationClient()
    private let suggestions = [
        "Build a focused live news reader",
        "Create a stock watchlist with a chart",
        "Make a personal income and expense ledger",
        "Design an original platform game",
        "Add a camera and QR scanner toolkit",
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
        .sheet(item: $pendingGeneration) { pending in
            if pending.mode == .designOnly {
                DesignGenerationReviewSheet(
                    before: pending.previousDocument,
                    after: pending.document,
                    summary: pending.designSummary ?? DesignChangeSummary(
                        before: pending.previousDocument,
                        after: pending.document
                    ),
                    onCancel: { pendingGeneration = nil },
                    onApply: { apply(pending) }
                )
                .presentationDetents([.large])
            } else {
                CapabilityReviewSheet(
                    capabilities: pending.addedCapabilities,
                    onCancel: { pendingGeneration = nil },
                    onApprove: { apply(pending) }
                )
                .presentationDetents([.medium, .large])
            }
        }
        .sheet(item: $designStudioProject) { project in
            DesignStudioSheet(
                project: project,
                onApply: { result in
                    try store.applyDesign(
                        result.theme,
                        tint: result.tint,
                        symbol: result.symbol,
                        pagePresentation: result.pagePresentation,
                        canvasBackgroundImageData: result.canvasBackgroundImageData,
                        removesCanvasBackground: result.removesCanvasBackground,
                        to: project.id
                    )
                    designStudioProject = nil
                    generationNote = "Design applied as version \(project.document.version + 1)."
                },
                onUseAIPrompt: { designPrompt in
                    prompt = designPrompt
                    generationMode = .designOnly
                    designStudioProject = nil
                    generationNote = "Design-only request is ready. Review it, then generate."
                }
            )
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
                    onAddImage: { store.addImageBlock(to: project.id) },
                    onOpenStudio: { designStudioProject = project }
                )

                BuilderPromptCard(
                    prompt: $prompt,
                    generationMode: $generationMode,
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
        let requestedMode = generationMode

        isGenerating = true
        generationNote = nil
        errorMessage = nil

        Task {
            do {
                let config = try aiSettings.connectionConfig()
                let document = try await client.generate(
                    prompt: requestedMode.promptPrefix + request,
                    currentDocument: project.document,
                    config: config
                )
                let mode = requestedMode
                let finalDocument = mode == .designOnly
                    ? AppDocumentDesignMerger().mergeDesign(from: document, into: project.document)
                    : document
                let existingCapabilities = Set(project.document.capabilities)
                let addedCapabilities = Set(finalDocument.capabilities)
                    .subtracting(existingCapabilities)
                    .sorted(by: { $0.rawValue < $1.rawValue })
                let pending = PendingGeneration(
                    projectID: project.id,
                    document: finalDocument,
                    prompt: request,
                    addedCapabilities: addedCapabilities,
                    mode: mode,
                    previousDocument: project.document,
                    designSummary: mode == .designOnly
                        ? DesignChangeSummary(before: project.document, after: finalDocument)
                        : nil
                )
                if addedCapabilities.isEmpty && mode == .full {
                    try applyImmediately(pending)
                } else {
                    pendingGeneration = pending
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isGenerating = false
        }
    }

    private func apply(_ pending: PendingGeneration) {
        do {
            try applyImmediately(pending)
            pendingGeneration = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyImmediately(_ pending: PendingGeneration) throws {
        try store.replaceDocument(
            projectID: pending.projectID,
            with: pending.document,
            prompt: pending.prompt
        )
        withAnimation(.snappy) {
            prompt = ""
            if let summary = pending.designSummary {
                generationNote = "Design updated: \(summary.conciseDescription)."
            } else {
                generationNote = "Version \(pending.document.version) passed validation and is ready to use."
            }
            generationMode = .full
            isPresentingRuntime = true
        }
    }
}

private struct BuilderPromptCard: View {
    @Binding var prompt: String
    @Binding var generationMode: GenerationMode
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
                .accessibilityIdentifier("builder.prompt")
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

            Picker("Generation mode", selection: $generationMode) {
                ForEach(GenerationMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .disabled(isGenerating)
            .accessibilityHint(
                generationMode == .designOnly
                    ? "Features, actions, data, and capabilities will be locked by the host"
                    : "AI may update both features and design"
            )

            if generationMode == .designOnly {
                Label("保留功能，只改設計", systemImage: "lock.shield.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
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
            .accessibilityIdentifier("builder.generate")
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
