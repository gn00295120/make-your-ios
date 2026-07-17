import SwiftUI

struct AIRequestConfirmationView: View {
    let task: String
    let input: String
    let onCancel: () -> Void
    let onSend: () -> Void

    @State private var acknowledged: Bool

    init(
        task: String,
        input: String,
        initiallyAcknowledged: Bool,
        onCancel: @escaping () -> Void,
        onSend: @escaping () -> Void
    ) {
        self.task = task
        self.input = input
        self.onCancel = onCancel
        self.onSend = onSend
        _acknowledged = State(initialValue: initiallyAcknowledged)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Label("Send this text to OpenAI?", systemImage: "paperplane.fill")
                        .font(.title2.bold())

                    reviewCard(title: "Mini-app task", value: resolvedTask)
                    reviewCard(title: "Text being sent", value: input)

                    Label(
                        "No photos, other fields, tasks, or other apps are included.",
                        systemImage: "lock.fill"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                    Toggle(
                        "I understand this text will be processed by OpenAI",
                        isOn: $acknowledged
                    )
                    .font(.footnote.weight(.medium))
                }
                .padding(20)
            }
            .navigationTitle("Review AI request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send", action: onSend)
                        .disabled(!acknowledged)
                }
            }
        }
    }

    private var resolvedTask: String {
        task.isEmpty ? "Respond helpfully to the text." : task
    }

    private func reviewCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(value)
                .textSelection(.enabled)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 14))
    }
}
