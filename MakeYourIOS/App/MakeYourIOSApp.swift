import SwiftUI

@main
struct MakeYourIOSApp: App {
    @State private var workspaceStore: WorkspaceStore
    @State private var aiSettings: AISettingsStore
    @State private var assetStore: LocalAssetStore
#if DEBUG
    @State private var didStartDemoTTSExport = false
#endif

    init() {
        RuntimeVoiceRecordingFiles.removeAllStagedRecordings()
        let assets = LocalAssetStore()
        _assetStore = State(initialValue: assets)
        _workspaceStore = State(initialValue: WorkspaceStore(assetStore: assets))
        _aiSettings = State(initialValue: AISettingsStore())
        TinyAppShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            appContent
        }
    }

    @ViewBuilder
    private var appContent: some View {
#if DEBUG
        rootContent
            .task {
                guard !didStartDemoTTSExport else { return }
                didStartDemoTTSExport = true
                await DemoTTSExportCoordinator.exportIfRequested(settings: aiSettings)
            }
#else
        rootContent
#endif
    }

    private var rootContent: some View {
        RootView()
            .environment(workspaceStore)
            .environment(aiSettings)
            .environment(assetStore)
            .tint(MakeYourTheme.brand)
            .onChange(of: workspaceStore.projects) {
                TinyAppShortcuts.updateAppShortcutParameters()
            }
    }
}
