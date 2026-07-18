import PhotosUI
import SwiftUI
import UIKit

struct ImageNodeView: View {
    let projectID: UUID
    let node: ComponentNode
    let tint: AppTint
    let theme: AppVisualTheme

    @Environment(LocalAssetStore.self) private var assetStore
    @Environment(\.runtimeDesign) private var design
    @State private var selectedItem: PhotosPickerItem?
    @State private var assetRevision = 0
    @State private var errorMessage: String?

    private var spec: ImageSpec {
        node.image ?? .editableLandscape
    }

    private var variant: ComponentVariant {
        RendererCatalog.normalizedVariant(node.resolvedPresentation.variant, for: .image)
    }

    private var storedImage: UIImage? {
        _ = assetRevision
        return assetStore.image(projectID: projectID, binding: node.binding)
    }

    private var isDecorative: Bool {
        spec.decorative || [.background, .decorative].contains(spec.resolvedMediaRole)
    }

    var body: some View {
        VStack(alignment: captionAlignment, spacing: variant == .compact ? 6 : 10) {
            ZStack(alignment: .topTrailing) {
                media

                if spec.allowsUserSelection, storedImage != nil {
                    photoPicker(label: "Change", symbol: "photo.badge.plus")
                        .padding(12)
                }
            }

            if variant != .photoOverlay {
                caption
            }

            if spec.allowsUserSelection {
                Label(
                    "This photo stays on this device and is never sent to AI.",
                    systemImage: "lock.shield.fill"
                )
                .font(.caption2)
                .foregroundStyle(design.secondaryForeground)
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(design.captionFont)
                    .foregroundStyle(design.danger)
            }
        }
        .frame(maxWidth: .infinity, alignment: node.resolvedPresentation.alignment.frameAlignment)
        .onChange(of: selectedItem) { _, item in
            guard let item else { return }
            Task { await importPhoto(item) }
        }
    }

    private var media: some View {
        ZStack(alignment: .bottomLeading) {
            ZStack {
                if let storedImage {
                    storedImageView(storedImage)
                } else {
                    placeholder
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            overlayLayer

            if variant == .photoOverlay {
                caption
                    .foregroundStyle(.white)
                    .padding(design.componentPadding)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(spec.aspect.ratio, contentMode: .fit)
        .clipShape(maskShape)
        .padding(variant == .framed ? 7 : 0)
        .background(variant == .framed ? design.surface : .clear, in: frameShape)
        .overlay {
            if variant == .framed {
                frameShape.stroke(
                    design.borderColor.opacity(max(0.26, design.borderOpacity)),
                    lineWidth: max(1, design.borderWidth)
                )
            }
        }
        .shadow(
            color: variant == .framed ? Color.black.opacity(design.shadowOpacity) : .clear,
            radius: variant == .framed ? design.shadowRadius : 0,
            y: variant == .framed ? design.shadowY : 0
        )
    }

    private func storedImageView(_ image: UIImage) -> some View {
        Group {
            if spec.contentMode == .fill {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: focalAlignment)
                    .clipped()
            } else {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: focalAlignment)
            }
        }
        .accessibilityHidden(isDecorative)
        .accessibilityLabel(spec.altText)
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [design.accent.opacity(0.24), design.secondaryAccent.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 12) {
                Image(systemName: placeholderSymbol)
                    .font(.system(size: variant == .compact ? 26 : 34, weight: .semibold))
                    .foregroundStyle(design.accent)
                    .accessibilityHidden(true)
                if spec.allowsUserSelection {
                    photoPicker(label: "Choose photo", symbol: "photo.badge.plus")
                } else {
                    Text("Image placeholder")
                        .font(design.captionFont.weight(.medium))
                        .foregroundStyle(design.secondaryForeground)
                }
            }
        }
        .accessibilityHidden(isDecorative && !spec.allowsUserSelection)
        .accessibilityLabel(spec.altText)
    }

    @ViewBuilder
    private var overlayLayer: some View {
        switch resolvedOverlay {
        case .none:
            EmptyView()
        case .scrim:
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.62)],
                startPoint: .center,
                endPoint: .bottom
            )
            .accessibilityHidden(true)
        case .tint:
            design.accent.opacity(design.reduceTransparency ? 0.10 : 0.24)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var caption: some View {
        if !node.title.isEmpty || !node.subtitle.isEmpty {
            VStack(alignment: captionAlignment, spacing: 3) {
                if !node.title.isEmpty {
                    Text(node.title)
                        .font(variant == .photoOverlay ? design.titleFont : .headline)
                }
                if !node.subtitle.isEmpty {
                    Text(node.subtitle)
                        .font(design.captionFont)
                        .foregroundStyle(variant == .photoOverlay ? .white.opacity(0.82) : design.secondaryForeground)
                }
            }
            .multilineTextAlignment(textAlignment)
        }
    }

    private func photoPicker(label: String, symbol: String) -> some View {
        PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
            Label(label, systemImage: symbol)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .tint(design.accent)
        .accessibilityHint("The photo stays on this device")
    }

    private var resolvedOverlay: ImageOverlay {
        variant == .photoOverlay ? .scrim : spec.resolvedOverlay
    }

    private var placeholderSymbol: String {
        if !node.symbol.isEmpty { return node.symbol }
        switch spec.resolvedMediaRole {
        case .logo: return "seal.fill"
        case .avatar: return "person.crop.circle.fill"
        case .thumbnail: return "rectangle.stack.fill"
        case .hero, .background, .content, .decorative: return "photo.fill"
        }
    }

    private var focalAlignment: Alignment {
        switch spec.resolvedFocalPoint {
        case .center: .center
        case .top: .top
        case .bottom: .bottom
        case .leading: .leading
        case .trailing: .trailing
        }
    }

    private var captionAlignment: HorizontalAlignment {
        switch node.resolvedPresentation.alignment {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }

    private var textAlignment: TextAlignment {
        node.resolvedPresentation.alignment.textAlignment
    }

    private var maskShape: AnyShape {
        if [.fullBleed, .immersive].contains(variant) {
            return AnyShape(Rectangle())
        }
        let mask = spec.mask == nil && spec.resolvedMediaRole == .avatar
            ? ImageMask.circle
            : spec.resolvedMask
        switch mask {
        case .none: return AnyShape(Rectangle())
        case .rounded:
            return AnyShape(RoundedRectangle(cornerRadius: design.cornerRadius, style: .continuous))
        case .circle: return AnyShape(Circle())
        case .capsule: return AnyShape(Capsule())
        }
    }

    private var frameShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: design.cornerRadius, style: .continuous)
    }

    @MainActor
    private func importPhoto(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw LocalAssetStoreError.invalidImageData
            }
            try assetStore.saveImageData(data, projectID: projectID, binding: node.binding)
            assetRevision += 1
            errorMessage = nil
            selectedItem = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

extension ImageAspect {
    var ratio: CGFloat {
        switch self {
        case .square: 1
        case .portrait: 3 / 4
        case .landscape: 16 / 10
        case .banner: 21 / 9
        }
    }
}
