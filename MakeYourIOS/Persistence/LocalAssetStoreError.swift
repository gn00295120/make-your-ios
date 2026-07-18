import Foundation

enum LocalAssetStoreError: LocalizedError, Equatable {
    case invalidBinding
    case invalidImageData
    case invalidVoiceRecordingData
    case voiceRecordingTooLarge
    case invalidManifest
    case missingAsset

    var errorDescription: String? {
        switch self {
        case .invalidBinding:
            "The asset binding is empty or too long."
        case .invalidImageData:
            "The selected item is not a supported image."
        case .invalidVoiceRecordingData:
            "The recording is empty, incomplete, or not a playable M4A audio file."
        case .voiceRecordingTooLarge:
            "The recording exceeds the 1 MB local storage limit."
        case .invalidManifest:
            "The local asset manifest is invalid."
        case .missingAsset:
            "A local asset file is missing."
        }
    }
}
