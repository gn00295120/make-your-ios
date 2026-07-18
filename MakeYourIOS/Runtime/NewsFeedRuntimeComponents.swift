import SwiftUI

struct NewsArticleRow: View {
    let article: NewsArticle
    let tint: AppTint
    let allowsBookmarks: Bool
    let isBookmarked: Bool
    let onToggleBookmark: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            originalArticleLink
            if allowsBookmarks {
                bookmarkButton
            }
        }
        .padding(.vertical, 11)
    }

    private var originalArticleLink: some View {
        Link(destination: article.url) {
            VStack(alignment: .leading, spacing: 6) {
                Text(article.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                if !article.summary.isEmpty {
                    Text(article.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                sourceMetadata
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the original article")
    }

    private var sourceMetadata: some View {
        HStack(spacing: 6) {
            Text(article.source.displayName)
            if let publishedAt = article.publishedAt {
                Text("•")
                Text(publishedAt, style: .relative)
            }
            Image(systemName: "arrow.up.right.square")
        }
        .font(.caption2.weight(.medium))
        .foregroundStyle(tint.color)
    }

    private var bookmarkButton: some View {
        Button(action: onToggleBookmark) {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                .foregroundStyle(tint.color)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isBookmarked ? "Remove saved article" : "Save article")
    }
}

struct NewsSourceCredit: View {
    let sources: [NewsSourceKind]

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Headlines are fetched from the publishers below. Open a story to read it at the source.")
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(sources, id: \.self) { source in
                    Link(source.displayName, destination: source.creditURL)
                        .font(.caption2.weight(.semibold))
                }
            }
        }
    }
}

struct NewsTopicEditorView: View {
    @Binding var topics: [String]
    let tint: AppTint

    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Add topic") {
                    HStack {
                        TextField("Example: climate", text: $draft)
                        Button("Add", action: addTopic)
                            .disabled(normalizedDraft.isEmpty || topics.count >= 8)
                    }
                }

                Section("Topics") {
                    if topics.isEmpty {
                        Text("No topic filters yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(topics, id: \.self) { topic in
                            Text(topic)
                        }
                        .onDelete { offsets in
                            topics.remove(atOffsets: offsets)
                        }
                    }
                }
            }
            .navigationTitle("News topics")
            .navigationBarTitleDisplayMode(.inline)
            .tint(tint.color)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var normalizedDraft: String {
        String(draft.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
    }

    private func addTopic() {
        let value = normalizedDraft
        guard !value.isEmpty,
              topics.count < 8,
              !topics.contains(where: { $0.caseInsensitiveCompare(value) == .orderedSame }) else {
            return
        }
        topics.append(value)
        draft = ""
    }
}
