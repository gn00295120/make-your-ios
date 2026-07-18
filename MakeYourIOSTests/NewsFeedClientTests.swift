import XCTest
@testable import MakeYourIOS

final class NewsFeedClientTests: XCTestCase {
    func testEveryNewsSourceUsesItsFixedHTTPSFeedHost() {
        let requests = Dictionary(uniqueKeysWithValues: NewsSourceKind.allCases.map {
            ($0, NewsFeedClient.makeRequest(source: $0))
        })

        XCTAssertEqual(requests[.bbcWorld]?.url?.host, "feeds.bbci.co.uk")
        XCTAssertEqual(requests[.bbcWorld]?.url?.path, "/news/world/rss.xml")
        XCTAssertEqual(requests[.bbcTechnology]?.url?.host, "feeds.bbci.co.uk")
        XCTAssertEqual(requests[.bbcTechnology]?.url?.path, "/news/technology/rss.xml")
        XCTAssertEqual(requests[.nprNews]?.url?.host, "feeds.npr.org")
        XCTAssertEqual(requests[.nprNews]?.url?.path, "/1001/rss.xml")
        XCTAssertTrue(requests.values.allSatisfy { $0.url?.scheme == "https" })
    }

    func testRSSParserProducesCleanStableArticles() throws {
        let data = Data(
            """
            <?xml version="1.0" encoding="UTF-8"?>
            <rss version="2.0">
              <channel>
                <title>Example feed</title>
                <item>
                  <title>AI &amp; climate update</title>
                  <link>https://www.bbc.com/news/articles/example</link>
                  <guid>bbc-example-1</guid>
                  <description><![CDATA[<p>A <strong>useful</strong> summary.</p>]]></description>
                  <pubDate>Fri, 17 Jul 2026 10:30:00 +0000</pubDate>
                  <category>Technology</category>
                  <category>Climate</category>
                </item>
              </channel>
            </rss>
            """.utf8
        )

        let articles = try NewsFeedClient.decodeFeed(data, source: .bbcTechnology)
        let article = try XCTUnwrap(articles.first)

        XCTAssertEqual(article.id, "bbcTechnology|bbc-example-1")
        XCTAssertEqual(article.source, .bbcTechnology)
        XCTAssertEqual(article.title, "AI & climate update")
        XCTAssertEqual(article.summary, "A useful summary.")
        XCTAssertEqual(article.url.host, "www.bbc.com")
        XCTAssertNotNil(article.publishedAt)
        XCTAssertEqual(article.categories, ["Climate", "Technology"])
    }

    func testRSSParserRejectsItemsWithoutSafeOriginalLinks() throws {
        let data = Data(
            """
            <rss version="2.0"><channel>
              <item><title>Missing link</title><description>Nothing</description></item>
              <item><title>Unsafe link</title><link>javascript:alert(1)</link></item>
            </channel></rss>
            """.utf8
        )

        XCTAssertThrowsError(try NewsFeedClient.decodeFeed(data, source: .bbcWorld)) { error in
            XCTAssertEqual(error as? NewsFeedError, .noArticles)
        }
    }

    func testArticleFilterCombinesSearchAndSelectedTopics() {
        let article = NewsArticle(
            id: "article",
            source: .nprNews,
            title: "New battery research cuts charging time",
            summary: "Scientists describe a cleaner transport technology.",
            url: URL(string: "https://www.npr.org/example")!,
            publishedAt: nil,
            categories: ["Science", "Technology"]
        )

        XCTAssertTrue(
            NewsArticleFilter.matches(
                article,
                searchText: "battery research",
                selectedTopics: ["technology"]
            )
        )
        XCTAssertFalse(
            NewsArticleFilter.matches(
                article,
                searchText: "battery",
                selectedTopics: ["politics"]
            )
        )
        XCTAssertFalse(
            NewsArticleFilter.matches(
                article,
                searchText: "quarterly earnings",
                selectedTopics: []
            )
        )
    }
}
