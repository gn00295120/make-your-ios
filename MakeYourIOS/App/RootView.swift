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

    private struct IntentRouteError: Identifiable {
        let id = UUID()
        let message: String
    }

    @Environment(WorkspaceStore.self) private var store
    @State private var intentRouter = TinyAppIntentRouter.shared
    @State private var selectedTab: RootTab
    @State private var runtimeRoute: RuntimeRoute?
    @State private var isPresentingDemo: Bool
    @State private var pendingIntentProjectID: UUID?
    @State private var intentRouteError: IntentRouteError?
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
        _isPresentingDemo = State(initialValue: Self.demoScreenNames.contains(screen ?? ""))
    }

    var body: some View {
        tabs
            .fullScreenCover(item: $runtimeRoute, onDismiss: presentPendingIntentRoute) { route in
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
            .fullScreenCover(isPresented: $isPresentingDemo, onDismiss: presentPendingIntentRoute) {
                if demoScreen == "generation-progress" {
                    AppGenerationProgressView(
                        mode: .full,
                        progress: .generating,
                        startedAt: Date().addingTimeInterval(-65),
                        promptPreview: "Create a polished three-page travel companion with native tools.",
                        failure: nil,
                        onCancel: { isPresentingDemo = false },
                        onRetry: {},
                        onClose: { isPresentingDemo = false }
                    )
                    .interactiveDismissDisabled()
                } else if let demoProject {
                    ImmersiveAppHostView(
                        project: demoProject,
                        openApps: { leaveDemo(for: .apps) },
                        openBuilder: {
                            selectWorkspaceProject(matching: demoProject.document)
                            leaveDemo(for: .builder)
                        },
                        openAIKey: { leaveDemo(for: .aiKey) }
                    )
                } else {
                    ContentUnavailableView(
                        "Demo unavailable",
                        systemImage: "exclamationmark.triangle"
                    )
                }
            }
            .onChange(of: intentRouter.pendingRequest, initial: true) { _, request in
                guard let request else { return }
                handleIntentRoute(request)
            }
            .alert(item: $intentRouteError) { error in
                Alert(
                    title: Text("Tiny app unavailable"),
                    message: Text(error.message),
                    dismissButton: .default(Text("OK"))
                )
            }
    }

    private var demoProject: WorkspaceProject? {
        guard let demoDocument else { return nil }
        return WorkspaceProject(
            id: demoDocument.id,
            document: demoDocument,
            createdAt: demoDocument.updatedAt,
            updatedAt: demoDocument.updatedAt,
            lastPrompt: "Demo route"
        )
    }

    private var demoDocument: AppDocument? {
        switch demoScreen {
        case "waterline": SampleDocuments.waterline
        case "star-garden": SampleDocuments.starGarden
        case "converter": SampleDocuments.quickConvert
        case "tasks": SampleDocuments.gentleTasks
        case "muse-journal": SampleDocuments.museJournal
        case "news": SampleDocuments.dailyBrief
        case "market": SampleDocuments.marketPocket
        case "ledger": SampleDocuments.pocketLedger
        case "platformer": SampleDocuments.skybound
        case "snake": SampleDocuments.neonSnake
        case "device": SampleDocuments.captureKit
        case "shortcuts": SampleDocuments.shortcutShelf
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

    private func leaveDemo(for destination: RootTab) {
        selectedTab = destination
        isPresentingDemo = false
    }

    private func selectWorkspaceProject(matching document: AppDocument) {
        guard let project = store.projects.first(where: {
            $0.document.name == document.name
        }) else { return }
        store.select(project.id)
    }

    private func handleIntentRoute(_ request: TinyAppIntentRouter.Request) {
        intentRouter.consume(requestID: request.id)
        selectedTab = .apps

        guard eligibleProject(id: request.projectID) != nil else {
            pendingIntentProjectID = nil
            intentRouteError = IntentRouteError(
                message: "It may have been deleted or its Shortcuts access was removed."
            )
            return
        }

        if runtimeRoute?.id == request.projectID {
            pendingIntentProjectID = nil
            return
        }

        pendingIntentProjectID = request.projectID
        if runtimeRoute != nil {
            runtimeRoute = nil
        } else if isPresentingDemo {
            isPresentingDemo = false
        } else {
            presentPendingIntentRoute()
        }
    }

    private func presentPendingIntentRoute() {
        guard let projectID = pendingIntentProjectID else { return }
        pendingIntentProjectID = nil
        guard eligibleProject(id: projectID) != nil else {
            intentRouteError = IntentRouteError(
                message: "It may have been deleted or its Shortcuts access was removed."
            )
            return
        }
        runtimeRoute = RuntimeRoute(id: projectID)
    }

    private func eligibleProject(id: UUID) -> WorkspaceProject? {
        store.projects.first {
            $0.id == id && TinyAppShortcutEligibility.isEligible($0.document)
        }
    }

    private static let demoScreenNames: Set<String> = [
        "waterline", "star-garden", "converter", "tasks", "muse-journal", "news", "market",
        "ledger", "platformer", "snake", "device", "shortcuts", "generation-progress"
    ]
}
