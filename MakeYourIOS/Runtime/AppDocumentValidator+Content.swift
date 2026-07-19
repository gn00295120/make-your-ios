import Foundation

extension AppDocumentValidator {
    func validateContent(_ document: AppDocument) throws {
        for node in document.pages.flatMap(\.nodes) {
            try validateNode(node)
        }
        try validateSpeechTranscriptReferences(document)
        try validateShortcutAccess(document)
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
        case .hero where node.image != nil: try validateImage(node)
        case .aiAssistant: try validateAIAssistant(node)
        default: break
        }
    }

    // Exhaustive interpreter dispatch: every stateful generated component has one validator.
    // swiftlint:disable:next cyclomatic_complexity
    private func validateStatefulRuntime(_ node: ComponentNode) throws {
        switch node.kind {
        case .recordCollection: try validateCollection(node)
        case .liveDataList: try validateLiveData(node)
        case .newsFeed: try validateNews(node)
        case .marketWatch: try validateMarket(node)
        case .ledger: try validateLedger(node)
        case .game: try validateGame(node)
        case .deviceInput: try validateDeviceInput(node)
        case .control: break
        case .map: try validateMap(node)
        case .calendarEvent: try validateCalendarEvent(node)
        case .documentExport: try validateDocumentExport(node)
        case .voiceNote: try validateVoiceNote(node)
        case .speechTranscript: try validateSpeechTranscript(node)
        case .currencyConverter: try validateCurrencyConverter(node)
        default: break
        }
    }

    private func validateCurrencyConverter(_ node: ComponentNode) throws {
        let currencies = CurrencyCalculator.normalizedCurrencyCodes(node.options)
        let rates = CurrencyCalculator.rateTable(items: node.items, currencies: currencies)
        guard (2...20).contains(currencies.count),
              currencies.count == node.options.count,
              rates.count == currencies.count else {
            throw AppDocumentValidationError.invalidComponentConfiguration(.currencyConverter)
        }
    }

    private func validateImage(_ node: ComponentNode) throws {
        guard let image = node.image,
              !node.binding.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              image.altText.count <= 180,
              image.decorative
                || !image.altText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              image.resolvedMediaRole != .decorative || image.decorative else {
            throw AppDocumentValidationError.invalidComponentConfiguration(node.kind)
        }
    }

    private func validateAIAssistant(_ node: ComponentNode) throws {
        guard !node.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              node.valueBinding?.isEmpty != false || node.valueBinding != node.binding else {
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
        switch game.kind {
        case .snake, .platformer:
            guard game.program == nil else {
                throw AppDocumentValidationError.invalidComponentConfiguration(.game)
            }
        case .custom:
            guard let program = game.program,
                  (try? TinyGameCompiler().compile(program)) != nil else {
                throw AppDocumentValidationError.invalidComponentConfiguration(.game)
            }
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

    private func validateMap(_ node: ComponentNode) throws {
        guard let map = node.map,
              map.latitude.isFinite,
              (-90...90).contains(map.latitude),
              map.longitude.isFinite,
              (-180...180).contains(map.longitude),
              map.spanMeters.isFinite,
              (250...100_000).contains(map.spanMeters),
              map.query.count <= 120,
              map.mode != .placeSearch
                || !map.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppDocumentValidationError.invalidComponentConfiguration(.map)
        }
    }

    private func validateCalendarEvent(_ node: ComponentNode) throws {
        guard let event = node.calendarEvent,
              !event.eventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              event.eventTitle.count <= 120,
              event.notes.count <= 500,
              event.location.count <= 160,
              (0...10_080).contains(event.startOffsetMinutes),
              (5...1_440).contains(event.durationMinutes) else {
            throw AppDocumentValidationError.invalidComponentConfiguration(.calendarEvent)
        }
    }

    private func validateDocumentExport(_ node: ComponentNode) throws {
        guard let export = node.documentExport,
              !export.fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              export.fileName.count <= 80,
              !export.fileName.contains("/"),
              !export.fileName.contains("\\"),
              export.fileName.unicodeScalars.allSatisfy({ $0.value >= 32 && $0.value != 127 }),
              export.contentTemplate.count <= RuntimeLogicEngine.maximumValueLength,
              !export.contentTemplate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !export.buttonLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              export.buttonLabel.count <= 60 else {
            throw AppDocumentValidationError.invalidComponentConfiguration(.documentExport)
        }
    }

    private func validateVoiceNote(_ node: ComponentNode) throws {
        guard let voiceNote = node.voiceNote,
              !node.binding.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              (5...60).contains(voiceNote.maximumDurationSeconds),
              !voiceNote.recordButtonLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              voiceNote.recordButtonLabel.count <= 60 else {
            throw AppDocumentValidationError.invalidComponentConfiguration(.voiceNote)
        }
    }

    private func validateSpeechTranscript(_ node: ComponentNode) throws {
        guard let transcript = node.speechTranscript,
              !node.binding.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !transcript.sourceBinding.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              transcript.sourceBinding.count <= 120,
              transcript.sourceBinding != node.binding,
              RuntimeSpeechLocale.isValid(transcript.localeIdentifier),
              !transcript.buttonLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              transcript.buttonLabel.count <= 60 else {
            throw AppDocumentValidationError.invalidComponentConfiguration(.speechTranscript)
        }
    }

    private func validateSpeechTranscriptReferences(_ document: AppDocument) throws {
        let nodes = document.pages.flatMap(\.nodes)
        let voiceBindings = Set(
            nodes.filter { $0.kind == .voiceNote }.map(\.binding)
        )
        let stateTypes = (document.logic?.state ?? []).reduce(into: [:]) { result, definition in
            result[definition.key] = definition.type
        }
        for node in nodes where node.kind == .speechTranscript {
            guard let sourceBinding = node.speechTranscript?.sourceBinding,
                  voiceBindings.contains(sourceBinding),
                  stateTypes[node.binding] == .text else {
                throw AppDocumentValidationError.invalidComponentConfiguration(.speechTranscript)
            }
        }
    }

    private func validateShortcutAccess(_ document: AppDocument) throws {
        let nodes = document.pages.flatMap(\.nodes).filter { $0.kind == .shortcutAccess }
        guard nodes.count <= 1 else {
            throw AppDocumentValidationError.invalidComponentConfiguration(.shortcutAccess)
        }
        guard let node = nodes.first else { return }
        guard !node.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              node.binding.isEmpty,
              node.value.isEmpty,
              node.placeholder.isEmpty,
              node.options.isEmpty,
              node.items.isEmpty,
              node.action == .none,
              node.valueBinding?.isEmpty != false,
              node.events?.isEmpty != false else {
            throw AppDocumentValidationError.invalidComponentConfiguration(.shortcutAccess)
        }
    }

    private func validateSpecializedConfiguration(_ node: ComponentNode) throws {
        let configurations: [(ComponentKind, Bool)] = [
            (.recordCollection, node.collection != nil),
            (.liveDataList, node.liveData != nil),
            (.newsFeed, node.newsFeed != nil),
            (.marketWatch, node.marketWatch != nil),
            (.ledger, node.ledger != nil),
            (.game, node.game != nil),
            (.deviceInput, node.deviceInput != nil),
            (.control, node.control != nil),
            (.map, node.map != nil),
            (.calendarEvent, node.calendarEvent != nil),
            (.documentExport, node.documentExport != nil),
            (.voiceNote, node.voiceNote != nil),
            (.speechTranscript, node.speechTranscript != nil)
        ]
        let configuredKinds = configurations.compactMap { $0.1 ? $0.0 : nil }
        let specializedKinds = Set(configurations.map { $0.0 })
        if specializedKinds.contains(node.kind) {
            guard configuredKinds == [node.kind], node.image == nil else {
                throw AppDocumentValidationError.invalidComponentConfiguration(node.kind)
            }
        } else if !configuredKinds.isEmpty {
            throw AppDocumentValidationError.invalidComponentConfiguration(node.kind)
        }

        switch node.kind {
        case .image:
            guard node.image != nil else {
                throw AppDocumentValidationError.invalidComponentConfiguration(.image)
            }
        case .hero:
            break
        default:
            guard node.image == nil else {
                throw AppDocumentValidationError.invalidComponentConfiguration(node.kind)
            }
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
