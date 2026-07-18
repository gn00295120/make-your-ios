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
            Button(action: openBuilder) {
                Label("Edit in Builder", systemImage: "wand.and.stars")
            }
            Button(action: openAIKey) {
                Label("AI Key", systemImage: "key.fill")
            }
        } label: {
            Image(systemName: "circle.grid.2x2.fill")
                .font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .contentShape(.circle)
        }
        .accessibilityLabel("MakeYour menu")
        .accessibilityHint("Opens app library, builder, and AI key options")
        .accessibilityIdentifier("runtime.host-menu")
    }
}
