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

    @State private var tasks: [RuntimeTask] = []
    @State private var showingNewTask = false
    @State private var newTitle = ""
    @State private var newDueDate = Date.now.addingTimeInterval(3_600)
    @State private var statusMessage: String?

    private var storageKey: String {
        "runtime.tasks.\(projectID.uuidString).\(node.id)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(node.title).font(.headline)
                    if !node.subtitle.isEmpty {
                        Text(node.subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button {
                    showingNewTask = true
                } label: {
                    Image(systemName: "plus")
                        .font(.subheadline.bold())
                        .frame(width: 34, height: 34)
                        .background(tint.color.opacity(0.12), in: Circle())
                }
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
                ForEach(tasks) { task in
                    HStack(spacing: 12) {
                        Button {
                            toggle(task.id)
                        } label: {
                            Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(task.isComplete ? tint.color : Color.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(task.isComplete ? "Mark incomplete" : "Mark complete")

                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.subheadline.weight(.medium))
                                .strikethrough(task.isComplete)
                                .foregroundStyle(task.isComplete ? .secondary : .primary)
                            Text(task.dueDate, style: .time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            scheduleReminder(for: task)
                        } label: {
                            Image(systemName: "bell")
                                .foregroundStyle(tint.color)
                                .frame(width: 32, height: 32)
                                .background(tint.color.opacity(0.10), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .disabled(task.isComplete)
                        .accessibilityLabel("Schedule reminder for \(task.title)")
                    }
                    .padding(.vertical, 3)
                }
            }

            if let statusMessage {
                Label(statusMessage, systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(tint.color)
                    .transition(.opacity.combined(with: .move(edge: .top)))
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
        tasks[index].isComplete.toggle()
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
                    withAnimation(.easeInOut) { statusMessage = "Reminder scheduled for \(task.title)." }
                }
            } catch {
                await MainActor.run { statusMessage = error.localizedDescription }
            }
        }
    }
}
