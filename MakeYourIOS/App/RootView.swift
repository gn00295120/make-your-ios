import SwiftUI

enum RootTab: Hashable {
    case apps
    case builder
    case aiKey
}

struct RootView: View {
    private struct RuntimeRoute: Identifiable {
        let id: UUID
    }

    @Environment(WorkspaceStore.self) private var store
    @State private var selectedTab: RootTab
    @State private var runtimeRoute: RuntimeRoute?
    private let demoScreen: String?

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        let screen = arguments
            .first(where: { $0.hasPrefix("--demo-screen=") })?
            .replacingOccurrences(of: "--demo-screen=", with: "")
        demoScreen = screen

        let initialTab: RootTab
        switch screen {
        case "builder": initialTab = .builder
        case "ai-key": initialTab = .aiKey
        default: initialTab = .apps
        }
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        if let demoDocument {
            NavigationStack {
                AppRuntimeView(
                    projectID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                    document: demoDocument
                )
            }
        } else {
            tabs
                .fullScreenCover(item: $runtimeRoute) { route in
                    if let project = store.projects.first(where: { $0.id == route.id }) {
                        ImmersiveAppHostView(
                            project: project,
                            openApps: { leaveRuntime(for: .apps) },
                            openBuilder: {
                                store.select(project.id)
                                leaveRuntime(for: .builder)
                            },
                            openAIKey: { leaveRuntime(for: .aiKey) }
                        )
                    }
                }
        }
    }

    private var demoDocument: AppDocument? {
        switch demoScreen {
        case "converter": SampleDocuments.quickConvert
        case "tasks": SampleDocuments.gentleTasks
        case "muse-journal": SampleDocuments.museJournal
        case "news": SampleDocuments.dailyBrief
        case "market": SampleDocuments.marketPocket
        case "ledger": SampleDocuments.pocketLedger
        case "platformer": SampleDocuments.skybound
        case "snake": SampleDocuments.neonSnake
        case "device": SampleDocuments.captureKit
        default: nil
        }
    }

    private var tabs: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                AppLibraryView(
                    openProject: { projectID in
                        store.select(projectID)
                        runtimeRoute = RuntimeRoute(id: projectID)
                    },
                    openBuilder: { selectedTab = .builder }
                )
            }
            .tabItem { Label("My Apps", systemImage: "square.grid.2x2.fill") }
            .tag(RootTab.apps)

            NavigationStack {
                BuilderView(
                    openApps: { selectedTab = .apps },
                    openAISettings: { selectedTab = .aiKey }
                )
            }
            .tabItem { Label("Builder", systemImage: "wand.and.stars") }
            .tag(RootTab.builder)

            NavigationStack {
                APIKeySettingsView()
            }
            .tabItem { Label("AI Key", systemImage: "key.fill") }
            .tag(RootTab.aiKey)
        }
    }

    private func leaveRuntime(for destination: RootTab) {
        selectedTab = destination
        runtimeRoute = nil
    }
}
