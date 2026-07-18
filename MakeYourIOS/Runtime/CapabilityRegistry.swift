import Foundation

enum CapabilityCategory: String, CaseIterable, Sendable {
    case data
    case computation
    case notifications
    case media
    case deviceInput
    case network
    case intelligence
    case location
    case people
    case files
    case motion
    case sharing
    case systemFeedback
    case calendar
}

enum CapabilityPrivacyRisk: String, CaseIterable, Comparable, Sendable {
    case low
    case moderate
    case high

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rank < rhs.rank
    }

    private var rank: Int {
        switch self {
        case .low: 0
        case .moderate: 1
        case .high: 2
        }
    }
}

enum CapabilityAvailabilityMode: String, CaseIterable, Sendable {
    /// Runs entirely through a bounded implementation inside the host app.
    case hostLocal

    /// The host presents an Apple-controlled or otherwise reviewable system surface.
    case systemMediated

    /// iOS authorization must be granted before the host can perform the operation.
    case permissionGated

    /// The host only connects through compiled, reviewed provider adapters.
    case fixedProvider

    /// The host requires a user-owned credential before contacting the service.
    case credentialGated
}

struct CapabilityMetadata: Equatable, Sendable {
    let capability: AppCapability
    let category: CapabilityCategory
    let privacyRisk: CapabilityPrivacyRisk
    let availability: CapabilityAvailabilityMode
    let requiresExplicitUserAction: Bool
    let hostEnforcedSummary: String
    let frameworkOrPermissionNote: String?
}

/// The source of truth for what the host runtime actually implements.
///
/// Keep `metadata(for:)` exhaustive. Adding an `AppCapability` then produces a compiler
/// error here until its security and availability contract has been reviewed.
enum CapabilityRegistry {
    static let orderedMetadata: [CapabilityMetadata] = AppCapability.allCases.map {
        metadata(for: $0)
    }

    // Intentionally exhaustive so every newly declared capability requires a reviewed contract.
    // swiftlint:disable:next cyclomatic_complexity
    static func metadata(for capability: AppCapability) -> CapabilityMetadata {
        switch capability {
        case .localStorage: localStorage
        case .safeCalculation: safeCalculation
        case .localNotifications: localNotifications
        case .photoPicker: photoPicker
        case .cameraCapture: cameraCapture
        case .codeScanner: codeScanner
        case .currentLocation: currentLocation
        case .contactPicker: contactPicker
        case .documentPicker: documentPicker
        case .documentExport: documentExport
        case .mapSearch: mapSearch
        case .calendarWrite: calendarWrite
        case .pedometer: pedometer
        case .shareSheet: shareSheet
        case .clipboardWrite: clipboardWrite
        case .haptics: haptics
        case .network: network
        case .aiRequests: aiRequests
        }
    }

    static func metadata(forRawValue rawValue: String) -> CapabilityMetadata? {
        guard let capability = AppCapability(rawValue: rawValue) else { return nil }
        return metadata(for: capability)
    }

    private static let localStorage = CapabilityMetadata(
        capability: .localStorage,
        category: .data,
        privacyRisk: .moderate,
        availability: .hostLocal,
        requiresExplicitUserAction: false,
        hostEnforcedSummary: "Persists only validated state and assets in the host sandbox; "
            + "it cannot browse files or another tiny app's data.",
        frameworkOrPermissionNote: "Foundation and the app container; no iOS permission prompt."
    )

    private static let safeCalculation = CapabilityMetadata(
        capability: .safeCalculation,
        category: .computation,
        privacyRisk: .low,
        availability: .hostLocal,
        requiresExplicitUserAction: false,
        hostEnforcedSummary: "Evaluates only host-defined calculations; generated tiny apps cannot execute "
            + "Swift, scripts, native code, or arbitrary expressions.",
        frameworkOrPermissionNote: nil
    )

    private static let localNotifications = CapabilityMetadata(
        capability: .localNotifications,
        category: .notifications,
        privacyRisk: .moderate,
        availability: .permissionGated,
        requiresExplicitUserAction: true,
        hostEnforcedSummary: "Schedules bounded local reminders after user review; "
            + "remote push and silent background delivery are unavailable.",
        frameworkOrPermissionNote: "UserNotifications; authorization is requested at use time."
    )

    private static let photoPicker = CapabilityMetadata(
        capability: .photoPicker,
        category: .media,
        privacyRisk: .high,
        availability: .systemMediated,
        requiresExplicitUserAction: true,
        hostEnforcedSummary: "Imports only items the user explicitly chooses in the system photo picker; "
            + "the tiny app cannot enumerate the photo library.",
        frameworkOrPermissionNote: "PhotosUI system picker; broad photo-library access is not requested."
    )

    private static let cameraCapture = CapabilityMetadata(
        capability: .cameraCapture,
        category: .deviceInput,
        privacyRisk: .high,
        availability: .permissionGated,
        requiresExplicitUserAction: true,
        hostEnforcedSummary: "Presents a foreground capture surface only after a user gesture; "
            + "background or hidden capture is unavailable.",
        frameworkOrPermissionNote: "AVFoundation/UIKit camera with NSCameraUsageDescription."
    )

    private static let codeScanner = CapabilityMetadata(
        capability: .codeScanner,
        category: .deviceInput,
        privacyRisk: .high,
        availability: .permissionGated,
        requiresExplicitUserAction: true,
        hostEnforcedSummary: "Returns inert text from a visible scanner; scanned URLs are never opened "
            + "and payloads are never executed automatically.",
        frameworkOrPermissionNote: "VisionKit DataScanner with camera authorization and NSCameraUsageDescription."
    )

