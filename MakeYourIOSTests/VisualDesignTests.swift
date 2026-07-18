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
        XCTAssertTrue(themes.allSatisfy(\.resolvedPalette.isValid))
    }

    func testLegacyDesignGenomeFieldsDecodeAsOptionalDefaults() throws {
        var source = SampleDocuments.museJournal
        source.theme?.backgroundAssetBinding = "journal-background"
        source.pages[0].presentation?.navigationStyle = .chips
        source.pages[0].nodes[0].image?.mediaRole = .hero
        source.pages[0].nodes[0].image?.focalPoint = .top
        source.pages[0].nodes[0].image?.mask = .capsule
        source.pages[0].nodes[0].image?.overlay = .scrim

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encoded = try encoder.encode(source)
        var root = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        var theme = try XCTUnwrap(root["theme"] as? [String: Any])
        for key in [
            "palette", "typeScale", "titleWeight", "elevation", "stroke", "controlShape",
            "motion", "backgroundAssetBinding"
        ] {
            theme.removeValue(forKey: key)
        }
        root["theme"] = theme

        var pages = try XCTUnwrap(root["pages"] as? [[String: Any]])
        var pagePresentation = try XCTUnwrap(pages[0]["presentation"] as? [String: Any])
        pagePresentation.removeValue(forKey: "navigationStyle")
        pages[0]["presentation"] = pagePresentation
        var nodes = try XCTUnwrap(pages[0]["nodes"] as? [[String: Any]])
        var image = try XCTUnwrap(nodes[0]["image"] as? [String: Any])
        ["mediaRole", "focalPoint", "mask", "overlay"].forEach {
            image.removeValue(forKey: $0)
        }
        nodes[0]["image"] = image
        pages[0]["nodes"] = nodes
        root["pages"] = pages

        let data = try JSONSerialization.data(withJSONObject: root)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(AppDocument.self, from: data)

        XCTAssertNil(decoded.theme?.palette)
        XCTAssertEqual(decoded.resolvedTheme.resolvedTypeScale, .expressive)
        XCTAssertEqual(decoded.pages[0].resolvedPresentation.resolvedNavigationStyle, .automatic)
        XCTAssertEqual(decoded.pages[0].nodes[0].image?.resolvedMediaRole, .content)
        XCTAssertEqual(decoded.pages[0].nodes[0].image?.resolvedFocalPoint, .center)
        XCTAssertEqual(decoded.pages[0].nodes[0].image?.resolvedMask, .rounded)
        XCTAssertEqual(decoded.pages[0].nodes[0].image?.resolvedOverlay, ImageOverlay.none)
    }

    func testRendererCatalogCanonicalizesOnlyUnsupportedVariants() {
        XCTAssertTrue(ComponentKind.allCases.allSatisfy {
            RendererCatalog.supportedVariants(for: $0).contains(.automatic)
        })
        XCTAssertEqual(RendererCatalog.normalizedVariant(.immersive, for: .game), .immersive)
        XCTAssertEqual(RendererCatalog.normalizedVariant(.immersive, for: .button), .automatic)
        XCTAssertTrue(RendererCatalog.supportedVariants(for: .newsFeed).contains(.editorial))
        XCTAssertTrue(RendererCatalog.supportedVariants(for: .button).contains(.softAction))
    }

    func testValidatorRejectsInvalidPaletteAndIncompatiblePersistedRenderer() {
        var invalidPalette = SampleDocuments.blank
        var theme = AppVisualTheme.preset(.native)
        theme.palette?.accentHex = "red"
        invalidPalette.theme = theme
        XCTAssertThrowsError(try AppDocumentValidator().validate(invalidPalette)) { error in
            XCTAssertEqual(error as? AppDocumentValidationError, .invalidVisualTheme)
        }

        var invalidRenderer = SampleDocuments.blank
        invalidRenderer.pages[0].nodes[0].presentation = ComponentPresentation(
            surface: .plain,
            span: .full,
            alignment: .leading,
            emphasis: .regular,
            variant: .outlinedAction
        )
        XCTAssertThrowsError(try AppDocumentValidator().validate(invalidRenderer)) { error in
            XCTAssertEqual(
                error as? AppDocumentValidationError,
                .unsupportedVariant(.hero, .outlinedAction)
            )
        }
    }

    func testBackgroundBindingAndEditableHeroDerivePhotoPickerCapability() throws {
        var background = SampleDocuments.blank
        var theme = background.resolvedTheme
        theme.backgroundAssetBinding = "personal-background"
        background.theme = theme
        background.capabilities = AppCapabilityResolver.requiredCapabilities(for: background)
            .sorted(by: { $0.rawValue < $1.rawValue })
        XCTAssertTrue(background.capabilities.contains(.photoPicker))
        XCTAssertNoThrow(try AppDocumentValidator().validate(background))
        background.capabilities.removeAll(where: { $0 == .photoPicker })
        XCTAssertThrowsError(try AppDocumentValidator().validate(background)) { error in
            XCTAssertEqual(error as? AppDocumentValidationError, .missingCapability(.photoPicker))
        }

        var hero = SampleDocuments.blank
        hero.pages[0].nodes = [
            ComponentNode(
                id: "hero",
                kind: .hero,
                title: "Personal hero",
                binding: "hero-photo",
                image: ImageSpec(
                    aspect: .banner,
                    contentMode: .fill,
                    altText: "A photo selected by the user",
                    decorative: false,
                    allowsUserSelection: true,
                    mediaRole: .hero,
                    focalPoint: .top,
                    mask: ImageMask.none,
                    overlay: .scrim
                )
            )
        ]
        hero.capabilities = AppCapabilityResolver.requiredCapabilities(for: hero)
            .sorted(by: { $0.rawValue < $1.rawValue })
        XCTAssertTrue(hero.capabilities.contains(.photoPicker))
        XCTAssertNoThrow(try AppDocumentValidator().validate(hero))
    }

    func testUnrelatedComponentCannotPersistImageConfiguration() {
        var document = SampleDocuments.blank
        document.pages[0].nodes = [
            ComponentNode(
                id: "text-with-image",
                kind: .text,
                title: "Text",
                binding: "unrelated-image",
                image: .editableLandscape
            )
        ]

        XCTAssertThrowsError(try AppDocumentValidator().validate(document)) { error in
            XCTAssertEqual(
                error as? AppDocumentValidationError,
                .invalidComponentConfiguration(.text)
            )
        }
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
