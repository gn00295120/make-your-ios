import SwiftUI

struct NewsFeedRuntimeView: View {
    private struct CachedState: Codable {
        var articles: [NewsArticle]
        var bookmarks: [String: NewsArticle]
        var topics: [String]
        var selectedTopics: Set<String>
        var lastUpdated: Date?
    }

    private enum DisplayMode: String, CaseIterable, Identifiable {
        case latest = "Latest"
        case saved = "Saved"

        var id: String { rawValue }
    }

    let projectID: UUID
    let node: ComponentNode
    let tint: AppTint

    @Environment(\.runtimeDesign) private var design

    @State private var articles: [NewsArticle] = []
    @State private var bookmarks: [String: NewsArticle] = [:]
    @State private var topics: [String]
    @State private var selectedTopics: Set<String> = []
    @State private var searchText = ""
    @State private var displayMode: DisplayMode = .latest
    @State private var lastUpdated: Date?
    @State private var errorMessage: String?
    @State private var isRefreshing = false
    @State private var hasLoaded = false
    @State private var isEditingTopics = false

    private let client = NewsFeedClient()
    private let stateStore = ProjectRuntimeStateStore()

    init(projectID: UUID, node: ComponentNode, tint: AppTint) {
        self.projectID = projectID
        self.node = node
        self.tint = tint
        _topics = State(initialValue: Self.normalizedTopics(node.newsFeed?.topics ?? []))
    }

    private var spec: NewsFeedSpec {
        node.newsFeed ?? NewsFeedSpec(
            sources: [.bbcWorld, .nprNews],
            topics: [],
            allowsTopicEditing: true,
            allowsBookmarks: true,
            maximumItems: 20
        )
    }

    private var displayedArticles: [NewsArticle] {
        let candidates = displayMode == .saved
            ? Array(bookmarks.values).sorted {
                ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast)
            }
            : articles
        return candidates.filter {
            NewsArticleFilter.matches(
                $0,
                searchText: searchText,
                selectedTopics: selectedTopics
            )
        }
    }

    private var variant: ComponentVariant {
        RendererCatalog.normalizedVariant(node.resolvedPresentation.variant, for: .newsFeed)
    }

    private var contentSpacing: CGFloat {
        [.compact, .dense].contains(variant) ? 9 : design.componentSpacing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: contentSpacing) {
            header
            controls
            topicFilters
            status
            articleList
            NewsSourceCredit(sources: spec.sources)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task {
            guard !hasLoaded else { return }
            hasLoaded = true
            loadCachedState()
            await refresh()
        }
        .sheet(isPresented: $isEditingTopics) {
            NewsTopicEditorView(topics: $topics, tint: tint)
                .onDisappear {
                    selectedTopics.formIntersection(Set(topics))
                    persist()
                }
        }
    }
}

