#if DEBUG
import Foundation

struct OpenAISpeechClient: Sendable {
    static let model = "gpt-4o-mini-tts"
    static let voice = "marin"
    static let instructions = """
    Speak in polished, warm, natural American English for a concise product demo. \
    Sound confident and conversational, with lively but controlled pacing. Use short, \
    natural pauses between ideas. Avoid a salesy, robotic, or overly dramatic delivery. \
    Clearly pronounce MakeYour, SwiftUI, GPT-5.6, and Codex.
    """

    private let endpoint = URL(string: "https://api.openai.com/v1/audio/speech")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func synthesize(text: String, apiKey: String) async throws -> Data {
        let request = try makeRequest(text: text, apiKey: apiKey)
        let (data, response) = try await session.data(for: request)
        try Self.validate(response: response, data: data)
        guard !data.isEmpty else { throw OpenAISpeechError.emptyAudio }
        return data
    }

    func makeRequest(text: String, apiKey: String) throws -> URLRequest {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, trimmedText.count <= 4_096 else {
            throw OpenAISpeechError.invalidInput
        }

        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { throw AIConfigurationError.missingKey }

        let body = SpeechRequest(
            model: Self.model,
            input: trimmedText,
            voice: Self.voice,
            instructions: Self.instructions,
            responseFormat: "mp3"
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 120
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    static func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAISpeechError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if let envelope = try? JSONDecoder().decode(SpeechAPIErrorEnvelope.self, from: data) {
                throw OpenAISpeechError.api(
                    statusCode: httpResponse.statusCode,
                    message: envelope.error.message
                )
            }
            throw OpenAISpeechError.api(
                statusCode: httpResponse.statusCode,
                message: "The provider returned an error."
            )
        }
    }
}

private struct SpeechRequest: Encodable {
    let model: String
    let input: String
    let voice: String
    let instructions: String
    let responseFormat: String

    enum CodingKeys: String, CodingKey {
        case model
        case input
        case voice
        case instructions
        case responseFormat = "response_format"
    }
}

private struct SpeechAPIErrorEnvelope: Decodable {
    struct Body: Decodable {
        let message: String
    }

    let error: Body
}

enum OpenAISpeechError: LocalizedError, Equatable {
    case invalidInput
    case invalidResponse
    case emptyAudio
    case api(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidInput:
            "Demo narration must contain between 1 and 4,096 characters."
        case .invalidResponse:
            "OpenAI returned an invalid speech response."
        case .emptyAudio:
            "OpenAI returned an empty speech file."
        case .api(let statusCode, let message):
            "OpenAI speech error \(statusCode): \(message)"
        }
    }
}
#endif
