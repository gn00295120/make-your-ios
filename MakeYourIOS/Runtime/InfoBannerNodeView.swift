import SwiftUI

struct InfoBannerNodeView: View {
    let node: ComponentNode
    let tint: AppTint

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: node.symbol.isEmpty ? "info.circle.fill" : node.symbol)
                .font(.title3)
                .foregroundStyle(tint.color)
            VStack(alignment: .leading, spacing: 3) {
                Text(node.title).font(.subheadline.weight(.semibold))
                if !node.subtitle.isEmpty {
                    Text(node.subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(15)
        .background(tint.color.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
