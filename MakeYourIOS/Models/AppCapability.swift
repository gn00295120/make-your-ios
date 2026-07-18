import Foundation

enum AppCapability: String, Codable, CaseIterable, Hashable, Sendable {
    case localStorage = "storage.local"
    case safeCalculation = "calculation.safe"
    case localNotifications = "notifications.scheduleLocal"
    case photoPicker = "photo.pick"
    case cameraCapture = "camera.capture"
    case codeScanner = "camera.scanCode"
    case currentLocation = "location.current"
    case contactPicker = "contacts.pick"
    case documentPicker = "files.import"
    case pedometer = "motion.pedometer"
    case shareSheet = "share.present"
    case clipboardWrite = "clipboard.write"
    case haptics = "haptics.play"
    case network = "http.request"
    case aiRequests = "ai.complete"

    var label: String {
        switch self {
        case .localStorage: "Local data"
        case .safeCalculation: "Calculations"
        case .localNotifications: "Notifications"
        case .photoPicker: "Photos"
        case .cameraCapture: "Camera"
        case .codeScanner: "Code scanner"
        case .currentLocation: "Current location"
        case .contactPicker: "Contact picker"
        case .documentPicker: "Document picker"
        case .pedometer: "Motion activity"
        case .shareSheet: "Share sheet"
        case .clipboardWrite: "Clipboard"
        case .haptics: "Haptics"
        case .network: "Internet access"
        case .aiRequests: "AI requests"
        }
    }

    var symbol: String {
        switch self {
        case .localStorage: "externaldrive"
        case .safeCalculation: "function"
        case .localNotifications: "bell.badge"
        case .photoPicker: "photo.on.rectangle"
        case .cameraCapture: "camera.fill"
        case .codeScanner: "qrcode.viewfinder"
        case .currentLocation: "location.fill"
        case .contactPicker: "person.crop.circle.badge.plus"
        case .documentPicker: "doc.badge.plus"
        case .pedometer: "figure.walk.motion"
        case .shareSheet: "square.and.arrow.up"
        case .clipboardWrite: "doc.on.clipboard"
        case .haptics: "waveform"
        case .network: "network"
        case .aiRequests: "sparkles"
        }
    }
}
