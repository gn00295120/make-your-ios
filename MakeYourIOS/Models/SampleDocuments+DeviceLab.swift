import Foundation

extension SampleDocuments {
    static let captureKit = AppDocument(
        name: "Device Lab",
        summary: "Compose private audio, on-device transcripts, camera, scanner, files, and sharing.",
        symbol: "qrcode.viewfinder",
        tint: .amber,
        capabilities: [
            .calendarWrite, .cameraCapture, .clipboardWrite, .codeScanner, .contactPicker,
            .currentLocation, .documentExport, .documentPicker, .haptics, .localStorage,
            .mapSearch, .microphoneRecordLocal, .pedometer, .shareSheet,
            .speechTranscribeOnDevice
        ],
        logic: RuntimeLogic(state: [
            RuntimeStateDefinition(
                key: "quick-transcript",
                type: .text,
                persistence: .project,
                initialValue: ""
            )
        ]),
        theme: .preset(.native),
        pages: [
            AppPage(
                id: "home",
                title: "Device Lab",
                nodes: [
                    mapNode,
                    calendarEventNode,
                    documentExportNode,
                    voiceNoteNode,
                    speechTranscriptNode,
                    ComponentNode(
                        id: "saved-transcript",
                        kind: .text,
                        title: "Saved transcript",
                        value: "Your reviewed transcript will appear here.",
                        valueBinding: "quick-transcript"
                    ),
                    deviceNode(
                        id: "receipt-photo",
                        kind: .cameraPhoto,
                        title: "Receipt camera",
                        subtitle: "Take a photo only when you choose.",
                        symbol: "camera.fill",
                        binding: "receipt-photo",
                        button: "Take receipt photo",
                        result: "Receipt photo"
                    ),
                    deviceNode(
                        id: "qr-scanner",
                        kind: .qrCode,
                        title: "QR scanner",
                        subtitle: "The result is shown as text and never opened automatically.",
                        symbol: "qrcode.viewfinder",
                        binding: "scanned-code",
                        button: "Scan QR code",
                        result: "QR result"
                    ),
                    deviceNode(
                        id: "current-location",
                        kind: .currentLocation,
                        title: "One-time location",
                        subtitle: "Read one coordinate after a tap; no background tracking.",
                        symbol: "location.fill",
                        binding: "current-location",
                        button: "Get current location",
                        result: "Coordinate"
                    ),
                    deviceNode(
                        id: "contact-picker",
                        kind: .contact,
                        title: "Choose a contact",
                        subtitle: "Apple’s picker reveals only the contact you select.",
                        symbol: "person.crop.circle.badge.plus",
                        binding: "chosen-contact",
                        button: "Choose contact",
                        result: "Selected contact"
                    ),
                    deviceNode(
                        id: "document-import",
                        kind: .documentText,
                        title: "Import a text note",
                        subtitle: "Read only a small text file you explicitly choose.",
                        symbol: "doc.badge.plus",
                        binding: "imported-note",
                        button: "Choose text file",
                        result: "Imported text"
                    ),
                    deviceNode(
                        id: "step-counter",
                        kind: .pedometer,
                        title: "Today’s steps",
                        subtitle: "Request a one-time pedometer reading.",
                        symbol: "figure.walk.motion",
                        binding: "today-steps",
                        button: "Read today’s steps",
                        result: "Step count"
                    ),
                    deviceNode(
                        id: "share-message",
                        kind: .shareText,
                        title: "Share with review",
                        subtitle: "The destination is always chosen in Apple’s share sheet.",
                        symbol: "square.and.arrow.up",
                        value: "Made with my tiny app in MakeYour.",
                        binding: "share-result",
                        button: "Open share sheet",
                        result: "Share status"
                    ),
                    deviceNode(
                        id: "copy-message",
                        kind: .copyText,
                        title: "Copy a result",
                        subtitle: "Write configured text to the clipboard after a tap.",
                        symbol: "doc.on.clipboard",
                        value: "Made with MakeYour",
                        binding: "copy-result",
                        button: "Copy text",
                        result: "Clipboard status"
                    ),
                    deviceNode(
                        id: "haptic-confirmation",
                        kind: .haptic,
                        title: "Tactile feedback",
                        subtitle: "Play a local success haptic.",
                        symbol: "waveform",
                        binding: "haptic-result",
                        button: "Play haptic",
                        result: "Haptic status"
                    )
                ],
                presentation: PagePresentation(layout: .flow, showsNavigationTitle: true)
            )
        ]
    )

