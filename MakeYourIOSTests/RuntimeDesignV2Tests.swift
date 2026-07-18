import SwiftUI
import XCTest
@testable import MakeYourIOS

final class RuntimeDesignV2Tests: XCTestCase {
    func testRuntimeContextResolvesGenomeTokensAndAccessibilityPreferences() {
        var theme = AppVisualTheme.preset(.soft)
        theme.typeScale = .expressive
        theme.titleWeight = .black
        theme.elevation = .floating
        theme.stroke = .accent
        theme.controlShape = .pill
        theme.motion = .expressive

        let context = RuntimeDesignContext(
            theme: theme,
            tint: .coral,
            colorScheme: .dark,
            reduceMotion: true,
            reduceTransparency: true,
            increasedContrast: true,
            differentiateWithoutColor: true
        )

        XCTAssertEqual(context.palette, theme.resolvedPalette)
        XCTAssertEqual(context.typeScale, .expressive)
        XCTAssertEqual(context.titleWeightToken, .black)
        XCTAssertEqual(context.elevation, .floating)
        XCTAssertEqual(context.stroke, .accent)
        XCTAssertEqual(context.controlShape, .pill)
        XCTAssertEqual(context.motion, .expressive)
        XCTAssertTrue(context.usesDarkPalette)
        XCTAssertNil(context.standardAnimation)
        XCTAssertEqual(context.shadowRadius, 0)
        XCTAssertGreaterThan(context.borderWidth, 2)
    }

    func testPageLayoutsProduceDifferentPlans() {
        let nodes = ["one", "two"].map { id in
            ComponentNode(
                id: id,
                kind: .metric,
                presentation: ComponentPresentation(
                    surface: .automatic,
                    span: .adaptive,
                    alignment: .leading,
                    emphasis: .regular,
                    variant: .automatic
                )
            )
        }

        XCTAssertEqual(rowCounts(nodes, layout: .flow), [1, 1])
        XCTAssertEqual(rowCounts(nodes, layout: .dashboard), [2])
        XCTAssertEqual(rowCounts(nodes, layout: .form), [1, 1])
        XCTAssertEqual(rowCounts(nodes, layout: .story), [1, 1])
    }

    func testExplicitHalfWidthFlowsButStoryRemainsImmersive() {
        let nodes = ["one", "two"].map { id in
            ComponentNode(
                id: id,
                kind: .image,
                presentation: ComponentPresentation(
                    surface: .plain,
                    span: .half,
                    alignment: .leading,
                    emphasis: .regular,
                    variant: .framed
                ),
                image: .editableLandscape
            )
        }

        XCTAssertEqual(rowCounts(nodes, layout: .flow), [2])
        XCTAssertEqual(rowCounts(nodes, layout: .story), [1, 1])
    }

    func testAccessibilityTypeAlwaysCollapsesToOneColumn() {
        let nodes = ["one", "two", "three"].map { id in
            ComponentNode(
                id: id,
                kind: .metric,
                presentation: ComponentPresentation(
                    surface: .card,
                    span: .half,
                    alignment: .leading,
                    emphasis: .regular,
                    variant: .cards
                )
            )
        }

        let rows = PageLayoutEngine.rows(for: nodes, layout: .dashboard, collapseColumns: true)

        XCTAssertEqual(rows.map(\.nodes.count), [1, 1, 1])
    }

    func testRendererCatalogExposesOnlyKindCompatibleVariants() {
        XCTAssertTrue(RendererCatalog.supportedVariants(for: .hero).contains(.split))
        XCTAssertTrue(RendererCatalog.supportedVariants(for: .image).contains(.fullBleed))
        XCTAssertTrue(RendererCatalog.supportedVariants(for: .button).contains(.outlinedAction))
        XCTAssertTrue(RendererCatalog.supportedVariants(for: .button).contains(.softAction))
        XCTAssertTrue(RendererCatalog.supportedVariants(for: .game).contains(.immersive))
        XCTAssertEqual(RendererCatalog.normalizedVariant(.timeline, for: .image), .automatic)
        XCTAssertEqual(RendererCatalog.normalizedVariant(.progress, for: .metric), .progress)
    }

    func testMediaDesignDefaultsStayBackwardCompatible() {
        let image = ImageSpec.editableLandscape

        XCTAssertEqual(image.resolvedMediaRole, .content)
        XCTAssertEqual(image.resolvedFocalPoint, .center)
        XCTAssertEqual(image.resolvedMask, .rounded)
        XCTAssertEqual(image.resolvedOverlay, .none)
    }

    private func rowCounts(_ nodes: [ComponentNode], layout: PageLayout) -> [Int] {
        PageLayoutEngine.rows(for: nodes, layout: layout, collapseColumns: false)
            .map(\.nodes.count)
    }
}
