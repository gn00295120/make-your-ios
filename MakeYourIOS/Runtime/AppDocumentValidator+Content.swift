import Foundation

extension AppDocumentValidator {
    func validateContent(_ document: AppDocument) throws {
        for node in document.pages.flatMap(\.nodes) {
            try validateNode(node)
        }
        try validateActions(document)
    }

    private func validateNode(_ node: ComponentNode) throws {
        guard node.title.count <= 120,
              node.subtitle.count <= 320,
              node.value.count <= 800,
              node.placeholder.count <= 160,
              node.binding.count <= 120,
              node.items.count <= Self.maximumItemsPerNode else {
            throw AppDocumentValidationError.contentLimitExceeded
        }
        try validateSpecializedConfiguration(node)
        try validateVisualOrAI(node)
        try validateStatefulRuntime(node)
    }

    private func validateVisualOrAI(_ node: ComponentNode) throws {
        switch node.kind {
        case .image: try validateImage(node)
        case .aiAssistant: try validateAIAssistant(node)
        default: break
        }
    }

    private func validateStatefulRuntime(_ node: ComponentNode) throws {
        switch node.kind {
        case .recordCollection: try validateCollection(node)
        case .liveDataList: try validateLiveData(node)
        case .newsFeed: try validateNews(node)
        case .marketWatch: try validateMarket(node)
        case .ledger: try validateLedger(node)
        case .game: try validateGame(node)
        case .deviceInput: try validateDeviceInput(node)
        default: break
        }
    }