    private static let mapNode = ComponentNode(
        id: "map-search",
        kind: .map,
        title: "Map and directions",
        subtitle: "Search Apple Maps or open a reviewed route handoff.",
        symbol: "map.fill",
        presentation: ComponentPresentation(
            surface: .plain,
            span: .full,
            alignment: .leading,
            emphasis: .regular,
            variant: .automatic
        ),
        map: RuntimeMapSpec(
            mode: .coordinate,
            query: "Taipei 101",
            latitude: 25.033,
            longitude: 121.5654,
            spanMeters: 3_000,
            allowsSearch: true,
            allowsDirections: true
        )
    )

    private static let calendarEventNode = ComponentNode(
        id: "calendar-event",
        kind: .calendarEvent,
        title: "Calendar write-only",
        subtitle: "Review one event before granting add-only access.",
        symbol: "calendar.badge.plus",
        presentation: ComponentPresentation(
            surface: .outlined,
            span: .full,
            alignment: .leading,
            emphasis: .regular,
            variant: .automatic
        ),
        calendarEvent: RuntimeCalendarEventSpec(
            eventTitle: "Review my tiny app",
            notes: "Created after an explicit review in MakeYour.",
            location: "",
            startOffsetMinutes: 60,
            durationMinutes: 30,
            allowsEditing: true
        )
    )

    private static let documentExportNode = ComponentNode(
        id: "document-export",
        kind: .documentExport,
        title: "Bounded export",
        subtitle: "Preview this text, then choose a destination in Apple's save panel.",
        symbol: "square.and.arrow.up.on.square",
        presentation: ComponentPresentation(
            surface: .outlined,
            span: .full,
            alignment: .leading,
            emphasis: .regular,
            variant: .automatic
        ),
        documentExport: RuntimeDocumentExportSpec(
            fileName: "tiny-app-notes.txt",
            format: .plainText,
            contentTemplate: "A private tiny app made in MakeYour.",
            buttonLabel: "Review and export"
        )
    )

    private static let voiceNoteNode = ComponentNode(
        id: "voice-note",
        kind: .voiceNote,
        title: "Private voice note",
        subtitle: "Record one short thought that stays inside this tiny app.",
        symbol: "mic.fill",
        binding: "quick-voice-note",
        presentation: ComponentPresentation(
            surface: .outlined,
            span: .full,
            alignment: .leading,
            emphasis: .regular,
            variant: .automatic
        ),
        voiceNote: RuntimeVoiceNoteSpec(
            maximumDurationSeconds: 30,
            recordButtonLabel: "Record a voice note"
        )
    )

    private static let speechTranscriptNode = ComponentNode(
        id: "speech-transcript",
        kind: .speechTranscript,
        title: "On-device transcript",
        subtitle: "Review and edit the text before this tiny app saves it.",
        symbol: "text.bubble.fill",
        binding: "quick-transcript",
        presentation: ComponentPresentation(
            surface: .outlined,
            span: .full,
            alignment: .leading,
            emphasis: .regular,
            variant: .automatic
        ),
        speechTranscript: RuntimeSpeechTranscriptSpec(
            sourceBinding: "quick-voice-note",
            localeIdentifier: "",
            buttonLabel: "Review on-device transcript"
        )
    )

    // Keeping the fixture labels explicit makes every generated device affordance reviewable here.
    // swiftlint:disable:next function_parameter_count
    private static func deviceNode(
        id: String,
        kind: DeviceInputKind,
        title: String,
        subtitle: String,
        symbol: String,
        value: String = "",
        binding: String,
        button: String,
        result: String
    ) -> ComponentNode {
        ComponentNode(
            id: id,
            kind: .deviceInput,
            title: title,
            subtitle: subtitle,
            symbol: symbol,
            value: value,
            binding: binding,
            presentation: ComponentPresentation(
                surface: .plain,
                span: .full,
                alignment: .leading,
                emphasis: .regular,
                variant: .automatic
            ),
            deviceInput: DeviceInputSpec(
                kind: kind,
                buttonLabel: button,
                resultLabel: result,
                allowsRepeat: true
            )
        )
    }
}
