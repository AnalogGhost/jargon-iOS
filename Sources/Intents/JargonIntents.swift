import AppIntents
import Foundation

/// Exposes dictionary entries to Siri, Shortcuts and Spotlight. App Intents run in the
/// app's own process, so they read the same bundled dictionary through DictionaryCache.
struct EntryEntity: AppEntity {
    let id: String
    let term: String
    let definition: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Jargon Entry"
    static var defaultQuery = EntryEntityQuery()

    init(_ entry: DictionaryEntry) {
        id = entry.id
        term = entry.term
        definition = entry.definition
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(term)", subtitle: "\(String(definition.prefix(80)))")
    }
}

struct EntryEntityQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [EntryEntity] {
        let wanted = Set(identifiers)
        return try await DictionaryCache.shared.entries()
            .filter { wanted.contains($0.id) }
            .map(EntryEntity.init)
    }

    /// Exact term first, then the same term/definition search the app's search field runs.
    func entities(matching string: String) async throws -> [EntryEntity] {
        let entries = try await DictionaryCache.shared.entries()
        var results = filterByQuery(entries, query: string)
        if let exact = findByTermText(entries, term: string.trimmingCharacters(in: .whitespacesAndNewlines)) {
            results.removeAll { $0.id == exact.id }
            results.insert(exact, at: 0)
        }
        return results.prefix(25).map(EntryEntity.init)
    }

    func suggestedEntities() async throws -> [EntryEntity] {
        let entries = try await DictionaryCache.shared.entries()
        let favoriteIds = Set(UserDefaults.standard.stringArray(forKey: FavoritesRepository.favoriteIdsKey) ?? [])
        var suggested = entries.filter { favoriteIds.contains($0.id) }
        if let today = WordOfTheDay.entry(for: Date(), in: entries), !favoriteIds.contains(today.id) {
            suggested.insert(today, at: 0)
        }
        return suggested.map(EntryEntity.init)
    }
}

/// Speaks or shows a definition without opening the app.
struct DefineTermIntent: AppIntent {
    static var title: LocalizedStringResource = "Look Up a Term"
    static var description = IntentDescription("Looks up a term in the Jargon File and returns its definition.")

    @Parameter(title: "Term", requestValueDialog: "Which term?")
    var entry: EntryEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Look up \(\.$entry)")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        .result(value: entry.definition, dialog: "\(entry.term): \(spokenDefinition(entry.definition))")
    }
}

/// Opens the app on the chosen entry.
struct OpenEntryIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Entry"
    static var description = IntentDescription("Opens a Jargon File entry in Jargon.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Entry", requestValueDialog: "Which entry?")
    var entry: EntryEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$entry)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        PendingLaunch.shared.pending = .entry(entry.id)
        return .result()
    }
}

/// The same as the "Random entry" quick action.
struct RandomEntryIntent: AppIntent {
    static var title: LocalizedStringResource = "Random Entry"
    static var description = IntentDescription("Opens a random Jargon File entry.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        PendingLaunch.shared.pending = .randomEntry
        return .result()
    }
}

/// Today's entry, the same one the widget shows.
struct WordOfTheDayIntent: AppIntent {
    static var title: LocalizedStringResource = "Word of the Day"
    static var description = IntentDescription("Returns today's Jargon File entry, the same one the widget shows.")

    func perform() async throws -> some IntentResult & ReturnsValue<EntryEntity> & ProvidesDialog {
        let entries = try await DictionaryCache.shared.entries()
        guard let today = WordOfTheDay.entry(for: Date(), in: entries) else {
            throw DictionaryRepositoryError.missingResource
        }
        return .result(value: EntryEntity(today), dialog: "\(today.term): \(spokenDefinition(today.definition))")
    }
}

/// Some definitions run to several paragraphs; Siri reads the first couple of sentences.
func spokenDefinition(_ definition: String, limit: Int = 300) -> String {
    guard definition.count > limit else { return definition }
    let head = definition.prefix(limit)
    if let end = head.lastIndex(where: { ".!?".contains($0) }), head.distance(from: head.startIndex, to: end) > limit / 3 {
        return String(head[...end])
    }
    return head.trimmingCharacters(in: .whitespaces) + "…"
}

struct JargonShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: DefineTermIntent(),
            phrases: [
                "Look up a term in \(.applicationName)",
                "Define a term in \(.applicationName)",
                "Look up \(\.$entry) in \(.applicationName)",
            ],
            shortTitle: "Look Up a Term",
            systemImageName: "text.book.closed"
        )
        AppShortcut(
            intent: WordOfTheDayIntent(),
            phrases: [
                "What's the word of the day in \(.applicationName)",
                "\(.applicationName) word of the day",
            ],
            shortTitle: "Word of the Day",
            systemImageName: "calendar"
        )
        AppShortcut(
            intent: RandomEntryIntent(),
            phrases: [
                "Show me a random entry in \(.applicationName)",
                "Surprise me with \(.applicationName)",
            ],
            shortTitle: "Random Entry",
            systemImageName: "shuffle"
        )
        AppShortcut(
            intent: OpenEntryIntent(),
            phrases: [
                "Open \(\.$entry) in \(.applicationName)",
            ],
            shortTitle: "Open Entry",
            systemImageName: "book"
        )
    }
}
