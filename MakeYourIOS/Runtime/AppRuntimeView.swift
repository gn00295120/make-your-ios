import SwiftUI
import UIKit
import UserNotifications

// swiftlint:disable:next type_body_length
struct AppRuntimeView: View {
    let projectID: UUID
    let document: AppDocument

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @State private var selectedPageID: String
    @State private var session: RuntimeSessionState
    private let logicEngine: RuntimeLogicEngine

    init(projectID: UUID, document: AppDocument) {
        self.projectID = projectID
        self.document = document
        let logicEngine = RuntimeLogicEngine(logic: document.logic)
        self.logicEngine = logicEngine
        let initialValues = document.initialState.merging(logicEngine.initialValues) { _, logicValue in
            logicValue
        }
        _selectedPageID = State(initialValue: document.startPageID)
        _session = State(initialValue: RuntimeSessionState(
            initialValues: initialValues,
            projectID: projectID,
            persistentKeys: logicEngine.persistentKeys
        ))
    }

    private var selectedPage: AppPage {
        document.pages.first(where: { $0.id == selectedPageID }) ?? document.pages[0]
    }

    private var theme: AppVisualTheme {
        document.resolvedTheme
    }

    private var design: RuntimeDesignContext {
        RuntimeDesignContext(
            theme: theme,
            tint: document.tint,
            colorScheme: colorScheme,
            reduceMotion: reduceMotion,
            reduceTransparency: reduceTransparency,
            increasedContrast: colorSchemeContrast == .increased,
            differentiateWithoutColor: differentiateWithoutColor
        )
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
            VStack(spacing: design.componentSpacing) {
                if document.pages.count > 1 {
                    pageNavigation
                }

                RuntimePageRenderer(page: selectedPage, rows: rows, design: design) { node in
                    ComponentRenderer(
                        projectID: projectID,
                        node: node,
                        tint: document.tint,
                        theme: theme,
                        capabilities: document.capabilities,
                        session: session,
                        onEvent: perform,
                        onLegacyAction: performLegacy
                    )
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
            RuntimeMediaBackground(projectID: projectID, theme: theme, tint: document.tint)
                .environment(\.runtimeDesign, design)
                .ignoresSafeArea()
        }
        .environment(\.runtimeDesign, design)
        .navigationTitle(selectedPage.resolvedPresentation.showsNavigationTitle ? selectedPage.title : "")
        .navigationBarTitleDisplayMode(.inline)
        .tint(design.accent)
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

    @ViewBuilder
    private var pageNavigation: some View {
        switch resolvedNavigationStyle {
        case .automatic, .segmented:
            Picker("Page", selection: $selectedPageID) {
                ForEach(document.pages) { page in
                    Text(page.title).tag(page.id)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Tiny app page")
        case .chips:
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(document.pages) { page in
                        let isSelected = page.id == selectedPageID
                        Button(page.title) { selectPage(page.id) }
                            .font(design.captionFont.weight(.semibold))
                            .foregroundStyle(isSelected ? design.onAccent : design.accent)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 9)
                            .background(
                                isSelected ? design.accent : design.accent.opacity(0.10),
                                in: Capsule()
                            )
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
            }
            .accessibilityLabel("Tiny app pages")
        case .menu:
            Menu {
                ForEach(document.pages) { page in
                    Button {
                        selectPage(page.id)
                    } label: {
                        if page.id == selectedPageID {
                            Label(page.title, systemImage: "checkmark")
                        } else {
                            Text(page.title)
                        }
                    }
                }
            } label: {
                Label(selectedPage.title, systemImage: "rectangle.stack.fill")
                    .font(design.captionFont.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 10)
                    .background(design.surface, in: RoundedRectangle(
                        cornerRadius: design.controlCornerRadius,
                        style: .continuous
                    ))
            }
            .accessibilityLabel("Current page, \(selectedPage.title)")
        }
    }

    private var resolvedNavigationStyle: PageNavigationStyle {
        let requested = selectedPage.resolvedPresentation.resolvedNavigationStyle
        guard requested == .automatic else { return requested }
        return document.pages.count <= 3 ? .segmented : .menu
    }

    private func selectPage(_ target: String) {
        guard document.pages.contains(where: { $0.id == target }) else { return }
        design.animate {
            selectedPageID = target
        }
    }

    private func perform(_ trigger: RuntimeEventTrigger, source node: ComponentNode) {
        let matchingEvents = (node.events ?? []).filter { $0.trigger == trigger }
        guard !matchingEvents.isEmpty else { return }
        let event = RuntimeEvent(
            trigger: trigger,
            steps: matchingEvents.flatMap(\.steps)
        )

        do {
            let execution = try logicEngine.execute(event: event, values: session.values)
            try session.commit(execution.values)
            perform(execution.effects, source: node)
        } catch {
            session.alertMessage = error.localizedDescription
        }
    }

    private func performLegacy(_ action: RuntimeAction, source node: ComponentNode) {
        switch action.type {
        case .none:
            break
        case .navigate:
            selectPage(action.target)
        case .setValue:
            session.set(action.value, for: action.target)
        case .showMessage:
            session.alertMessage = session.resolveTemplate(action.value)
        case .scheduleNotification:
            guard document.capabilities.contains(.localNotifications) else {
                session.alertMessage = "This app has not requested notification access."
                return
            }
            let minutes = max(1, min(Int(action.target) ?? 60, 10_080))
            Task {
                await scheduleNotification(
                    delayMinutes: minutes,
                    message: session.resolveTemplate(action.value),
                    source: node
                )
            }
        }
    }

    private func perform(_ effects: [RuntimeLogicEffect], source node: ComponentNode) {
        for effect in effects {
            switch effect {
            case .navigate(let pageID):
                selectPage(pageID)
            case .message(let message):
                session.alertMessage = session.resolveTemplate(message)
            case .notification(let delayMinutes, let message):
                guard document.capabilities.contains(.localNotifications) else {
                    session.alertMessage = "This app has not requested notification access."
                    continue
                }
                Task {
                    await scheduleNotification(
                        delayMinutes: delayMinutes,
                        message: session.resolveTemplate(message),
                        source: node
                    )
                }
            case .haptic:
                guard document.capabilities.contains(.haptics) else {
                    session.alertMessage = "This app has not requested haptic access."
                    continue
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    private func scheduleNotification(
        delayMinutes: Int,
        message: String,
        source node: ComponentNode
    ) async {
        do {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            guard granted else {
                session.alertMessage = "Notifications are turned off."
                return
            }

            let content = UNMutableNotificationContent()
            let title = session.resolveTemplate(node.title)
            content.title = title.isEmpty ? "MakeYour reminder" : title
            content.body = message.isEmpty ? "A reminder from your mini app." : message
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "makeyour.action.\(projectID.uuidString).\(node.id)",
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(
                    timeInterval: TimeInterval(delayMinutes * 60),
                    repeats: false
                )
            )
            try await center.add(request)
            session.alertMessage = "Reminder scheduled for \(delayMinutes) minutes from now."
        } catch {
            session.alertMessage = error.localizedDescription
        }
    }
}

struct ComponentRenderer: View {
    let projectID: UUID
    let node: ComponentNode
    let tint: AppTint
    let theme: AppVisualTheme
    let capabilities: [AppCapability]
    @Bindable var session: RuntimeSessionState
    let onEvent: (RuntimeEventTrigger, ComponentNode) -> Void
    let onLegacyAction: (RuntimeAction, ComponentNode) -> Void

    var body: some View {
        content
            .runtimeNodeSurface(node: node, theme: theme, tint: tint)
    }

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
        case .divider:
            Divider().padding(.vertical, 4)
        }
    }
}
