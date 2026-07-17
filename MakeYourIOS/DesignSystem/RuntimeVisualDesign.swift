import SwiftUI

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

    var body: some View {
        switch theme.background {
        case .grouped:
            Color(uiColor: .systemGroupedBackground)
        case .plain:
            Color(uiColor: .systemBackground)
        case .tinted:
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                tint.color.opacity(0.08)
            }
        case .paper:
            ZStack {
                Color(uiColor: .systemBackground)
                Color.orange.opacity(0.045)
            }
        case .gradient:
            LinearGradient(
                colors: [tint.color.opacity(0.20), Color(uiColor: .systemBackground), tint.color.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .midnight:
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.05, blue: 0.11), tint.color.opacity(0.30)],
                startPoint: .top,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct RuntimeNodeSurfaceModifier: ViewModifier {
    let node: ComponentNode
    let theme: AppVisualTheme
    let tint: AppTint

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private var presentation: ComponentPresentation {
        node.resolvedPresentation
    }

    private var surface: ComponentSurface {
        if presentation.surface != .automatic {
            return presentation.surface
        }

        switch node.kind {
        case .button, .divider, .image:
            return .plain
        default:
            return theme.defaultSurface == .automatic ? .card : theme.defaultSurface
        }
    }

    private var opacity: Double {
        presentation.emphasis == .subtle ? 0.82 : 1
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
        let aligned = content
            .frame(maxWidth: .infinity, alignment: presentation.alignment.frameAlignment)
            .opacity(opacity)

        switch surface {
        case .automatic, .plain:
            aligned
        case .card:
            aligned
                .padding(theme.componentPadding)
                .background(Color(uiColor: .secondarySystemBackground), in: shape)
                .overlay { shape.stroke(Color.primary.opacity(0.06), lineWidth: 1) }
        case .tinted:
            aligned
                .padding(theme.componentPadding)
                .background(tint.color.opacity(0.11), in: shape)
        case .outlined:
            aligned
                .padding(theme.componentPadding)
                .background(Color.clear, in: shape)
                .overlay { shape.stroke(tint.color.opacity(0.42), lineWidth: 1.2) }
        case .material:
            if reduceTransparency {
                aligned
                    .padding(theme.componentPadding)
                    .background(Color(uiColor: .secondarySystemBackground), in: shape)
            } else {
                aligned
                    .padding(theme.componentPadding)
                    .background(.thinMaterial, in: shape)
                    .overlay { shape.stroke(Color.white.opacity(0.16), lineWidth: 1) }
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
