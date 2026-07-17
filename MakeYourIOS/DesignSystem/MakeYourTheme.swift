import SwiftUI

enum MakeYourTheme {
    static let brand = Color(red: 0.36, green: 0.30, blue: 0.96)
    static let brandSecondary = Color(red: 0.65, green: 0.35, blue: 0.98)

    static var canvas: Color {
        Color(uiColor: .systemGroupedBackground)
    }

    static var raised: Color {
        Color(uiColor: .secondarySystemGroupedBackground)
    }

    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [brand, brandSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct MakeYourCardModifier: ViewModifier {
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(MakeYourTheme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            }
    }
}

extension View {
    func makeYourCard(padding: CGFloat = 18) -> some View {
        modifier(MakeYourCardModifier(padding: padding))
    }
}

struct AppGlyph: View {
    let symbol: String
    let tint: AppTint
    var size: CGFloat = 54

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.38, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(
                    colors: [tint.color, tint.color.opacity(0.72)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            )
            .shadow(color: tint.color.opacity(0.22), radius: 12, y: 6)
            .accessibilityHidden(true)
    }
}

struct CapabilityPill: View {
    let capability: AppCapability

    var body: some View {
        Label(capability.label, systemImage: capability.symbol)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.quaternary, in: Capsule())
    }
}
