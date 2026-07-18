import SwiftUI

struct RuntimePageRenderer<NodeContent: View>: View {
    let page: AppPage
    let rows: [RuntimeNodeRow]
    let design: RuntimeDesignContext
    let nodeContent: (ComponentNode) -> NodeContent

    init(
        page: AppPage,
        rows: [RuntimeNodeRow],
        design: RuntimeDesignContext,
        @ViewBuilder nodeContent: @escaping (ComponentNode) -> NodeContent
    ) {
        self.page = page
        self.rows = rows
        self.design = design
        self.nodeContent = nodeContent
    }

    @ViewBuilder
    var body: some View {
        switch page.resolvedPresentation.layout {
        case .flow:
            rowLayout(spacing: design.componentSpacing)
        case .dashboard:
            rowLayout(spacing: max(10, design.componentSpacing * 0.82))
        case .form:
            formLayout
        case .story:
            storyLayout
        }
    }

    private func rowLayout(spacing: CGFloat) -> some View {
        LazyVStack(spacing: spacing) {
            ForEach(rows) { row in
                HStack(alignment: .top, spacing: spacing) {
                    ForEach(row.nodes) { node in
                        nodeContent(node)
                            .frame(maxWidth: .infinity, alignment: .top)
                    }
                }
            }
        }
    }

    private var formLayout: some View {
        VStack(spacing: 0) {
            ForEach(Array(page.nodes.enumerated()), id: \.element.id) { index, node in
                nodeContent(formNode(node))
                    .padding(.vertical, max(8, design.componentSpacing * 0.55))
                if index < page.nodes.count - 1 {
                    Divider()
                }
            }
        }
        .padding(.horizontal, design.componentPadding)
        .background(design.surface, in: formShape)
        .overlay {
            formShape.stroke(
                design.borderColor.opacity(design.borderOpacity),
                lineWidth: design.borderWidth
            )
        }
        .shadow(
            color: Color.black.opacity(design.shadowOpacity),
            radius: design.shadowRadius,
            y: design.shadowY
        )
        .accessibilityElement(children: .contain)
    }

    private var storyLayout: some View {
        LazyVStack(spacing: max(24, design.componentSpacing * 1.45)) {
            ForEach(page.nodes) { node in
                nodeContent(storyNode(node))
                    .padding(.horizontal, storyHorizontalInset(for: node))
            }
        }
    }

    private var formShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: design.cornerRadius, style: .continuous)
    }

    private func formNode(_ node: ComponentNode) -> ComponentNode {
        var copy = node
        var presentation = copy.resolvedPresentation
        presentation.span = .full
        if presentation.surface == .automatic {
            presentation.surface = .plain
        }
        copy.presentation = presentation
        return copy
    }

    private func storyNode(_ node: ComponentNode) -> ComponentNode {
        var copy = node
        var presentation = copy.resolvedPresentation
        presentation.span = .full
        copy.presentation = presentation
        return copy
    }

    private func storyHorizontalInset(for node: ComponentNode) -> CGFloat {
        let variant = RendererCatalog.normalizedVariant(
            node.resolvedPresentation.variant,
            for: node.kind
        )
        if [.fullBleed, .immersive].contains(variant), [.hero, .image, .game].contains(node.kind) {
            return -16
        }
        if [.text, .sectionHeader].contains(node.kind) {
            return min(12, design.componentPadding * 0.55)
        }
        return 0
    }
}
