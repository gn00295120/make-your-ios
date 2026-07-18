import SwiftUI
import UserNotifications

struct RecordCollectionRuntimeView: View {
    struct RuntimeRecord: Codable, Hashable, Identifiable {
        var id: UUID
        var title: String
        var note: String
        var numericValue: Double?
        var date: Date?
        var isComplete: Bool
    }

    struct EditorContext: Identifiable {
        var id = UUID()
        var record: RuntimeRecord?
    }

    let projectID: UUID
    let node: ComponentNode
    let tint: AppTint
    let capabilities: [AppCapability]

    @Environment(\.runtimeDesign) var design
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @State var records: [RuntimeRecord] = []
    @State var editorContext: EditorContext?
    @State private var statusMessage: String?

    private let stateStore = ProjectRuntimeStateStore()

    var variant: ComponentVariant {
        RendererCatalog.normalizedVariant(node.resolvedPresentation.variant, for: .recordCollection)
    }

    private var contentSpacing: CGFloat {
        [.compact, .dense].contains(variant) ? 8 : design.componentSpacing
    }

    var spec: RecordCollectionSpec {
        node.collection ?? RecordCollectionSpec(
            itemName: "Item",
            titleLabel: "Name",
            noteLabel: "Notes",
            valueLabel: "Value",
            valueKind: .none,
            valueUnit: "",
            dateLabel: "Date",
            dateKind: .none,
            aggregate: .none,
            allowsCompletion: false,
            allowsReminders: false
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: contentSpacing) {
            header
            aggregateView
            recordsView

            if let statusMessage {
                Label(statusMessage, systemImage: "checkmark.circle.fill")
                    .font(design.captionFont)
                    .foregroundStyle(design.accent)
                    .accessibilityLabel(statusMessage)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear(perform: load)
        .sheet(item: $editorContext) { context in
            RecordEditorView(
                spec: spec,
                existing: context.record.map {
                    RecordDraft(
                        id: $0.id,
                        title: $0.title,
                        note: $0.note,
                        numericValue: $0.numericValue.map { String($0) } ?? "",
                        date: $0.date ?? .now,
                        isComplete: $0.isComplete
                    )
                },
                onSave: saveDraft,
                onDelete: context.record == nil ? nil : { delete(context.record!.id) }
            )
        }
    }

}

extension RecordCollectionRuntimeView {
    private func load() {
        do {
            if let saved = try stateStore.load(
                [RuntimeRecord].self,
                projectID: projectID,
                nodeID: node.id,
                namespace: "records"
            ) {
                records = saved
                return
            }
        } catch {
            statusMessage = "Saved items could not be read."
        }

        records = node.items.enumerated().map { index, item in
            RuntimeRecord(
                id: UUID(),
                title: item.title,
                note: item.subtitle,
                numericValue: Double(item.value),
                date: spec.dateKind == .none
                    ? nil
                    : Calendar.current.date(byAdding: .day, value: (index + 1) * 7, to: .now),
                isComplete: item.isComplete
            )
        }
        persist()
    }

    private func saveDraft(_ draft: RecordDraft) {
        let record = RuntimeRecord(
            id: draft.id,
            title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
            note: draft.note.trimmingCharacters(in: .whitespacesAndNewlines),
            numericValue: spec.valueKind == .none
                ? nil
                : Double(draft.numericValue.replacingOccurrences(of: ",", with: "")),
            date: spec.dateKind == .none ? nil : draft.date,
            isComplete: draft.isComplete
        )
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
        } else {
            records.append(record)
        }
        editorContext = nil
        persist()
    }

    func toggle(_ id: UUID) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        design.animate { records[index].isComplete.toggle() }
        persist()
    }

    private func delete(_ id: UUID) {
        records.removeAll { $0.id == id }
        editorContext = nil
        persist()
    }

    private func persist() {
        do {
            try stateStore.save(
                records,
                projectID: projectID,
                nodeID: node.id,
                namespace: "records"
            )
        } catch {
            statusMessage = "Changes could not be saved."
        }
    }

    func scheduleReminder(for record: RuntimeRecord) {
        guard capabilities.contains(.localNotifications) else {
            statusMessage = "This app has not requested notification access."
            return
        }
        guard let recordDate = record.date else { return }

        Task {
            do {
                let center = UNUserNotificationCenter.current()
                let granted = try await center.requestAuthorization(options: [.alert, .sound])
                guard granted else {
                    statusMessage = "Notifications are turned off."
                    return
                }
                let content = UNMutableNotificationContent()
                content.title = node.title.isEmpty ? "MakeYour reminder" : node.title
                content.body = record.title
                content.sound = .default
                let date = max(recordDate, .now.addingTimeInterval(5))
                let components = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute, .second],
                    from: date
                )
                let request = UNNotificationRequest(
                    identifier: "makeyour.record.\(projectID.uuidString).\(record.id.uuidString)",
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                )
                try await center.add(request)
                statusMessage = "Reminder scheduled for \(record.title)."
            } catch {
                statusMessage = error.localizedDescription
            }
        }
    }
}
