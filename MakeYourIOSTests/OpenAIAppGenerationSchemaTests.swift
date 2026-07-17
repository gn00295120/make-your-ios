import XCTest
@testable import MakeYourIOS

final class OpenAIAppGenerationSchemaTests: XCTestCase {
    func testStructuredOutputSchemaIsValidJSON() throws {
        let schema = OpenAIAppGenerationClient.responseSchema
        XCTAssertTrue(JSONSerialization.isValidJSONObject(schema))

        let data = try JSONSerialization.data(withJSONObject: schema)
        XCTAssertFalse(data.isEmpty)
    }

    func testEveryStructuredOutputObjectIsStrictAndRequiresEveryProperty() throws {
        try assertStrictObjectTree(OpenAIAppGenerationClient.responseSchema, path: "root")
    }

    func testSchemaIncludesVisualMediaAndRuntimeAICapabilities() throws {
        let root = OpenAIAppGenerationClient.responseSchema
        let properties = try XCTUnwrap(root["properties"] as? [String: Any])
        XCTAssertNotNil(properties["theme"])

        let capabilities = try XCTUnwrap(properties["capabilities"] as? [String: Any])
        let items = try XCTUnwrap(capabilities["items"] as? [String: Any])
        let values = try XCTUnwrap(items["enum"] as? [String])
        XCTAssertTrue(values.contains(AppCapability.photoPicker.rawValue))
        XCTAssertTrue(values.contains(AppCapability.aiRequests.rawValue))

        let componentKinds = try findEnum(named: "kind", in: root)
        XCTAssertTrue(componentKinds.contains(ComponentKind.image.rawValue))
        XCTAssertTrue(componentKinds.contains(ComponentKind.aiAssistant.rawValue))
        XCTAssertTrue(componentKinds.contains(ComponentKind.recordCollection.rawValue))
        XCTAssertTrue(componentKinds.contains(ComponentKind.liveDataList.rawValue))

        XCTAssertNotNil(try findProperty(named: "collection", in: root))
        XCTAssertNotNil(try findProperty(named: "liveData", in: root))
    }

    private func assertStrictObjectTree(_ value: Any, path: String) throws {
        if let dictionary = value as? [String: Any] {
            if dictionary["type"] as? String == "object" {
                XCTAssertEqual(dictionary["additionalProperties"] as? Bool, false, path)
                let properties = try XCTUnwrap(
                    dictionary["properties"] as? [String: Any],
                    "Missing properties at \(path)"
                )
                let required = try XCTUnwrap(
                    dictionary["required"] as? [String],
                    "Missing required at \(path)"
                )
                XCTAssertEqual(Set(properties.keys), Set(required), path)
            }
            for (key, child) in dictionary {
                try assertStrictObjectTree(child, path: "\(path).\(key)")
            }
        } else if let array = value as? [Any] {
            for (index, child) in array.enumerated() {
                try assertStrictObjectTree(child, path: "\(path)[\(index)]")
            }
        }
    }

    private func findEnum(named key: String, in value: Any) throws -> [String] {
        if let dictionary = value as? [String: Any] {
            if let candidate = dictionary[key] as? [String: Any],
               let values = candidate["enum"] as? [String] {
                return values
            }
            for child in dictionary.values {
                let result = try findEnum(named: key, in: child)
                if !result.isEmpty { return result }
            }
        } else if let array = value as? [Any] {
            for child in array {
                let result = try findEnum(named: key, in: child)
                if !result.isEmpty { return result }
            }
        }
        return []
    }

    private func findProperty(named key: String, in value: Any) throws -> Any? {
        if let dictionary = value as? [String: Any] {
            if let properties = dictionary["properties"] as? [String: Any],
               let candidate = properties[key] {
                return candidate
            }
            for child in dictionary.values {
                if let result = try findProperty(named: key, in: child) { return result }
            }
        } else if let array = value as? [Any] {
            for child in array {
                if let result = try findProperty(named: key, in: child) { return result }
            }
        }
        return nil
    }
}
