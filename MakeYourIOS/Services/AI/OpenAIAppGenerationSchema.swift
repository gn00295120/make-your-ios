import Foundation

extension OpenAIAppGenerationClient {
    static var responseSchema: [String: Any] {
        let string: [String: Any] = ["type": "string"]
        let boolean: [String: Any] = ["type": "boolean"]
        let number: [String: Any] = ["type": "number"]
        let integer: [String: Any] = ["type": "integer"]
        let stringArray: [String: Any] = ["type": "array", "items": string]
        func nullableObject(_ object: [String: Any]) -> [String: Any] {
            var result = object
            result["type"] = ["object", "null"]
            return result
        }
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
        let newsFeed: [String: Any] = [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "sources": [
                    "type": "array",
                    "items": ["type": "string", "enum": NewsSourceKind.allCases.map(\.rawValue)]
                ],
                "topics": stringArray,
                "allowsTopicEditing": boolean,
                "allowsBookmarks": boolean,
                "maximumItems": integer
            ],
            "required": [
                "sources", "topics", "allowsTopicEditing", "allowsBookmarks", "maximumItems"
            ]
        ]
        let marketWatch: [String: Any] = [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "provider": [
                    "type": "string",
                    "enum": MarketDataProviderKind.allCases.map(\.rawValue)
                ],
                "initialSymbols": stringArray,
                "allowsSymbolEditing": boolean,
                "showsChart": boolean,
                "range": ["type": "string", "enum": MarketRange.allCases.map(\.rawValue)]
            ],
            "required": [
                "provider", "initialSymbols", "allowsSymbolEditing", "showsChart", "range"
            ]
        ]
        let ledgerEntry: [String: Any] = [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "title": string,
                "note": string,
                "amount": number,
                "type": ["type": "string", "enum": LedgerEntryType.allCases.map(\.rawValue)],
                "category": string,
                "date": string
            ],
            "required": ["title", "note", "amount", "type", "category", "date"]
        ]
        let ledger: [String: Any] = [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "currencyCode": string,
                "categories": stringArray,
                "period": ["type": "string", "enum": LedgerPeriod.allCases.map(\.rawValue)],
                "monthlyBudget": number,
                "allowsIncome": boolean,
                "initialEntries": ["type": "array", "items": ledgerEntry]
            ],
            "required": [
                "currencyCode", "categories", "period", "monthlyBudget", "allowsIncome",
                "initialEntries"
            ]
        ]
        let game: [String: Any] = [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "kind": ["type": "string", "enum": GameKind.allCases.map(\.rawValue)],
                "difficulty": ["type": "string", "enum": GameDifficulty.allCases.map(\.rawValue)],
                "palette": ["type": "string", "enum": GamePalette.allCases.map(\.rawValue)],
                "targetScore": integer,
                "levelSeed": integer,
                "playerName": string,
                "collectibleName": string,
                "haptics": boolean
            ],
            "required": [
                "kind", "difficulty", "palette", "targetScore", "levelSeed", "playerName",
                "collectibleName", "haptics"
            ]
        ]
        let deviceInput: [String: Any] = [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "kind": ["type": "string", "enum": DeviceInputKind.allCases.map(\.rawValue)],
                "buttonLabel": string,
                "resultLabel": string,
                "allowsRepeat": boolean
            ],
            "required": ["kind", "buttonLabel", "resultLabel", "allowsRepeat"]
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
                "image": nullableObject(image),
                "collection": nullableObject(collection),
                "liveData": nullableObject(liveData),
                "newsFeed": nullableObject(newsFeed),
                "marketWatch": nullableObject(marketWatch),
                "ledger": nullableObject(ledger),
                "game": nullableObject(game),
                "deviceInput": nullableObject(deviceInput)
            ],
            "required": [
                "id", "kind", "title", "subtitle", "symbol", "value",
                "placeholder", "binding", "options", "items", "action",
                "presentation", "image", "collection", "liveData", "newsFeed",
                "marketWatch", "ledger", "game", "deviceInput"
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