    private func validateImage(_ node: ComponentNode) throws {
        guard let image = node.image,
              !node.binding.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              image.decorative
                || !image.altText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppDocumentValidationError.invalidComponentConfiguration(.image)
        }
    }

    private func validateAIAssistant(_ node: ComponentNode) throws {
        guard !node.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppDocumentValidationError.invalidComponentConfiguration(.aiAssistant)
        }
    }

    private func validateCollection(_ node: ComponentNode) throws {
        guard let collection = node.collection,
              !collection.itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !collection.titleLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              collection.itemName.count <= 40,
              collection.titleLabel.count <= 60,
              collection.noteLabel.count <= 60,
              collection.valueLabel.count <= 60,
              collection.valueUnit.count <= 12,
              collection.dateLabel.count <= 60,
              collection.aggregate != .sum || collection.valueKind != .none else {
            throw AppDocumentValidationError.invalidComponentConfiguration(.recordCollection)
        }
    }

    private func validateLiveData(_ node: ComponentNode) throws {
        guard let liveData = node.liveData,
              Self.isCurrencyCode(liveData.primaryValue),
              !liveData.initialSymbols.isEmpty,
              liveData.initialSymbols.count <= 30,
              liveData.initialSymbols.allSatisfy(Self.isCurrencyCode),
              !liveData.initialSymbols.contains(liveData.primaryValue.uppercased()) else {
            throw AppDocumentValidationError.invalidComponentConfiguration(.liveDataList)
        }
    }

    private func validateNews(_ node: ComponentNode) throws {
        guard let newsFeed = node.newsFeed,
              !newsFeed.sources.isEmpty,
              newsFeed.sources.count <= NewsSourceKind.allCases.count,
              Set(newsFeed.sources).count == newsFeed.sources.count,
              newsFeed.topics.count <= 8,
              newsFeed.topics.allSatisfy({ !$0.isEmpty && $0.count <= 40 }),
              (5...40).contains(newsFeed.maximumItems) else {
            throw AppDocumentValidationError.invalidComponentConfiguration(.newsFeed)
        }
    }

    private func validateMarket(_ node: ComponentNode) throws {
        guard let marketWatch = node.marketWatch,
              !marketWatch.initialSymbols.isEmpty,
              marketWatch.initialSymbols.count <= 10,
              marketWatch.initialSymbols.allSatisfy(Self.isMarketSymbol),
              Set(marketWatch.initialSymbols).count == marketWatch.initialSymbols.count else {
            throw AppDocumentValidationError.invalidComponentConfiguration(.marketWatch)
        }
    }

    private func validateLedger(_ node: ComponentNode) throws {
        guard let ledger = node.ledger,
              Self.isCurrencyCode(ledger.currencyCode),
              !ledger.categories.isEmpty,
              ledger.categories.count <= 16,
              ledger.categories.allSatisfy({ !$0.isEmpty && $0.count <= 30 }),
              Set(ledger.categories.map { $0.lowercased() }).count == ledger.categories.count,
              ledger.monthlyBudget.isFinite,
              ledger.monthlyBudget >= 0,
              ledger.initialEntries.count <= 30,
              ledger.initialEntries.allSatisfy({ Self.isValid($0, in: ledger) }) else {
            throw AppDocumentValidationError.invalidComponentConfiguration(.ledger)
        }
    }

    private func validateGame(_ node: ComponentNode) throws {
        guard let game = node.game,
              (1...100).contains(game.targetScore),
              (0...999_999).contains(game.levelSeed),
              !game.playerName.isEmpty,
              game.playerName.count <= 30,
              !game.collectibleName.isEmpty,
              game.collectibleName.count <= 30 else {
            throw AppDocumentValidationError.invalidComponentConfiguration(.game)
        }
    }

    private func validateDeviceInput(_ node: ComponentNode) throws {
        guard !node.binding.isEmpty,
              let input = node.deviceInput,
              !input.buttonLabel.isEmpty,
              input.buttonLabel.count <= 60,
              !input.resultLabel.isEmpty,
              input.resultLabel.count <= 60,
              ![.shareText, .copyText].contains(input.kind)
                || !node.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppDocumentValidationError.invalidComponentConfiguration(.deviceInput)
        }
    }

    private func validateSpecializedConfiguration(_ node: ComponentNode) throws {
        let configurations: [(ComponentKind, Bool)] = [
            (.image, node.image != nil),
            (.recordCollection, node.collection != nil),
            (.liveDataList, node.liveData != nil),
            (.newsFeed, node.newsFeed != nil),
            (.marketWatch, node.marketWatch != nil),
            (.ledger, node.ledger != nil),
            (.game, node.game != nil),
            (.deviceInput, node.deviceInput != nil)
        ]
        let configuredKinds = configurations.compactMap { $0.1 ? $0.0 : nil }
        let specializedKinds = Set(configurations.map { $0.0 })
        if specializedKinds.contains(node.kind) {
            guard configuredKinds == [node.kind] else {
                throw AppDocumentValidationError.invalidComponentConfiguration(node.kind)
            }
        } else if !configuredKinds.isEmpty {
            throw AppDocumentValidationError.invalidComponentConfiguration(node.kind)
        }
    }

    private static func isValid(_ entry: LedgerSeedEntry, in ledger: LedgerSpec) -> Bool {
        !entry.title.isEmpty
            && entry.title.count <= 80
            && entry.note.count <= 160
            && entry.amount.isFinite
            && entry.amount >= 0
            && ledger.categories.contains(entry.category)
            && isISODate(entry.date)
            && (ledger.allowsIncome || entry.type == .expense)
    }

    private static func isCurrencyCode(_ value: String) -> Bool {
        let code = value.uppercased()
        return code.count == 3 && code.allSatisfy(\.isLetter)
    }

    private static func isMarketSymbol(_ value: String) -> Bool {
        guard (1...15).contains(value.count), value == value.uppercased() else { return false }
        return value.allSatisfy { character in
            character.isLetter || character.isNumber || ".-^".contains(character)
        }
    }

    private static func isISODate(_ value: String) -> Bool {
        let parts = value.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              parts[0].count == 4,
              parts[1].count == 2,
              parts[2].count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            return false
        }
        let calendar = Calendar(identifier: .gregorian)
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            return false
        }
        let resolved = calendar.dateComponents([.year, .month, .day], from: date)
        return resolved.year == year && resolved.month == month && resolved.day == day
    }
}
