import Foundation

struct BrandPalette: Codable, Hashable, Sendable {
    var primaryHex: String
    var secondaryHex: String
    var accentHex: String
    var canvasLightHex: String
    var canvasDarkHex: String
    var surfaceLightHex: String
    var surfaceDarkHex: String

    var isValid: Bool {
        [
            primaryHex,
            secondaryHex,
            accentHex,
            canvasLightHex,
            canvasDarkHex,
            surfaceLightHex,
            surfaceDarkHex
        ].allSatisfy(Self.isValidHex)
    }

    func normalized(fallback: BrandPalette) -> BrandPalette {
        BrandPalette(
            primaryHex: Self.normalizedHex(primaryHex, fallback: fallback.primaryHex),
            secondaryHex: Self.normalizedHex(secondaryHex, fallback: fallback.secondaryHex),
            accentHex: Self.normalizedHex(accentHex, fallback: fallback.accentHex),
            canvasLightHex: Self.normalizedHex(canvasLightHex, fallback: fallback.canvasLightHex),
            canvasDarkHex: Self.normalizedHex(canvasDarkHex, fallback: fallback.canvasDarkHex),
            surfaceLightHex: Self.normalizedHex(surfaceLightHex, fallback: fallback.surfaceLightHex),
            surfaceDarkHex: Self.normalizedHex(surfaceDarkHex, fallback: fallback.surfaceDarkHex)
        )
    }

    static func isValidHex(_ value: String) -> Bool {
        isHexShape(value) && value == value.uppercased()
    }

    private static func normalizedHex(_ value: String, fallback: String) -> String {
        isHexShape(value) ? value.uppercased() : fallback
    }

    private static func isHexShape(_ value: String) -> Bool {
        value.count == 7 && value.first == "#" && value.dropFirst().allSatisfy(\.isHexDigit)
    }
}

extension BrandPalette {
    static let nativeDesign = BrandPalette(
        primaryHex: "#5450EF", secondaryHex: "#667085", accentHex: "#0A84FF",
        canvasLightHex: "#F2F2F7", canvasDarkHex: "#000000",
        surfaceLightHex: "#FFFFFF", surfaceDarkHex: "#1C1C1E"
    )
    static let minimalDesign = BrandPalette(
        primaryHex: "#171717", secondaryHex: "#737373", accentHex: "#525252",
        canvasLightHex: "#FAFAFA", canvasDarkHex: "#0A0A0A",
        surfaceLightHex: "#FFFFFF", surfaceDarkHex: "#171717"
    )
    static let softDesign = BrandPalette(
        primaryHex: "#8B5CF6", secondaryHex: "#EC4899", accentHex: "#14B8A6",
        canvasLightHex: "#FAF7FF", canvasDarkHex: "#17121F",
        surfaceLightHex: "#FFFFFF", surfaceDarkHex: "#251D30"
    )
    static let editorialDesign = BrandPalette(
        primaryHex: "#292524", secondaryHex: "#78716C", accentHex: "#B45309",
        canvasLightHex: "#FAF8F3", canvasDarkHex: "#1C1917",
        surfaceLightHex: "#FFFDF8", surfaceDarkHex: "#292524"
    )
    static let playfulDesign = BrandPalette(
        primaryHex: "#7C3AED", secondaryHex: "#EC4899", accentHex: "#F59E0B",
        canvasLightHex: "#F5F3FF", canvasDarkHex: "#140D2B",
        surfaceLightHex: "#FFFFFF", surfaceDarkHex: "#261B45"
    )
    static let boldDesign = BrandPalette(
        primaryHex: "#F97316", secondaryHex: "#A855F7", accentHex: "#22D3EE",
        canvasLightHex: "#F8FAFC", canvasDarkHex: "#09090B",
        surfaceLightHex: "#FFFFFF", surfaceDarkHex: "#18181B"
    )
}

extension AppVisualTheme {
    var resolvedPalette: BrandPalette {
        palette ?? Self.preset(preset).palette ?? .nativeDesign
    }

    var resolvedTypeScale: ThemeTypeScale {
        typeScale ?? Self.preset(preset).typeScale ?? .balanced
    }

    var resolvedTitleWeight: ThemeTitleWeight {
        titleWeight ?? Self.preset(preset).titleWeight ?? .bold
    }

    var resolvedElevation: ThemeElevation {
        elevation ?? Self.preset(preset).elevation ?? .subtle
    }

    var resolvedStroke: ThemeStroke {
        stroke ?? Self.preset(preset).stroke ?? .hairline
    }

    var resolvedControlShape: ThemeControlShape {
        controlShape ?? Self.preset(preset).controlShape ?? .native
    }

    var resolvedMotion: ThemeMotion {
        motion ?? Self.preset(preset).motion ?? .subtle
    }
}

enum ThemeTypeScale: String, Codable, CaseIterable, Hashable, Sendable {
    case compact
    case balanced
    case editorial
    case expressive
}

enum ThemeTitleWeight: String, Codable, CaseIterable, Hashable, Sendable {
    case regular
    case semibold
    case bold
    case black
}

enum ThemeElevation: String, Codable, CaseIterable, Hashable, Sendable {
    case flat
    case subtle
    case floating
}

enum ThemeStroke: String, Codable, CaseIterable, Hashable, Sendable {
    case none
    case hairline
    case accent
}

enum ThemeControlShape: String, Codable, CaseIterable, Hashable, Sendable {
    case native
    case soft
    case pill
    case angular
}

enum ThemeMotion: String, Codable, CaseIterable, Hashable, Sendable {
    case none
    case subtle
    case expressive
}

enum PageNavigationStyle: String, Codable, CaseIterable, Hashable, Sendable {
    case automatic
    case segmented
    case chips
    case menu
}

enum MediaRole: String, Codable, CaseIterable, Hashable, Sendable {
    case content
    case hero
    case background
    case logo
    case avatar
    case thumbnail
    case decorative
}

enum ImageFocalPoint: String, Codable, CaseIterable, Hashable, Sendable {
    case center
    case top
    case bottom
    case leading
    case trailing
}

enum ImageMask: String, Codable, CaseIterable, Hashable, Sendable {
    case none
    case rounded
    case circle
    case capsule
}

enum ImageOverlay: String, Codable, CaseIterable, Hashable, Sendable {
    case none
    case scrim
    case tint
}
