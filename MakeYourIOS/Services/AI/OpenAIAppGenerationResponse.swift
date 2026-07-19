import Foundation

struct ResponsesAPIResponse: Decodable {
    struct IncompleteDetails: Decodable {
        var reason: String
    }

    struct Output: Decodable {
        var content: [Content]?
    }

    struct Content: Decodable {
        var type: String
        var text: String?
        var refusal: String?
    }

    var status: String?
    var incompleteDetails: IncompleteDetails?
    var output: [Output]

    enum CodingKeys: String, CodingKey {
        case status
        case incompleteDetails = "incomplete_details"
        case output
    }
}

struct APIErrorEnvelope: Decodable {
    struct Body: Decodable { var message: String }
    var error: Body
}

enum AppGenerationError: LocalizedError, Equatable {
    case invalidResponse
    case invalidDocumentEncoding
    case missingOutput
    case refused(String)
    case incomplete(String)
    case api(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "OpenAI returned an invalid response."
        case .invalidDocumentEncoding: "The current app could not be encoded for generation."
        case .missingOutput: "The model did not return an app document."
        case .refused(let reason): reason
        case .incomplete(let reason):
            "OpenAI stopped before the app document was complete (\(reason)). Try again."
        case .api(let statusCode, let message): "OpenAI error \(statusCode): \(message)"
        }
    }
}
