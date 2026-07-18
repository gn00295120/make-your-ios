import SwiftUI

struct RuntimeCollectionNodeView: View {
    let node: ComponentNode
    @Bindable var session: RuntimeSessionState

    @Environment(\.runtimeDesign) private var design

    private struct ObjectEntry: Identifiable {
        var id: String { key }
        let key: String
        let value: String
    }

    private enum Content {
        case list([String])
        case object([ObjectEntry])
        case invalid
    }

    private var content: Content {
        let value = session.binding(for: node.binding, fallback: node.value)
        if let list = try? RuntimeValueCodec.decodedList(value) {
            return .list(list)
        }
        if let object = try? RuntimeValueCodec.decodedObject(value) {
            return .object(object
                .map { ObjectEntry(key: $0.key, value: $0.value) }
                .sorted(by: { $0.key.localizedStandardCompare($1.key) == .orderedAscending }))
        }
        return .invalid
    }

    private var emptyMessage: String {
        let placeholder = session.resolveTemplate(node.placeholder)
        return placeholder.isEmpty ? "No items yet" : placeholder
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            switch content {
            case .list(let values):
                if values.isEmpty {
                    emptyState
                } else {
                    ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                        listRow(index: index, value: value)
                    }
                }
            case .object(let entries):
                if entries.isEmpty {
                    emptyState
                } else {
                    ForEach(entries) { entry in
                        objectRow(key: entry.key, value: entry.value)
                    }
                }
            case .invalid:
                Label("This collection is unavailable.", systemImage: "exclamationmark.triangle")
                    .font(design.captionFont)
                    .foregroundStyle(design.secondaryForeground)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("runtime.node.\(node.id)")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            if !node.title.isEmpty {
                Label {
                    Text(session.resolveTemplate(node.title))
                        .font(design.bodyFont.weight(.semibold))
                } icon: {
                    Image(systemName: node.symbol.isEmpty ? "list.bullet" : node.symbol)
                        .foregroundStyle(design.accent)
                }
            }
            if !node.subtitle.isEmpty {
                Text(session.resolveTemplate(node.subtitle))
                    .font(design.captionFont)
                    .foregroundStyle(design.secondaryForeground)
            }
        }
    }

    private var emptyState: some View {
        Text(emptyMessage)
            .font(design.captionFont)
            .foregroundStyle(design.secondaryForeground)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    }

    private func listRow(index: Int, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(index + 1)")
                .font(design.captionFont.monospacedDigit().weight(.semibold))
                .foregroundStyle(design.accent)
                .frame(minWidth: 22, alignment: .trailing)
            Text(value)
                .font(design.bodyFont)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Item \(index + 1), \(value)")
    }

    private func objectRow(key: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(key)
                .font(design.captionFont.weight(.semibold))
                .foregroundStyle(design.secondaryForeground)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(value)
                .font(design.bodyFont)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(key), \(value)")
    }
}
