import SwiftUI

struct AppLibraryView: View {
    @Environment(WorkspaceStore.self) private var store
    let openProject: (UUID) -> Void
    let openBuilder: () -> Void

    @State private var searchText = ""
    @State private var showingCreateSheet = false
    @State private var projectToDelete: WorkspaceProject?

    private var filteredProjects: [WorkspaceProject] {
        guard !searchText.isEmpty else { return store.projects }
        return store.projects.filter {
            $0.document.name.localizedCaseInsensitiveContains(searchText)
                || $0.document.summary.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                LibraryHeroView(projectCount: store.projects.count)

                HStack {
                    Text("Your apps")
                        .font(.title2.bold())
                    Spacer()
                    Text("\(store.projects.count)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.quaternary, in: Capsule())
                }

                if filteredProjects.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .frame(minHeight: 260)
                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 156), spacing: 14)],
                        spacing: 14
                    ) {
                        ForEach(filteredProjects) { project in
                            Button {
                                openProject(project.id)
                            } label: {
                                ProjectCardView(project: project)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button {
                                    store.select(project.id)
                                    openBuilder()
                                } label: {
                                    Label("Edit in Builder", systemImage: "wand.and.stars")
                                }
                                Button {
                                    store.duplicate(project.id)
                                } label: {
                                    Label("Duplicate", systemImage: "plus.square.on.square")
                                }
                                Button(role: .destructive) {
                                    projectToDelete = project
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .accessibilityHint("Opens \(project.document.name)")
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .background(MakeYourTheme.canvas)
        .navigationTitle("MakeYour")
        .searchable(text: $searchText, prompt: "Find an app")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create app")
                .accessibilityIdentifier("library.create")
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateAppSheet { document in
                store.createProject(document: document)
                showingCreateSheet = false
                openBuilder()
            }
            .presentationDetents([.large])
        }
        .confirmationDialog(
            "Delete \(projectToDelete?.document.name ?? "this app")?",
            isPresented: Binding(
                get: { projectToDelete != nil },
                set: { if !$0 { projectToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete app and its local data", role: .destructive) {
                if let projectToDelete { store.delete(projectToDelete.id) }
                projectToDelete = nil
            }
            Button("Cancel", role: .cancel) { projectToDelete = nil }
        }
    }
}

private struct LibraryHeroView: View {
    let projectCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Your tiny apps.")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                    Text("One home.")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.white.opacity(0.78))
                }
                Spacer()
                Image(systemName: "square.3.layers.3d.top.filled")
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
            }

            Text(
                "Build a news reader, scanner, game, tracker, calculator, or AI tool — "
                    + "then change it whenever life changes."
            )
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)

            Label("\(projectCount) private apps on this device", systemImage: "lock.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.86))
        }
        .padding(22)
        .background(MakeYourTheme.brandGradient, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(.white.opacity(0.10))
                .frame(width: 140, height: 140)
                .offset(x: 45, y: -55)
                .allowsHitTesting(false)
        }
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
    }
}

private struct ProjectCardView: View {
    let project: WorkspaceProject

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top) {
                AppGlyph(symbol: project.document.symbol, tint: project.document.tint, size: 52)
                Spacer()
                Text("v\(project.document.version)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(project.document.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(project.document.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .frame(minHeight: 48, alignment: .top)
            }

            HStack(spacing: 5) {
                ForEach(project.document.capabilities.prefix(3), id: \.self) { capability in
                    Image(systemName: capability.symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(project.document.tint.color)
                        .frame(width: 24, height: 24)
                        .background(project.document.tint.color.opacity(0.10), in: Circle())
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 186, alignment: .topLeading)
        .makeYourCard(padding: 16)
    }
}

private struct CreateAppSheet: View {
    let onCreate: (AppDocument) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Start with a useful shape")
                            .font(.title2.bold())
                        Text("AI can change every detail after you choose.")
                            .foregroundStyle(.secondary)
                    }

                    TemplateButton(
                        document: SampleDocuments.blank,
                        label: "Blank canvas",
                        detail: "Start from one sentence",
                        onCreate: onCreate
                    )
                    TemplateButton(
                        document: SampleDocuments.captureKit,
                        label: "Device toolkit",
                        detail: "Camera, QR, location, files, and more",
                        onCreate: onCreate
                    )
                    TemplateButton(
                        document: SampleDocuments.dailyBrief,
                        label: "Live news reader",
                        detail: "Credited feeds, topics, and bookmarks",
                        onCreate: onCreate
                    )
                    TemplateButton(
                        document: SampleDocuments.marketPocket,
                        label: "Stock watchlist",
                        detail: "Latest quotes, symbols, and charts",
                        onCreate: onCreate
                    )
                    TemplateButton(
                        document: SampleDocuments.pocketLedger,
                        label: "Personal ledger",
                        detail: "Income, expenses, budgets, and charts",
                        onCreate: onCreate
                    )
                    TemplateButton(
                        document: SampleDocuments.skybound,
                        label: "Original game",
                        detail: "Touch controls, scoring, and saved bests",
                        onCreate: onCreate
                    )
                    TemplateButton(
                        document: SampleDocuments.quickConvert,
                        label: "Calculator",
                        detail: "Inputs, formulas, and results",
                        onCreate: onCreate
                    )
                    TemplateButton(
                        document: SampleDocuments.gentleTasks,
                        label: "Task + notify",
                        detail: "A list with local reminders",
                        onCreate: onCreate
                    )
                    TemplateButton(
                        document: SampleDocuments.liveFXWatch,
                        label: "Live data watchlist",
                        detail: "Editable currencies and rate alerts",
                        onCreate: onCreate
                    )
                    TemplateButton(
                        document: SampleDocuments.useItFirst,
                        label: "Personal tracker + AI",
                        detail: "Photos, records, reminders, and reviewed AI",
                        onCreate: onCreate
                    )
                    TemplateButton(
                        document: SampleDocuments.museJournal,
                        label: "Photo + AI journal",
                        detail: "Personal images and user-triggered AI",
                        onCreate: onCreate
                    )
                }
                .padding(20)
            }
            .background(MakeYourTheme.canvas)
            .navigationTitle("New app")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

private struct TemplateButton: View {
    let document: AppDocument
    let label: String
    let detail: String
    let onCreate: (AppDocument) -> Void

    var body: some View {
        Button {
            var copy = document
            copy.id = UUID()
            copy.updatedAt = .now
            onCreate(copy)
        } label: {
            HStack(spacing: 15) {
                AppGlyph(symbol: document.symbol, tint: document.tint, size: 50)
                VStack(alignment: .leading, spacing: 3) {
                    Text(label).font(.headline).foregroundStyle(.primary)
                    Text(detail).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .makeYourCard()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityIdentifier(templateIdentifier)
    }

    private var templateIdentifier: String {
        let slug = label.lowercased().replacingOccurrences(of: " ", with: "-")
        return "create.template.\(slug)"
    }
}
