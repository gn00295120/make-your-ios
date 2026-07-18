import SwiftUI

struct InfoBannerNodeView: View {
    let node: ComponentNode
    let tint: AppTint

    @Environment(\.runtimeDesign) private var design

    private var variant: ComponentVariant {
        RendererCatalog.normalizedVariant(node.resolvedPresentation.variant, for: .infoBanner)
    }

    var body: some View {
        Group {
            if variant == .centered {
                VStack(spacing: 8) {
                    bannerIcon
                    bannerCopy
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            } else {
                HStack(alignment: .top, spacing: variant == .compact ? 8 : 12) {
                    bannerIcon
                    bannerCopy
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(variant == .compact ? 10 : 15)
        .background(background, in: shape)
        .overlay {
            if variant == .framed || design.differentiateWithoutColor {
                shape.stroke(design.accent.opacity(0.64), lineWidth: max(1, design.borderWidth))
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var bannerIcon: some View {
        Image(systemName: node.symbol.isEmpty ? "info.circle.fill" : node.symbol)
            .font(variant == .compact ? .subheadline : .title3)
            .foregroundStyle(design.accent)
            .accessibilityHidden(true)
    }

    private var bannerCopy: some View {
        VStack(alignment: variant == .centered ? .center : .leading, spacing: 3) {
            Text(node.title).font(design.captionFont.weight(.semibold))
            if !node.subtitle.isEmpty {
                Text(node.subtitle).font(design.captionFont).foregroundStyle(design.secondaryForeground)
            }
        }
    }

    private var background: Color {
        variant == .framed ? design.surface : design.accent.opacity(0.10)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: design.compactCornerRadius, style: .continuous)
    }
}
