import Foundation

extension OpenAIAppGenerationClient {
    static func makeRepairContext(
        after error: Error,
        responseData: Data,
        replacing currentDocument: AppDocument,
        pass: Int
    ) -> AppGenerationRepairContext? {
        guard isRepairableGenerationError(error) else { return nil }

        let previousOutput = responseOutputText(from: responseData)
            ?? "No complete candidate JSON was returned. Rebuild the complete document from the original request."
        var diagnostic = repairDiagnostic(for: error)
        if let outputData = previousOutput.data(using: .utf8),
           let payload = try? JSONDecoder().decode(GeneratedAppPayload.self, from: outputData) {
            let document = payload.makeDocument(
                existingID: currentDocument.id,
                version: currentDocument.version + 1
            )
            diagnostic += "\n" + AppDocumentValidationFeedback.describe(
                error: error,
                in: document
            )
        }

        return AppGenerationRepairContext(
            pass: max(1, pass),
            previousOutput: previousOutput,
            diagnostic: String(diagnostic.prefix(6_000))
        )
    }

    static func requestInput(
        prompt: String,
        currentJSON: String,
        repairContext: AppGenerationRepairContext?
    ) -> String {
        guard let repairContext else {
            return """
            USER REQUEST:
            \(prompt)

            CURRENT APP DOCUMENT:
            \(currentJSON)

            Return a complete replacement document. Preserve what already works unless the user asks to change it.
            """
        }

        return """
        AUTOMATIC REPAIR PASS \(repairContext.pass)

        ORIGINAL USER REQUEST:
        \(prompt)

        APPLICATION-SIDE VALIDATION DIAGNOSTIC:
        \(repairContext.diagnostic)

        PREVIOUS COMPLETE CANDIDATE JSON:
        \(repairContext.previousOutput)

        Return a corrected complete replacement document, not a patch and not an explanation. Preserve every
        valid feature and design choice from the candidate. Audit all IDs, state declarations, bindings,
        references, event triggers, step targets, conditions, expression operand counts, operand types, and exact
        result types before returning. Expressions cannot nest. If one requested behavior cannot be represented,
        replace only that behavior with an honest infoBanner instead of repeating invalid logic. Do not weaken or
        remove unrelated working features. Continue satisfying the original request.
        """
    }
}

private extension OpenAIAppGenerationClient {
    static func isRepairableGenerationError(_ error: Error) -> Bool {
        if error is AppDocumentValidationError || error is DecodingError {
            return true
        }
        guard let generationError = error as? AppGenerationError else { return false }
        switch generationError {
        case .missingOutput, .incomplete:
            return true
        case .invalidResponse, .invalidDocumentEncoding, .refused, .api:
            return false
        }
    }

    static func responseOutputText(from data: Data) -> String? {
        guard let apiResponse = try? JSONDecoder().decode(ResponsesAPIResponse.self, from: data) else {
            return nil
        }
        return apiResponse.output
            .compactMap(\.content)
            .flatMap { $0 }
            .first(where: { $0.type == "output_text" })?
            .text
    }

    static func repairDiagnostic(for error: Error) -> String {
        if let validationError = error as? AppDocumentValidationError {
            return """
            VALIDATION CODE: \(validationCode(for: validationError))
            HOST RULE: \(validationError.localizedDescription)
            """
        }
        if let decodingError = error as? DecodingError {
            return """
            VALIDATION CODE: payload_decoding_failed
            HOST RULE: The candidate must match every required response-schema field and value type.
            DECODING PATH: \(decodingPath(for: decodingError))
            """
        }
        if let generationError = error as? AppGenerationError {
            switch generationError {
            case .missingOutput:
                return "VALIDATION CODE: missing_output\nHOST RULE: Return one complete output_text JSON document."
            case .incomplete:
                return """
                VALIDATION CODE: incomplete_output
                HOST RULE: Return a smaller but complete app document. Preserve the requested outcomes, use at
                most three pages and twelve components per page, and approximate unsupported detail honestly.
                """
            default:
                break
            }
        }
        return "VALIDATION CODE: invalid_candidate\nHOST RULE: Return a complete valid replacement document."
    }

    // swiftlint:disable:next cyclomatic_complexity
    static func validationCode(for error: AppDocumentValidationError) -> String {
        switch error {
        case .unsupportedSchema: "unsupported_schema"
        case .invalidName: "invalid_name"
        case .invalidPageCount: "invalid_page_count"
        case .missingStartPage: "missing_start_page"
        case .tooManyNodes: "too_many_nodes"
        case .duplicateIdentifier: "duplicate_identifier"
        case .contentLimitExceeded: "content_limit_exceeded"
        case .invalidComponentConfiguration: "invalid_component_configuration"
        case .invalidAction: "invalid_action"
        case .duplicateBinding: "duplicate_binding"
        case .missingCapability: "missing_capability"
        case .unnecessaryCapability: "unnecessary_capability"
        case .invalidVisualTheme: "invalid_visual_theme"
        case .unsupportedVariant: "unsupported_variant"
        case .invalidRuntimeLogic: "invalid_runtime_logic"
        case .invalidRuntimeReference: "invalid_runtime_reference"
        case .invalidRuntimeExpression: "invalid_runtime_expression"
        case .runtimeLimitExceeded: "runtime_limit_exceeded"
        }
    }

    static func decodingPath(for error: DecodingError) -> String {
        let path: [CodingKey]
        switch error {
        case .dataCorrupted(let context),
             .keyNotFound(_, let context),
             .typeMismatch(_, let context),
             .valueNotFound(_, let context):
            path = context.codingPath
        @unknown default:
            return "unknown"
        }
        let description = path.map { key in
            key.intValue.map(String.init) ?? key.stringValue
        }.joined(separator: ".")
        return description.isEmpty ? "root" : String(description.prefix(500))
    }
}
