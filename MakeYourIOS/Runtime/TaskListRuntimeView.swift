import SwiftUI
import UserNotifications

struct TaskListRuntimeView: View {
    private struct RuntimeTask: Codable, Identifiable, Hashable {
        var id: UUID
        var title: String
        var dueDate: Date
        var isComplete: Bool
    }

    let projectID: UUID
    let node: ComponentNode
    let tint: AppTint

    @Environment(\.runtimeDesign) private var design
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var tasks: [RuntimeTask] = []
    @State private var showingNewTask = false
    @State private var newTitle = ""
    @State private var newDueDate = Date.now.addingTimeInterval(3_600)
    @State private var statusMessage: String?

    private var storageKey: String {
        "runtime.tasks.\(projectID.uuidString).\(node.id)"
    }

    private var variant: ComponentVariant {
        RendererCatalog.normalizedVariant(node.resolvedPresentation.variant, for: .taskList)
    }

    private var contentSpacing: CGFloat {
        [.compact, .dense].contains(variant) ? 8 : design.componentSpacing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: contentSpacing) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(node.title)
                        .font(design.sectionFont)
                        .accessibilityAddTraits(.isHeader)
                    if !node.subtitle.isEmpty {
                        Text(node.subtitle)
                            .font(design.captionFont)
                            .foregroundStyle(design.secondaryForeground)
                    }
                }
                Spacer()
                Button {
                    showingNewTask = true
                } label: {
                    Image(systemName: "plus")
                        .font(.subheadline.bold())
                        .foregroundStyle(design.accent)
                        .frame(width: 44, height: 44)
                        .background(
                            design.accent.opacity(0.12),
                            in: RoundedRectangle(
                                cornerRadius: design.controlCornerRadius,
                                style: .continuous
                            )
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add task")
            }

            if tasks.isEmpty {
                ContentUnavailableView(
                    "All clear",
                    systemImage: "checkmark.circle",
                    description: Text("Add one small thing when you are ready.")
                )
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: variant == .cards ? 9 : 0) {
                    ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                        taskRow(task)
                        if variant != .cards, index < tasks.count - 1 {
                            Divider()
                                .padding(.leading, variant == .timeline ? 25 : 40)
                        }
                    }
                }
            }

            if let statusMessage {
                Label(statusMessage, systemImage: "checkmark.circle.fill")
                    .font(design.captionFont)
                    .foregroundStyle(design.accent)
                    .transition(design.contentTransition)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear(perform: load)
        .sheet(isPresented: $showingNewTask) {
            NavigationStack {
                Form {
                    Section("Task") {
                        TextField("What needs doing?", text: $newTitle)
                        DatePicker("Remind me", selection: $newDueDate, in: Date.now...)
                    }
                    Section {
                        Text(
                            "The task stays inside this mini app. "
                                + "A notification is scheduled only when you tap its bell."
                        )
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("New task")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingNewTask = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { addTask() }
                            .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func taskRow(_ task: RuntimeTask) -> some View {
        HStack(alignment: .center, spacing: variant == .dense ? 8 : 12) {
            completionButton(task)
            taskDetails(task)
            Spacer(minLength: 8)
            reminderButton(task)
        }
        .padding(.vertical, variant == .dense ? 1 : 4)
        .padding(.horizontal, variant == .cards ? 12 : 0)
        .background { taskRowBackground }
        .accessibilityElement(children: .contain)
    }

    private func completionButton(_ task: RuntimeTask) -> some View {
        ZStack {
            if variant == .timeline {
                Capsule()
                    .fill(design.accent.opacity(0.18))
                    .frame(width: 3, height: dynamicTypeSize.isAccessibilitySize ? 60 : 46)
                    .accessibilityHidden(true)
            }
            Button { toggle(task.id) } label: {
                Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isComplete ? design.accent : design.secondaryForeground)
                    .background(design.surface, in: Circle())
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isComplete ? "Mark incomplete" : "Mark complete")
        }
    }

    private func taskDetails(_ task: RuntimeTask) -> some View {
        VStack(alignment: .leading, spacing: variant == .dense ? 0 : 3) {
            Text(task.title)
                .font(.system(
                    .subheadline,
                    design: design.theme.typography.fontDesign,
                    weight: .semibold
                ))
                .strikethrough(task.isComplete)
                .foregroundStyle(
                    task.isComplete ? design.secondaryForeground : design.primaryForeground
                )
            Text(task.dueDate, style: .time)
                .font(design.captionFont)
                .foregroundStyle(design.secondaryForeground)
        }
    }

    private func reminderButton(_ task: RuntimeTask) -> some View {
        Button { scheduleReminder(for: task) } label: {
            Image(systemName: task.isComplete ? "bell.slash" : "bell")
                .foregroundStyle(task.isComplete ? design.secondaryForeground : design.accent)
                .frame(width: 44, height: 44)
                .background(
                    design.accent.opacity(task.isComplete ? 0 : 0.10),
                    in: RoundedRectangle(
                        cornerRadius: design.controlCornerRadius,
                        style: .continuous
                    )
                )
        }
        .buttonStyle(.plain)
        .disabled(task.isComplete)
        .accessibilityLabel("Schedule reminder for \(task.title)")
    }

    @ViewBuilder
    private var taskRowBackground: some View {
        if variant == .cards {
            RoundedRectangle(cornerRadius: design.compactCornerRadius, style: .continuous)
                .fill(design.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: design.compactCornerRadius, style: .continuous)
                        .stroke(
                            design.borderColor.opacity(design.borderOpacity),
                            lineWidth: design.borderWidth
                        )
                }
        }
    }
}

private extension TaskListRuntimeView {
    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([RuntimeTask].self, from: data) {
            tasks = saved
            return
        }

        let calendar = Calendar.current
        tasks = node.items.enumerated().map { index, item in
            RuntimeTask(
                id: UUID(),
                title: item.title,
                dueDate: calendar.date(byAdding: .minute, value: (index + 1) * 60, to: .now) ?? .now,
                isComplete: item.isComplete
            )
        }
        save()
    }

    private func addTask() {
        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        tasks.append(RuntimeTask(id: UUID(), title: title, dueDate: newDueDate, isComplete: false))
        newTitle = ""
        newDueDate = .now.addingTimeInterval(3_600)
        showingNewTask = false
        save()
    }

    private func toggle(_ id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        design.animate { tasks[index].isComplete.toggle() }
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func scheduleReminder(for task: RuntimeTask) {
        Task {
            do {
                let center = UNUserNotificationCenter.current()
                let granted = try await center.requestAuthorization(options: [.alert, .sound])
                guard granted else {
                    await MainActor.run { statusMessage = "Notifications are turned off." }
                    return
                }

                let content = UNMutableNotificationContent()
                content.title = node.title.isEmpty ? "MakeYour reminder" : node.title
                content.body = task.title
                content.sound = .default

                let date = max(task.dueDate, Date.now.addingTimeInterval(5))
                let components = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute, .second],
                    from: date
                )
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "makeyour.\(projectID.uuidString).\(task.id.uuidString)",
                    content: content,
                    trigger: trigger
                )
                try await center.add(request)
                await MainActor.run {
                    design.animate { statusMessage = "Reminder scheduled for \(task.title)." }
                }
            } catch {
                await MainActor.run { statusMessage = error.localizedDescription }
            }
        }
    }
}
