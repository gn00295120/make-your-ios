import SwiftUI

struct RuntimeDesignContext: Sendable {
    let theme: AppVisualTheme
    let tint: AppTint
    let palette: BrandPalette
    let typeScale: ThemeTypeScale
    let titleWeightToken: ThemeTitleWeight
    let elevation: ThemeElevation
    let stroke: ThemeStroke
    let controlShape: ThemeControlShape
    let motion: ThemeMotion
    let usesDarkPalette: Bool
    let reduceMotion: Bool
    let reduceTransparency: Bool
    let increasedContrast: Bool
    let differentiateWithoutColor: Bool

    init(
        theme: AppVisualTheme,
        tint: AppTint,
        colorScheme: ColorScheme = .light,
        reduceMotion: Bool = false,
        reduceTransparency: Bool = false,
        increasedContrast: Bool = false,
        differentiateWithoutColor: Bool = false
    ) {
        self.theme = theme
        self.tint = tint
        palette = theme.resolvedPalette
        typeScale = theme.resolvedTypeScale
        titleWeightToken = theme.resolvedTitleWeight
        elevation = theme.resolvedElevation
        stroke = theme.resolvedStroke
        controlShape = theme.resolvedControlShape
        motion = theme.resolvedMotion
        usesDarkPalette = switch theme.appearance {
        case .system: colorScheme == .dark
        case .light: false
        case .dark: true
        }
        self.reduceMotion = reduceMotion
        self.reduceTransparency = reduceTransparency
        self.increasedContrast = increasedContrast
        self.differentiateWithoutColor = differentiateWithoutColor
    }

    static let `default` = RuntimeDesignContext(theme: .legacy, tint: .indigo)

    var accent: Color { Color(runtimeHex: palette.primaryHex) }
    var secondaryAccent: Color { Color(runtimeHex: palette.secondaryHex) }
    var highlight: Color { Color(runtimeHex: palette.accentHex) }
    var onAccent: Color { Color.contrastingForeground(for: palette.primaryHex) }
    var canvas: Color {
        Color(runtimeHex: usesDarkPalette ? palette.canvasDarkHex : palette.canvasLightHex)
    }
    var surface: Color {
        Color(runtimeHex: usesDarkPalette ? palette.surfaceDarkHex : palette.surfaceLightHex)
    }
    var primaryForeground: Color { .primary }
    var secondaryForeground: Color { .secondary }
    var success: Color { .green }
    var warning: Color { .orange }
    var danger: Color { .red }

    var componentSpacing: CGFloat { theme.componentSpacing }
    var componentPadding: CGFloat { theme.componentPadding }
    var cornerRadius: CGFloat { theme.cornerRadius }
    var compactCornerRadius: CGFloat { max(6, cornerRadius * 0.68) }

    var controlCornerRadius: CGFloat {
        switch controlShape {
        case .native: 12
        case .soft: 16
        case .pill: 999
        case .angular: 5
        }
    }

    var borderWidth: CGFloat {
        switch stroke {
        case .none: increasedContrast ? 1 : 0
        case .hairline: increasedContrast ? 1.5 : 1
        case .accent: increasedContrast ? 2.2 : 1.5
        }
    }

    var borderOpacity: Double {
        switch stroke {
        case .none: increasedContrast ? 0.40 : 0
        case .hairline: increasedContrast ? 0.48 : 0.14
        case .accent: increasedContrast ? 0.92 : 0.62
        }
    }

    var borderColor: Color {
        stroke == .accent ? accent : primaryForeground
    }

    var shadowRadius: CGFloat {
        guard !reduceTransparency else { return 0 }
        switch elevation {
        case .flat: return 0
        case .subtle: return 8
        case .floating: return 18
        }
    }

    var shadowY: CGFloat { shadowRadius == 0 ? 0 : shadowRadius * 0.38 }
    var shadowOpacity: Double { increasedContrast ? 0.18 : 0.10 }

    var titleWeight: Font.Weight {
        switch titleWeightToken {
        case .regular: return .regular
        case .semibold: return .semibold
        case .bold: return .bold
        case .black: return .black
        }
    }

    var displayFont: Font {
        .system(displayTextStyle, design: theme.typography.fontDesign, weight: titleWeight)
    }

    var titleFont: Font {
        .system(titleTextStyle, design: theme.typography.fontDesign, weight: titleWeight)
    }

    var sectionFont: Font {
        .system(.title3, design: theme.typography.fontDesign, weight: titleWeight)
    }

    var bodyFont: Font { .system(.body, design: theme.typography.fontDesign) }
    var captionFont: Font { .system(.caption, design: theme.typography.fontDesign) }

    var standardAnimation: Animation? {
        guard !reduceMotion else { return nil }
        switch motion {
        case .none: return nil
        case .subtle: return .easeInOut(duration: 0.24)
        case .expressive: return .spring(duration: 0.46, bounce: 0.18)
        }
    }

    var contentTransition: AnyTransition {
        reduceMotion ? .identity : .opacity.combined(with: .scale(scale: 0.985))
    }

    func animate(_ changes: () -> Void) {
        if let standardAnimation {
            withAnimation(standardAnimation, changes)
        } else {
            changes()
        }
    }

    private var displayTextStyle: Font.TextStyle {
        switch typeScale {
        case .compact: .title
        case .balanced, .editorial, .expressive: .largeTitle
        }
    }

    private var titleTextStyle: Font.TextStyle {
        switch typeScale {
        case .compact: .title3
        case .balanced: .title2
        case .editorial, .expressive: .title
        }
    }
}

private struct RuntimeDesignContextKey: EnvironmentKey {
    static let defaultValue = RuntimeDesignContext.default
}

extension EnvironmentValues {
    var runtimeDesign: RuntimeDesignContext {
        get { self[RuntimeDesignContextKey.self] }
        set { self[RuntimeDesignContextKey.self] = newValue }
    }
}

private extension Color {
    init(runtimeHex value: String) {
        let hex = value.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let number = UInt64(hex, radix: 16) ?? 0
        let red = Double((number >> 16) & 0xFF) / 255
        let green = Double((number >> 8) & 0xFF) / 255
        let blue = Double(number & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }

    static func contrastingForeground(for value: String) -> Color {
        let hex = value.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let number = UInt64(hex, radix: 16) ?? 0
        let red = Double((number >> 16) & 0xFF) / 255
        let green = Double((number >> 8) & 0xFF) / 255
        let blue = Double(number & 0xFF) / 255
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        return luminance > 0.55 ? .black : .white
    }
}
