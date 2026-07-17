import Foundation

extension OpenAIAppGenerationClient {
    static var responseSchema: [String: Any] {
        let string: [String: Any] = ["type": "string"]
        let boolean: [String: Any] = ["type": "boolean"]
        let stringArray: [String: Any] = ["type": "array", "items": string]
        let theme: [String: Any] = [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "preset": ["type": "string", "enum": VisualThemePreset.allCases.map(\.rawValue)],
                "appearance": ["type": "string", "enum": ThemeAppearance.allCases.map(\.rawValue)],
                "typography": ["type": "string", "enum": ThemeTypography.allCases.map(\.rawValue)],
                "background": ["type": "string", "enum": ThemeBackground.allCases.map(\.rawValue)],
                "cornerStyle": ["type": "string", "enum": ThemeCornerStyle.allCases.map(\.rawValue)],
                "density": ["type": "string", "enum": ThemeDensity.allCases.map(\.rawValue)],
                "defaultSurface": ["type": "string", "enum": ComponentSurface.allCases.map(\.rawValue)]
            ],
            "required": [
                "preset", "appearance", "typography", "background",
                "cornerStyle", "density", "defaultSurface"
            ]
        ]
        let pageDesign: [String: Any] = [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "layout": ["type": "string", "enum": PageLayout.allCases.map(\.rawValue)],
                "showsNavigationTitle": boolean
            ],
            "required": ["layout", "showsNavigationTitle"]
        ]
        let nodeDesign: [String: Any] = [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "surface": ["type": "string", "enum": ComponentSurface.allCases.map(\.rawValue)],
                "span": ["type": "string", "enum": ComponentSpan.allCases.map(\.rawValue)],
                "alignment": ["type": "string", "enum": ComponentAlignment.allCases.map(\.rawValue)],
                "emphasis": ["type": "string", "enum": ComponentEmphasis.allCases.map(\.rawValue)],
                "variant": ["type": "string", "enum": ComponentVariant.allCases.map(\.rawValue)]
            ],
            "required": ["surface", "span", "alignment", "emphasis", "variant"]
        ]
        let image: [String: Any] = [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "aspect": ["type": "string", "enum": ImageAspect.allCases.map(\.rawValue)],
                "contentMode": ["type": "string", "enum": ImageContentMode.allCases.map(\.rawValue)],
                "altText": string,
                "decorative": boolean,
                "allowsUserSelection": boolean
            ],
            "required": ["aspect", "contentMode", "altText", "decorative", "allowsUserSelection"]
        ]
        let collection: [String: Any] = [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "itemName": string,
                "titleLabel": string,
                "noteLabel": string,
                "valueLabel": string,
                "valueKind": ["type": "string", "enum": RecordValueKind.allCases.map(\.rawValue)],
                "valueUnit": string,
                "dateLabel": string,
                "dateKind": ["type": "string", "enum": RecordDateKind.allCases.map(\.rawValue)],
                "aggregate": ["type": "string", "enum": RecordAggregate.allCases.map(\.rawValue)],
                "allowsCompletion": boolean,
                "allowsReminders": boolean
            ],
            "required": [
                "itemName", "titleLabel", "noteLabel", "valueLabel", "valueKind", "valueUnit",
                "dateLabel", "dateKind", "aggregate", "allowsCompletion", "allowsReminders"
            ]
        ]
        let liveData: [String: Any] = [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "resource": ["type": "string", "enum": LiveResourceKind.allCases.map(\.rawValue)],
                "primaryValue": string,
                "initialSymbols": stringArray,
                "allowsPrimarySelection": boolean,
                "allowsItemEditing": boolean,
                "allowsThresholds": boolean
            ],
            "required": [
                "resource", "primaryValue", "initialSymbols", "allowsPrimarySelection",
                "allowsItemEditing", "allowsThresholds"
            ]
        ]
        let item: [String: Any] = [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "id": string,
                "title": string,
                "subtitle": string,
                "value": string,
                "symbol": ["type": "string", "enum": Array(GeneratedAppPayload.allowedSymbols).sorted()],
                "isComplete": ["type": "boolean"]
            ],
            "required": ["id", "title", "subtitle", "value", "symbol", "isComplete"]
        ]
        let action: [String: Any] = [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "type": ["type": "string", "enum": RuntimeActionType.allCases.map(\.rawValue)],
                "target": string,
                "value": string
            ],
            "required": ["type", "target", "value"]
        ]
        let node: [String: Any] = [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "id": string,
                "kind": ["type": "string", "enum": ComponentKind.allCases.map(\.rawValue)],
                "title": string,
                "subtitle": string,
                "symbol": ["type": "string", "enum": Array(GeneratedAppPayload.allowedSymbols).sorted()],
                "value": string,
                "placeholder": string,
                "binding": string,
                "options": stringArray,
                "items": ["type": "array", "items": item],
                "action": action,
                "presentation": nodeDesign,
                "image": image,
                "collection": collection,
                "liveData": liveData
            ],
            "required": [
                "id", "kind", "title", "subtitle", "symbol", "value",
                "placeholder", "binding", "options", "items", "action",
                "presentation", "image", "collection", "liveData"
            ]
        ]
        let page: [String: Any] = [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "id": string,
                "title": string,
                "nodes": ["type": "array", "items": node],
                "presentation": pageDesign
            ],
            "required": ["id", "title", "nodes", "presentation"]
        ]
        let stateEntry: [String: Any] = [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "key": string,
                "value": string
            ],
            "required": ["key", "value"]
        ]

        return [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "name": string,
                "summary": string,
                "symbol": ["type": "string", "enum": Array(GeneratedAppPayload.allowedSymbols).sorted()],
                "tint": ["type": "string", "enum": AppTint.allCases.map(\.rawValue)],
                "theme": theme,
                "capabilities": [
                    "type": "array",
                    "items": ["type": "string", "enum": AppCapability.allCases.map(\.rawValue)]
                ],
                "startPageID": string,
                "initialState": ["type": "array", "items": stateEntry],
                "pages": ["type": "array", "items": page]
            ],
            "required": [
                "name", "summary", "symbol", "tint", "theme", "capabilities",
                "startPageID", "initialState", "pages"
            ]
        ]
    }
}
