import Foundation

struct AppVisualTheme: Codable, Hashable, Sendable {
    var preset: VisualThemePreset
    var appearance: ThemeAppearance
    var typography: ThemeTypography
    var background: ThemeBackground
    var cornerStyle: ThemeCornerStyle
    var density: ThemeDensity
    var defaultSurface: ComponentSurface

    static let legacy = AppVisualTheme.preset(.native)

    static func preset(_ preset: VisualThemePreset) -> AppVisualTheme {
        switch preset {
        case .native:
            nativePreset
        case .minimal:
            minimalPreset
        case .soft:
            softPreset
        case .editorial:
            editorialPreset
        case .playful:
            playfulPreset
        case .bold:
            boldPreset
        }
    }

    private static let nativePreset = AppVisualTheme(
        preset: .native,
        appearance: .system,
        typography: .system,
        background: .grouped,
        cornerStyle: .soft,
        density: .regular,
        defaultSurface: .card
    )

    private static let minimalPreset = AppVisualTheme(
        preset: .minimal,
        appearance: .system,
        typography: .system,
        background: .plain,
        cornerStyle: .square,
        density: .compact,
        defaultSurface: .plain
    )

    private static let softPreset = AppVisualTheme(
        preset: .soft,
        appearance: .system,
        typography: .rounded,
        background: .tinted,
        cornerStyle: .round,
        density: .regular,
        defaultSurface: .tinted
    )

    private static let editorialPreset = AppVisualTheme(
        preset: .editorial,
        appearance: .light,
        typography: .serif,
        background: .paper,
        cornerStyle: .square,
        density: .airy,
        defaultSurface: .plain
    )

    private static let playfulPreset = AppVisualTheme(
        preset: .playful,
        appearance: .system,
        typography: .rounded,
        background: .gradient,
        cornerStyle: .round,
        density: .airy,
        defaultSurface: .material
    )

    private static let boldPreset = AppVisualTheme(
        preset: .bold,
        appearance: .dark,
        typography: .rounded,
        background: .midnight,
        cornerStyle: .soft,
        density: .compact,
        defaultSurface: .outlined
    )
}

enum VisualThemePreset: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case native
    case minimal
    case soft
    case editorial
    case playful
    case bold

    var id: Self { self }

    var label: String {
        switch self {
        case .native: "Native"
        case .minimal: "Minimal"
        case .soft: "Soft"
        case .editorial: "Editorial"
        case .playful: "Playful"
        case .bold: "Bold"
        }
    }

    var symbol: String {
        switch self {
        case .native: "iphone"
        case .minimal: "line.3.horizontal"
        case .soft: "cloud.fill"
        case .editorial: "textformat"
        case .playful: "party.popper.fill"
        case .bold: "bolt.fill"
        }
    }
}

enum ThemeAppearance: String, Codable, CaseIterable, Hashable, Sendable {
    case system
    case light
    case dark
}

enum ThemeTypography: String, Codable, CaseIterable, Hashable, Sendable {
    case system
    case rounded
    case serif
    case monospaced
}

enum ThemeBackground: String, Codable, CaseIterable, Hashable, Sendable {
    case grouped
    case plain
    case tinted
    case paper
    case gradient
    case midnight
}

enum ThemeCornerStyle: String, Codable, CaseIterable, Hashable, Sendable {
    case square
    case soft
    case round
}

enum ThemeDensity: String, Codable, CaseIterable, Hashable, Sendable {
    case compact
    case regular
    case airy
}

struct PagePresentation: Codable, Hashable, Sendable {
    var layout: PageLayout
    var showsNavigationTitle: Bool

    static let flow = PagePresentation(layout: .flow, showsNavigationTitle: true)
}

enum PageLayout: String, Codable, CaseIterable, Hashable, Sendable {
    case flow
    case dashboard
    case form
    case story
}

struct ComponentPresentation: Codable, Hashable, Sendable {
    var surface: ComponentSurface
    var span: ComponentSpan
    var alignment: ComponentAlignment
    var emphasis: ComponentEmphasis
    var variant: ComponentVariant

    static let automatic = ComponentPresentation(
        surface: .automatic,
        span: .full,
        alignment: .leading,
        emphasis: .regular,
        variant: .automatic
    )
}

enum ComponentSurface: String, Codable, CaseIterable, Hashable, Sendable {
    case automatic
    case plain
    case card
    case tinted
    case outlined
    case material
}

enum ComponentSpan: String, Codable, CaseIterable, Hashable, Sendable {
    case full
    case half
    case adaptive
}

enum ComponentAlignment: String, Codable, CaseIterable, Hashable, Sendable {
    case leading
    case center
    case trailing
}

enum ComponentEmphasis: String, Codable, CaseIterable, Hashable, Sendable {
    case subtle
    case regular
    case strong
}

enum ComponentVariant: String, Codable, CaseIterable, Hashable, Sendable {
    case automatic
    case compact
    case centered
    case photoOverlay
    case numberFirst
    case progress
    case timeline
}

struct ImageSpec: Codable, Hashable, Sendable {
    var aspect: ImageAspect
    var contentMode: ImageContentMode
    var altText: String
    var decorative: Bool
    var allowsUserSelection: Bool

    static let editableLandscape = ImageSpec(
        aspect: .landscape,
        contentMode: .fill,
        altText: "User-selected image",
        decorative: false,
        allowsUserSelection: true
    )
}

enum ImageAspect: String, Codable, CaseIterable, Hashable, Sendable {
    case square
    case portrait
    case landscape
    case banner
}

enum ImageContentMode: String, Codable, CaseIterable, Hashable, Sendable {
    case fit
    case fill
}
