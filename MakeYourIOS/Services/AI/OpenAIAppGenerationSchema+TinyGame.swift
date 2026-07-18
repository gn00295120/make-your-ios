import Foundation

extension OpenAIAppGenerationClient {
    static var tinyGameProgramSchema: [String: Any] {
        let string: [String: Any] = ["type": "string"]
        let integer: [String: Any] = ["type": "integer"]
        let symbols = [""] + GeneratedAppPayload.allowedSymbols.sorted()
        let stringArray: [String: Any] = ["type": "array", "items": string]

        func object(
            _ properties: [String: Any],
            required: [String]
        ) -> [String: Any] {
            [
                "type": "object",
                "additionalProperties": false,
                "properties": properties,
                "required": required
            ]
        }

        func nullableObject(_ value: [String: Any]) -> [String: Any] {
            var result = value
            result["type"] = ["object", "null"]
            return result
        }

        let world = object([
            "width": integer,
            "height": integer,
            "gravityX": integer,
            "gravityY": integer,
            "edgeBehavior": [
                "type": "string",
                "enum": TinyGameEdgeBehavior.allCases.map(\.rawValue)
            ]
        ], required: ["width", "height", "gravityX", "gravityY", "edgeBehavior"])

        let variable = object([
            "id": string,
            "kind": ["type": "string", "enum": TinyGameVariableKind.allCases.map(\.rawValue)],
            "initialValue": integer,
            "minimumValue": integer,
            "maximumValue": integer
        ], required: ["id", "kind", "initialValue", "minimumValue", "maximumValue"])

        let visual = object([
            "kind": ["type": "string", "enum": TinyGameVisualKind.allCases.map(\.rawValue)],
            "colorRole": ["type": "string", "enum": TinyGameColorRole.allCases.map(\.rawValue)],
            "symbol": ["type": "string", "enum": symbols]
        ], required: ["kind", "colorRole", "symbol"])

        let physics = object([
            "collisionMode": [
                "type": "string",
                "enum": TinyGameCollisionMode.allCases.map(\.rawValue)
            ],
            "maximumVelocityX": integer,
            "maximumVelocityY": integer,
            "lifetimeTicks": integer
        ], required: [
            "collisionMode", "maximumVelocityX", "maximumVelocityY", "lifetimeTicks"
        ])

        let template = object([
            "id": string,
            "role": ["type": "string", "enum": TinyGameEntityRole.allCases.map(\.rawValue)],
            "visual": visual,
            "body": ["type": "string", "enum": TinyGameBodyKind.allCases.map(\.rawValue)],
            "movement": ["type": "string", "enum": TinyGameMovementKind.allCases.map(\.rawValue)],
            "width": integer,
            "height": integer,
            "velocityX": integer,
            "velocityY": integer,
            "speed": integer,
            "tags": stringArray,
            "physics": nullableObject(physics)
        ], required: [
            "id", "role", "visual", "body", "movement", "width", "height",
            "velocityX", "velocityY", "speed", "tags", "physics"
        ])

        let spawn = object([
            "id": string,
            "templateID": string,
            "x": integer,
            "y": integer
        ], required: ["id", "templateID", "x", "y"])

        let action = object([
            "kind": [
                "type": "string",
                "enum": TinyGameControlActionKind.allCases.map(\.rawValue)
            ],
            "impulse": integer,
            "cooldownTicks": integer,
            "maximumActive": integer,
            "offsetX": integer,
            "offsetY": integer
        ], required: [
            "kind", "impulse", "cooldownTicks", "maximumActive", "offsetX", "offsetY"
        ])

        let control = object([
            "id": string,
            "kind": ["type": "string", "enum": TinyGameControlKind.allCases.map(\.rawValue)],
            "label": string,
            "symbol": [
                "type": "string",
                "enum": GeneratedAppPayload.allowedSymbols.sorted()
            ],
            "targetTag": string,
            "speed": integer,
            "spawnTemplateID": string,
            "action": nullableObject(action)
        ], required: [
            "id", "kind", "label", "symbol", "targetTag", "speed", "spawnTemplateID",
            "action"
        ])

        let trigger = object([
            "kind": ["type": "string", "enum": TinyGameTriggerKind.allCases.map(\.rawValue)],
            "subjectTag": string,
            "otherTag": string,
            "everyTicks": integer
        ], required: ["kind", "subjectTag", "otherTag", "everyTicks"])

        let condition = object([
            "variableID": string,
            "comparison": ["type": "string", "enum": TinyGameComparison.allCases.map(\.rawValue)],
            "value": integer
        ], required: ["variableID", "comparison", "value"])

        let effect = object([
            "kind": ["type": "string", "enum": TinyGameEffectKind.allCases.map(\.rawValue)],
            "target": ["type": "string", "enum": TinyGameEffectTarget.allCases.map(\.rawValue)],
            "targetTag": string,
            "variableID": string,
            "value": integer,
            "x": integer,
            "y": integer,
            "templateID": string,
            "feedback": ["type": "string", "enum": TinyGameFeedback.allCases.map(\.rawValue)]
        ], required: [
            "kind", "target", "targetTag", "variableID", "value", "x", "y",
            "templateID", "feedback"
        ])

        let rule = object([
            "id": string,
            "trigger": trigger,
            "conditions": ["type": "array", "items": condition],
            "effects": ["type": "array", "items": effect]
        ], required: ["id", "trigger", "conditions", "effects"])

        let hud = object([
            "id": string,
            "kind": ["type": "string", "enum": TinyGameHUDKind.allCases.map(\.rawValue)],
            "variableID": string,
            "label": string,
            "symbol": [
                "type": "string",
                "enum": GeneratedAppPayload.allowedSymbols.sorted()
            ]
        ], required: ["id", "kind", "variableID", "label", "symbol"])

        return object([
            "version": ["type": "integer", "enum": [TinyGameProgram.currentVersion]],
            "seed": integer,
            "tickRate": ["type": "integer", "enum": TinyGameTickRate.allCases.map(\.rawValue)],
            "world": world,
            "variables": ["type": "array", "items": variable],
            "templates": ["type": "array", "items": template],
            "spawns": ["type": "array", "items": spawn],
            "controls": ["type": "array", "items": control],
            "rules": ["type": "array", "items": rule],
            "hud": ["type": "array", "items": hud]
        ], required: [
            "version", "seed", "tickRate", "world", "variables", "templates",
            "spawns", "controls", "rules", "hud"
        ])
    }
}
