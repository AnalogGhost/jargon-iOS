import XCTest
@testable import Jargon

final class SearchHistoryTests: XCTestCase {
    func testAddsANewQueryToTheFrontOfEmptyHistory() {
        XCTAssertEqual(updatedSearchHistory([], adding: "hacker"), ["hacker"])
    }

    func testMostRecentQueryComesFirst() {
        let history = updatedSearchHistory(updatedSearchHistory([], adding: "foo"), adding: "bar")
        XCTAssertEqual(history, ["bar", "foo"])
    }

    func testReSearchingAnExistingTermMovesItToTheFrontWithoutDuplicating() {
        let history = ["kludge", "hacker", "foo"]
        XCTAssertEqual(updatedSearchHistory(history, adding: "hacker"), ["hacker", "kludge", "foo"])
    }

    func testDuplicateDetectionIsCaseInsensitive() {
        XCTAssertEqual(updatedSearchHistory(["Hacker", "kludge"], adding: "HACKER"), ["HACKER", "kludge"])
    }

    func testQueryIsTrimmedBeforeStoring() {
        XCTAssertEqual(updatedSearchHistory([], adding: "  hacker  "), ["hacker"])
    }

    func testBlankOrWhitespaceOnlyQueriesAreIgnored() {
        let history = ["hacker"]
        XCTAssertEqual(updatedSearchHistory(history, adding: ""), history)
        XCTAssertEqual(updatedSearchHistory(history, adding: "   "), history)
    }

    func testHistoryIsCappedAtMaxRecentSearchesDroppingTheOldest() {
        var history: [String] = []
        for i in 1...(maxRecentSearches + 3) {
            history = updatedSearchHistory(history, adding: "q\(i)")
        }
        XCTAssertEqual(history.count, maxRecentSearches)
        XCTAssertEqual(history.first, "q\(maxRecentSearches + 3)")
        XCTAssertEqual(history.last, "q4")
    }
}
