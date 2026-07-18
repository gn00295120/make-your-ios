import SwiftUI
import UIKit

extension ThemeAppearance {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

extension ThemeTypography {
    var fontDesign: Font.Design {
        switch self {
        case .system: .default
        case .rounded: .rounded
        case .serif: .serif
        case .monospaced: .monospaced
        }
    }
}

extension AppVisualTheme {
    var componentSpacing: CGFloat {
        switch density {
        case .compact: 10
        case .regular: 16
        case .airy: 24
        }
    }

    var componentPadding: CGFloat {
        switch density {
        case .compact: 13
        case .regular: 18
        case .airy: 22
        }
    }

    var cornerRadius: CGFloat {
        switch cornerStyle {
        case .square: 4
        case .soft: 15
        case .round: 26
        }
    }
}

extension ComponentAlignment {
    var frameAlignment: Alignment {
        switch self {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }

    var horizontalAlignment: HorizontalAlignment {
        switch self {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }

    var textAlignment: TextAlignment {
        switch self {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }
}

struct RuntimeCanvasBackground: View {
    let theme: AppVisualTheme
    let tint: AppTint

    @Environment(\.runtimeDesign) private var design

    var body: some View {
        switch theme.background {
        case .grouped:
            design.canvas
        case .plain:
            design.canvas
        case .tinted:
            ZStack {
                design.canvas
                design.accent.opacity(design.increasedContrast ? 0.12 : 0.07)
            }
        case .paper:
            ZStack {
                design.canvas
                design.highlight.opacity(0.04)
            }
        case .gradient:
            LinearGradient(
                colors: [
                    design.accent.opacity(0.25),
                    design.canvas,
                    design.secondaryAccent.opacity(0.13)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .midnight:
            LinearGradient(
                colors: [design.canvas, design.accent.opacity(0.36)],
                startPoint: .top,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct RuntimeMediaBackground: View {
    let projectID: UUID
    let theme: AppVisualTheme
    let tint: AppTint

    @Environment(LocalAssetStore.self) private var assetStore
    @Environment(\.runtimeDesign) private var design

    private var backgroundImage: UIImage? {
        guard let binding = theme.backgroundAssetBinding?.trimmingCharacters(
            in: .whitespacesAndNewlines
        ), !binding.isEmpty else {
            return nil
        }
        return assetStore.image(projectID: projectID, binding: binding)
    }

    var body: some View {
        ZStack {
            RuntimeCanvasBackground(theme: theme, tint: tint)
            if let backgroundImage {
                Image(uiImage: backgroundImage)
                    .resizable()
                    .scaledToFill()
                    .accessibilityHidden(true)
                design.canvas.opacity(design.reduceTransparency ? 0.90 : 0.60)
            }
        }
        .clipped()
    }
}

struct RuntimeNodeSurfaceModifier: ViewModifier {
    let node: ComponentNode
    let theme: AppVisualTheme
    let tint: AppTint

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.runtimeDesign) private var design

    private var presentation: ComponentPresentation {
        node.resolvedPresentation
    }

    private var surface: ComponentSurface {
        if presentation.surface != .automatic {
            return presentation.surface
        }

        let variant = RendererCatalog.normalizedVariant(presentation.variant, for: node.kind)
        switch variant {
        case .cards:
            return .card
        case .framed, .outlinedAction:
            return .outlined
        case .softAction:
            return .tinted
        case .editorial, .fullBleed, .immersive:
            return .plain
        default:
            break
        }

        switch node.kind {
        case .button, .divider, .image:
            return .plain
        default:
            return design.theme.defaultSurface == .automatic ? .card : design.theme.defaultSurface
        }
    }

    private var nodePadding: CGFloat {
        let variant = RendererCatalog.normalizedVariant(presentation.variant, for: node.kind)
        if [.fullBleed, .immersive].contains(variant) { return 0 }
        if [.compact, .dense].contains(variant) { return max(9, design.componentPadding * 0.68) }
        return design.componentPadding
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: design.cornerRadius, style: .continuous)
        let aligned = content
            .frame(maxWidth: .infinity, alignment: presentation.alignment.frameAlignment)

        surfaced(aligned, in: shape)
        .saturation(presentation.emphasis == .subtle ? 0.72 : 1)
        .contrast(presentation.emphasis == .strong ? 1.08 : 1)
        .shadow(
            color: presentation.emphasis == .strong
                ? design.accent.opacity(design.increasedContrast ? 0.22 : 0.12)
                : .clear,
            radius: presentation.emphasis == .strong ? 8 : 0,
            y: presentation.emphasis == .strong ? 3 : 0
        )
    }

    @ViewBuilder
    private func surfaced<ContentView: View>(
        _ content: ContentView,
        in shape: RoundedRectangle
    ) -> some View {
        switch surface {
        case .automatic, .plain:
            content
        case .card:
            content
                .padding(nodePadding)
                .background(design.surface, in: shape)
                .overlay {
                    shape.stroke(
                        design.borderColor.opacity(design.borderOpacity),
                        lineWidth: design.borderWidth
                    )
                }
                .shadow(
                    color: Color.black.opacity(design.shadowOpacity),
                    radius: design.shadowRadius,
                    y: design.shadowY
                )
        case .tinted:
            content
                .padding(nodePadding)
                .background(design.accent.opacity(0.11), in: shape)
                .overlay {
                    if design.differentiateWithoutColor {
                        shape.stroke(design.accent, lineWidth: max(1, design.borderWidth))
                    }
                }
        case .outlined:
            content
                .padding(nodePadding)
                .background(Color.clear, in: shape)
                .overlay {
                    shape.stroke(
                        design.accent.opacity(design.increasedContrast ? 0.92 : 0.56),
                        lineWidth: max(1.2, design.borderWidth)
                    )
                }
        case .material:
            materialSurface(content, in: shape)
        }
    }

    @ViewBuilder
    private func materialSurface<ContentView: View>(
        _ content: ContentView,
        in shape: RoundedRectangle
    ) -> some View {
        if reduceTransparency || design.reduceTransparency {
            content
                .padding(nodePadding)
                .background(design.surface, in: shape)
        } else {
            content
                .padding(nodePadding)
                .background(.thinMaterial, in: shape)
                .overlay {
                    shape.stroke(
                        design.borderColor.opacity(design.borderOpacity),
                        lineWidth: design.borderWidth
                    )
                }
        }
    }
}

extension View {
    func runtimeNodeSurface(
        node: ComponentNode,
        theme: AppVisualTheme,
        tint: AppTint
    ) -> some View {
        modifier(RuntimeNodeSurfaceModifier(node: node, theme: theme, tint: tint))
    }
}
