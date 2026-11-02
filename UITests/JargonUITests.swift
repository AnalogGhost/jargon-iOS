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

    func testClearSearchButtonResetsList() {
        let app = launchedApp()
        let search = app.textFields["Search"]
        XCTAssertTrue(search.waitForExistence(timeout: 10))

        // No clear button until there's text to clear.
        XCTAssertFalse(app.buttons["Clear search"].exists)

        search.tap()
        search.typeText("hacker")
        let clearButton = app.buttons["Clear search"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["hacker"].waitForExistence(timeout: 5))

        clearButton.tap()
        // Back to the unfiltered list -- "0" (the first bundled entry) is visible again.
        XCTAssertTrue(app.staticTexts["0"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Clear search"].exists)
        XCTAssertEqual(search.value as? String, "Search")
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

        // On iPad the list is already beside the entry, and the bar's first button is the star.
        if !isPad {
            app.navigationBars["hacker"].buttons.firstMatch.tap() // back
        }
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
        if isPad {
            // About fills the detail column beside the list, so there's no back to tap.
            XCTAssertTrue(app.navigationBars["Jargon"].exists)
            return
        }
        app.navigationBars["About"].buttons.firstMatch.tap() // back
        XCTAssertTrue(app.navigationBars["Jargon"].waitForExistence(timeout: 5))
    }

    // MARK: - iPad split view

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    func testSplitViewShowsWordOfTheDayBesideTheList() throws {
        try XCTSkipUnless(isPad, "The split view is iPad-only")
        let app = launchedApp()
        XCTAssertTrue(app.navigationBars["Jargon"].waitForExistence(timeout: 10))
        let openEntry = app.buttons["Open entry"]
        XCTAssertTrue(openEntry.waitForExistence(timeout: 5))
        openEntry.tap()
        // The word of the day opens as a regular entry, so the button goes away.
        let entryBar = NSPredicate(format: "identifier != %@", "Jargon")
        XCTAssertTrue(app.navigationBars.element(matching: entryBar).waitForExistence(timeout: 5))
        XCTAssertFalse(openEntry.exists)
    }

    func testSplitViewKeepsTheListBesideTheOpenEntry() throws {
        try XCTSkipUnless(isPad, "The split view is iPad-only")
        let app = launchedApp()
        let search = app.textFields["Search"]
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap()
        search.typeText("hacker")
        let cell = app.staticTexts["hacker"]
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        cell.tap()

        XCTAssertTrue(app.navigationBars["hacker"].waitForExistence(timeout: 5))
        // The list stays put, and picking another entry replaces the detail.
        XCTAssertTrue(app.navigationBars["Jargon"].exists)
        XCTAssertFalse(app.buttons["Open entry"].exists)
        app.buttons["Clear search"].tap()
        search.tap()
        search.typeText("kludge")
        let kludge = app.staticTexts["kludge"]
        XCTAssertTrue(kludge.waitForExistence(timeout: 5))
        kludge.tap()
        XCTAssertTrue(app.navigationBars["kludge"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars["hacker"].exists)
    }

    func testSplitViewCrossReferencePushesInTheDetailColumn() throws {
        try XCTSkipUnless(isPad, "The split view is iPad-only")
        let app = XCUIApplication()
        app.launchArguments += ["--simulate-open-url", "jargon://entry/AFJ"]
        app.launch()
        XCTAssertTrue(app.navigationBars["AFJ"].waitForExistence(timeout: 10))

        let seeAlso = app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "See also")).firstMatch
        XCTAssertTrue(seeAlso.waitForExistence(timeout: 5))
        seeAlso.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5)).tap()

        let kremvax = app.navigationBars["kremvax"]
        XCTAssertTrue(kremvax.waitForExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["Jargon"].exists)
        // Back in the detail column returns to the entry the link came from.
        kremvax.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["AFJ"].waitForExistence(timeout: 5))
    }

    func testShuffleOpensSomeEntryDetail() {
        let app = launchedApp()
        XCTAssertTrue(app.navigationBars["Jargon"].waitForExistence(timeout: 10))
        app.navigationBars["Jargon"].buttons["Random entry"].tap()
        // Any entry detail navigation bar appears (title varies), proven by leaving the list's own bar.
        let leftList = NSPredicate(format: "identifier != %@", "Jargon")
        XCTAssertTrue(app.navigationBars.element(matching: leftList).waitForExistence(timeout: 5))
    }

    func testRandomEntryQuickActionOpensAnEntry() {
        let app = XCUIApplication()
        app.launchArguments += ["--simulate-random-entry-shortcut"]
        app.launch()
        // Should land directly on some entry's detail, not the list.
        let leftList = NSPredicate(format: "identifier != %@", "Jargon")
        XCTAssertTrue(app.navigationBars.element(matching: leftList).waitForExistence(timeout: 10))
    }

    func testWidgetLinkOpensThatEntry() {
        let app = XCUIApplication()
        app.launchArguments += ["--simulate-open-url", "jargon://entry/kludge"]
        app.launch()
        XCTAssertTrue(app.navigationBars["kludge"].waitForExistence(timeout: 10))
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
