import Foundation

let maxRecentSearches = 8

/// Returns `current` with `query` inserted at the front: trimmed, blank queries
/// ignored, any existing case-insensitive duplicate removed so the list stays
/// most-recent-first with no repeats, and capped at `maxRecentSearches`
/// (dropping the oldest). Mirrors the Android app's `updatedSearchHistory`.
func updatedSearchHistory(_ current: [String], adding query: String) -> [String] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return current }
    let withoutDuplicate = current.filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
    return Array(([trimmed] + withoutDuplicate).prefix(maxRecentSearches))
}
