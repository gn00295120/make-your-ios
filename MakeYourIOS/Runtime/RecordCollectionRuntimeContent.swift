import SwiftUI

extension RecordCollectionRuntimeView {
    var header: some View {
        HStack(alignment: .top, spacing: 12) {
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
                editorContext = EditorContext(record: nil)
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
            .accessibilityLabel("Add \(spec.itemName)")
        }
    }

    @ViewBuilder
    var aggregateView: some View {
        switch spec.aggregate {
        case .none:
            EmptyView()
        case .count:
            aggregateSurface(
                label: "Total \(spec.itemName.lowercased())s",
                value: records.count.formatted()
            )
        case .sum:
            aggregateSurface(
                label: spec.valueLabel.isEmpty ? "Total" : "Total \(spec.valueLabel.lowercased())",
                value: formattedValue(records.compactMap(\.numericValue).reduce(0, +))
            )
        }
    }

    @ViewBuilder
    var recordsView: some View {
        if records.isEmpty {
            ContentUnavailableView(
                "No \(spec.itemName.lowercased())s yet",
                systemImage: "tray",
                description: Text("Tap Add to create your first one.")
            )
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: variant == .cards ? 9 : 0) {
                ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                    recordRow(record)
                    if variant != .cards, index < records.count - 1 {
                        Divider().padding(.leading, spec.allowsCompletion ? 42 : 0)
                    }
                }
            }
        }
    }

    private func aggregateSurface(label: String, value: String) -> some View {
        LabeledContent(label) {
            Text(value)
                .font(design.titleFont.monospacedDigit())
                .foregroundStyle(design.accent)
        }
        .padding(.horizontal, variant == .compact ? 10 : 14)
        .padding(.vertical, variant == .compact ? 8 : 11)
        .background(
            design.accent.opacity(0.09),
            in: RoundedRectangle(
                cornerRadius: design.compactCornerRadius,
                style: .continuous
            )
        )
    }

    private func recordRow(_ record: RuntimeRecord) -> some View {
        HStack(alignment: .center, spacing: 10) {
            completionButton(record)
            recordEditorButton(record)
            reminderButton(record)
        }
        .padding(.vertical, variant == .dense ? 1 : 5)
        .padding(.horizontal, variant == .cards ? 12 : 0)
        .background { recordRowBackground }
    }

    @ViewBuilder
    private func completionButton(_ record: RuntimeRecord) -> some View {
        if spec.allowsCompletion {
            Button { toggle(record.id) } label: {
                Image(systemName: record.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(
                        record.isComplete ? design.accent : design.secondaryForeground
                    )
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                record.isComplete
                    ? "Mark \(record.title) incomplete"
                    : "Mark \(record.title) complete"
            )
        }
    }

    private func recordEditorButton(_ record: RuntimeRecord) -> some View {
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
    }

    @ViewBuilder
    private func reminderButton(_ record: RuntimeRecord) -> some View {
        if spec.allowsReminders {
            Button { scheduleReminder(for: record) } label: {
                Image(systemName: "bell")
                    .foregroundStyle(design.accent)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .disabled(record.date == nil)
            .accessibilityLabel("Schedule reminder for \(record.title)")
        }
    }

    @ViewBuilder
    private var recordRowBackground: some View {
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

    private func recordDetails(_ record: RuntimeRecord) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(record.title)
                .font(.system(
                    .subheadline,
                    design: design.theme.typography.fontDesign,
                    weight: .semibold
                ))
                .strikethrough(record.isComplete)
                .foregroundStyle(
                    record.isComplete ? design.secondaryForeground : design.primaryForeground
                )
                .multilineTextAlignment(.leading)
            if !record.note.isEmpty {
                Text(record.note)
                    .font(design.captionFont)
                    .foregroundStyle(design.secondaryForeground)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    private func recordMetadata(_ record: RuntimeRecord) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            if let value = record.numericValue, spec.valueKind != .none {
                Text(formattedValue(value))
                    .font(.system(
                        .subheadline,
                        design: design.theme.typography.fontDesign,
                        weight: .semibold
                    ).monospacedDigit())
                    .foregroundStyle(design.accent)
            }
            if let date = record.date, spec.dateKind != .none {
                Text(formattedDate(date))
                    .font(design.captionFont)
                    .foregroundStyle(design.secondaryForeground)
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
