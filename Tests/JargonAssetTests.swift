import XCTest
@testable import Jargon

final class JargonAssetTests: XCTestCase {
    private lazy var entries: [DictionaryEntry] = {
        guard let url = Bundle.main.url(forResource: "jargon", withExtension: "json") else {
            XCTFail("jargon.json asset is missing")
            return []
        }
        let data = try! Data(contentsOf: url)
        return try! JSONDecoder().decode([DictionaryEntry].self, from: data)
    }()

    func testHasASubstantialNumberOfEntries() {
        XCTAssertGreaterThanOrEqual(entries.count, 2000, "expected at least 2000 entries, got \(entries.count)")
    }

    func testEntryIdsAreUnique() {
        let ids = entries.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testEveryEntryHasANonBlankTermSortKeyAndDefinition() {
        for entry in entries {
            XCTAssertFalse(entry.term.trimmingCharacters(in: .whitespaces).isEmpty, "entry \(entry.id) has a blank term")
            XCTAssertFalse(entry.sortKey.trimmingCharacters(in: .whitespaces).isEmpty, "entry \(entry.id) has a blank sortKey")
            XCTAssertFalse(entry.definition.trimmingCharacters(in: .whitespaces).isEmpty, "entry \(entry.id) has a blank definition")
        }
    }

    func testEntriesAreSortedBySortKey() {
        let sortKeys = entries.map(\.sortKey)
        XCTAssertEqual(sortKeys, sortKeys.sorted())
    }

    /// A handful of upstream cross-references don't exactly match their target's term text
    /// (e.g. "ID10T" referencing the entry titled "ID10T error") -- that's a content quirk,
    /// not a parser bug, and the app's cross-reference tap falls back to search for those.
    /// This guards against the resolution rate collapsing, which would signal a real parser regression.
    func testNearlyAllSeeAlsoReferencesResolveToARealEntry() {
        let termsLower = Set(entries.map { $0.term.lowercased() })
        let allRefs = entries.flatMap(\.seeAlso)
        let resolved = allRefs.filter { termsLower.contains($0.lowercased()) }.count
        let rate = Double(resolved) / Double(allRefs.count)
        XCTAssertGreaterThanOrEqual(rate, 0.99, "seeAlso resolution rate dropped to \(rate * 100)%")
    }

    func testAWellKnownEntryParsesAsExpected() {
        let hacker = entries.first { $0.id == "hacker" }
        XCTAssertNotNil(hacker, "expected an entry with id 'hacker'")
        XCTAssertEqual(hacker?.term, "hacker")
        XCTAssertFalse(hacker?.definition.isEmpty ?? true)
    }
}
