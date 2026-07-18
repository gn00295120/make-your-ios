import SwiftUI

struct ComponentRenderer: View {
    let projectID: UUID
    let node: ComponentNode
    let tint: AppTint
    let theme: AppVisualTheme
    let capabilities: [AppCapability]
    @Bindable var session: RuntimeSessionState
    let audioHost: RuntimeAudioHost
    let speechHost: RuntimeSpeechHost
    let onEvent: (RuntimeEventTrigger, ComponentNode) -> Void
    let onLegacyAction: (RuntimeAction, ComponentNode) -> Void

    @Environment(\.scenePhase) private var scenePhase
    @State private var didRunAppearEvent = false

    var body: some View {
        content
            .runtimeNodeSurface(node: node, theme: theme, tint: tint)
            .onAppear {
                guard !didRunAppearEvent,
                      node.events?.contains(where: { $0.trigger == .appear }) == true else { return }
                didRunAppearEvent = true
                onEvent(.appear, node)
            }
            .task(id: timerInterval) {
                guard let timerInterval else { return }
                while !Task.isCancelled {
                    do {
                        try await Task.sleep(for: .seconds(timerInterval))
                    } catch {
                        return
                    }
                    guard !Task.isCancelled else { return }
                    if scenePhase == .active {
                        onEvent(.timer, node)
                    }
                }
            }
    }

    private var timerInterval: Int? {
        node.events?.first(where: { $0.trigger == .timer })?.intervalSeconds
    }

    // Exhaustive interpreter dispatch: each generated component kind maps to one reviewed renderer.
    @ViewBuilder
    private var content: some View {
        switch node.kind {
        case .hero:
            HeroNodeView(projectID: projectID, node: node, tint: tint, theme: theme)
        case .sectionHeader:
            SectionHeaderNodeView(node: node)
        case .text:
            TextNodeView(node: node, session: session)
        case .metric:
            MetricNodeView(node: node, tint: tint, session: session)
        case .textInput, .numberInput:
            InputNodeView(
                node: node,
                tint: tint,
                session: session,
                onValueChanged: { onEvent(.valueChanged, node) }
            )
        case .picker:
            PickerNodeView(
                node: node,
                tint: tint,
                session: session,
                onValueChanged: { onEvent(.valueChanged, node) }
            )
        case .button:
            ActionButtonNodeView(node: node, session: session) {
                if node.events?.isEmpty == false {
                    onEvent(.tap, node)
                } else {
                    onLegacyAction(node.action, node)
                }
            }
        case .checklist:
            ChecklistNodeView(node: node, tint: tint, session: session)
        case .infoBanner:
            InfoBannerNodeView(node: node, tint: tint, session: session)
        case .currencyConverter:
            CurrencyConverterRuntimeView(node: node, tint: tint)
        case .taskList:
            TaskListRuntimeView(projectID: projectID, node: node, tint: tint)
        case .image:
            ImageNodeView(projectID: projectID, node: node, tint: tint, theme: theme)
        case .aiAssistant:
            AITextRuntimeView(
                node: node,
                tint: tint,
                session: session,
                onValueChanged: { onEvent(.valueChanged, node) }
            )
        case .recordCollection:
            RecordCollectionRuntimeView(
                projectID: projectID,
                node: node,
                tint: tint,
                capabilities: capabilities
            )
        case .liveDataList:
            LiveDataListRuntimeView(projectID: projectID, node: node, tint: tint)
        case .newsFeed:
            NewsFeedRuntimeView(projectID: projectID, node: node, tint: tint)
        case .marketWatch:
            MarketWatchRuntimeView(projectID: projectID, node: node, tint: tint)
        case .ledger:
            LedgerRuntimeView(projectID: projectID, node: node, tint: tint)
        case .game:
            GameRuntimeView(projectID: projectID, node: node, tint: tint)
        case .deviceInput:
            DeviceInputRuntimeView(
                projectID: projectID,
                node: node,
                tint: tint,
                theme: theme,
                session: session,
                onValueChanged: { onEvent(.valueChanged, node) }
            )
        case .control:
            RuntimeControlNodeView(
                node: node,
                session: session,
                onValueChanged: { onEvent(.valueChanged, node) }
            )
        case .collectionView:
            RuntimeCollectionNodeView(node: node, session: session)
        case .map:
            RuntimeMapView(node: node)
        case .calendarEvent:
            RuntimeCalendarEventView(node: node, session: session)
        case .documentExport:
            RuntimeDocumentExportView(node: node, session: session)
        case .voiceNote:
            RuntimeVoiceNoteView(
                projectID: projectID,
                node: node,
                audioHost: audioHost,
                speechHost: speechHost
            )
        case .speechTranscript:
            RuntimeSpeechTranscriptView(
                projectID: projectID,
                node: node,
                session: session,
                audioHost: audioHost,
                speechHost: speechHost,
                onValueChanged: { onEvent(.valueChanged, node) }
            )
        case .divider:
            Divider().padding(.vertical, 4)
        }
    }
}
