import SwiftUI

struct DesignGenerationReviewSheet: View {
    let before: AppDocument
    let after: AppDocument
    let summary: DesignChangeSummary
    let onCancel: () -> Void
    let onApply: () -> Void

    @State private var showsPreview = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    boundaryNotice
                    if showsPreview {
                        DesignGenerationPreview(document: after)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    changeList
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .background(MakeYourTheme.canvas)
            .navigationTitle("Review design changes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
            .safeAreaInset(edge: .bottom) { actionBar }
        }
    }

    private var boundaryNotice: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label("Features are locked", systemImage: "lock.shield.fill")
                .font(.headline)
                .foregroundStyle(.green)
            Text(
                "MakeYour discarded every generated change to features, content, actions, data, "
                    + "bindings, and capabilities. Only the visual fields below can be applied."
            )
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .makeYourCard()
    }

    private var changeList: some View {
        VStack(alignment: .leading, spacing: 0) {
            reviewRow(
                "App identity",
                before.symbol,
                after.symbol
            )
            Divider()
            reviewRow(
                "Style",
                before.resolvedTheme.preset.label,
                after.resolvedTheme.preset.label
            )
            Divider()
            paletteRow
            Divider()
            reviewRow(
                "Typography",
                typographyDescription(before.resolvedTheme),
                typographyDescription(after.resolvedTheme)
            )
            Divider()
            reviewRow(
                "Motion",
                before.resolvedTheme.resolvedMotion.rawValue.capitalized,
                after.resolvedTheme.resolvedMotion.rawValue.capitalized
            )
            Divider()
            impactRow
        }
        .makeYourCard()
    }

    private var paletteRow: some View {
        HStack(spacing: 12) {
            Text("Palette")
                .font(.subheadline.weight(.medium))
            Spacer()
            paletteSwatches(before.resolvedTheme.resolvedPalette)
                .opacity(0.58)
                .accessibilityLabel("Current palette")
            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundStyle(.secondary)
            paletteSwatches(after.resolvedTheme.resolvedPalette)
                .accessibilityLabel("Proposed palette")
        }
        .frame(minHeight: 54)
    }

    private var impactRow: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Affected presentation")
                .font(.subheadline.weight(.medium))
            Text(
                "\(summary.layoutPageCount) page layouts · "
                    + "\(summary.styledNodeCount) component styles"
            )
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
    }

    private var actionBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                Button {
                    withAnimation(.snappy) { showsPreview.toggle() }
                } label: {
                    Label(showsPreview ? "Hide Preview" : "Preview", systemImage: "iphone")
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.bordered)

                Button(action: onApply) {
                    Label("Apply", systemImage: "checkmark")
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(after.tint.color)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.bar)
        }
    }

    private func reviewRow(_ title: String, _ oldValue: String, _ newValue: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline.weight(.medium))
            HStack(spacing: 7) {
                Text(oldValue)
                    .foregroundStyle(.secondary)
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text(newValue)
                    .fontWeight(.semibold)
            }
            .font(.caption)
        }
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
    }

    private func typographyDescription(_ theme: AppVisualTheme) -> String {
        "\(theme.typography.rawValue.capitalized), "
            + "\(theme.resolvedTypeScale.rawValue.capitalized), "
            + theme.resolvedTitleWeight.rawValue.capitalized
    }

    private func paletteSwatches(_ palette: BrandPalette) -> some View {
        HStack(spacing: -3) {
            ForEach(
                [palette.primaryHex, palette.secondaryHex, palette.accentHex],
                id: \.self
            ) { hex in
                Circle()
                    .fill(Color(studioHex: hex))
                    .frame(width: 25, height: 25)
                    .overlay { Circle().stroke(.white.opacity(0.8), lineWidth: 1) }
            }
        }
    }
}

private struct DesignGenerationPreview: View {
    let document: AppDocument

    private var theme: AppVisualTheme { document.resolvedTheme }
    private var palette: BrandPalette { theme.resolvedPalette }

    var body: some View {
        VStack(spacing: 12) {
            Text("PROPOSED PREVIEW")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: document.symbol)
                        .font(.title3)
                        .foregroundStyle(Color(studioHex: palette.primaryHex))
                    Spacer()
                    Image(systemName: "ellipsis")
                }
                Text(document.name)
                    .font(.system(.title2, design: theme.typography.fontDesign).bold())
                Text(document.summary)
                    .font(.system(.caption, design: theme.typography.fontDesign))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                RoundedRectangle(cornerRadius: previewCornerRadius, style: .continuous)
                    .fill(Color(studioHex: palette.surfaceLightHex))
                    .frame(height: 92)
                    .overlay(alignment: .leading) {
                        VStack(alignment: .leading, spacing: 8) {
                            Capsule()
                                .fill(Color(studioHex: palette.accentHex))
                                .frame(width: 48, height: 6)
                            Text("Your features stay exactly the same")
                                .font(.caption.weight(.semibold))
                        }
                        .padding(14)
                    }
                    .shadow(color: .black.opacity(0.10), radius: shadowRadius, y: 3)
            }
            .padding(18)
            .frame(maxWidth: 270, minHeight: 340, alignment: .top)
            .background(Color(studioHex: palette.canvasLightHex))
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(.black, lineWidth: 6)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Proposed design preview for \(document.name)")
        }
        .frame(maxWidth: .infinity)
    }

    private var previewCornerRadius: CGFloat {
        switch theme.cornerStyle {
        case .square: 3
        case .soft: 14
        case .round: 24
        }
    }

    private var shadowRadius: CGFloat {
        switch theme.resolvedElevation {
        case .flat: 0
        case .subtle: 4
        case .floating: 12
        }
    }
}
