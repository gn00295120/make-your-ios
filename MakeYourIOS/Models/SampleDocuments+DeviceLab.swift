import Foundation

extension SampleDocuments {
    static let captureKit = AppDocument(
        name: "Device Lab",
        summary: "Compose private camera, scanner, location, files, contacts, motion, sharing, and haptics.",
        symbol: "qrcode.viewfinder",
        tint: .amber,
        capabilities: [
            .cameraCapture, .clipboardWrite, .codeScanner, .contactPicker, .currentLocation,
            .documentPicker, .haptics, .localStorage, .pedometer, .shareSheet
        ],
        theme: .preset(.native),
        pages: [
            AppPage(
                id: "home",
                title: "Device Lab",
                nodes: [
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
