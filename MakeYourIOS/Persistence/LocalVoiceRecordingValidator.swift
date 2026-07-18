@preconcurrency import AVFAudio
import Foundation

enum LocalVoiceRecordingValidator {
    static func isPlayableM4A(_ data: Data) -> Bool {
        guard data.count >= 8,
              data.subdata(in: 4..<8) == Data("ftyp".utf8),
              let player = try? AVAudioPlayer(data: data),
              player.duration.isFinite,
              player.duration > 0,
              player.duration <= 61,
              player.prepareToPlay() else {
            return false
        }
        return true
    }
}
