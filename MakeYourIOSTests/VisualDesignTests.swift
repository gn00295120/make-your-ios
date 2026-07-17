import XCTest
@testable import MakeYourIOS

final class VisualDesignTests: XCTestCase {
    func testLegacyDocumentWithoutDesignFieldsStillDecodes() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encoded = try encoder.encode(SampleDocuments.quickConvert)
        var root = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )

        root.removeValue(forKey: "theme")
        var pages = try XCTUnwrap(root["pages"] as? [[String: Any]])
        for pageIndex in pages.indices {
            pages[pageIndex].removeValue(forKey: "presentation")
            var nodes = try XCTUnwrap(pages[pageIndex]["nodes"] as? [[String: Any]])
            for nodeIndex in nodes.indices {
                nodes[nodeIndex].removeValue(forKey: "presentation")
                nodes[nodeIndex].removeValue(forKey: "image")
            }
            pages[pageIndex]["nodes"] = nodes
        }
        root["pages"] = pages

        let legacyData = try JSONSerialization.data(withJSONObject: root)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(AppDocument.self, from: legacyData)

        XCTAssertNil(decoded.theme)
        XCTAssertEqual(decoded.resolvedTheme, .legacy)
        XCTAssertNil(decoded.pages[0].presentation)
        XCTAssertNil(decoded.pages[0].nodes[0].presentation)
        XCTAssertNil(decoded.pages[0].nodes[0].image)
    }

    func testDashboardPairsOnlySafeHalfWidthComponents() {
        let metric = ComponentNode(
            id: "metric",
            kind: .metric,
            title: "Metric",
            presentation: halfWidthPresentation
        )
        let image = ComponentNode(
            id: "image",
            kind: .image,
            title: "Image",
            binding: "image",
            presentation: halfWidthPresentation,
            image: .editableLandscape
        )
        let taskList = ComponentNode(
            id: "tasks",
            kind: .taskList,
            title: "Tasks",
            presentation: halfWidthPresentation
        )

        let rows = PageLayoutEngine.rows(
            for: [metric, image, taskList],
            layout: .dashboard,
            collapseColumns: false
        )

        XCTAssertEqual(rows.map(\.nodes.count), [2, 1])
        XCTAssertEqual(rows[0].nodes.map(\.id), ["metric", "image"])
        XCTAssertEqual(rows[1].nodes.map(\.id), ["tasks"])
    }

    func testAccessibilityTypeCollapsesDashboardToOneColumn() {
        let nodes = ["one", "two"].map {
            ComponentNode(
                id: $0,
                kind: .metric,
                presentation: halfWidthPresentation
            )
        }

        let rows = PageLayoutEngine.rows(
            for: nodes,
            layout: .dashboard,
            collapseColumns: true
        )

        XCTAssertEqual(rows.map(\.nodes.count), [1, 1])
    }

    func testThemePresetsProduceDistinctTokenCombinations() {
        let themes = VisualThemePreset.allCases.map(AppVisualTheme.preset)
        XCTAssertEqual(Set(themes).count, VisualThemePreset.allCases.count)
        XCTAssertTrue(themes.contains(where: { $0.defaultSurface == .plain }))
        XCTAssertTrue(themes.contains(where: { $0.typography == .serif }))
        XCTAssertTrue(themes.contains(where: { $0.appearance == .dark }))
    }

    private var halfWidthPresentation: ComponentPresentation {
        ComponentPresentation(
            surface: .card,
            span: .half,
            alignment: .leading,
            emphasis: .regular,
            variant: .automatic
        )
    }
}
