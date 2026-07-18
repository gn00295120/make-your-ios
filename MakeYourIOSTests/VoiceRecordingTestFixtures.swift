@preconcurrency import AVFAudio
import Foundation

func makePlayableVoiceRecordingData(minimumByteCount: Int = 0) throws -> Data {
    let fileURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("makeyour-test-voice-\(UUID().uuidString.lowercased())")
        .appendingPathExtension("m4a")
    defer { try? FileManager.default.removeItem(at: fileURL) }
    try writeSilentVoiceRecording(to: fileURL)
    var data = try Data(contentsOf: fileURL)
    if data.count < minimumByteCount {
        data.append(Data(repeating: 0, count: minimumByteCount - data.count))
    }
    return data
}

private func writeSilentVoiceRecording(to fileURL: URL) throws {
    let settings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 16_000.0,
        AVNumberOfChannelsKey: 1,
        AVEncoderBitRateKey: 32_000
    ]
    let file = try AVAudioFile(forWriting: fileURL, settings: settings)
    let buffer = AVAudioPCMBuffer(
        pcmFormat: file.processingFormat,
        frameCapacity: 1_600
    )!
    buffer.frameLength = 1_600
    try file.write(from: buffer)
}
