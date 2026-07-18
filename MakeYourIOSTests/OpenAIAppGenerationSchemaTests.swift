import XCTest
@testable import MakeYourIOS

final class OpenAIAppGenerationSchemaTests: XCTestCase {
    private struct SchemaMetrics {
        var propertyCount: Int
        var maximumObjectDepth: Int
        var enumValueCount: Int

        static func + (lhs: Self, rhs: Self) -> Self {
            SchemaMetrics(
                propertyCount: lhs.propertyCount + rhs.propertyCount,
                maximumObjectDepth: max(lhs.maximumObjectDepth, rhs.maximumObjectDepth),
                enumValueCount: lhs.enumValueCount + rhs.enumValueCount
            )
        }
    }

    func testStructuredOutputSchemaIsValidJSON() throws {
        let schema = OpenAIAppGenerationClient.responseSchema
        XCTAssertTrue(JSONSerialization.isValidJSONObject(schema))

        let data = try JSONSerialization.data(withJSONObject: schema)
        XCTAssertFalse(data.isEmpty)
    }

    func testEveryStructuredOutputObjectIsStrictAndRequiresEveryProperty() throws {
        try assertStrictObjectTree(OpenAIAppGenerationClient.responseSchema, path: "root")
    }

    func testSchemaStaysWithinStructuredOutputComplexityLimits() {
        let metrics = schemaMetrics(OpenAIAppGenerationClient.responseSchema)
        XCTAssertLessThanOrEqual(metrics.propertyCount, 5_000)
        XCTAssertLessThanOrEqual(metrics.maximumObjectDepth, 10)
        XCTAssertLessThanOrEqual(metrics.enumValueCount, 1_000)
    }

    func testSchemaIncludesVisualMediaAndRuntimeAICapabilities() throws {
        let root = OpenAIAppGenerationClient.responseSchema
        let properties = try XCTUnwrap(root["properties"] as? [String: Any])
        try assertThemeSchema(in: properties)

        let capabilities = try XCTUnwrap(properties["capabilities"] as? [String: Any])
        let items = try XCTUnwrap(capabilities["items"] as? [String: Any])
        let values = try XCTUnwrap(items["enum"] as? [String])
        XCTAssertTrue(values.contains(AppCapability.photoPicker.rawValue))
        XCTAssertTrue(values.contains(AppCapability.aiRequests.rawValue))
        XCTAssertTrue(values.contains(AppCapability.cameraCapture.rawValue))
        XCTAssertTrue(values.contains(AppCapability.codeScanner.rawValue))

        let componentKinds = try XCTUnwrap(
            findEnums(named: "kind", in: root).first(where: {
                $0.contains(ComponentKind.hero.rawValue)
            })
        )
        XCTAssertTrue(componentKinds.contains(ComponentKind.image.rawValue))
        XCTAssertTrue(componentKinds.contains(ComponentKind.aiAssistant.rawValue))
        XCTAssertTrue(componentKinds.contains(ComponentKind.recordCollection.rawValue))
        XCTAssertTrue(componentKinds.contains(ComponentKind.liveDataList.rawValue))
        XCTAssertTrue(componentKinds.contains(ComponentKind.newsFeed.rawValue))
        XCTAssertTrue(componentKinds.contains(ComponentKind.marketWatch.rawValue))
        XCTAssertTrue(componentKinds.contains(ComponentKind.ledger.rawValue))
        XCTAssertTrue(componentKinds.contains(ComponentKind.game.rawValue))
        XCTAssertTrue(componentKinds.contains(ComponentKind.deviceInput.rawValue))
        XCTAssertTrue(componentKinds.contains(ComponentKind.control.rawValue))

        try assertRendererSchema(in: root)
        try assertLogicSchema(in: root)

        for propertyName in [
            "image", "collection", "liveData", "newsFeed", "marketWatch", "ledger", "game",
            "deviceInput", "control"
        ] {
            let property = try XCTUnwrap(
                try findProperty(named: propertyName, in: root) as? [String: Any]
            )
            XCTAssertEqual(Set(property["type"] as? [String] ?? []), Set(["object", "null"]))
        }

        let gameSchema = try XCTUnwrap(
            try findProperty(named: "game", in: root) as? [String: Any]
        )
        let gameProperties = try XCTUnwrap(gameSchema["properties"] as? [String: Any])
        let program = try XCTUnwrap(gameProperties["program"] as? [String: Any])
        XCTAssertEqual(Set(program["type"] as? [String] ?? []), Set(["object", "null"]))
        let programProperties = try XCTUnwrap(program["properties"] as? [String: Any])
        XCTAssertNotNil(programProperties["world"])
        XCTAssertNotNil(programProperties["templates"])
        XCTAssertNotNil(programProperties["rules"])
        XCTAssertNotNil(programProperties["controls"])
    }

