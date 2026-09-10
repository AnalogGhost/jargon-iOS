import XCTest
@testable import Jargon

final class EntryShareTextTests: XCTestCase {
    func testPlainEntryIsTermThenDefinitionThenCredit() {
        let entry = DictionaryEntry(
            id: "kludge", term: "kludge", sortKey: "kludge",
            definition: "an inelegant solution"
        )
        XCTAssertEqual(entry.shareText, "kludge\n\nan inelegant solution\n\n— The Jargon File")
    }

    func testPronunciationAndPartOfSpeechAppearOnTheTermLine() {
        let entry = DictionaryEntry(
            id: "hacker", term: "hacker", sortKey: "hacker",
            pronunciation: "/hak'r/", partOfSpeech: "n.",
            definition: "someone who enjoys programming"
        )
        XCTAssertEqual(
            entry.shareText,
            "hacker  /hak'r/  ·  n.\n\nsomeone who enjoys programming\n\n— The Jargon File"
        )
    }

    func testASingleSubtitleFieldHasNoSeparator() {
        let entry = DictionaryEntry(
            id: "foo", term: "foo", sortKey: "foo",
            pronunciation: "/foo/",
            definition: "a metasyntactic variable"
        )
        XCTAssertEqual(
            entry.shareText,
            "foo  /foo/\n\na metasyntactic variable\n\n— The Jargon File"
        )
    }
}
