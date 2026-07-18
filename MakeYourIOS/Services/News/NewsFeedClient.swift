import Foundation

struct NewsArticle: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var source: NewsSourceKind
    var title: String
    var summary: String
    var url: URL
    var publishedAt: Date?
    var categories: [String]
}

extension NewsSourceKind {
    var displayName: String {
        switch self {
        case .bbcWorld: "BBC World"
        case .bbcTechnology: "BBC Technology"
        case .nprNews: "NPR News"
        }
    }

    var feedURL: URL {
        switch self {
        case .bbcWorld:
            URL(string: "https://feeds.bbci.co.uk/news/world/rss.xml")!
        case .bbcTechnology:
            URL(string: "https://feeds.bbci.co.uk/news/technology/rss.xml")!
        case .nprNews:
            URL(string: "https://feeds.npr.org/1001/rss.xml")!
        }
    }

    var creditURL: URL {
        switch self {
        case .bbcWorld:
            URL(string: "https://www.bbc.com/news/world")!
        case .bbcTechnology:
            URL(string: "https://www.bbc.com/news/technology")!
        case .nprNews:
            URL(string: "https://www.npr.org/sections/news/")!
        }
    }
}

enum NewsArticleFilter {
    static func matches(
        _ article: NewsArticle,
        searchText: String,
        selectedTopics: Set<String>
    ) -> Bool {
        let haystack = normalized(
            [article.title, article.summary, article.categories.joined(separator: " ")]
                .joined(separator: " ")
        )
        let searchTerms = normalized(searchText)
            .split(separator: " ")
            .map(String.init)
        let matchesSearch = searchTerms.allSatisfy(haystack.contains)
        let matchesTopic = selectedTopics.isEmpty || selectedTopics.contains { topic in
            haystack.contains(normalized(topic))
        }
        return matchesSearch && matchesTopic
    }

    private static func normalized(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
    }
}

struct NewsFeedClient: Sendable {
    private struct FetchResult: Sendable {
        var articles: [NewsArticle]
        var error: NewsFeedError?
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func latest(
        sources: [NewsSourceKind],
        maximumItems: Int
    ) async throws -> [NewsArticle] {
        let uniqueSources = Array(Set(sources)).sorted { $0.rawValue < $1.rawValue }
        guard !uniqueSources.isEmpty else { throw NewsFeedError.noSources }

        let results = await withTaskGroup(of: FetchResult.self) { group in
            for source in uniqueSources {
                group.addTask {
                    do {
                        return FetchResult(articles: try await fetch(source: source), error: nil)
                    } catch let error as NewsFeedError {
                        return FetchResult(articles: [], error: error)
                    } catch {
                        return FetchResult(articles: [], error: .invalidResponse)
                    }
                }
            }

            var collected: [FetchResult] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        let articles = results.flatMap(\.articles)
        guard !articles.isEmpty else {
            throw results.compactMap(\.error).first ?? NewsFeedError.noArticles
        }

        var seenURLs = Set<String>()
        return articles
            .sorted { lhs, rhs in
                (lhs.publishedAt ?? .distantPast) > (rhs.publishedAt ?? .distantPast)
            }
            .filter { seenURLs.insert($0.url.absoluteString).inserted }
            .prefix(min(max(maximumItems, 5), 40))
            .map { $0 }
    }

    private func fetch(source: NewsSourceKind) async throws -> [NewsArticle] {
        let request = Self.makeRequest(source: source)
        let (data, response) = try await session.data(for: request)
        try Self.validate(response: response)
        return try Self.decodeFeed(data, source: source)
    }

    static func makeRequest(source: NewsSourceKind) -> URLRequest {
        var request = URLRequest(url: source.feedURL)
        request.timeoutInterval = 20
        request.cachePolicy = .reloadRevalidatingCacheData
        request.setValue("MakeYour/1.0 RSS reader", forHTTPHeaderField: "User-Agent")
        request.setValue(
            "application/rss+xml, application/xml;q=0.9, text/xml;q=0.8",
            forHTTPHeaderField: "Accept"
        )
        return request
    }

    static func decodeFeed(_ data: Data, source: NewsSourceKind) throws -> [NewsArticle] {
        let delegate = RSSParserDelegate(source: source)
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.shouldProcessNamespaces = false
        parser.shouldReportNamespacePrefixes = true
        guard parser.parse() else {
            throw NewsFeedError.invalidFeed
        }
        guard !delegate.articles.isEmpty else {
            throw NewsFeedError.noArticles
        }
        return delegate.articles
    }

    private static func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NewsFeedError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NewsFeedError.api(statusCode: httpResponse.statusCode)
        }
    }
}