    private func assertLogicSchema(in root: [String: Any]) throws {
        let properties = try XCTUnwrap(root["properties"] as? [String: Any])
        let logic = try XCTUnwrap(properties["logic"] as? [String: Any])
        XCTAssertEqual(Set(logic["type"] as? [String] ?? []), Set(["object", "null"]))

        let nodeEvents = try XCTUnwrap(try findProperty(named: "events", in: root) as? [String: Any])
        XCTAssertEqual(nodeEvents["type"] as? String, "array")
        let valueBinding = try XCTUnwrap(
            try findProperty(named: "valueBinding", in: root) as? [String: Any]
        )
        XCTAssertEqual(valueBinding["type"] as? String, "string")

        let stepKinds = findEnums(named: "kind", in: nodeEvents)
            .first(where: { $0.contains(RuntimeStepKind.setState.rawValue) })
        XCTAssertEqual(Set(try XCTUnwrap(stepKinds)), Set(RuntimeStepKind.allCases.map(\.rawValue)))
        let operations = try XCTUnwrap(findEnums(named: "operation", in: nodeEvents).first)
        XCTAssertEqual(Set(operations), Set(RuntimeExpressionOperation.allCases.map(\.rawValue)))
        let comparisons = try XCTUnwrap(findEnums(named: "comparison", in: nodeEvents).first)
        XCTAssertEqual(Set(comparisons), Set(RuntimeComparison.allCases.map(\.rawValue)))
    }

    private func assertThemeSchema(in properties: [String: Any]) throws {
        let theme = try XCTUnwrap(properties["theme"] as? [String: Any])
        let themeProperties = try XCTUnwrap(theme["properties"] as? [String: Any])
        for property in [
            "palette", "typeScale", "titleWeight", "elevation", "stroke", "controlShape",
            "motion", "backgroundAssetBinding"
        ] {
            XCTAssertNotNil(themeProperties[property], property)
        }
        let palette = try XCTUnwrap(themeProperties["palette"] as? [String: Any])
        let paletteProperties = try XCTUnwrap(palette["properties"] as? [String: Any])
        XCTAssertEqual(Set(paletteProperties.keys), Set([
            "primaryHex", "secondaryHex", "accentHex", "canvasLightHex", "canvasDarkHex",
            "surfaceLightHex", "surfaceDarkHex"
        ]))
        for colorSchema in paletteProperties.values {
            let color = try XCTUnwrap(colorSchema as? [String: Any])
            XCTAssertEqual(color["pattern"] as? String, "^#[0-9A-F]{6}$")
        }
    }

    private func assertRendererSchema(in root: [String: Any]) throws {
        let variants = try XCTUnwrap(findEnums(named: "variant", in: root).first)
        XCTAssertTrue(variants.contains(ComponentVariant.editorial.rawValue))
        XCTAssertTrue(variants.contains(ComponentVariant.immersive.rawValue))
        XCTAssertTrue(variants.contains(ComponentVariant.softAction.rawValue))
        let navigationStyles = try XCTUnwrap(
            findEnums(named: "navigationStyle", in: root).first
        )
        XCTAssertEqual(Set(navigationStyles), Set(PageNavigationStyle.allCases.map(\.rawValue)))

        let imageSchema = try XCTUnwrap(
            try findProperty(named: "image", in: root) as? [String: Any]
        )
        let imageProperties = try XCTUnwrap(imageSchema["properties"] as? [String: Any])
        for property in ["mediaRole", "focalPoint", "mask", "overlay"] {
            XCTAssertNotNil(imageProperties[property], property)
        }
    }

    private func assertStrictObjectTree(_ value: Any, path: String) throws {
        if let dictionary = value as? [String: Any] {
            let scalarObject = dictionary["type"] as? String == "object"
            let nullableObject = (dictionary["type"] as? [String])?.contains("object") == true
            if scalarObject || nullableObject {
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

    private func findEnums(named key: String, in value: Any) -> [[String]] {
        var results: [[String]] = []
        if let dictionary = value as? [String: Any] {
            if let candidate = dictionary[key] as? [String: Any],
               let values = candidate["enum"] as? [String] {
                results.append(values)
            }
            for child in dictionary.values {
                results.append(contentsOf: findEnums(named: key, in: child))
            }
        } else if let array = value as? [Any] {
            for child in array {
                results.append(contentsOf: findEnums(named: key, in: child))
            }
        }
        return results
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

    private func schemaMetrics(_ value: Any, objectDepth: Int = 0) -> SchemaMetrics {
        guard let dictionary = value as? [String: Any] else {
            if let array = value as? [Any] {
                return array.reduce(SchemaMetrics(
                    propertyCount: 0,
                    maximumObjectDepth: objectDepth,
                    enumValueCount: 0
                )) { result, child in
                    let childMetrics = schemaMetrics(child, objectDepth: objectDepth)
                    return result + childMetrics
                }
            }
            return SchemaMetrics(
                propertyCount: 0,
                maximumObjectDepth: objectDepth,
                enumValueCount: 0
            )
        }

        let isObject = dictionary["type"] as? String == "object"
            || (dictionary["type"] as? [String])?.contains("object") == true
        let nextDepth = objectDepth + (isObject ? 1 : 0)
        let ownPropertyCount = (dictionary["properties"] as? [String: Any])?.count ?? 0
        let ownEnumCount = (dictionary["enum"] as? [Any])?.count ?? 0
        let ownMetrics = SchemaMetrics(
            propertyCount: ownPropertyCount,
            maximumObjectDepth: nextDepth,
            enumValueCount: ownEnumCount
        )
        return dictionary.values.reduce(ownMetrics) { result, child in
            let childMetrics = schemaMetrics(child, objectDepth: nextDepth)
            return result + childMetrics
        }
    }
}
