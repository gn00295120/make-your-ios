import SwiftUI
import UserNotifications

struct AppRuntimeView: View {
    let projectID: UUID
    let document: AppDocument

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedPageID: String
    @State private var session: RuntimeSessionState

    init(projectID: UUID, document: AppDocument) {
        self.projectID = projectID
        self.document = document
        _selectedPageID = State(initialValue: document.startPageID)
        _session = State(initialValue: RuntimeSessionState(initialValues: document.initialState))
    }

    private var selectedPage: AppPage {
        document.pages.first(where: { $0.id == selectedPageID }) ?? document.pages[0]
    }

    private var theme: AppVisualTheme {
        document.resolvedTheme
    }

    private var rows: [RuntimeNodeRow] {
        PageLayoutEngine.rows(
            for: selectedPage.nodes,
            layout: selectedPage.resolvedPresentation.layout,
            collapseColumns: dynamicTypeSize.isAccessibilitySize
        )
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: theme.componentSpacing) {
                if document.pages.count > 1 {
                    Picker("Page", selection: $selectedPageID) {
                        ForEach(document.pages) { page in
                            Text(page.title).tag(page.id)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.bottom, 2)
                }

                ForEach(rows) { row in
                    HStack(alignment: .top, spacing: theme.componentSpacing) {
                        ForEach(row.nodes) { node in
                            ComponentRenderer(
                                projectID: projectID,
                                node: node,
                                tint: document.tint,
                                theme: theme,
                                capabilities: document.capabilities,
                                session: session,
                                onNavigate: { target in
                                    guard document.pages.contains(where: { $0.id == target }) else { return }
                                    withAnimation(.snappy) { selectedPageID = target }
                                }
                            )
                            .frame(maxWidth: .infinity, alignment: .top)
                        }
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("Made in MakeYour")
                }
                .font(.caption2.weight(.medium))
                .foregroundStyle(.tertiary)
                .padding(.top, 12)
            }
            .padding(16)
        }
        .background {
            RuntimeCanvasBackground(theme: theme, tint: document.tint)
                .ignoresSafeArea()
        }
        .navigationTitle(selectedPage.resolvedPresentation.showsNavigationTitle ? selectedPage.title : "")
        .navigationBarTitleDisplayMode(.inline)
        .tint(document.tint.color)
        .fontDesign(theme.typography.fontDesign)
        .preferredColorScheme(theme.appearance.colorScheme)
        .alert(
            "MakeYour",
            isPresented: Binding(
                get: { session.alertMessage != nil },
                set: { if !$0 { session.alertMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { session.alertMessage = nil }
        } message: {
            Text(session.alertMessage ?? "")
        }
    }
}

private struct ComponentRenderer: View {
    let projectID: UUID
    let node: ComponentNode
    let tint: AppTint
    let theme: AppVisualTheme
    let capabilities: [AppCapability]
    @Bindable var session: RuntimeSessionState
    let onNavigate: (String) -> Void

    var body: some View {
        content
            .runtimeNodeSurface(node: node, theme: theme, tint: tint)
    }

    @ViewBuilder
    private var content: some View {
        switch node.kind {
        case .hero:
            HeroNodeView(node: node, tint: tint, theme: theme)
        case .sectionHeader:
            VStack(alignment: .leading, spacing: 4) {
                Text(node.title).font(.title3.bold())
                if !node.subtitle.isEmpty {
                    Text(node.subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)
        case .text:
            Text(node.title.isEmpty ? node.value : node.title)
                .font(.body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(node.resolvedPresentation.alignment.textAlignment)
                .frame(
                    maxWidth: .infinity,
                    alignment: node.resolvedPresentation.alignment.frameAlignment
                )
        case .metric:
            MetricNodeView(node: node, tint: tint)
        case .textInput, .numberInput:
            InputNodeView(node: node, tint: tint, session: session)
        case .picker:
            PickerNodeView(node: node, tint: tint, session: session)
        case .button:
            Button {
                perform(node.action)
            } label: {
                Label(node.title, systemImage: node.symbol.isEmpty ? "arrow.right" : node.symbol)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(tint.color)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        case .checklist:
            ChecklistNodeView(node: node, tint: tint, session: session)
        case .infoBanner:
            InfoBannerNodeView(node: node, tint: tint)
        case .currencyConverter:
            CurrencyConverterRuntimeView(node: node, tint: tint)
        case .taskList:
            TaskListRuntimeView(projectID: projectID, node: node, tint: tint)
        case .image:
            ImageNodeView(projectID: projectID, node: node, tint: tint, theme: theme)
        case .aiAssistant:
            AITextRuntimeView(node: node, tint: tint)
        case .recordCollection:
            RecordCollectionRuntimeView(
                projectID: projectID,
                node: node,
                tint: tint,
                capabilities: capabilities
            )
        case .liveDataList:
            LiveDataListRuntimeView(projectID: projectID, node: node, tint: tint)
        case .divider:
            Divider().padding(.vertical, 4)
        }
    }

    private func perform(_ action: RuntimeAction) {
        switch action.type {
        case .none:
            break
        case .navigate:
            onNavigate(action.target)
        case .setValue:
            session.set(action.value, for: action.target)
        case .showMessage:
            session.alertMessage = action.value
        case .scheduleNotification:
            guard capabilities.contains(.localNotifications) else {
                session.alertMessage = "This app has not requested notification access."
                return
            }
            Task { await scheduleNotification(action) }
        }
    }

    private func scheduleNotification(_ action: RuntimeAction) async {
        do {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            guard granted else {
                session.alertMessage = "Notifications are turned off."
                return
            }

            let minutes = max(1, min(Int(action.target) ?? 60, 10_080))
            let content = UNMutableNotificationContent()
            content.title = node.title.isEmpty ? "MakeYour reminder" : node.title
            content.body = action.value.isEmpty ? "A reminder from your mini app." : action.value
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "makeyour.action.\(projectID.uuidString).\(node.id)",
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(
                    timeInterval: TimeInterval(minutes * 60),
                    repeats: false
                )
            )
            try await center.add(request)
            session.alertMessage = "Reminder scheduled for \(minutes) minutes from now."
        } catch {
            session.alertMessage = error.localizedDescription
        }
    }
}
