import AppIntents
import SwiftUI

struct RuntimeShortcutAccessView: View {
    let node: ComponentNode

    @Environment(\.runtimeDesign) private var design

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                node.title,
                systemImage: node.symbol.isEmpty
                    ? "square.stack.3d.up.badge.automatic"
                    : node.symbol
            )
            .font(design.bodyFont.weight(.semibold))

            if !node.subtitle.isEmpty {
                Text(node.subtitle)
                    .font(design.captionFont)
                    .foregroundStyle(design.secondaryForeground)
            }

            SiriTipView(intent: OpenTinyAppIntent())
                .siriTipViewStyle(.automatic)

            ShortcutsLink {
                TinyAppShortcuts.updateAppShortcutParameters()
            }
            .shortcutsLinkStyle(.automaticOutline)
            .accessibilityIdentifier("runtime.shortcuts.\(node.id).open")

            Label(
                "Shortcuts receives only opted-in app identities, names, and icons. The shortcut "
                    + "only opens the chosen app; once open, it behaves normally.",
                systemImage: "lock.shield.fill"
            )
            .font(design.captionFont)
            .foregroundStyle(design.secondaryForeground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("runtime.shortcuts.\(node.id)")
    }
}
