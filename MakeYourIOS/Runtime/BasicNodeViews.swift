// swiftlint:disable file_length
import PhotosUI
import SwiftUI
import UIKit

struct HeroNodeView: View {
    let projectID: UUID
    let node: ComponentNode
    let tint: AppTint
    let theme: AppVisualTheme

    @Environment(LocalAssetStore.self) private var assetStore
    @Environment(\.runtimeDesign) private var design
    @State private var selectedItem: PhotosPickerItem?
    @State private var assetRevision = 0
    @State private var imageError: String?

    private var variant: ComponentVariant {
        RendererCatalog.normalizedVariant(node.resolvedPresentation.variant, for: .hero)
    }

    private var storedImage: UIImage? {
        _ = assetRevision
        let binding = node.binding.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !binding.isEmpty else { return nil }
        return assetStore.image(projectID: projectID, binding: binding)
    }

    @ViewBuilder
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            switch variant {
            case .photoOverlay, .fullBleed, .immersive:
                mediaHero
            case .centered:
                centeredHero
            case .split:
                splitHero
            case .editorial:
                editorialHero
            case .compact:
                compactHero
            default:
                standardHero
            }

            if let imageError {
                Label(imageError, systemImage: "exclamationmark.triangle.fill")
                    .font(design.captionFont)
                    .foregroundStyle(design.danger)
            }
        }
        .onChange(of: selectedItem) { _, item in
            guard let item else { return }
            Task { await importPhoto(item) }
        }
    }

    private var mediaHero: some View {
        let hasStoredImage = storedImage != nil
        return ZStack(alignment: .bottomLeading) {
            Group {
                if let storedImage {
                    Image(uiImage: storedImage)
                        .resizable()
                        .scaledToFill()
                        .accessibilityHidden(imageSpec?.decorative ?? true)
                        .accessibilityLabel(imageSpec?.altText ?? "Hero image")
                } else {
                    LinearGradient(
                        colors: [design.secondaryAccent, design.accent, Color.black.opacity(0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.78)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: node.symbol.isEmpty ? "sparkles" : node.symbol)
                    .font(.title2.weight(design.titleWeight))
                    .accessibilityHidden(true)
                heroTitle(foreground: .white)
            }
            .padding(variant == .immersive ? 28 : 22)

            if imageSpec?.allowsUserSelection == true {
                PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                    Label(hasStoredImage ? "Change photo" : "Choose photo", systemImage: "photo.badge.plus")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 8)
                        .foregroundStyle(.white)
                        .background(.black.opacity(0.56), in: Capsule())
                }
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .accessibilityHint("The photo stays on this device")
            }
        }
        .frame(
            maxWidth: .infinity,
            minHeight: variant == .immersive || theme.density == .airy ? 270 : 210
        )
        .clipShape(RoundedRectangle(cornerRadius: design.cornerRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var centeredHero: some View {
        VStack(spacing: 12) {
            Image(systemName: node.symbol.isEmpty ? "sparkles" : node.symbol)
                .font(.system(size: 34, weight: design.titleWeight))
                .foregroundStyle(design.accent)
                .frame(width: 64, height: 64)
                .background(design.secondaryAccent.opacity(0.14), in: Circle())
                .accessibilityHidden(true)
            heroTitle(foreground: design.primaryForeground)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
    }

    private var splitHero: some View {
        HStack(alignment: .center, spacing: design.componentSpacing) {
            heroTitle(foreground: design.primaryForeground)
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: node.symbol.isEmpty ? "sparkles" : node.symbol)
                .font(.system(size: 38, weight: design.titleWeight))
                .foregroundStyle(design.onAccent)
                .frame(width: 92, height: 104)
                .background(design.accent.gradient, in: heroIconShape)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }

    private var editorialHero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: node.symbol.isEmpty ? "textformat" : node.symbol)
                Rectangle().frame(height: max(1, design.borderWidth))
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(design.accent)
            .accessibilityHidden(true)
            heroTitle(foreground: design.primaryForeground)
            Text("CURATED FOR YOU")
                .font(.caption2.weight(.semibold))
                .tracking(1.4)
                .foregroundStyle(design.secondaryForeground)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    private var compactHero: some View {
        HStack(spacing: 12) {
            Image(systemName: node.symbol.isEmpty ? "sparkles" : node.symbol)
                .font(.headline.weight(design.titleWeight))
                .foregroundStyle(design.onAccent)
                .frame(width: 44, height: 44)
                .background(design.accent, in: heroIconShape)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(node.title).font(design.sectionFont)
                    .accessibilityAddTraits(.isHeader)
                if !node.subtitle.isEmpty {
                    Text(node.subtitle).font(design.captionFont).foregroundStyle(design.secondaryForeground)
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var standardHero: some View {
        HStack(spacing: 16) {
            Image(systemName: node.symbol.isEmpty ? "sparkles" : node.symbol)
                .font(.system(size: 28, weight: design.titleWeight))
                .foregroundStyle(design.onAccent)
                .frame(width: 58, height: 58)
                .background(design.accent.gradient, in: heroIconShape)
                .accessibilityHidden(true)
            heroTitle(foreground: design.primaryForeground)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var heroIconShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: design.compactCornerRadius, style: .continuous)
    }

    private var imageSpec: ImageSpec? { node.image }

    private func heroTitle(foreground: Color) -> some View {
        VStack(alignment: variant == .centered ? .center : .leading, spacing: 6) {
            Text(node.title)
                .font(design.displayFont)
                .foregroundStyle(foreground)
                .accessibilityAddTraits(.isHeader)
            if !node.subtitle.isEmpty {
                Text(node.subtitle)
                    .font(design.bodyFont)
                    .foregroundStyle(foreground.opacity(0.78))
            }
        }
    }

    @MainActor
    private func importPhoto(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw LocalAssetStoreError.invalidImageData
            }
            try assetStore.saveImageData(data, projectID: projectID, binding: node.binding)
            assetRevision += 1
            selectedItem = nil
            imageError = nil
        } catch {
            imageError = error.localizedDescription
        }
    }
}

struct SectionHeaderNodeView: View {
    let node: ComponentNode

    @Environment(\.runtimeDesign) private var design

    private var variant: ComponentVariant {
        RendererCatalog.normalizedVariant(node.resolvedPresentation.variant, for: .sectionHeader)
    }

    var body: some View {
        VStack(
            alignment: variant == .centered ? .center : .leading,
            spacing: variant == .compact ? 2 : 5
        ) {
            Text(node.title)
                .font(variant == .editorial ? design.titleFont : design.sectionFont)
                .accessibilityAddTraits(.isHeader)
            if variant == .editorial {
                Rectangle()
                    .fill(design.accent)
                    .frame(width: 42, height: max(2, design.borderWidth))
                    .accessibilityHidden(true)
            }
            if !node.subtitle.isEmpty {
                Text(node.subtitle)
                    .font(design.captionFont)
                    .foregroundStyle(design.secondaryForeground)
            }
        }
        .multilineTextAlignment(variant == .centered ? .center : .leading)
        .frame(maxWidth: .infinity, alignment: variant == .centered ? .center : .leading)
        .padding(.top, variant == .compact ? 2 : 6)
    }
}

struct TextNodeView: View {
    let node: ComponentNode
    @Bindable var session: RuntimeSessionState

    @Environment(\.runtimeDesign) private var design

    private var variant: ComponentVariant {
        RendererCatalog.normalizedVariant(node.resolvedPresentation.variant, for: .text)
    }

    var body: some View {
        VStack(alignment: variant == .centered ? .center : .leading, spacing: 4) {
            Text(primaryText)
                .font(variant == .editorial ? design.sectionFont : design.bodyFont)
                .foregroundStyle(design.primaryForeground)
                .lineSpacing(variant == .editorial ? 7 : (variant == .compact ? 1 : 4))
            if !resolvedSubtitle.isEmpty {
                Text(resolvedSubtitle)
                    .font(design.captionFont)
                    .foregroundStyle(design.secondaryForeground)
            }
        }
        .multilineTextAlignment(textAlignment)
        .frame(maxWidth: .infinity, alignment: frameAlignment)
        .padding(variant == .framed ? design.componentPadding : 0)
        .background(
            variant == .framed ? design.surface : .clear,
            in: RoundedRectangle(cornerRadius: design.compactCornerRadius, style: .continuous)
        )
        .accessibilityIdentifier("runtime.node.\(node.id)")
    }

    private var textAlignment: TextAlignment {
        variant == .centered ? .center : node.resolvedPresentation.alignment.textAlignment
    }

    private var frameAlignment: Alignment {
        variant == .centered ? .center : node.resolvedPresentation.alignment.frameAlignment
    }

    private var resolvedTitle: String {
        session.resolveTemplate(node.title)
    }

    private var resolvedSubtitle: String {
        session.resolveTemplate(node.subtitle)
    }

    private var primaryText: String {
        if node.valueBinding?.isEmpty == false {
            return resolvedValue
        }
        return resolvedTitle.isEmpty ? resolvedValue : resolvedTitle
    }

    private var resolvedValue: String {
        if let valueBinding = node.valueBinding, !valueBinding.isEmpty {
            return session.binding(for: valueBinding, fallback: session.resolveTemplate(node.value))
        }
        return session.resolveTemplate(node.value)
    }
}

struct MetricNodeView: View {
    let node: ComponentNode
    let tint: AppTint
    @Bindable var session: RuntimeSessionState

    @Environment(\.runtimeDesign) private var design

    private var variant: ComponentVariant {
        RendererCatalog.normalizedVariant(node.resolvedPresentation.variant, for: .metric)
    }

    var body: some View {
        Group {
            switch variant {
            case .compact, .dense:
                compactMetric
            case .centered:
                metricContent(alignment: .center)
                    .multilineTextAlignment(.center)
            case .progress:
                progressMetric
            default:
                metricContent(alignment: .leading)
            }
        }
        .padding([.cards, .framed].contains(variant) ? design.componentPadding : 0)
        .background(
            [.cards, .framed].contains(variant) ? design.surface : .clear,
            in: RoundedRectangle(cornerRadius: design.compactCornerRadius, style: .continuous)
        )
        .overlay {
            if variant == .framed {
                RoundedRectangle(cornerRadius: design.compactCornerRadius, style: .continuous)
                    .stroke(design.accent.opacity(0.5), lineWidth: max(1, design.borderWidth))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(resolvedTitle)
        .accessibilityValue(resolvedValue)
        .accessibilityIdentifier("runtime.node.\(node.id)")
    }

    private var compactMetric: some View {
        HStack(spacing: 10) {
            Label(resolvedTitle, systemImage: node.symbol.isEmpty ? "chart.bar.fill" : node.symbol)
                .font(design.captionFont.weight(.semibold))
                .foregroundStyle(design.accent)
            Spacer(minLength: 8)
            Text(resolvedValue).font(design.sectionFont.monospacedDigit())
        }
    }

    private var progressMetric: some View {
        VStack(alignment: .leading, spacing: 9) {
            metricContent(alignment: .leading)
            ProgressView(value: normalizedProgress)
                .tint(design.accent)
                .accessibilityLabel(resolvedTitle)
                .accessibilityValue(Text(normalizedProgress, format: .percent))
        }
    }

    private func metricContent(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 7) {
            if variant != .numberFirst {
                Label(resolvedTitle, systemImage: node.symbol.isEmpty ? "chart.bar.fill" : node.symbol)
                    .font(design.captionFont.weight(.semibold))
                    .foregroundStyle(design.accent)
            }
            Text(resolvedValue).font(design.displayFont.monospacedDigit())
            if variant == .numberFirst {
                Text(resolvedTitle).font(design.captionFont.weight(.semibold)).foregroundStyle(design.accent)
            }
            if !resolvedSubtitle.isEmpty {
                Text(resolvedSubtitle).font(design.captionFont).foregroundStyle(design.secondaryForeground)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
    }

    private var normalizedProgress: Double {
        let value = Double(resolvedValue) ?? 0
        return min(max(value > 1 ? value / 100 : value, 0), 1)
    }

    private var resolvedTitle: String {
        session.resolveTemplate(node.title)
    }

    private var resolvedSubtitle: String {
        session.resolveTemplate(node.subtitle)
    }

    private var resolvedValue: String {
        if let valueBinding = node.valueBinding, !valueBinding.isEmpty {
            return session.binding(for: valueBinding, fallback: session.resolveTemplate(node.value))
        }
        return session.resolveTemplate(node.value)
    }
}
