import EventKit
import SwiftUI

struct RuntimeCalendarEventView: View {
    let node: ComponentNode
    @Bindable var session: RuntimeSessionState

    @Environment(\.runtimeDesign) private var design
    @State private var isReviewPresented = false
    @State private var isSaving = false
    @State private var eventTitle = ""
    @State private var eventNotes = ""
    @State private var eventLocation = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3_600)
    @State private var saveError: String?

    private var spec: RuntimeCalendarEventSpec {
        node.calendarEvent ?? RuntimeCalendarEventSpec(
            eventTitle: node.title.isEmpty ? "New event" : node.title,
            notes: "",
            location: "",
            startOffsetMinutes: 0,
            durationMinutes: 60,
            allowsEditing: true
        )
    }

    private var proposedStartDate: Date {
        Calendar.current.date(
            byAdding: .minute,
            value: spec.startOffsetMinutes,
            to: .now
        ) ?? .now
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Label(node.title, systemImage: node.symbol.isEmpty ? "calendar.badge.plus" : node.symbol)
                    .font(design.bodyFont.weight(.semibold))
                if !node.subtitle.isEmpty {
                    Text(session.resolveTemplate(node.subtitle))
                        .font(design.captionFont)
                        .foregroundStyle(design.secondaryForeground)
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(session.resolveTemplate(spec.eventTitle))
                    .font(design.bodyFont.weight(.medium))
                Text(proposedStartDate.formatted(date: .abbreviated, time: .shortened))
                    .font(design.captionFont)
                    .foregroundStyle(design.secondaryForeground)
                if !spec.location.isEmpty {
                    Label(session.resolveTemplate(spec.location), systemImage: "mappin.and.ellipse")
                        .font(design.captionFont)
                        .foregroundStyle(design.secondaryForeground)
                }
            }
            .accessibilityElement(children: .combine)

            Button {
                prepareReview()
                isReviewPresented = true
            } label: {
                Label("Review calendar event", systemImage: "calendar.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .frame(minHeight: 44)
            .accessibilityIdentifier("runtime.calendar.\(node.id).review")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $isReviewPresented) {
            reviewSheet
                .presentationDetents([.medium, .large])
        }
        .accessibilityIdentifier("runtime.node.\(node.id)")
    }

    private var reviewSheet: some View {
        NavigationStack {
            Form {
                Section("Event") {
                    if spec.allowsEditing {
                        TextField("Title", text: $eventTitle)
                        TextField("Location", text: $eventLocation)
                        TextField("Notes", text: $eventNotes, axis: .vertical)
                            .lineLimit(2...5)
                    } else {
                        LabeledContent("Title", value: eventTitle)
                        if !eventLocation.isEmpty {
                            LabeledContent("Location", value: eventLocation)
                        }
                        if !eventNotes.isEmpty {
                            LabeledContent("Notes", value: eventNotes)
                        }
                    }
                }

                Section("Time") {
                    if spec.allowsEditing {
                        DatePicker("Starts", selection: $startDate)
                        DatePicker(
                            "Ends",
                            selection: $endDate,
                            in: startDate.addingTimeInterval(300)...
                        )
                    } else {
                        LabeledContent(
                            "Starts",
                            value: startDate.formatted(date: .abbreviated, time: .shortened)
                        )
                        LabeledContent(
                            "Ends",
                            value: endDate.formatted(date: .abbreviated, time: .shortened)
                        )
                    }
                }

                Section {
                    Label(
                        "MakeYour can add this single event, but cannot read your existing calendar.",
                        systemImage: "hand.raised.fill"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                if let saveError {
                    Section {
                        Label(saveError, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Review event")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(isSaving)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isReviewPresented = false }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await saveEvent() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Add Event")
                        }
                    }
                    .disabled(
                        isSaving
                            || eventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || endDate.timeIntervalSince(startDate) < 300
                    )
                    .accessibilityIdentifier("runtime.calendar.\(node.id).save")
                }
            }
        }
    }

    private func prepareReview() {
        let start = proposedStartDate
        eventTitle = session.resolveTemplate(spec.eventTitle)
        eventNotes = session.resolveTemplate(spec.notes)
        eventLocation = session.resolveTemplate(spec.location)
        startDate = start
        endDate = start.addingTimeInterval(TimeInterval(spec.durationMinutes * 60))
        saveError = nil
    }

    @MainActor
    private func saveEvent() async {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            let store = EKEventStore()
            guard try await store.requestWriteOnlyAccessToEvents() else {
                throw RuntimeCalendarError.accessDenied
            }
            guard let calendar = store.defaultCalendarForNewEvents else {
                throw RuntimeCalendarError.noWritableCalendar
            }

            let event = EKEvent(eventStore: store)
            event.title = String(eventTitle.prefix(120))
            event.notes = String(eventNotes.prefix(500))
            event.location = String(eventLocation.prefix(160))
            event.startDate = startDate
            event.endDate = endDate
            event.calendar = calendar
            try store.save(event, span: .thisEvent, commit: true)

            isReviewPresented = false
            session.alertMessage = "Event added to Calendar."
        } catch RuntimeCalendarError.accessDenied {
            saveError = "Calendar write access was not granted. You can change it in Settings."
        } catch RuntimeCalendarError.noWritableCalendar {
            saveError = "No writable calendar is available on this device."
        } catch {
            saveError = "The event could not be added. Please try again."
        }
    }
}

private enum RuntimeCalendarError: Error {
    case accessDenied
    case noWritableCalendar
}
