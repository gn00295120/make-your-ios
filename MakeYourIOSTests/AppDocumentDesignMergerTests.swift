import XCTest
@testable import MakeYourIOS

final class AppDocumentDesignMergerTests: XCTestCase {
    func testDesignOnlyMergeKeepsAllFunctionalDocumentData() throws {
        let current = SampleDocuments.gentleTasks
        var proposed = current
        proposed.name = "Changed name"
        proposed.summary = "Changed summary"
        proposed.capabilities = [.aiRequests]
        proposed.initialState = ["changed": "true"]
        proposed.tint = .coral
        proposed.symbol = "camera.fill"
        proposed.theme = .preset(.playful)
        proposed.theme?.backgroundAssetBinding = "proposed-untrusted-background"
        proposed.pages[0].nodes[0].title = "Changed copy"
        proposed.pages[0].nodes[0].action = RuntimeAction(
            type: .showMessage,
            target: "",
            value: "Changed action"
        )
        proposed.pages[0].presentation = PagePresentation(
            layout: .story,
            showsNavigationTitle: false,
            navigationStyle: .chips
        )
        proposed.pages[0].nodes[0].presentation = ComponentPresentation(
            surface: .material,
            span: .full,
            alignment: .center,
            emphasis: .strong,
            variant: .centered
        )

        let merged = AppDocumentDesignMerger().mergeDesign(from: proposed, into: current)

        XCTAssertEqual(merged.name, current.name)
        XCTAssertEqual(merged.summary, current.summary)
        XCTAssertEqual(merged.capabilities, current.capabilities)
        XCTAssertEqual(merged.initialState, current.initialState)
        XCTAssertEqual(merged.pages[0].nodes[0].title, current.pages[0].nodes[0].title)
        XCTAssertEqual(merged.pages[0].nodes[0].action, current.pages[0].nodes[0].action)
        XCTAssertEqual(merged.tint, .coral)
        XCTAssertEqual(merged.symbol, "camera.fill")
        XCTAssertEqual(merged.resolvedTheme.preset, .playful)
        XCTAssertNil(merged.resolvedTheme.backgroundAssetBinding)
        XCTAssertEqual(merged.pages[0].resolvedPresentation.layout, .story)
        XCTAssertEqual(merged.pages[0].nodes[0].resolvedPresentation.alignment, .center)
        XCTAssertNoThrow(try AppDocumentValidator().validate(merged))
    }

    func testDesignOnlyImageMergePreservesSelectionAndBinding() throws {
        let current = SampleDocuments.museJournal
        var proposed = current
        let imageIndex = try XCTUnwrap(
            proposed.pages[0].nodes.firstIndex(where: { $0.kind == .image })
        )
        proposed.pages[0].nodes[imageIndex].binding = "malicious-binding-change"
        proposed.pages[0].nodes[imageIndex].image?.allowsUserSelection = false
        proposed.pages[0].nodes[imageIndex].image?.aspect = .portrait
        proposed.pages[0].nodes[imageIndex].image?.mediaRole = .hero
        proposed.pages[0].nodes[imageIndex].image?.mask = .circle

        let merged = AppDocumentDesignMerger().mergeDesign(from: proposed, into: current)
        let image = try XCTUnwrap(merged.pages[0].nodes[imageIndex].image)

        XCTAssertEqual(merged.pages[0].nodes[imageIndex].binding, "journal-photo")
        XCTAssertTrue(image.allowsUserSelection)
        XCTAssertEqual(image.aspect, .portrait)
        XCTAssertEqual(image.resolvedMediaRole, .hero)
        XCTAssertEqual(image.resolvedMask, .circle)
        XCTAssertNoThrow(try AppDocumentValidator().validate(merged))
    }

    func testDesignOnlyMergePreservesExistingBackgroundAssetBoundary() throws {
        let backgroundBinding = "design-canvas-background"
        var current = SampleDocuments.museJournal
        current.theme?.backgroundAssetBinding = backgroundBinding
        var proposed = current
        proposed.theme = .preset(.bold)
        proposed.theme?.backgroundAssetBinding = "generated-background"

        let merged = AppDocumentDesignMerger().mergeDesign(from: proposed, into: current)

        XCTAssertEqual(
            merged.theme?.backgroundAssetBinding,
            backgroundBinding
        )
        XCTAssertEqual(merged.capabilities, current.capabilities)
        XCTAssertNoThrow(try AppDocumentValidator().validate(merged))
    }

    func testDesignOnlyMergeRejectsUncuratedAppSymbol() {
        let current = SampleDocuments.blank
        var proposed = current
        proposed.symbol = "not.a.real.allowed.symbol"

        let merged = AppDocumentDesignMerger().mergeDesign(from: proposed, into: current)

        XCTAssertEqual(merged.symbol, current.symbol)
    }

    func testDesignOnlyModeAddsHardBoundaryInstruction() {
        XCTAssertTrue(GenerationMode.full.promptPrefix.isEmpty)
        XCTAssertTrue(GenerationMode.designOnly.promptPrefix.contains("DESIGN-ONLY MODE"))
        XCTAssertTrue(GenerationMode.designOnly.promptPrefix.contains("host will enforce"))
    }
}
