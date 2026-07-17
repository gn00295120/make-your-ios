import PhotosUI
import SwiftUI

struct ImageNodeView: View {
    let projectID: UUID
    let node: ComponentNode
    let tint: AppTint
    let theme: AppVisualTheme

    @Environment(LocalAssetStore.self) private var assetStore
    @State private var selectedItem: PhotosPickerItem?
    @State private var assetRevision = 0
    @State private var errorMessage: String?

    private var spec: ImageSpec {
        node.image ?? .editableLandscape
    }

    private var storedImage: UIImage? {
        _ = assetRevision
        return assetStore.image(projectID: projectID, binding: node.binding)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                imageContent

                if spec.allowsUserSelection, storedImage != nil {
                    PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                        Label("Change", systemImage: "photo.badge.plus")
                            .font(.caption.bold())
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                            .background(.regularMaterial, in: Capsule())
                    }
                    .padding(12)
                }
            }

            if !node.title.isEmpty || !node.subtitle.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    if !node.title.isEmpty { Text(node.title).font(.headline) }
                    if !node.subtitle.isEmpty {
                        Text(node.subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }

            if spec.allowsUserSelection {
                Label(
                    "This photo stays on this device and is never sent to AI.",
                    systemImage: "lock.shield.fill"
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .onChange(of: selectedItem) { _, item in
            guard let item else { return }
            Task { await importPhoto(item) }
        }
    }

    @ViewBuilder
    private var imageContent: some View {
        if let storedImage {
            Group {
                if spec.contentMode == .fill {
                    Image(uiImage: storedImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(uiImage: storedImage)
                        .resizable()
                        .scaledToFit()
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(spec.aspect.ratio, contentMode: .fit)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
            .accessibilityHidden(spec.decorative)
            .accessibilityLabel(spec.altText)
        } else {
            ZStack {
                LinearGradient(
                    colors: [tint.color.opacity(0.28), tint.color.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                VStack(spacing: 12) {
                    Image(systemName: node.symbol.isEmpty ? "photo.fill" : node.symbol)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(tint.color)
                    if spec.allowsUserSelection {
                        PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                            Label("Choose photo", systemImage: "photo.badge.plus")
                                .font(.subheadline.bold())
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(tint.color)
                    } else {
                        Text("Image placeholder")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(spec.aspect.ratio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(spec.altText)
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
            errorMessage = nil
            selectedItem = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private extension ImageAspect {
    var ratio: CGFloat {
        switch self {
        case .square: 1
        case .portrait: 3 / 4
        case .landscape: 16 / 10
        case .banner: 21 / 9
        }
    }
}
