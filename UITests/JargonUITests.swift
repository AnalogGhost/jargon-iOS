import XCTest

final class JargonUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchedApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    func testListLoadsWithSearchAndEntries() {
        let app = launchedApp()
        XCTAssertTrue(app.navigationBars["Jargon"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.textFields["Search"].waitForExistence(timeout: 5))
        // The list is lazy, so only near-the-top entries are guaranteed to be materialized
        // without scrolling -- "0" is the very first entry in the bundled dictionary.
        XCTAssertTrue(app.staticTexts["0"].waitForExistence(timeout: 5))
    }

    func testSearchNarrowsResultsAndOpensDetail() {
        let app = launchedApp()
        let search = app.textFields["Search"]
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap()
        search.typeText("hacker")

        let cell = app.staticTexts["hacker"]
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        cell.tap()

        XCTAssertTrue(app.navigationBars["hacker"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "hack")).firstMatch.waitForExistence(timeout: 5))
    }

    func testFavoriteToggleInDetailAndFilterInList() {
        let app = launchedApp()
        let search = app.textFields["Search"]
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap()
        search.typeText("hacker")

        let cell = app.staticTexts["hacker"]
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        cell.tap()
        XCTAssertTrue(app.navigationBars["hacker"].waitForExistence(timeout: 5))

        // Starting favorite state may carry over from a previous run -- handle both.
        let wasAlreadyFavorite = app.navigationBars["hacker"].buttons["Remove from favorites"].exists
        let favoriteButton = wasAlreadyFavorite
            ? app.navigationBars["hacker"].buttons["Remove from favorites"]
            : app.navigationBars["hacker"].buttons["Add to favorites"]
        XCTAssertTrue(favoriteButton.waitForExistence(timeout: 5))
        favoriteButton.tap()
        let expectedLabelAfterTap = wasAlreadyFavorite ? "Add to favorites" : "Remove from favorites"
        XCTAssertTrue(app.navigationBars["hacker"].buttons[expectedLabelAfterTap].waitForExistence(timeout: 5))

        app.navigationBars["hacker"].buttons.firstMatch.tap() // back
        XCTAssertTrue(app.navigationBars["Jargon"].waitForExistence(timeout: 5))

        if !wasAlreadyFavorite {
            // "hacker" is now favorited -- confirm the favorites-only filter surfaces it.
            let showFavoritesOnly = app.navigationBars["Jargon"].buttons["Show favorites only"]
            XCTAssertTrue(showFavoritesOnly.waitForExistence(timeout: 5))
            showFavoritesOnly.tap()
            XCTAssertTrue(app.staticTexts["hacker"].waitForExistence(timeout: 5))
            app.navigationBars["Jargon"].buttons["Show all entries"].tap()
        }
    }

    func testAboutScreenShowsLicenseInfo() {
        let app = launchedApp()
        XCTAssertTrue(app.navigationBars["Jargon"].waitForExistence(timeout: 10))
        app.navigationBars["Jargon"].buttons["About"].tap()
        XCTAssertTrue(app.navigationBars["About"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["App license"].waitForExistence(timeout: 5))
        app.navigationBars["About"].buttons.firstMatch.tap() // back
        XCTAssertTrue(app.navigationBars["Jargon"].waitForExistence(timeout: 5))
    }

    func testShuffleOpensSomeEntryDetail() {
        let app = launchedApp()
        XCTAssertTrue(app.navigationBars["Jargon"].waitForExistence(timeout: 10))
        app.navigationBars["Jargon"].buttons["Random entry"].tap()
        // Any entry detail navigation bar appears (title varies), proven by leaving the list's own bar.
        let leftList = NSPredicate(format: "identifier != %@", "Jargon")
        XCTAssertTrue(app.navigationBars.element(matching: leftList).waitForExistence(timeout: 5))
    }

    func testTappingCrossReferenceNavigatesToTargetEntry() {
        let app = launchedApp()
        let search = app.textFields["Search"]
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap()
        search.typeText("AFJ")

        let cell = app.staticTexts["AFJ"]
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        cell.tap()
        XCTAssertTrue(app.navigationBars["AFJ"].waitForExistence(timeout: 5))

        let seeAlso = app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "See also")).firstMatch
        XCTAssertTrue(seeAlso.waitForExistence(timeout: 5))
        // "See also: kremvax" -- tap near the end of the line, where the "kremvax" link is.
        let point = seeAlso.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5))
        point.tap()

        XCTAssertTrue(app.navigationBars["kremvax"].waitForExistence(timeout: 5))
    }
}
