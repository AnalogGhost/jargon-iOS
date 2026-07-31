import XCTest
@testable import Jargon

private func entry(id: String, term: String, definition: String? = nil) -> DictionaryEntry {
    DictionaryEntry(id: id, term: term, sortKey: term.lowercased(), definition: definition ?? "def of \(term)")
}

final class EntryFiltersTests: XCTestCase {
    private let hacker = entry(id: "hacker", term: "hacker", definition: "someone who enjoys programming")
    private let cracker = entry(id: "cracker", term: "cracker", definition: "a malicious meddler, see hacker sense 8")
    private let kludge = entry(id: "kludge", term: "kludge", definition: "an inelegant solution")
    private lazy var all = [hacker, cracker, kludge]

    func testBlankQueryReturnsAllEntriesUnchanged() {
        XCTAssertEqual(filterByQuery(all, query: ""), all)
        XCTAssertEqual(filterByQuery(all, query: "   "), all)
    }

    func testTermMatchesAreCaseInsensitiveAndComeBeforeDefinitionOnlyMatches() {
        let result = filterByQuery(all, query: "HACKER")
        XCTAssertEqual(result, [hacker, cracker])
    }

    func testDefinitionOnlyMatchesAreNotDuplicatedAsTermMatches() {
        let result = filterByQuery(all, query: "malicious")
        XCTAssertEqual(result, [cracker])
    }

    func testNoMatchesReturnsAnEmptyList() {
        XCTAssertEqual(filterByQuery(all, query: "zzznotaword"), [])
    }

    func testFavoritesFilterPassesEverythingThroughWhenDisabled() {
        let result = filterFavorites(all, favoriteIds: [hacker.id], showFavoritesOnly: false)
        XCTAssertEqual(result, all)
    }

    func testFavoritesFilterKeepsOnlyFavoritedEntriesWhenEnabled() {
        let result = filterFavorites(all, favoriteIds: [hacker.id, kludge.id], showFavoritesOnly: true)
        XCTAssertEqual(result, [hacker, kludge])
    }

    func testFavoritesFilterReturnsEmptyListWhenNothingIsFavorited() {
        let result = filterFavorites(all, favoriteIds: [], showFavoritesOnly: true)
        XCTAssertEqual(result, [])
    }

    func testFindByTermTextMatchesCaseInsensitively() {
        XCTAssertEqual(findByTermText(all, term: "Hacker"), hacker)
        XCTAssertEqual(findByTermText(all, term: "HACKER"), hacker)
    }

    func testFindByTermTextReturnsNilWhenNoEntryHasThatExactTerm() {
        XCTAssertNil(findByTermText(all, term: "hack"))
        XCTAssertNil(findByTermText(all, term: "hackers"))
    }
}
