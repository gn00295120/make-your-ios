import SwiftUI
import UserNotifications

struct RecordCollectionRuntimeView: View {
    private struct RuntimeRecord: Codable, Hashable, Identifiable {
        var id: UUID
        var title: String
        var note: String
        var numericValue: Double?
        var date: Date?
        var isComplete: Bool
    }

    private struct EditorContext: Identifiable {
        var id = UUID()
        var record: RuntimeRecord?
    }

    let projectID: UUID
    let node: ComponentNode
    let tint: AppTint
    let capabilities: [AppCapability]

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var records: [RuntimeRecord] = []
    @State private var editorContext: EditorContext?
    @State private var statusMessage: String?

    private let stateStore = ProjectRuntimeStateStore()

    private var spec: RecordCollectionSpec {
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
        VStack(alignment: .leading, spacing: 14) {
            header
            aggregateView
            recordsView

            if let statusMessage {
                Label(statusMessage, systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(tint.color)
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

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(node.title).font(.headline)
                if !node.subtitle.isEmpty {
                    Text(node.subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                editorContext = EditorContext(record: nil)
            } label: {
                Image(systemName: "plus")
                    .font(.subheadline.bold())
                    .frame(width: 44, height: 44)
                    .background(tint.color.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add \(spec.itemName)")
        }
    }

    @ViewBuilder
    private var aggregateView: some View {
        switch spec.aggregate {
        case .none:
            EmptyView()
        case .count:
            LabeledContent("Total \(spec.itemName.lowercased())s") {
                Text(records.count, format: .number)
                    .font(.headline.monospacedDigit())
            }
        case .sum:
            LabeledContent(spec.valueLabel.isEmpty ? "Total" : "Total \(spec.valueLabel.lowercased())") {
                Text(formattedValue(records.compactMap(\.numericValue).reduce(0, +)))
                    .font(.headline.monospacedDigit())
            }
        }
    }

    @ViewBuilder
    private var recordsView: some View {
        if records.isEmpty {
            ContentUnavailableView(
                "No \(spec.itemName.lowercased())s yet",
                systemImage: "tray",
                description: Text("Tap Add to create your first one.")
            )
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                    recordRow(record)
                    if index < records.count - 1 { Divider().padding(.leading, 42) }
                }
            }
        }
    }

    private func recordRow(_ record: RuntimeRecord) -> some View {
        HStack(alignment: .center, spacing: 10) {
            if spec.allowsCompletion {
                Button { toggle(record.id) } label: {
                    Image(systemName: record.isComplete ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(record.isComplete ? tint.color : Color.secondary)
                        .frame(width: 32, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    record.isComplete
                        ? "Mark \(record.title) incomplete"
                        : "Mark \(record.title) complete"
                )
            }

            Button {
                editorContext = EditorContext(record: record)
            } label: {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: 12) {
                        recordDetails(record)
                        Spacer(minLength: 8)
                        recordMetadata(record)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        recordDetails(record)
                        recordMetadata(record)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(recordAccessibilityLabel(record))

            if spec.allowsReminders {
                Button { scheduleReminder(for: record) } label: {
                    Image(systemName: "bell")
                        .foregroundStyle(tint.color)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .disabled(record.date == nil)
                .accessibilityLabel("Schedule reminder for \(record.title)")
            }
        }
        .padding(.vertical, 5)
    }

    private func recordDetails(_ record: RuntimeRecord) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(record.title)
                .font(.subheadline.weight(.semibold))
                .strikethrough(record.isComplete)
                .foregroundStyle(record.isComplete ? .secondary : .primary)
                .multilineTextAlignment(.leading)
            if !record.note.isEmpty {
                Text(record.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    private func recordMetadata(_ record: RuntimeRecord) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            if let value = record.numericValue, spec.valueKind != .none {
                Text(formattedValue(value))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
            }
            if let date = record.date, spec.dateKind != .none {
                Text(formattedDate(date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formattedValue(_ value: Double) -> String {
        switch spec.valueKind {
        case .currency:
            value.formatted(.currency(code: spec.valueUnit.isEmpty ? "USD" : spec.valueUnit))
        case .number:
            value.formatted(.number.precision(.fractionLength(0...2)))
                + (spec.valueUnit.isEmpty ? "" : " \(spec.valueUnit)")
        case .none:
            ""
        }
    }

    private func formattedDate(_ date: Date) -> String {
        switch spec.dateKind {
        case .date: date.formatted(date: .abbreviated, time: .omitted)
        case .dateTime: date.formatted(date: .abbreviated, time: .shortened)
        case .none: ""
        }
    }

    private func recordAccessibilityLabel(_ record: RuntimeRecord) -> String {
        [
            record.title,
            record.note,
            record.numericValue.map(formattedValue),
            record.date.map(formattedDate),
            record.isComplete ? "Completed" : nil
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        .joined(separator: ", ")
    }
}

private extension RecordCollectionRuntimeView {
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

    private func toggle(_ id: UUID) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        records[index].isComplete.toggle()
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

    private func scheduleReminder(for record: RuntimeRecord) {
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
