import Foundation

func filterByQuery(_ entries: [DictionaryEntry], query: String) -> [DictionaryEntry] {
    let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
    if q.isEmpty { return entries }

    let termMatches = entries.filter { $0.term.range(of: q, options: .caseInsensitive) != nil }
    let termMatchIds = Set(termMatches.map(\.id))
    let definitionMatches = entries.filter {
        !termMatchIds.contains($0.id) && $0.definition.range(of: q, options: .caseInsensitive) != nil
    }
    return termMatches + definitionMatches
}

func filterFavorites(
    _ entries: [DictionaryEntry],
    favoriteIds: Set<String>,
    showFavoritesOnly: Bool
) -> [DictionaryEntry] {
    guard showFavoritesOnly else { return entries }
    return entries.filter { favoriteIds.contains($0.id) }
}

func findByTermText(_ entries: [DictionaryEntry], term: String) -> DictionaryEntry? {
    entries.first { $0.term.caseInsensitiveCompare(term) == .orderedSame }
}