extension NewsFeedRuntimeView {
    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(node.title.isEmpty ? "News" : node.title)
                    .font(variant == .editorial ? design.titleFont : design.sectionFont)
                    .accessibilityAddTraits(.isHeader)
                if !node.subtitle.isEmpty {
                    Text(node.subtitle)
                        .font(design.captionFont)
                        .foregroundStyle(design.secondaryForeground)
                }
            }
            Spacer()
            Button {
                Task { await refresh() }
            } label: {
                if isRefreshing {
                    ProgressView().frame(width: 36, height: 36)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 36, height: 36)
                }
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .tint(design.accent)
            .disabled(isRefreshing)
            .accessibilityLabel("Refresh news")
        }
    }

    private var controls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search headlines and topics", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, [.compact, .dense].contains(variant) ? 8 : 11)
            .background(
                variant == .cards ? design.surface : design.accent.opacity(0.08),
                in: RoundedRectangle(cornerRadius: design.controlCornerRadius, style: .continuous)
            )
            .overlay {
                if design.increasedContrast {
                    RoundedRectangle(cornerRadius: design.controlCornerRadius, style: .continuous)
                        .stroke(design.borderColor, lineWidth: design.borderWidth)
                }
            }

            if spec.allowsBookmarks {
                Picker("Articles", selection: $displayMode) {
                    ForEach(DisplayMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    @ViewBuilder
    private var topicFilters: some View {
        if !topics.isEmpty || spec.allowsTopicEditing {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(topics, id: \.self) { topic in
                        Button {
                            if selectedTopics.contains(topic) {
                                selectedTopics.remove(topic)
                            } else {
                                selectedTopics.insert(topic)
                            }
                            persist()
                        } label: {
                            Text(topic)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 11)
                                .padding(.vertical, 8)
                                .foregroundStyle(
                                    selectedTopics.contains(topic) ? design.onAccent : design.accent
                                )
                                .background(
                                    selectedTopics.contains(topic)
                                        ? design.accent
                                        : design.accent.opacity(0.12),
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    if spec.allowsTopicEditing {
                        Button {
                            isEditingTopics = true
                        } label: {
                            Label("Topics", systemImage: "slider.horizontal.3")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 11)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .tint(design.accent)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var status: some View {
        if let errorMessage {
            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.orange)
        } else if let lastUpdated {
            Label {
                Text("Updated \(lastUpdated, style: .relative)")
            } icon: {
                Image(systemName: "clock")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var articleList: some View {
        if isRefreshing && articles.isEmpty {
            HStack {
                Spacer()
                ProgressView("Loading headlines…")
                Spacer()
            }
            .padding(.vertical, 24)
        } else if displayedArticles.isEmpty {
            ContentUnavailableView(
                displayMode == .saved ? "No saved stories" : "No matching stories",
                systemImage: displayMode == .saved ? "bookmark" : "newspaper",
                description: Text(
                    displayMode == .saved
                        ? "Bookmark an article to keep it here."
                        : "Try another search or topic."
                )
            )
            .frame(maxWidth: .infinity)
        } else {
            LazyVStack(spacing: variant == .cards ? 10 : 0) {
                ForEach(Array(displayedArticles.enumerated()), id: \.element.id) { index, article in
                    NewsArticleRow(
                        article: article,
                        tint: tint,
                        variant: variant,
                        allowsBookmarks: spec.allowsBookmarks,
                        isBookmarked: bookmarks[article.id] != nil,
                        onToggleBookmark: { toggleBookmark(article) }
                    )
                    .padding(variant == .cards ? 12 : 0)
                    .background(
                        variant == .cards ? design.surface : .clear,
                        in: RoundedRectangle(
                            cornerRadius: design.compactCornerRadius,
                            style: .continuous
                        )
                    )
                    .overlay {
                        if variant == .cards {
                            RoundedRectangle(
                                cornerRadius: design.compactCornerRadius,
                                style: .continuous
                            )
                            .stroke(
                                design.borderColor.opacity(design.borderOpacity),
                                lineWidth: design.borderWidth
                            )
                        }
                    }
                    if variant != .cards, index < displayedArticles.count - 1 {
                        Divider().padding(.leading, 12)
                    }
                }
            }
        }
    }

    private func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            articles = try await client.latest(
                sources: spec.sources,
                maximumItems: spec.maximumItems
            )
            lastUpdated = .now
            errorMessage = nil
            persist()
        } catch {
            errorMessage = articles.isEmpty
                ? error.localizedDescription
                : "Couldn’t refresh. Showing saved headlines."
        }
    }

    private func toggleBookmark(_ article: NewsArticle) {
        if bookmarks[article.id] == nil {
            bookmarks[article.id] = article
        } else {
            bookmarks[article.id] = nil
        }
        persist()
    }

    private func loadCachedState() {
        guard let cached = try? stateStore.load(
            CachedState.self,
            projectID: projectID,
            nodeID: node.id,
            namespace: "news-feed-v1"
        ) else { return }
        articles = cached.articles
        bookmarks = cached.bookmarks
        topics = Self.normalizedTopics(cached.topics)
        selectedTopics = cached.selectedTopics.intersection(Set(topics))
        lastUpdated = cached.lastUpdated
    }

    private func persist() {
        let state = CachedState(
            articles: Array(articles.prefix(40)),
            bookmarks: bookmarks,
            topics: topics,
            selectedTopics: selectedTopics,
            lastUpdated: lastUpdated
        )
        do {
            try stateStore.save(
                state,
                projectID: projectID,
                nodeID: node.id,
                namespace: "news-feed-v1"
            )
        } catch {
            errorMessage = "News changes could not be saved."
        }
    }

    private static func normalizedTopics(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.compactMap { value in
            let trimmed = String(value.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
            guard !trimmed.isEmpty, seen.insert(trimmed.lowercased()).inserted else { return nil }
            return trimmed
        }
        .prefix(8)
        .map { $0 }
    }
}
