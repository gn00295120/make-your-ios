import Foundation

extension CapabilityRegistry {
    static let shortcutsOpenTinyApp = CapabilityMetadata(
        capability: .shortcutsOpenTinyApp,
        category: .automation,
        privacyRisk: .moderate,
        availability: .systemMediated,
        requiresExplicitUserAction: true,
        hostEnforcedSummary: "Exposes only opted-in tiny apps' stable IDs, names, and safe icons to "
            + "Apple Shortcuts, then opens the chosen app in the foreground like tapping its app card.",
        frameworkOrPermissionNote: "One fixed AppIntent and dynamic AppEntity query; local device "
            + "authentication is required, and generated code, state, prompts, and assets are excluded."
    )
}
