import Foundation

extension GeneratedAppPayload {
    func makeTheme() -> AppVisualTheme {
        let preset = VisualThemePreset(rawValue: theme.preset) ?? .native
        let defaults = AppVisualTheme.preset(preset)
        let requestedPalette = BrandPalette(
            primaryHex: theme.palette.primaryHex,
            secondaryHex: theme.palette.secondaryHex,
            accentHex: theme.palette.accentHex,
            canvasLightHex: theme.palette.canvasLightHex,
            canvasDarkHex: theme.palette.canvasDarkHex,
            surfaceLightHex: theme.palette.surfaceLightHex,
            surfaceDarkHex: theme.palette.surfaceDarkHex
        )
        return AppVisualTheme(
            preset: preset,
            appearance: ThemeAppearance(rawValue: theme.appearance) ?? defaults.appearance,
            typography: ThemeTypography(rawValue: theme.typography) ?? defaults.typography,
            background: ThemeBackground(rawValue: theme.background) ?? defaults.background,
            cornerStyle: ThemeCornerStyle(rawValue: theme.cornerStyle) ?? defaults.cornerStyle,
            density: ThemeDensity(rawValue: theme.density) ?? defaults.density,
            defaultSurface: ComponentSurface(rawValue: theme.defaultSurface) ?? defaults.defaultSurface,
            palette: requestedPalette.normalized(fallback: defaults.resolvedPalette),
            typeScale: ThemeTypeScale(rawValue: theme.typeScale) ?? defaults.resolvedTypeScale,
            titleWeight: ThemeTitleWeight(rawValue: theme.titleWeight) ?? defaults.resolvedTitleWeight,
            elevation: ThemeElevation(rawValue: theme.elevation) ?? defaults.resolvedElevation,
            stroke: ThemeStroke(rawValue: theme.stroke) ?? defaults.resolvedStroke,
            controlShape: ThemeControlShape(rawValue: theme.controlShape)
                ?? defaults.resolvedControlShape,
            motion: ThemeMotion(rawValue: theme.motion) ?? defaults.resolvedMotion,
            backgroundAssetBinding: normalizedAssetBinding(theme.backgroundAssetBinding)
        )
    }

    private func normalizedAssetBinding(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              trimmed.count <= 120,
              trimmed.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" }) else {
            return nil
        }
        return trimmed.lowercased()
    }
}