    private static let currentLocation = CapabilityMetadata(
        capability: .currentLocation,
        category: .location,
        privacyRisk: .high,
        availability: .permissionGated,
        requiresExplicitUserAction: true,
        hostEnforcedSummary: "Requests one foreground location after the user taps; continuous updates, "
            + "geofencing, visit monitoring, and background tracking are unavailable.",
        frameworkOrPermissionNote: "CoreLocation with When In Use authorization and "
            + "NSLocationWhenInUseUsageDescription."
    )

    private static let contactPicker = CapabilityMetadata(
        capability: .contactPicker,
        category: .people,
        privacyRisk: .high,
        availability: .systemMediated,
        requiresExplicitUserAction: true,
        hostEnforcedSummary: "Returns only the single contact the user chooses in Apple's picker; "
            + "the tiny app cannot enumerate, search, edit, or export the address book.",
        frameworkOrPermissionNote: "ContactsUI CNContactPickerViewController; "
            + "broad Contacts authorization is not requested."
    )

    private static let documentPicker = CapabilityMetadata(
        capability: .documentPicker,
        category: .files,
        privacyRisk: .high,
        availability: .systemMediated,
        requiresExplicitUserAction: true,
        hostEnforcedSummary: "Reads only one user-selected text, JSON, or CSV document through a security-scoped URL, "
            + "with host-enforced size and stored-text limits.",
        frameworkOrPermissionNote: "SwiftUI fileImporter and UniformTypeIdentifiers; "
            + "access is limited to the selected document."
    )

    private static let documentExport = CapabilityMetadata(
        capability: .documentExport,
        category: .files,
        privacyRisk: .moderate,
        availability: .systemMediated,
        requiresExplicitUserAction: true,
        hostEnforcedSummary: "Exports only the bounded text the user can review through Apple's save panel; "
            + "the tiny app cannot choose a destination or overwrite a file silently.",
        frameworkOrPermissionNote: "SwiftUI fileExporter and UniformTypeIdentifiers; no permission prompt."
    )

    private static let mapSearch = CapabilityMetadata(
        capability: .mapSearch,
        category: .location,
        privacyRisk: .moderate,
        availability: .fixedProvider,
        requiresExplicitUserAction: false,
        hostEnforcedSummary: "Displays a bounded MapKit region and searches only Apple Maps after visible input; "
            + "it cannot read location history or call arbitrary map providers.",
        frameworkOrPermissionNote: "MapKit display and MKLocalSearch; no location permission is requested."
    )

    private static let calendarWrite = CapabilityMetadata(
        capability: .calendarWrite,
        category: .calendar,
        privacyRisk: .high,
        availability: .permissionGated,
        requiresExplicitUserAction: true,
        hostEnforcedSummary: "Creates one event only after a visible review and confirmation; "
            + "the tiny app cannot enumerate, edit, or delete existing calendar data.",
        frameworkOrPermissionNote: "EventKit write-only event access requested at use time with "
            + "NSCalendarsWriteOnlyAccessUsageDescription."
    )

    private static let pedometer = CapabilityMetadata(
        capability: .pedometer,
        category: .motion,
        privacyRisk: .high,
        availability: .permissionGated,
        requiresExplicitUserAction: true,
        hostEnforcedSummary: "Reads only today's aggregate step count after the user taps; "
            + "raw motion streaming and background monitoring are unavailable.",
        frameworkOrPermissionNote: "CoreMotion CMPedometer with Motion & Fitness authorization "
            + "and NSMotionUsageDescription."
    )

    private static let shareSheet = CapabilityMetadata(
        capability: .shareSheet,
        category: .sharing,
        privacyRisk: .moderate,
        availability: .systemMediated,
        requiresExplicitUserAction: true,
        hostEnforcedSummary: "Presents configured text in Apple's share sheet; nothing leaves the app "
            + "until the user reviews it and selects a destination.",
        frameworkOrPermissionNote: "UIKit UIActivityViewController; no permission prompt."
    )

    private static let clipboardWrite = CapabilityMetadata(
        capability: .clipboardWrite,
        category: .sharing,
        privacyRisk: .moderate,
        availability: .hostLocal,
        requiresExplicitUserAction: true,
        hostEnforcedSummary: "Writes only configured text to the clipboard after the user taps; "
            + "clipboard reading and background writes are unavailable.",
        frameworkOrPermissionNote: "UIKit UIPasteboard write-only operation; no permission prompt."
    )

    private static let haptics = CapabilityMetadata(
        capability: .haptics,
        category: .systemFeedback,
        privacyRisk: .low,
        availability: .hostLocal,
        requiresExplicitUserAction: true,
        hostEnforcedSummary: "Plays one host-defined tactile confirmation after the user taps; "
            + "it reads no sensors and stores no device data.",
        frameworkOrPermissionNote: "UIKit UINotificationFeedbackGenerator; no permission prompt."
    )

    private static let network = CapabilityMetadata(
        capability: .network,
        category: .network,
        privacyRisk: .high,
        availability: .fixedProvider,
        requiresExplicitUserAction: false,
        hostEnforcedSummary: "Fetches only through compiled provider adapters; arbitrary URLs, methods, "
            + "headers, request bodies, and sockets are unavailable.",
        frameworkOrPermissionNote: "URLSession through the host's fixed-provider allowlist."
    )

    private static let aiRequests = CapabilityMetadata(
        capability: .aiRequests,
        category: .intelligence,
        privacyRisk: .high,
        availability: .credentialGated,
        requiresExplicitUserAction: true,
        hostEnforcedSummary: "Sends only text the user reviews and confirms to OpenAI using their key; "
            + "other tiny-app and device data are not attached automatically.",
        frameworkOrPermissionNote: "OpenAI Responses API through the host client; a user-owned key is required."
    )
}
