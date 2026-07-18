import Foundation

enum GenerationMode: String, CaseIterable, Identifiable, Sendable {
    case full
    case designOnly

    var id: Self { self }

    var label: String {
        switch self {
        case .full: "Full app"
        case .designOnly: "Design only"
        }
    }

    var promptPrefix: String {
        switch self {
        case .full:
            ""
        case .designOnly:
            """
            DESIGN-ONLY MODE. Preserve every feature, page identity, component identity, value, copy, \
            state binding, action, capability, and data configuration. Change only tint, theme tokens, \
            page presentation, component presentation, and image visual metadata. Do not add or remove \
            functionality. The host will enforce this boundary after generation.

            """
        }
    }
}

struct AppDocumentDesignMerger: Sendable {
    func mergeDesign(from proposed: AppDocument, into current: AppDocument) -> AppDocument {
        var merged = current
        if GeneratedAppPayload.allowedSymbols.contains(proposed.symbol) {
            merged.symbol = proposed.symbol
        }
        merged.tint = proposed.tint
        var mergedTheme = proposed.theme ?? current.theme
        mergedTheme?.backgroundAssetBinding = current.theme?.backgroundAssetBinding
        merged.theme = mergedTheme

        for pageIndex in merged.pages.indices {
            guard let proposedPage = matchingPage(
                for: merged.pages[pageIndex],
                at: pageIndex,
                in: proposed.pages
            ) else { continue }

            if let presentation = proposedPage.presentation {
                merged.pages[pageIndex].presentation = presentation
            }
            mergeNodes(from: proposedPage.nodes, into: &merged.pages[pageIndex].nodes)
        }
        return merged
    }

    private func matchingPage(
        for current: AppPage,
        at index: Int,
        in proposedPages: [AppPage]
    ) -> AppPage? {
        proposedPages.first(where: { $0.id == current.id })
            ?? proposedPages[safe: index]
    }

    private func mergeNodes(from proposedNodes: [ComponentNode], into nodes: inout [ComponentNode]) {
        for nodeIndex in nodes.indices {
            let proposedNode = proposedNodes.first(where: { $0.id == nodes[nodeIndex].id })
                ?? proposedNodes[safe: nodeIndex].flatMap { candidate in
                    candidate.kind == nodes[nodeIndex].kind ? candidate : nil
                }
            guard let proposedNode else { continue }

            if let presentation = proposedNode.presentation {
                nodes[nodeIndex].presentation = presentation
            }
            nodes[nodeIndex].image = mergeImageVisuals(
                from: proposedNode.image,
                into: nodes[nodeIndex].image
            )
        }
    }

    private func mergeImageVisuals(from proposed: ImageSpec?, into current: ImageSpec?) -> ImageSpec? {
        guard let proposed, var current else { return current }
        current.aspect = proposed.aspect
        current.contentMode = proposed.contentMode
        current.altText = proposed.altText
        current.decorative = proposed.decorative
        current.mediaRole = proposed.mediaRole
        current.focalPoint = proposed.focalPoint
        current.mask = proposed.mask
        current.overlay = proposed.overlay
        return current
    }
}

struct DesignChangeSummary: Hashable, Sendable {
    var identityChanged: Bool
    var themeChanged: Bool
    var paletteChanged: Bool
    var typographyChanged: Bool
    var layoutPageCount: Int
    var styledNodeCount: Int
    var motionChanged: Bool

    init(before: AppDocument, after: AppDocument) {
        let oldTheme = before.resolvedTheme
        let newTheme = after.resolvedTheme
        identityChanged = before.symbol != after.symbol || before.tint != after.tint
        themeChanged = oldTheme != newTheme
        paletteChanged = oldTheme.resolvedPalette != newTheme.resolvedPalette
        typographyChanged = oldTheme.typography != newTheme.typography
            || oldTheme.resolvedTypeScale != newTheme.resolvedTypeScale
            || oldTheme.resolvedTitleWeight != newTheme.resolvedTitleWeight
        motionChanged = oldTheme.resolvedMotion != newTheme.resolvedMotion
        layoutPageCount = zip(before.pages, after.pages).filter {
            $0.resolvedPresentation != $1.resolvedPresentation
        }.count
        styledNodeCount = zip(before.pages, after.pages).reduce(into: 0) { count, pages in
            count += zip(pages.0.nodes, pages.1.nodes).filter {
                $0.presentation != $1.presentation || $0.image != $1.image
            }.count
        }
    }

    var conciseDescription: String {
        var changes: [String] = []
        if identityChanged { changes.append("brand identity") }
        if themeChanged { changes.append("style") }
        if paletteChanged { changes.append("colors") }
        if typographyChanged { changes.append("type") }
        if layoutPageCount > 0 { changes.append("\(layoutPageCount) page layouts") }
        if styledNodeCount > 0 { changes.append("\(styledNodeCount) components") }
        if motionChanged { changes.append("motion") }
        return changes.isEmpty ? "No visual changes" : changes.joined(separator: ", ")
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