enum NewsFeedError: LocalizedError, Equatable, Sendable {
    case noSources
    case invalidResponse
    case invalidFeed
    case noArticles
    case api(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .noSources:
            "Choose at least one news source."
        case .invalidResponse:
            "A news source returned an invalid response."
        case .invalidFeed:
            "A news source returned an unreadable feed."
        case .noArticles:
            "No articles are available from the selected sources."
        case .api:
            "A news source could not be refreshed."
        }
    }
}

private final class RSSParserDelegate: NSObject, XMLParserDelegate {
    private static let itemElements: Set<String> = ["item", "entry"]
    private static let summaryElements: Set<String> = ["description", "summary", "encoded"]
    private static let identifierElements: Set<String> = ["guid", "id"]
    private static let dateElements: Set<String> = ["pubdate", "published", "updated"]

    private struct Draft {
        var title = ""
        var summary = ""
        var link = ""
        var identifier = ""
        var published = ""
        var categories: [String] = []
    }

    private let source: NewsSourceKind
    private var draft: Draft?
    private var textBuffer = ""

    private(set) var articles: [NewsArticle] = []

    init(source: NewsSourceKind) {
        self.source = source
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        let name = Self.localName(qName ?? elementName)
        if Self.itemElements.contains(name) {
            draft = Draft()
        }
        guard draft != nil else { return }
        textBuffer = ""
        if name == "link", let href = attributeDict["href"], !href.isEmpty {
            draft?.link = href
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard draft != nil else { return }
        textBuffer += string
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        guard draft != nil, let value = String(data: CDATABlock, encoding: .utf8) else { return }
        textBuffer += value
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        guard var item = draft else { return }
        let name = Self.localName(qName ?? elementName)
        let value = Self.cleanText(textBuffer)

        if Self.itemElements.contains(name) {
            if let article = makeArticle(from: item) {
                articles.append(article)
            }
            draft = nil
        } else {
            item = Self.updatedDraft(item, element: name, value: value)
            draft = item
        }
        textBuffer = ""
    }

    private static func updatedDraft(_ draft: Draft, element: String, value: String) -> Draft {
        var updated = draft
        switch element {
        case "title":
            updated.title = value
        case let name where summaryElements.contains(name):
            updated.summary = updated.summary.isEmpty || name != "encoded" ? value : updated.summary
        case "link":
            updated.link = updated.link.isEmpty ? value : updated.link
        case let name where identifierElements.contains(name):
            updated.identifier = value
        case let name where dateElements.contains(name):
            updated.published = value
        case "category":
            updated.categories += value.isEmpty ? [] : [value]
        default:
            break
        }
        return updated
    }

    private func makeArticle(from draft: Draft) -> NewsArticle? {
        guard !draft.title.isEmpty,
              let url = URL(string: draft.link),
              url.scheme == "https" || url.scheme == "http" else {
            return nil
        }
        let stableID = draft.identifier.isEmpty ? url.absoluteString : draft.identifier
        return NewsArticle(
            id: "\(source.rawValue)|\(stableID)",
            source: source,
            title: String(draft.title.prefix(240)),
            summary: String(draft.summary.prefix(800)),
            url: url,
            publishedAt: Self.parseDate(draft.published),
            categories: Array(Set(draft.categories.filter { !$0.isEmpty })).sorted()
        )
    }

    private static func localName(_ value: String) -> String {
        value.split(separator: ":").last.map(String.init)?.lowercased() ?? value.lowercased()
    }

    private static func cleanText(_ value: String) -> String {
        let withoutMarkup = value.replacingOccurrences(
            of: "<[^>]+>",
            with: " ",
            options: .regularExpression
        )
        return withoutMarkup
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func parseDate(_ value: String) -> Date? {
        guard !value.isEmpty else { return nil }
        let formats = [
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "EEE, d MMM yyyy HH:mm:ss Z",
            "yyyy-MM-dd'T'HH:mm:ssXXXXX",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd"
        ]
        for format in formats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = format
            if let date = formatter.date(from: value) { return date }
        }
        return nil
    }
}
