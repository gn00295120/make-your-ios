import SwiftUI

struct ImmersiveAppHostView: View {
    let project: WorkspaceProject
    let openApps: () -> Void
    let openBuilder: () -> Void
    let openAIKey: () -> Void

    var body: some View {
        NavigationStack {
            AppRuntimeView(projectID: project.id, document: project.document)
                .navigationBarBackButtonHidden()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        hostMenu
                    }
                }
        }
    }

    private var hostMenu: some View {
        Menu {
            Button(action: openApps) {
                Label("My Apps", systemImage: "square.grid.2x2.fill")
            }
            .accessibilityIdentifier("runtime.open-apps")
            Button(action: openBuilder) {
                Label("Edit in Builder", systemImage: "wand.and.stars")
            }
            .accessibilityIdentifier("runtime.open-builder")
            Button(action: openAIKey) {
                Label("AI Key", systemImage: "key.fill")
            }
            .accessibilityIdentifier("runtime.open-ai-key")
        } label: {
            Image(systemName: "circle.grid.2x2.fill")
                .font(.body.weight(.semibold))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(Color.primary)
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
                .overlay {
                    Circle().stroke(Color.primary.opacity(0.14), lineWidth: 1)
                }
                .contentShape(.circle)
        }
        .accessibilityLabel("MakeYour menu")
        .accessibilityHint("Opens app library, builder, and AI key options")
        .accessibilityIdentifier("runtime.host-menu")
    }
}
