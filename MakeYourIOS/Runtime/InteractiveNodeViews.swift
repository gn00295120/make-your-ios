import SwiftUI

struct InputNodeView: View {
    let node: ComponentNode
    let tint: AppTint
    @Bindable var session: RuntimeSessionState

    @Environment(\.runtimeDesign) private var design

    private var value: Binding<String> {
        Binding(
            get: { session.binding(for: node.binding, fallback: node.value) },
            set: { session.set($0, for: node.binding) }
        )
    }

    private var variant: ComponentVariant {
        RendererCatalog.normalizedVariant(node.resolvedPresentation.variant, for: node.kind)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: variant == .compact ? 6 : 10) {
            Text(node.title).font(design.captionFont.weight(.semibold))
            TextField(node.placeholder, text: value)
                .keyboardType(node.kind == .numberInput ? .decimalPad : .default)
                .textFieldStyle(.plain)
                .font(design.bodyFont)
                .padding(.horizontal, variant == .compact ? 11 : 14)
                .padding(.vertical, variant == .compact ? 9 : 13)
                .background(fieldBackground, in: fieldShape)
                .overlay {
                    if variant == .framed || design.increasedContrast {
                        fieldShape.stroke(
                            design.accent.opacity(design.increasedContrast ? 0.9 : 0.45),
                            lineWidth: max(1, design.borderWidth)
                        )
                    }
                }
                .accessibilityLabel(node.title)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tint(design.accent)
    }

    private var fieldShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: design.controlCornerRadius, style: .continuous)
    }

    private var fieldBackground: Color {
        variant == .framed ? design.surface : design.accent.opacity(0.08)
    }
}

struct PickerNodeView: View {
    let node: ComponentNode
    let tint: AppTint
    @Bindable var session: RuntimeSessionState

    @Environment(\.runtimeDesign) private var design

    private var selection: Binding<String> {
        Binding(
            get: { session.binding(for: node.binding, fallback: node.options.first ?? "") },
            set: { session.set($0, for: node.binding) }
        )
    }

    private var variant: ComponentVariant {
        RendererCatalog.normalizedVariant(node.resolvedPresentation.variant, for: .picker)
    }

    @ViewBuilder
    var body: some View {
        if variant == .framed, node.options.count <= 4 {
            VStack(alignment: .leading, spacing: 8) {
                Text(node.title).font(design.captionFont.weight(.semibold))
                Picker(node.title, selection: selection) {
                    options
                }
                .pickerStyle(.segmented)
            }
            .tint(design.accent)
        } else {
            HStack(spacing: 10) {
                Text(node.title).font(variant == .compact ? design.captionFont.weight(.semibold) : .headline)
                Spacer()
                Picker(node.title, selection: selection) {
                    options
                }
                .pickerStyle(.menu)
            }
            .padding(variant == .framed ? 12 : 0)
            .background(
                variant == .framed ? design.surface : .clear,
                in: RoundedRectangle(cornerRadius: design.controlCornerRadius, style: .continuous)
            )
            .tint(design.accent)
        }
    }

    @ViewBuilder
    private var options: some View {
        ForEach(node.options, id: \.self) { option in
            Text(option).tag(option)
        }
    }
}

struct ActionButtonNodeView: View {
    let node: ComponentNode
    let action: () -> Void

    @Environment(\.runtimeDesign) private var design

    private var variant: ComponentVariant {
        RendererCatalog.normalizedVariant(node.resolvedPresentation.variant, for: .button)
    }

    @ViewBuilder
    var body: some View {
        switch variant {
        case .outlinedAction:
            Button(action: action) { label }
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle(radius: design.controlCornerRadius))
                .tint(design.accent)
        case .softAction:
            Button(action: action) { label }
                .buttonStyle(.plain)
                .foregroundStyle(design.accent)
                .background(design.accent.opacity(0.12), in: controlShape)
                .overlay {
                    if design.differentiateWithoutColor {
                        controlShape.stroke(design.accent, lineWidth: max(1, design.borderWidth))
                    }
                }
        default:
            Button(action: action) { label }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: design.controlCornerRadius))
                .tint(design.accent)
        }
    }

    private var label: some View {
        Label(node.title, systemImage: node.symbol.isEmpty ? "arrow.right" : node.symbol)
            .font(variant == .compact ? design.captionFont.weight(.semibold) : .headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, variant == .compact ? 10 : 14)
    }

    private var controlShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: design.controlCornerRadius, style: .continuous)
    }
}

struct ChecklistNodeView: View {
    let node: ComponentNode
    let tint: AppTint
    @Bindable var session: RuntimeSessionState

    @Environment(\.runtimeDesign) private var design

    private var variant: ComponentVariant {
        RendererCatalog.normalizedVariant(node.resolvedPresentation.variant, for: .checklist)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: variant == .dense ? 7 : 12) {
            Text(node.title)
                .font(design.sectionFont)
                .accessibilityAddTraits(.isHeader)
            ForEach(Array(node.items.enumerated()), id: \.element.id) { index, item in
                checklistRow(item, isLast: index == node.items.count - 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func checklistRow(_ item: ComponentItem, isLast: Bool) -> some View {
        let isChecked = session.checkedItemIDs.contains(item.id)
        return Button {
            if isChecked {
                session.checkedItemIDs.remove(item.id)
            } else {
                session.checkedItemIDs.insert(item.id)
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 0) {
                    Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(design.accent)
                        .frame(width: 24, height: 24)
                    if variant == .timeline, !isLast {
                        Rectangle()
                            .fill(design.accent.opacity(0.24))
                            .frame(width: max(1, design.borderWidth), height: 24)
                            .accessibilityHidden(true)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .foregroundStyle(design.primaryForeground)
                        .strikethrough(isChecked)
                    if !item.subtitle.isEmpty {
                        Text(item.subtitle).font(design.captionFont).foregroundStyle(design.secondaryForeground)
                    }
                }
                Spacer()
            }
            .padding(variant == .cards ? 12 : 0)
            .background(
                variant == .cards ? design.surface : .clear,
                in: RoundedRectangle(cornerRadius: design.compactCornerRadius, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityValue(isChecked ? "Checked" : "Not checked")
        .accessibilityHint("Double tap to toggle")
    }
}
