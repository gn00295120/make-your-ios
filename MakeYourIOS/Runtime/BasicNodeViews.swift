import SwiftUI

struct HeroNodeView: View {
    let node: ComponentNode
    let tint: AppTint
    let theme: AppVisualTheme

    @ViewBuilder
    var body: some View {
        switch node.resolvedPresentation.variant {
        case .photoOverlay:
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [tint.color.opacity(0.62), tint.color, Color.black.opacity(0.58)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: node.symbol.isEmpty ? "sparkles" : node.symbol)
                        .font(.title2.bold())
                    Text(node.title).font(.largeTitle.bold())
                    if !node.subtitle.isEmpty {
                        Text(node.subtitle).font(.subheadline).foregroundStyle(.white.opacity(0.82))
                    }
                }
                .foregroundStyle(.white)
                .padding(24)
            }
            .frame(maxWidth: .infinity, minHeight: theme.density == .airy ? 240 : 190)
            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
        case .centered:
            VStack(spacing: 12) {
                Image(systemName: node.symbol.isEmpty ? "sparkles" : node.symbol)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(tint.color)
                Text(node.title).font(.largeTitle.bold()).multilineTextAlignment(.center)
                if !node.subtitle.isEmpty {
                    Text(node.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        default:
            HStack(spacing: 16) {
                Image(systemName: node.symbol.isEmpty ? "sparkles" : node.symbol)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(
                        tint.color.gradient,
                        in: RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 5) {
                    Text(node.title).font(.title2.bold()).foregroundStyle(.primary)
                    if !node.subtitle.isEmpty {
                        Text(node.subtitle).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct MetricNodeView: View {
    let node: ComponentNode
    let tint: AppTint

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if node.resolvedPresentation.variant != .numberFirst {
                Label(node.title, systemImage: node.symbol.isEmpty ? "chart.bar.fill" : node.symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint.color)
            }
            Text(node.value).font(.system(.largeTitle, design: .rounded, weight: .bold))
            if node.resolvedPresentation.variant == .numberFirst {
                Text(node.title).font(.subheadline.weight(.semibold)).foregroundStyle(tint.color)
            }
            if node.resolvedPresentation.variant == .progress,
               let progress = Double(node.value) {
                ProgressView(value: min(max(progress, 0), 1))
                    .tint(tint.color)
            }
            if !node.subtitle.isEmpty {
                Text(node.subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct InputNodeView: View {
    let node: ComponentNode
    let tint: AppTint
    @Bindable var session: RuntimeSessionState

    private var value: Binding<String> {
        Binding(
            get: { session.binding(for: node.binding, fallback: node.value) },
            set: { session.set($0, for: node.binding) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(node.title).font(.subheadline.weight(.semibold))
            TextField(node.placeholder, text: value)
                .keyboardType(node.kind == .numberInput ? .decimalPad : .default)
                .textFieldStyle(.plain)
                .padding(14)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tint(tint.color)
    }
}

struct PickerNodeView: View {
    let node: ComponentNode
    let tint: AppTint
    @Bindable var session: RuntimeSessionState

    private var selection: Binding<String> {
        Binding(
            get: { session.binding(for: node.binding, fallback: node.options.first ?? "") },
            set: { session.set($0, for: node.binding) }
        )
    }

    var body: some View {
        HStack {
            Text(node.title).font(.headline)
            Spacer()
            Picker(node.title, selection: selection) {
                ForEach(node.options, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
        }
        .tint(tint.color)
    }
}

struct ChecklistNodeView: View {
    let node: ComponentNode
    let tint: AppTint
    @Bindable var session: RuntimeSessionState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(node.title).font(.headline)
            ForEach(node.items) { item in
                Button {
                    if session.checkedItemIDs.contains(item.id) {
                        session.checkedItemIDs.remove(item.id)
                    } else {
                        session.checkedItemIDs.insert(item.id)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(
                            systemName: session.checkedItemIDs.contains(item.id)
                                ? "checkmark.circle.fill"
                                : "circle"
                        )
                        .foregroundStyle(tint.color)
                        Text(item.title)
                            .foregroundStyle(.primary)
                            .strikethrough(session.checkedItemIDs.contains(item.id))
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
