import Foundation

struct RuntimeNodeRow: Identifiable, Hashable, Sendable {
    let nodes: [ComponentNode]

    var id: String {
        nodes.map(\.id).joined(separator: ":")
    }
}

enum PageLayoutEngine {
    static func rows(
        for nodes: [ComponentNode],
        layout: PageLayout,
        collapseColumns: Bool
    ) -> [RuntimeNodeRow] {
        guard !collapseColumns else {
            return nodes.map { RuntimeNodeRow(nodes: [$0]) }
        }

        var rows: [RuntimeNodeRow] = []
        var pending: ComponentNode?

        for node in nodes {
            guard canShareRow(node, layout: layout) else {
                if let pendingNode = pending {
                    rows.append(RuntimeNodeRow(nodes: [pendingNode]))
                }
                pending = nil
                rows.append(RuntimeNodeRow(nodes: [node]))
                continue
            }

            if let pendingNode = pending {
                rows.append(RuntimeNodeRow(nodes: [pendingNode, node]))
                pending = nil
            } else {
                pending = node
            }
        }

        if let pendingNode = pending {
            rows.append(RuntimeNodeRow(nodes: [pendingNode]))
        }
        return rows
    }

    private static func canShareRow(_ node: ComponentNode, layout: PageLayout) -> Bool {
        let span = node.resolvedPresentation.span
        let wantsCompactWidth = span == .half || (span == .adaptive && layout == .dashboard)
        guard wantsCompactWidth else { return false }

        switch node.kind {
        case .text, .metric, .infoBanner, .image:
            return true
        default:
            return false
        }
    }
}
