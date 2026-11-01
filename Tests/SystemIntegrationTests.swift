import CoreSpotlight
import XCTest
@testable import Jargon

final class WordOfTheDayTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Denver")!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func entry(_ id: String, definitionLength: Int) -> DictionaryEntry {
        DictionaryEntry(id: id, term: id, sortKey: id, definition: String(repeating: "x", count: definitionLength))
    }

    func testSameDayGivesTheSameEntryAtAnyHour() {
        let entries = (0..<50).map { entry("e\($0)", definitionLength: 200) }
        let morning = WordOfTheDay.entry(for: date(2026, 11, 1, hour: 0), in: entries, calendar: calendar)
        let night = WordOfTheDay.entry(for: date(2026, 11, 1, hour: 23), in: entries, calendar: calendar)
        XCTAssertEqual(morning, night)
    }

    func testConsecutiveDaysUsuallyDiffer() {
        let entries = (0..<500).map { entry("e\($0)", definitionLength: 200) }
        let ids = (1...30).compactMap { WordOfTheDay.entry(for: date(2026, 11, $0), in: entries, calendar: calendar)?.id }
        XCTAssertGreaterThan(Set(ids).count, 25)
    }

    func testShortRedirectDefinitionsAreNeverChosen() {
        let entries = [entry("stub", definitionLength: 20), entry("real", definitionLength: 300)]
        for day in 1...30 {
            XCTAssertEqual(WordOfTheDay.entry(for: date(2026, 11, day), in: entries, calendar: calendar)?.id, "real")
        }
    }

    func testNoEligibleEntriesGivesNil() {
        XCTAssertNil(WordOfTheDay.entry(for: Date(), in: [entry("stub", definitionLength: 5)]))
    }

    func testIndexStaysInRange() {
        for day in -1000...1000 {
            XCTAssert((0..<7).contains(WordOfTheDay.index(for: day, count: 7)))
        }
    }
}

final class EntryLinkTests: XCTestCase {
    func testRoundTripsAnEntryId() {
        for id in ["hacker", "one-TBS", "AI-complete", "numeral-zero", "foo_bar"] {
            XCTAssertEqual(EntryLink.entryId(from: EntryLink.url(forEntryId: id)), id)
        }
    }

    func testUsesTheJargonScheme() {
        XCTAssertEqual(EntryLink.url(forEntryId: "hacker").absoluteString, "jargon://entry/hacker")
    }

    func testIgnoresOtherLinks() {
        XCTAssertNil(EntryLink.entryId(from: URL(string: "jargon-term://term/hacker")!))
        XCTAssertNil(EntryLink.entryId(from: URL(string: "jargon://search/hacker")!))
        XCTAssertNil(EntryLink.entryId(from: URL(string: "jargon://entry/")!))
    }
}

final class SpotlightIndexerTests: XCTestCase {
    func testItemCarriesTheEntryIdAndTerm() {
        let entry = DictionaryEntry(id: "kludge", term: "kludge", sortKey: "kludge", definition: "an inelegant solution")
        let item = SpotlightIndexer.searchableItem(for: entry)
        XCTAssertEqual(item.uniqueIdentifier, "kludge")
        XCTAssertEqual(item.domainIdentifier, SpotlightIndexer.domainIdentifier)
        XCTAssertEqual(item.attributeSet.title, "kludge")
        XCTAssertEqual(item.attributeSet.contentDescription, "an inelegant solution")
    }

    func testOpeningAResultTargetsThatEntry() {
        let activity = NSUserActivity(activityType: CSSearchableItemActionType)
        activity.userInfo = [CSSearchableItemActivityIdentifier: "kludge"]
        XCTAssertEqual(SpotlightIndexer.launchTarget(for: activity), .entry("kludge"))
    }

    func testSearchInAppCarriesTheQuery() {
        let activity = NSUserActivity(activityType: CSQueryContinuationActionType)
        activity.userInfo = [CSSearchQueryString: "grok"]
        XCTAssertEqual(SpotlightIndexer.launchTarget(for: activity), .search("grok"))
    }

    func testIndexVersionChangesWithTheDictionary() {
        XCTAssertNotEqual(SpotlightIndexer.indexVersion(entryCount: 2307), SpotlightIndexer.indexVersion(entryCount: 2308))
    }
}

final class SpokenDefinitionTests: XCTestCase {
    func testShortDefinitionsAreReadInFull() {
        XCTAssertEqual(spokenDefinition("An inelegant solution."), "An inelegant solution.")
    }

    func testLongDefinitionsStopAtASentenceEnd() {
        let first = String(repeating: "word ", count: 30) + "end."
        let spoken = spokenDefinition(first + " " + String(repeating: "more ", count: 100))
        XCTAssertEqual(spoken, first)
    }

    func testRunOnDefinitionsAreCutWithAnEllipsis() {
        let spoken = spokenDefinition(String(repeating: "word ", count: 200))
        XCTAssertTrue(spoken.hasSuffix("…"))
        XCTAssertLessThanOrEqual(spoken.count, 301)
    }
}

final class EntryEntityQueryTests: XCTestCase {
    func testExactTermComesFirst() async throws {
        let results = try await EntryEntityQuery().entities(matching: "hack")
        XCTAssertEqual(results.first?.term, "hack")
    }

    func testLooksUpByIdentifier() async throws {
        let results = try await EntryEntityQuery().entities(for: ["kludge", "grok"])
        XCTAssertEqual(Set(results.map(\.id)), ["kludge", "grok"])
    }
}
