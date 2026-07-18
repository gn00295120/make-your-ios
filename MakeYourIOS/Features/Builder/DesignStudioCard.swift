import SwiftUI

struct DesignStudioCard: View {
    let project: WorkspaceProject
    let onTheme: (VisualThemePreset) -> Void
    let onAddImage: () -> Void
    let onOpenStudio: () -> Void

    private var selectedPreset: VisualThemePreset {
        project.document.resolvedTheme.preset
    }

    private var hasImageBlock: Bool {
        project.document.pages.flatMap(\.nodes).contains(where: { $0.kind == .image })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            presetPicker
            studioButton
            imageButton
            Text(
                "Build a complete visual identity here, or ask AI to preserve every feature "
                    + "and change only the design."
            )
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .makeYourCard()
    }

    private var header: some View {
        HStack {
            Label("Visual identity", systemImage: "paintpalette.fill")
                .font(.headline)
            Spacer()
            Text("STYLE")
                .font(.caption2.bold())
                .foregroundStyle(project.document.tint.color)
        }
    }

    private var presetPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(VisualThemePreset.allCases) { preset in
                    presetButton(preset)
                }
            }
        }
    }

    private func presetButton(_ preset: VisualThemePreset) -> some View {
        Button {
            onTheme(preset)
        } label: {
            VStack(spacing: 7) {
                Image(systemName: preset.symbol)
                    .font(.headline)
                    .frame(width: 42, height: 34)
                    .background(presetBackground(preset), in: RoundedRectangle(cornerRadius: 11))
                Text(preset.label).font(.caption2.weight(.medium))
            }
            .foregroundStyle(preset == selectedPreset ? project.document.tint.color : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Use \(preset.label) style")
    }

    private func presetBackground(_ preset: VisualThemePreset) -> Color {
        preset == selectedPreset
            ? project.document.tint.color.opacity(0.18)
            : Color.primary.opacity(0.05)
    }

    private var imageButton: some View {
        Button(action: onAddImage) {
            Label(
                hasImageBlock ? "Reset primary photo block" : "Add a private photo block",
                systemImage: "photo.badge.plus"
            )
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
        }
        .buttonStyle(.bordered)
        .tint(project.document.tint.color)
    }

    private var studioButton: some View {
        Button(action: onOpenStudio) {
            HStack {
                Label("Open Design Studio", systemImage: "slider.horizontal.3")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
        }
        .buttonStyle(.borderedProminent)
        .tint(project.document.tint.color)
        .accessibilityHint("Customize colors, type, layout, shape, depth, and motion")
    }
}
